#!/usr/bin/env bash
set -euo pipefail

PROGRAM=${0##*/}
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SCRIPT_PATH="$SCRIPT_DIR/$PROGRAM"

usage() {
  cat <<'EOF'
Usage:
  compose.sh --input FILE --output FILE.png --width PX --height PX [options]
  compose.sh --self-check

Compose a foreground screenshot onto an exact PNG canvas. The foreground keeps
its aspect ratio. Outer margin (canvas to base) and padding (base to foreground)
are independent. The base alone receives --base-opacity; foreground opacity is
preserved. Opaque input with a translucent base requires explicit background
extraction. Existing outputs are protected unless --overwrite is explicit.

Required:
  --input FILE             Foreground screenshot
  --output FILE.png        Final PNG path
  --width PX               Exact canvas width
  --height PX              Exact canvas height

Options:
  --wallpaper FILE         Crop wallpaper to fill the canvas (default: alpha)
  --outer-margin PX        Canvas-to-base margin (default: 64)
  --padding PX             Base-to-foreground padding (default: 24)
  --base-color COLOR       ImageMagick color (default: #10141a)
  --base-opacity 0..1      Base alpha only (default: 0.88)
  --source-background COLOR
                           Explicit opaque source background to make transparent
  --source-fuzz 0..3       Source color match tolerance in percent (default: 0)
  --wallpaper-dim 0..1     Black overlay applied to wallpaper (default: 0.20)
  --radius PX              Product-layer corner radius (default: 24)
  --shadow                 Add a restrained neutral shadow (default: off)
  --allow-upscale          Permit foreground enlargement (default: shrink only)
  --overwrite              Permit replacing an existing output
  --dry-run                Validate and print the plan without writing
  --self-check             Test extraction, alpha, geometry, wallpaper, safety
  -h, --help               Show this help

Examples:
  compose.sh --input terminal.png --output /tmp/preview.png \
    --width 1600 --height 900 --outer-margin 80 --padding 32 \
    --source-background '#10141a' --source-fuzz 0.5 --dry-run

  compose.sh --input app.png --output approved.png --wallpaper wall.jpg \
    --width 1600 --height 900 --base-opacity 1 --overwrite

Source extraction globally keys pixels matching COLOR. Keep fuzz at 0 for exact
PNG backgrounds and raise it only enough for known capture variation. Matching
colors in intentional surfaces can also be removed; inspect alpha at 100%.
Keep base/source colors equal for preblended antialiased edges; recoloring needs
real renderer alpha.
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

is_unit_interval() {
  awk -v value="$1" 'BEGIN {
    if (value !~ /^([0-9]+([.][0-9]*)?|[.][0-9]+)$/) exit 1
    exit !(value >= 0 && value <= 1)
  }'
}

is_source_fuzz() {
  awk -v value="$1" 'BEGIN {
    if (value !~ /^([0-9]+([.][0-9]*)?|[.][0-9]+)$/) exit 1
    exit !(value >= 0 && value <= 3)
  }'
}

alpha_at() {
  magick "$1" -crop "1x1+$2+$3" +repage -alpha extract \
    -format '%[fx:round(255*mean)]' info:
}

require_magick() {
  command -v magick >/dev/null 2>&1 || die "ImageMagick 7 'magick' is required; check installed tools before installing"
}

self_check() {
  require_magick
  local fixture transparent_output wallpaper wallpaper_output dimensions extrema
  local outer_alpha padding_alpha keyed_alpha glyph_alpha surface_alpha wallpaper_alpha
  local base_rgb wallpaper_base_rgb
  check_dir=$(mktemp -d "${TMPDIR:-/tmp}/compose-self-check.XXXXXX")
  trap 'rm -rf -- "$check_dir"' EXIT INT TERM
  fixture="$check_dir/opaque-fixture.png"
  transparent_output="$check_dir/transparent-output.png"
  wallpaper="$check_dir/wallpaper.png"
  wallpaper_output="$check_dir/wallpaper-output.png"

  # Opaque source background with separate opaque glyph and styled-surface colors.
  magick -size 60x30 xc:'#102030' \
    -fill white -draw 'rectangle 10,10 18,18' \
    -fill '#d05040' -draw 'rectangle 30,5 48,20' \
    -strip -define png:exclude-chunks=date,time "PNG24:$fixture"
  magick -size 80x50 xc:'#4080c0' -strip \
    -define png:exclude-chunks=date,time "PNG24:$wallpaper"

  if bash "$SCRIPT_PATH" --input "$fixture" --output "$check_dir/must-fail.png" \
    --width 80 --height 50 --outer-margin 5 --padding 5 \
    --base-color '#102030' --base-opacity 0.5 --radius 1 >/dev/null 2>&1; then
    die "self-check found opaque input accepted with translucent base and no extraction"
  fi
  if bash "$SCRIPT_PATH" --input "$fixture" --output "$check_dir/wrong-key.png" \
    --width 80 --height 50 --outer-margin 5 --padding 5 \
    --base-color '#102030' --base-opacity 0.5 --source-background '#010203' \
    --radius 1 --dry-run >/dev/null 2>&1; then
    die "self-check found nonmatching source background accepted"
  fi
  if bash "$SCRIPT_PATH" --input "$fixture" --output "$check_dir/excess-fuzz.png" \
    --width 80 --height 50 --outer-margin 5 --padding 5 \
    --source-background '#102030' --source-fuzz 3.1 --dry-run >/dev/null 2>&1; then
    die "self-check found out-of-bounds source fuzz accepted"
  fi

  bash "$SCRIPT_PATH" --input "$fixture" --output "$transparent_output" \
    --width 80 --height 50 --outer-margin 5 --padding 5 \
    --base-color '#102030' --base-opacity 0.5 --source-background '#102030' \
    --source-fuzz 0 --radius 1 >/dev/null

  dimensions=$(magick identify -format '%wx%h' "$transparent_output")
  [ "$dimensions" = "80x50" ] || die "self-check expected 80x50, got $dimensions"
  extrema=$(magick "$transparent_output" -alpha extract -format '%[fx:round(255*minima)] %[fx:round(255*maxima)]' info:)
  [ "$extrema" = "0 255" ] || die "self-check expected alpha extrema 0 255, got $extrema"
  outer_alpha=$(alpha_at "$transparent_output" 0 0)
  padding_alpha=$(alpha_at "$transparent_output" 7 25)
  keyed_alpha=$(alpha_at "$transparent_output" 12 12)
  glyph_alpha=$(alpha_at "$transparent_output" 22 22)
  surface_alpha=$(alpha_at "$transparent_output" 45 18)
  [ "$outer_alpha" -eq 0 ] || die "self-check expected transparent outer margin, got alpha $outer_alpha"
  [ "$padding_alpha" -ge 126 ] && [ "$padding_alpha" -le 129 ] || die "self-check expected fractional padding/base alpha, got $padding_alpha"
  [ "$keyed_alpha" -ge 126 ] && [ "$keyed_alpha" -le 129 ] || die "self-check expected fractional keyed-background alpha, got $keyed_alpha"
  [ "$glyph_alpha" -eq 255 ] || die "self-check expected opaque glyph, got alpha $glyph_alpha"
  [ "$surface_alpha" -eq 255 ] || die "self-check expected opaque styled surface, got alpha $surface_alpha"

  bash "$SCRIPT_PATH" --input "$fixture" --output "$wallpaper_output" \
    --wallpaper "$wallpaper" --wallpaper-dim 0 \
    --width 80 --height 50 --outer-margin 5 --padding 5 \
    --base-color '#102030' --base-opacity 0.5 --source-background '#102030' \
    --source-fuzz 0 --radius 1 >/dev/null
  dimensions=$(magick identify -format '%wx%h' "$wallpaper_output")
  [ "$dimensions" = "80x50" ] || die "self-check expected wallpaper output 80x50, got $dimensions"
  wallpaper_alpha=$(magick "$wallpaper_output" -alpha extract -format '%[fx:round(255*minima)]' info:)
  [ "$wallpaper_alpha" -eq 255 ] || die "self-check expected opaque wallpaper output, got alpha minimum $wallpaper_alpha"
  base_rgb=$(magick -size 1x1 xc:'#102030' -format '%[pixel:p{0,0}]' info:)
  wallpaper_base_rgb=$(magick "$wallpaper_output" -format '%[pixel:p{12,12}]' info:)
  [ "$wallpaper_base_rgb" != "$base_rgb" ] || die "self-check expected wallpaper to show through translucent base"
  [ "$(alpha_at "$wallpaper_output" 22 22)" -eq 255 ] || die "self-check expected opaque wallpaper-composited glyph"
  [ "$(alpha_at "$wallpaper_output" 45 18)" -eq 255 ] || die "self-check expected opaque wallpaper-composited surface"

  if bash "$SCRIPT_PATH" --input "$fixture" --output "$transparent_output" \
    --width 80 --height 50 --base-opacity 1 >/dev/null 2>&1; then
    die "self-check found overwrite protection failure"
  fi
  bash "$SCRIPT_PATH" --input "$fixture" --output "$check_dir/dry.png" \
    --width 80 --height 50 --outer-margin 5 --padding 5 --base-opacity 1 \
    --radius 1 --dry-run >/dev/null
  [ ! -e "$check_dir/dry.png" ] || die "self-check found dry-run wrote an output"

  printf 'self-check passed: opaque-source refusal, conservative keying, fractional base/padding, opaque glyph/surface, wallpaper-through-base, exact dimensions, overwrite protection, dry-run\n'
}

input=
output=
width=
height=
wallpaper=
outer_margin=64
padding=24
base_color='#10141a'
base_opacity=0.88
source_background=
source_fuzz=0
wallpaper_dim=0.20
radius=24
shadow=0
allow_upscale=0
overwrite=0
dry_run=0
run_self_check=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --input) need_value "$@"; input=$2; shift 2 ;;
    --output) need_value "$@"; output=$2; shift 2 ;;
    --width) need_value "$@"; width=$2; shift 2 ;;
    --height) need_value "$@"; height=$2; shift 2 ;;
    --wallpaper) need_value "$@"; wallpaper=$2; shift 2 ;;
    --outer-margin) need_value "$@"; outer_margin=$2; shift 2 ;;
    --padding) need_value "$@"; padding=$2; shift 2 ;;
    --base-color) need_value "$@"; base_color=$2; shift 2 ;;
    --base-opacity) need_value "$@"; base_opacity=$2; shift 2 ;;
    --source-background) need_value "$@"; source_background=$2; shift 2 ;;
    --source-fuzz) need_value "$@"; source_fuzz=$2; shift 2 ;;
    --wallpaper-dim) need_value "$@"; wallpaper_dim=$2; shift 2 ;;
    --radius) need_value "$@"; radius=$2; shift 2 ;;
    --shadow) shadow=1; shift ;;
    --allow-upscale) allow_upscale=1; shift ;;
    --overwrite) overwrite=1; shift ;;
    --dry-run) dry_run=1; shift ;;
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

[ -n "$input" ] || die "--input is required"
[ -n "$output" ] || die "--output is required"
[ -n "$width" ] || die "--width is required"
[ -n "$height" ] || die "--height is required"
[ -r "$input" ] || die "input is not readable: $input"
[ -z "$wallpaper" ] || [ -r "$wallpaper" ] || die "wallpaper is not readable: $wallpaper"

for pair in "width:$width" "height:$height" "outer-margin:$outer_margin" "padding:$padding" "radius:$radius"; do
  name=${pair%%:*}
  value=${pair#*:}
  is_uint "$value" || die "--$name must be a non-negative integer"
done
[ "$width" -gt 0 ] || die "--width must be greater than zero"
[ "$height" -gt 0 ] || die "--height must be greater than zero"
is_unit_interval "$base_opacity" || die "--base-opacity must be between 0 and 1"
is_source_fuzz "$source_fuzz" || die "--source-fuzz must be a percentage between 0 and 3"
source_fuzz_is_zero=$(awk -v value="$source_fuzz" 'BEGIN { print (value == 0) ? "yes" : "no" }')
[ -n "$source_background" ] || [ "$source_fuzz_is_zero" = yes ] || die "--source-fuzz requires --source-background"
is_unit_interval "$wallpaper_dim" || die "--wallpaper-dim must be between 0 and 1"

case "$output" in
  *.[Pp][Nn][Gg]) ;;
  *) die "--output must end in .png (required for deterministic alpha handling)" ;;
esac

output_dir=$(dirname -- "$output")
[ -d "$output_dir" ] || die "output directory does not exist: $output_dir"
[ -w "$output_dir" ] || die "output directory is not writable: $output_dir"
if [ -e "$output" ] && [ "$overwrite" -ne 1 ]; then
  die "output exists; use a fresh preview path or explicit --overwrite after approval: $output"
fi

input_abs=$(CDPATH= cd -- "$(dirname -- "$input")" && printf '%s/%s' "$PWD" "$(basename -- "$input")")
output_abs=$(CDPATH= cd -- "$output_dir" && printf '%s/%s' "$PWD" "$(basename -- "$output")")
[ "$input_abs" != "$output_abs" ] || die "input and output must be different files"
if [ -n "$wallpaper" ]; then
  wallpaper_abs=$(CDPATH= cd -- "$(dirname -- "$wallpaper")" && printf '%s/%s' "$PWD" "$(basename -- "$wallpaper")")
  [ "$wallpaper_abs" != "$output_abs" ] || die "wallpaper and output must be different files"
fi

base_width=$((width - 2 * outer_margin))
base_height=$((height - 2 * outer_margin))
[ "$base_width" -gt 0 ] && [ "$base_height" -gt 0 ] || die "outer margin leaves no base area"
inner_width=$((base_width - 2 * padding))
inner_height=$((base_height - 2 * padding))
[ "$inner_width" -gt 0 ] && [ "$inner_height" -gt 0 ] || die "padding leaves no foreground area"
max_radius=$((base_width < base_height ? base_width / 2 : base_height / 2))
[ "$radius" -le "$max_radius" ] || die "radius exceeds half the smaller base dimension ($max_radius)"

require_magick
magick -size 1x1 "xc:$base_color" null: 2>/dev/null || die "ImageMagick does not recognize --base-color: $base_color"
if [ -n "$source_background" ]; then
  magick -size 1x1 "xc:$source_background" null: 2>/dev/null || \
    die "ImageMagick does not recognize --source-background: $source_background"
fi
input_alpha_min=$(magick "$input" -alpha extract -format '%[fx:round(255*minima)]' info:)
base_is_translucent=$(awk -v value="$base_opacity" 'BEGIN { print (value < 1) ? "yes" : "no" }')
if [ "$input_alpha_min" -eq 255 ] && [ "$base_is_translucent" = yes ] && [ -z "$source_background" ]; then
  die "input is fully opaque while --base-opacity is below 1; provide --source-background COLOR (and conservative --source-fuzz if needed), supply a real-alpha source, or use --base-opacity 1"
fi
if [ "$input_alpha_min" -eq 255 ] && [ -n "$source_background" ]; then
  source_key_extrema=$(magick "$input" -auto-orient -alpha set -fuzz "${source_fuzz}%" \
    -transparent "$source_background" -alpha extract \
    -format '%[fx:round(255*minima)] %[fx:round(255*maxima)]' info:)
  source_key_alpha_min=${source_key_extrema%% *}
  source_key_alpha_max=${source_key_extrema##* }
  [ "$source_key_alpha_min" -lt 255 ] || \
    die "--source-background/--source-fuzz matched no source pixels; refusing fake translucency"
  [ "$source_key_alpha_max" -eq 255 ] || \
    die "source extraction would leave no fully opaque foreground; use the exact background color and lower --source-fuzz"
fi

if [ "$allow_upscale" -eq 1 ]; then
  resize_geometry="${inner_width}x${inner_height}"
else
  resize_geometry="${inner_width}x${inner_height}>"
fi
wallpaper_label=${wallpaper:-transparent}

printf 'compose plan\n'
printf '  input: %s\n' "$input_abs"
printf '  output: %s\n' "$output_abs"
printf '  canvas: %sx%s\n' "$width" "$height"
printf '  base: %sx%s (outer margin %s)\n' "$base_width" "$base_height" "$outer_margin"
printf '  foreground fit: %sx%s (internal padding %s, preserve aspect, upscale %s)\n' \
  "$inner_width" "$inner_height" "$padding" "$allow_upscale"
printf '  base color/opacity: %s / %s\n' "$base_color" "$base_opacity"
printf '  source alpha minimum/background/fuzz: %s / %s / %s%%\n' \
  "$input_alpha_min" "${source_background:-none}" "$source_fuzz"
printf '  wallpaper/dim: %s / %s\n' "$wallpaper_label" "$wallpaper_dim"
printf '  radius/shadow: %s / %s\n' "$radius" "$shadow"
printf '  overwrite/dry-run: %s / %s\n' "$overwrite" "$dry_run"

[ "$dry_run" -eq 0 ] || exit 0

tmp_dir=$(mktemp -d "$output_dir/.compose.XXXXXX")
trap 'rm -rf -- "$tmp_dir"' EXIT INT TERM

foreground="$tmp_dir/foreground.png"
base="$tmp_dir/base.png"
layer="$tmp_dir/layer.png"
mask="$tmp_dir/mask.png"
alpha="$tmp_dir/alpha.png"
combined_alpha="$tmp_dir/combined-alpha.png"
product="$tmp_dir/product.png"
canvas="$tmp_dir/canvas.png"
product_canvas="$tmp_dir/product-canvas.png"
final="$tmp_dir/final.png"

if [ -n "$source_background" ]; then
  magick "$input" -auto-orient -alpha set -fuzz "${source_fuzz}%" \
    -transparent "$source_background" -resize "$resize_geometry" -strip \
    -define png:exclude-chunks=date,time "PNG32:$foreground"
  foreground_extrema=$(magick "$foreground" -alpha extract \
    -format '%[fx:round(255*minima)] %[fx:round(255*maxima)]' info:)
  foreground_alpha_min=${foreground_extrema%% *}
  foreground_alpha_max=${foreground_extrema##* }
  [ "$foreground_alpha_min" -lt 255 ] || \
    die "--source-background/--source-fuzz matched no pixels; refusing fake translucency"
  [ "$foreground_alpha_max" -eq 255 ] || \
    die "source extraction left no fully opaque foreground; use the exact background color and lower --source-fuzz"
else
  magick "$input" -auto-orient -resize "$resize_geometry" -strip \
    -define png:exclude-chunks=date,time "PNG32:$foreground"
fi
magick -size "${base_width}x${base_height}" "xc:$base_color" -alpha set \
  -channel A -evaluate multiply "$base_opacity" +channel -strip \
  -define png:exclude-chunks=date,time "PNG32:$base"
magick "$base" "$foreground" -gravity center -compose over -composite \
  -strip -define png:exclude-chunks=date,time "PNG32:$layer"
magick -size "${base_width}x${base_height}" xc:black -fill white \
  -draw "roundrectangle 0,0 $((base_width - 1)),$((base_height - 1)) $radius,$radius" \
  -strip "$mask"
magick "$layer" -alpha extract "$alpha"
magick "$alpha" "$mask" -compose multiply -composite "$combined_alpha"
magick "$layer" "$combined_alpha" -alpha off -compose copyopacity -composite \
  -strip -define png:exclude-chunks=date,time "PNG32:$product"

if [ -n "$wallpaper" ]; then
  dim_percent=$(awk -v value="$wallpaper_dim" 'BEGIN { printf "%.4f", value * 100 }')
  magick "$wallpaper" -auto-orient -background black -alpha remove -alpha off \
    -resize "${width}x${height}^" -gravity center -extent "${width}x${height}" \
    -fill black -colorize "${dim_percent}%" -strip \
    -define png:exclude-chunks=date,time "PNG24:$canvas"
else
  magick -size "${width}x${height}" xc:none -strip \
    -define png:exclude-chunks=date,time "PNG32:$canvas"
fi

magick -size "${width}x${height}" xc:none "$product" -gravity center \
  -compose over -composite -strip "PNG32:$product_canvas"

if [ "$shadow" -eq 1 ]; then
  shadow_alpha="$tmp_dir/shadow-alpha.png"
  shadow_layer="$tmp_dir/shadow-layer.png"
  shadowed_canvas="$tmp_dir/shadowed-canvas.png"
  magick "$product_canvas" -alpha extract -blur 0x12 -evaluate multiply 0.30 "$shadow_alpha"
  magick -size "${width}x${height}" xc:black "$shadow_alpha" -alpha off \
    -compose copyopacity -composite "PNG32:$shadow_layer"
  magick "$canvas" "$shadow_layer" -gravity center -geometry +0+8 \
    -compose over -composite "PNG32:$shadowed_canvas"
  canvas="$shadowed_canvas"
fi

if [ -n "$wallpaper" ]; then
  magick "$canvas" "$product_canvas" -compose over -composite -background black \
    -alpha remove -alpha off -strip -define png:exclude-chunks=date,time "PNG24:$final"
else
  magick "$canvas" "$product_canvas" -compose over -composite -strip \
    -define png:exclude-chunks=date,time "PNG32:$final"
fi

final_dimensions=$(magick identify -format '%wx%h' "$final")
[ "$final_dimensions" = "${width}x${height}" ] || die "internal error: expected ${width}x${height}, got $final_dimensions"
if [ "$overwrite" -eq 1 ]; then
  mv -f -- "$final" "$output_abs"
else
  if ! ln -- "$final" "$output_abs"; then
    die "output appeared during composition; refusing to overwrite: $output_abs"
  fi
  rm -f -- "$final"
fi
printf 'wrote: %s\n' "$output_abs"
