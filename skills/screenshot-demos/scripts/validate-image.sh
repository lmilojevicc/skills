#!/usr/bin/env bash
set -euo pipefail

PROGRAM=${0##*/}
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SCRIPT_PATH="$SCRIPT_DIR/$PROGRAM"

usage() {
  cat <<'EOF'
Usage:
  validate-image.sh --image FILE [expectations]
  validate-image.sh --self-check

Print deterministic image evidence and fail when an expectation is not met.
Requires ImageMagick 7. This complements—not replaces—visual/privacy review.

Options:
  --image FILE              Image to inspect
  --expect-width PX         Required pixel width
  --expect-height PX        Required pixel height
  --expect-display WxH      Intended rendered size; require matching aspect and
                            enough source pixels for at least 1x display
  --max-bytes N             Maximum file size
  --require-alpha           Require an alpha channel, some transparency, and
                            some fully opaque foreground pixels
  --forbid-alpha            Require no alpha channel and fully opaque pixels
  --self-check              Generate fixtures and exercise pass/fail checks
  -h, --help                Show this help

The report includes format, dimensions, bytes, channels, colorspace, alpha
extrema, embedded profiles, and SHA-256. Inspect the image at 100% and at
--expect-display size, then perform the privacy/provenance checklist manually.
EOF
}

die() {
  printf '%s: %s\n' "$PROGRAM" "$*" >&2
  exit 1
}

need_value() {
  [ "$#" -ge 2 ] || die "$1 requires a value"
}

is_uint() {
  case "$1" in
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

require_magick() {
  command -v magick >/dev/null 2>&1 || die "ImageMagick 7 'magick' is required; check installed tools before installing"
}

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 -- "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum -- "$1" | awk '{print $1}'
  else
    die "shasum or sha256sum is required for SHA-256 evidence"
  fi
}

self_check() {
  require_magick
  check_dir=$(mktemp -d "${TMPDIR:-/tmp}/validate-image-self-check.XXXXXX")
  trap 'rm -rf -- "$check_dir"' EXIT INT TERM
  local alpha_image opaque_image
  alpha_image="$check_dir/alpha.png"
  opaque_image="$check_dir/opaque.png"

  magick -size 20x10 xc:none -fill white -draw 'rectangle 5,2 14,7' \
    -strip -define png:exclude-chunks=date,time "PNG32:$alpha_image"
  magick -size 20x10 xc:white -strip -define png:exclude-chunks=date,time "PNG24:$opaque_image"

  bash "$SCRIPT_PATH" --image "$alpha_image" --expect-width 20 --expect-height 10 \
    --expect-display 10x5 --require-alpha --max-bytes 10000 >/dev/null
  bash "$SCRIPT_PATH" --image "$opaque_image" --expect-width 20 --expect-height 10 \
    --forbid-alpha >/dev/null

  if bash "$SCRIPT_PATH" --image "$alpha_image" --expect-width 21 >/dev/null 2>&1; then
    die "self-check found dimension failure was not detected"
  fi
  if bash "$SCRIPT_PATH" --image "$opaque_image" --require-alpha >/dev/null 2>&1; then
    die "self-check found missing alpha was not detected"
  fi
  if bash "$SCRIPT_PATH" --image "$alpha_image" --expect-display 10x10 >/dev/null 2>&1; then
    die "self-check found display aspect mismatch was not detected"
  fi

  printf 'self-check passed: dimensions, bytes, display aspect/scale, alpha modes, SHA-256\n'
}

image=
expect_width=
expect_height=
expect_display=
max_bytes=
alpha_mode=either
run_self_check=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --image) need_value "$@"; image=$2; shift 2 ;;
    --expect-width) need_value "$@"; expect_width=$2; shift 2 ;;
    --expect-height) need_value "$@"; expect_height=$2; shift 2 ;;
    --expect-display) need_value "$@"; expect_display=$2; shift 2 ;;
    --max-bytes) need_value "$@"; max_bytes=$2; shift 2 ;;
    --require-alpha)
      [ "$alpha_mode" != forbid ] || die "--require-alpha conflicts with --forbid-alpha"
      alpha_mode=require
      shift
      ;;
    --forbid-alpha)
      [ "$alpha_mode" != require ] || die "--forbid-alpha conflicts with --require-alpha"
      alpha_mode=forbid
      shift
      ;;
    --self-check) run_self_check=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; [ "$#" -eq 0 ] || die "unexpected positional arguments: $*" ;;
    -*) die "unknown option: $1" ;;
    *) die "unexpected positional argument: $1" ;;
  esac
done

if [ "$run_self_check" -eq 1 ]; then
  self_check
  exit 0
fi

[ -n "$image" ] || die "--image is required"
[ -r "$image" ] || die "image is not readable: $image"
for pair in "expect-width:$expect_width" "expect-height:$expect_height" "max-bytes:$max_bytes"; do
  name=${pair%%:*}
  value=${pair#*:}
  if [ -n "$value" ]; then
    is_uint "$value" || die "--$name must be a non-negative integer"
  fi
done

if [ -n "$expect_display" ]; then
  case "$expect_display" in
    *x*) display_width=${expect_display%x*}; display_height=${expect_display#*x} ;;
    *) die "--expect-display must be WIDTHxHEIGHT" ;;
  esac
  is_uint "$display_width" && is_uint "$display_height" || die "--expect-display must be WIDTHxHEIGHT with integers"
  [ "$display_width" -gt 0 ] && [ "$display_height" -gt 0 ] || die "--expect-display dimensions must be greater than zero"
fi

require_magick
format=$(magick identify -format '%m' "$image")
width=$(magick identify -format '%w' "$image")
height=$(magick identify -format '%h' "$image")
channels=$(magick identify -format '%[channels]' "$image")
colorspace=$(magick identify -format '%[colorspace]' "$image")
bytes=$(wc -c < "$image" | tr -d '[:space:]')
alpha_extrema=$(magick "$image" -alpha extract -format '%[fx:round(255*minima)] %[fx:round(255*maxima)]' info:)
alpha_min=${alpha_extrema%% *}
alpha_max=${alpha_extrema##* }
profiles=$(magick identify -format '%[profiles]' "$image" 2>/dev/null || true)
[ -n "$profiles" ] || profiles=none
sha256=$(sha256_file "$image")

[ -z "$expect_width" ] || [ "$width" -eq "$expect_width" ] || die "expected width $expect_width, got $width"
[ -z "$expect_height" ] || [ "$height" -eq "$expect_height" ] || die "expected height $expect_height, got $height"
[ -z "$max_bytes" ] || [ "$bytes" -le "$max_bytes" ] || die "file has $bytes bytes, exceeds $max_bytes"

case "$alpha_mode" in
  require)
    case "$channels" in *a*) ;; *) die "alpha channel required; channels are $channels" ;; esac
    [ "$alpha_min" -lt 255 ] || die "real transparency required; all pixels are opaque"
    [ "$alpha_max" -eq 255 ] || die "fully opaque foreground pixels required; alpha maximum is $alpha_max"
    ;;
  forbid)
    case "$channels" in *a*) die "alpha channel forbidden; channels are $channels" ;; esac
    [ "$alpha_min" -eq 255 ] && [ "$alpha_max" -eq 255 ] || die "fully opaque pixels required"
    ;;
esac

if [ -n "$expect_display" ]; then
  aspect_ok=$(awk -v sw="$width" -v sh="$height" -v dw="$display_width" -v dh="$display_height" 'BEGIN {
    delta = sw * dh - sh * dw
    if (delta < 0) delta = -delta
    scale = sw * dh
    if (scale == 0) exit 1
    print (delta / scale <= 0.001) ? "yes" : "no"
  }')
  [ "$aspect_ok" = yes ] || die "source ${width}x${height} and display ${expect_display} differ in aspect ratio"
  [ "$width" -ge "$display_width" ] && [ "$height" -ge "$display_height" ] || \
    die "source ${width}x${height} is smaller than display ${expect_display}"
  display_scale=$(awk -v sw="$width" -v dw="$display_width" 'BEGIN { printf "%.3f", sw / dw }')
else
  display_scale=not-checked
fi

printf 'image=%s\n' "$image"
printf 'format=%s\n' "$format"
printf 'width=%s\n' "$width"
printf 'height=%s\n' "$height"
printf 'bytes=%s\n' "$bytes"
printf 'channels=%s\n' "$channels"
printf 'colorspace=%s\n' "$colorspace"
printf 'alpha_min_255=%s\n' "$alpha_min"
printf 'alpha_max_255=%s\n' "$alpha_max"
printf 'profiles=%s\n' "$profiles"
printf 'sha256=%s\n' "$sha256"
printf 'display=%s\n' "${expect_display:-not-checked}"
printf 'display_scale=%s\n' "$display_scale"
printf 'mechanical_validation=passed\n'
printf 'manual_review_required=100%% pixels, actual display size, clipping/tofu, privacy, provenance, credits, cleanup\n'
