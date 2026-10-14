#!/usr/bin/env bash
# Read-only detection of the terminal font/theme/palette behind a screenshot.
# This script never writes to any terminal configuration.
set -euo pipefail

PROGRAM=${0##*/}
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SCRIPT_PATH="$SCRIPT_DIR/$PROGRAM"

DEFAULT_GHOSTTY_RESOURCES=/Applications/Ghostty.app/Contents/Resources/ghostty
TERMINALS='ghostty wezterm alacritty kitty iterm2'

usage() {
  cat <<'EOF'
Usage:
  terminal-theme.sh [options]

Report the terminal font and palette an author's screenshot was rendered with,
plus a ready-to-paste VHS block. Read-only: no config is ever modified.

Options:
  --terminal NAME        Read one source only, instead of detecting all:
                         ghostty | wezterm | alacritty | kitty | iterm2
  --config PATH          Use PATH instead of the detected config
                         (requires --terminal)
  --theme-file PATH      Use PATH instead of the resolved theme file
                         (requires --terminal ghostty or kitty)
  --json                 Emit machine-readable JSON instead of the report
  --self-check           Run built-in fixtures and invariants
  -h, --help             Show this help

The report lists the config path, font family (fallbacks noted), font size,
theme name and resolved theme file, background/foreground/cursor/selection, the
full ANSI 0-15 palette, and warnings for settings a browser rasterizer cannot
reproduce. The palette is resolved from the emulator's own theme file, never
from a published palette. Values that cannot be determined are reported as
UNDETERMINED instead of guessed, and window opacity is never claimed from the
config alone: the capture is ground truth. See
references/terminal-theme-fonts.md.

When more than one terminal is configured, every one is reported and the
ambiguity is stated rather than resolved silently.

Exit status is 0 when at least one config was read, 1 when none was found.

Examples:
  terminal-theme.sh
  terminal-theme.sh --terminal ghostty --json
  terminal-theme.sh --terminal ghostty --theme-file /tmp/theme
EOF
}

die() {
  printf '%s: %s\n' "$PROGRAM" "$*" >&2
  exit 1
}

need_value() {
  [ "$#" -ge 2 ] || die "$1 requires a value"
}

is_hex() {
  case "$1" in
    '#'[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]) return 0 ;;
    *) return 1 ;;
  esac
}

is_uint_in_range() { # is_uint_in_range <value> <max>
  case "$1" in
    ''|*[!0-9]*) return 1 ;;
  esac
  [ "$1" -le "$2" ]
}

norm_hex() {
  printf '%s' "$1" | tr 'A-F' 'a-f'
}

expand_tilde() {
  case "$1" in
    '~') printf '%s\n' "$HOME" ;;
    '~/'*) printf '%s\n' "$HOME/${1#'~/'}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

abs_path() {
  local p dir base
  p=$(expand_tilde "$1")
  case "$p" in
    /*) printf '%s\n' "$p" ;;
    *)
      dir=$(dirname -- "$p")
      base=$(basename -- "$p")
      printf '%s/%s\n' "$(CDPATH= cd -- "$dir" && pwd)" "$base"
      ;;
  esac
}

dedupe_lines() {
  printf '%s\n' "$1" | awk 'NF && !seen[$0]++'
}

first_readable_file() { # expects a newline-separated list on stdin
  local p
  while IFS= read -r p; do
    if [ -n "$p" ] && [ -r "$p" ]; then
      abs_path "$p"
      return 0
    fi
  done
  return 1
}

json_string() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  printf '"%s"' "$s"
}

json_string_or_null() {
  if [ -n "$1" ]; then
    json_string "$1"
  else
    printf 'null'
  fi
}

json_number_or_null() {
  local v=$1
  case "$v" in
    '') printf 'null'; return 0 ;;
    *[!0-9.]*) json_string "$v"; return 0 ;;
  esac
  case "$v" in
    *.*.*) json_string "$v"; return 0 ;;
  esac
  printf '%s' "$v"
}

json_bool_or_null() {
  case "$1" in
    true|True|TRUE|1) printf 'true' ;;
    false|False|FALSE|0) printf 'false' ;;
    '') printf 'null' ;;
    *) json_string "$1" ;;
  esac
}

record_value() { # record_value <kind> <key> -> first value, empty when absent
  awk -F'\t' -v kind="$1" -v key="$2" '$1 == kind && $2 == key { print $3; exit }' "$RECORD_FILE"
}

record_lines() { # record_lines <kind> <key> -> all values, one per line
  awk -F'\t' -v kind="$1" -v key="$2" '$1 == kind && $2 == key { print $3 }' "$RECORD_FILE"
}

emit() {
  printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$RECORD_FILE"
}

emit_lines() { # emit_lines <kind> <key> <newline-separated values>
  local line
  while IFS= read -r line; do
    if [ -n "$line" ]; then
      emit "$1" "$2" "$line"
    fi
  done <<EOF
$3
EOF
}

reset_terminal_state() {
  SEARCHED_PATHS=
  CFG_PATH=
  FONT_FAMILY=
  FONT_FALLBACKS=
  FONT_SIZE=
  FONT_FEATURES=
  FONT_THICKEN=
  FONT_THICKEN_STRENGTH=
  THEME_NAME=
  THEME_FILE=
  THEME_BG=
  BG=
  BG_ORIGIN=
  FG=
  FG_ORIGIN=
  CURSOR=
  SEL_BG=
  SEL_FG=
  OPACITY=
  OPAQUE_ONLY_SETTING=
  BEST_EFFORT=
  WARNINGS=
  UNREPRODUCIBLE=
  UNDETERMINED=
  NOTES=
  PALETTE_FILE=
}

add_warning() { WARNINGS="${WARNINGS}${1}"$'\n'; }
add_unreproducible() { UNREPRODUCIBLE="${UNREPRODUCIBLE}${1}"$'\n'; }
add_undetermined() { UNDETERMINED="${UNDETERMINED}${1}"$'\n'; }
add_note() { NOTES="${NOTES}${1}"$'\n'; }

set_palette_entry() { # set_palette_entry <index> <#rrggbb>
  printf '%s\t%s\n' "$1" "$2" >> "$PALETTE_FILE"
}

set_palette_from_kv() { # "13=#f2aede" (ghostty palette line)
  local kv=$1 idx color
  case "$kv" in
    *=*) ;;
    *) add_undetermined "unrecognized palette entry: $kv"; return 0 ;;
  esac
  idx=${kv%%=*}
  color=${kv#*=}
  idx=$(printf '%s' "$idx" | tr -d '[:space:]')
  color=$(norm_hex "$(printf '%s' "$color" | tr -d '[:space:]')")
  if ! is_uint_in_range "$idx" 15; then
    add_undetermined "palette index out of range 0-15: $kv"
    return 0
  fi
  if ! is_hex "$color"; then
    add_undetermined "unrecognized palette color: $kv"
    return 0
  fi
  set_palette_entry "$idx" "$color"
}

palette_value() { # palette_value <index> -> last recorded value, empty when absent
  awk -F'\t' -v i="$1" '$1 == i { v=$2 } END { if (v != "") print v }' "$PALETTE_FILE"
}

# --- parsers -----------------------------------------------------------------

ghostty_config_paths() {
  local paths=
  if [ -n "${XDG_CONFIG_HOME:-}" ]; then
    paths="$XDG_CONFIG_HOME/ghostty/config
"
  fi
  paths="$paths$HOME/.config/ghostty/config
$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  dedupe_lines "$paths"
}

ghostty_theme_paths() { # ghostty_theme_paths <name>
  local name=$1 paths=
  if [ -n "${XDG_CONFIG_HOME:-}" ]; then
    paths="$XDG_CONFIG_HOME/ghostty/themes/$name
"
  fi
  paths="$paths$HOME/.config/ghostty/themes/$name
${GHOSTTY_RESOURCES_DIR:-$DEFAULT_GHOSTTY_RESOURCES}/themes/$name"
  dedupe_lines "$paths"
}

parse_key_value() { # line-oriented "key = value" config (ghostty, kitty themes)
  awk '
    {
      line = $0
      sub(/\r$/, "", line)
      if (line ~ /^[[:space:]]*#/) next
      if (line ~ /^[[:space:]]*$/) next
      eq = index(line, "=")
      if (eq == 0) next
      key = substr(line, 1, eq - 1)
      value = substr(line, eq + 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      gsub(/"/, "", value)
      if (key == "") next
      printf "%s\t%s\n", key, value
    }
  '
}

parse_kitty_conf() { # "key value" list config, including line continuations
  awk '
    {
      line = $0
      sub(/\r$/, "", line)
      if (line ~ /^[[:space:]]*#/) next
      if (line ~ /^[[:space:]]*$/) next
      if (line ~ /^[[:space:]]*include[[:space:]]/) {
        printf "include\t%s\n", line
        next
      }
      key = line
      sub(/[[:space:]].*$/, "", key)
      value = substr(line, length(key) + 1)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      printf "%s\t%s\n", key, value
    }
  '
}

parse_alacritty_toml() { # prints "section<TAB>key<TAB>value"
  awk '
    {
      line = $0
      sub(/\r$/, "", line)
      if (line ~ /^[[:space:]]*#/) next
      if (line ~ /^[[:space:]]*$/) next
      if (line ~ /^[[:space:]]*\[/) {
        section = line
        sub(/^[[:space:]]*\[/, "", section)
        sub(/\][[:space:]]*$/, "", section)
        gsub(/[[:space:]]/, "", section)
        next
      }
      eq = index(line, "=")
      if (eq == 0) next
      key = substr(line, 1, eq - 1)
      value = substr(line, eq + 1)
      sub(/[[:space:]]+#[^\n]*$/, "", value)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      gsub(/"/, "", value)
      gsub(/[[:space:]]/, "", key)
      if (key == "") next
      printf "%s\t%s\t%s\n", section, key, value
    }
  '
}

lua_block() { # lua_block <file> <substring> -> assignment block, brace-depth bounded
  awk -v needle="$2" '
    !inblk {
      p = index($0, needle)
      # Reject a longer identifier: "config.font" must not match "config.font_size".
      if (p > 0 && substr($0, p + length(needle), 1) !~ /[A-Za-z_]/) inblk = 1
    }
    inblk {
      print
      o = gsub(/[({[]/, "(")
      c = gsub(/[)}\]]/, ")")
      depth += o - c
      if (depth <= 0) exit
    }
  ' "$1"
}

lua_scalar() { # lua_scalar <file> <substring> -> value on the matching line
  awk -v needle="$2" '
    index($0, needle) > 0 { print; exit }
  ' "$1"
}

lua_families() { # first family plus fallbacks, one per line
  sed -n 's/.*family[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$1"
}

lua_quoted() {
  sed -n 's/^[^"]*"\([^"]*\)".*$/\1/p' "$1"
}

lua_hex_after() { # lua_hex_after <file> <key>
  sed -n "s/^[[:space:]]*$2[[:space:]]*=[[:space:]]*\"\(#[0-9a-fA-F]\{6\}\)\".*/\1/p" "$1" | tr 'A-F' 'a-f'
}

lua_number() { # lua_number <file> <key>
  sed -n "s/^[[:space:]]*$2[[:space:]]*=[[:space:]]*\(-\{0,1\}[0-9][0-9.]*\).*/\1/p" "$1" | sed -n '1p'
}

# --- detectors ---------------------------------------------------------------

detect_ghostty() {
  local key value entry
  SEARCHED_PATHS=$(ghostty_config_paths)
  if [ -n "$OPT_CONFIG" ]; then
    [ -r "$OPT_CONFIG" ] || die "--config is not readable: $OPT_CONFIG"
    CFG_PATH=$(abs_path "$OPT_CONFIG")
  else
    CFG_PATH=$(first_readable_file <<EOF
$SEARCHED_PATHS
EOF
) || CFG_PATH=
    [ -n "$CFG_PATH" ] || return 1
  fi

  CONFIG_PALETTE="$WORK_DIR/ghostty-config-palette.txt"
  : > "$CONFIG_PALETTE"

  while IFS=$'\t' read -r key value; do
    case "$key" in
      font-family)
        if [ -z "$FONT_FAMILY" ]; then
          FONT_FAMILY=$value
        else
          FONT_FALLBACKS="${FONT_FALLBACKS}${value}"$'\n'
        fi
        ;;
      font-size) FONT_SIZE=$value ;;
      font-feature) FONT_FEATURES=$value ;;
      font-thicken) FONT_THICKEN=$value ;;
      font-thicken-strength) FONT_THICKEN_STRENGTH=$value ;;
      theme) THEME_NAME=$value ;;
      background)
        if is_hex "$(norm_hex "$value")"; then
          BG=$(norm_hex "$value")
          BG_ORIGIN=config
        else
          add_undetermined "config background is not #rrggbb: $value"
        fi
        ;;
      foreground)
        if is_hex "$(norm_hex "$value")"; then
          FG=$(norm_hex "$value")
          FG_ORIGIN=config
        fi
        ;;
      cursor-color) if is_hex "$(norm_hex "$value")"; then CURSOR=$(norm_hex "$value"); fi ;;
      selection-background) if is_hex "$(norm_hex "$value")"; then SEL_BG=$(norm_hex "$value"); fi ;;
      selection-foreground) if is_hex "$(norm_hex "$value")"; then SEL_FG=$(norm_hex "$value"); fi ;;
      background-opacity) OPACITY=$value ;;
      alpha-blending) OPAQUE_ONLY_SETTING="alpha-blending = $value" ;;
      palette) printf '%s\n' "$value" >> "$CONFIG_PALETTE" ;;
      config-file)
        add_undetermined "config-file = $value is not followed; re-run with an explicit --config"
        ;;
    esac
  done <<EOF
$(parse_key_value < "$CFG_PATH")
EOF

  if [ -n "$OPT_THEME_FILE" ]; then
    [ -r "$OPT_THEME_FILE" ] || die "--theme-file is not readable: $OPT_THEME_FILE"
    THEME_FILE=$(abs_path "$OPT_THEME_FILE")
  elif [ -n "$THEME_NAME" ]; then
    THEME_FILE=$(first_readable_file <<EOF
$(ghostty_theme_paths "$THEME_NAME")
EOF
) || THEME_FILE=
  fi

  if [ -n "$THEME_NAME" ] && [ -z "$THEME_FILE" ]; then
    add_undetermined "theme '$THEME_NAME' did not resolve to a readable theme file (searched: $(ghostty_theme_paths "$THEME_NAME" | tr '\n' ' ')); palette left unresolved. Pass --theme-file after verifying the theme by hand"
  fi

  if [ -n "$THEME_FILE" ]; then
    while IFS=$'\t' read -r key value; do
      case "$key" in
        palette) set_palette_from_kv "$value" ;;
        background) if is_hex "$(norm_hex "$value")"; then THEME_BG=$(norm_hex "$value"); fi ;;
        foreground)
          if [ -z "$FG" ] && is_hex "$(norm_hex "$value")"; then
            FG=$(norm_hex "$value")
            FG_ORIGIN=theme
          fi
          ;;
        cursor-color) if [ -z "$CURSOR" ] && is_hex "$(norm_hex "$value")"; then CURSOR=$(norm_hex "$value"); fi ;;
        selection-background) if [ -z "$SEL_BG" ] && is_hex "$(norm_hex "$value")"; then SEL_BG=$(norm_hex "$value"); fi ;;
        selection-foreground) if [ -z "$SEL_FG" ] && is_hex "$(norm_hex "$value")"; then SEL_FG=$(norm_hex "$value"); fi ;;
      esac
    done <<EOF
$(parse_key_value < "$THEME_FILE")
EOF
    if [ -z "$BG" ] && [ -n "$THEME_BG" ]; then
      BG=$THEME_BG
      BG_ORIGIN=theme
    fi
  fi

  # A config palette line overrides the theme's own palette entry.
  while IFS= read -r entry; do
    if [ -n "$entry" ]; then
      set_palette_from_kv "$entry"
    fi
  done < "$CONFIG_PALETTE"

  case "$FONT_THICKEN" in
    true|True|TRUE|1)
      add_unreproducible "font-thicken = true${FONT_THICKEN_STRENGTH:+ (font-thicken-strength = $FONT_THICKEN_STRENGTH)}; a browser rasterizer cannot thicken glyph strokes, so text renders thinner than the capture"
      ;;
  esac
  if [ -n "$FONT_FEATURES" ]; then
    add_unreproducible "font-feature = $FONT_FEATURES; VHS sets no CSS font-feature-settings, so ligatures/contextual alternates stay enabled and advances can differ"
  fi
  if [ -n "$OPAQUE_ONLY_SETTING" ]; then
    add_unreproducible "$OPAQUE_ONLY_SETTING; emulator-side blending is not reproduced by a browser rasterizer, so translucent overlaps will differ"
  fi
  if [ -z "$OPACITY" ]; then
    add_note "background-opacity is not set in this config; do not report the window as opaque or translucent from the config alone. Measure alpha from the capture."
  fi
  if [ -n "$FONT_FALLBACKS" ]; then
    add_note "repeated font-family lines are a fallback chain; the first family wins: $FONT_FAMILY"
  fi
  return 0
}

detect_wezterm() {
  local scheme_line family_index
  SEARCHED_PATHS="$HOME/.config/wezterm/wezterm.lua
$HOME/.wezterm.lua"
  if [ -n "$OPT_CONFIG" ]; then
    [ -r "$OPT_CONFIG" ] || die "--config is not readable: $OPT_CONFIG"
    CFG_PATH=$(abs_path "$OPT_CONFIG")
  else
    CFG_PATH=$(first_readable_file <<EOF
$SEARCHED_PATHS
EOF
) || CFG_PATH=
    [ -n "$CFG_PATH" ] || return 1
  fi

  BEST_EFFORT=1
  add_warning "wezterm.lua is a Lua program; this script pattern-matches it and does not execute or interpret Lua. Every value below is best-effort and must be confirmed by hand"

  local font_file
  font_file="$WORK_DIR/wezterm-font.txt"
  lua_block "$CFG_PATH" "config.font" > "$font_file"
  family_index=0
  while IFS= read -r family; do
    if [ -n "$family" ]; then
      if [ "$family_index" -eq 0 ]; then
        FONT_FAMILY=$family
      else
        FONT_FALLBACKS="${FONT_FALLBACKS}${family}"$'\n'
      fi
      family_index=$((family_index + 1))
    fi
  done <<EOF
$(lua_families "$font_file")
EOF
  if [ -z "$FONT_FAMILY" ]; then
    while IFS= read -r family; do
      if [ -z "$family" ]; then
        continue
      fi
      case "$family" in
        wezterm|config|local) continue ;;
      esac
      if [ -z "$FONT_FAMILY" ]; then
        FONT_FAMILY=$family
      else
        FONT_FALLBACKS="${FONT_FALLBACKS}${family}"$'\n'
      fi
    done <<EOF
$(lua_quoted "$font_file")
EOF
  fi
  if [ -z "$FONT_FAMILY" ]; then
    add_undetermined "config.font could not be pattern-matched; read the Lua file by hand"
  fi

  FONT_SIZE=$(lua_number "$CFG_PATH" "config.font_size")
  OPACITY=$(lua_number "$CFG_PATH" "config.window_background_opacity")
  local blur
  blur=$(lua_number "$CFG_PATH" "config.macos_window_background_blur")
  if [ -z "$blur" ]; then
    blur=$(lua_number "$CFG_PATH" "config.window_background_blur")
  fi
  if [ -n "$blur" ] && [ "$blur" != "0" ]; then
    add_unreproducible "macOS window background blur is enabled (blur radius $blur); a browser rasterizer cannot reproduce the blurred desktop behind the window"
  fi

  scheme_line=$(lua_scalar "$CFG_PATH" "config.color_scheme =")
  case "$scheme_line" in
    *\"*) THEME_NAME=$(printf '%s' "$scheme_line" | sed -n 's/.*"\([^"]*\)".*/\1/p') ;;
  esac

  local schemes_file scheme_name scheme_file_block
  schemes_file="$WORK_DIR/wezterm-schemes.txt"
  lua_block "$CFG_PATH" "config.color_schemes" > "$schemes_file"
  if [ -z "$THEME_NAME" ]; then
    if [ -s "$schemes_file" ]; then
      add_undetermined "config.color_schemes defines a scheme but config.color_scheme does not name one; confirm the active scheme by hand"
    fi
  else
    scheme_name=$(printf '%s' "$THEME_NAME")
    scheme_file_block="$WORK_DIR/wezterm-scheme.txt"
    : > "$scheme_file_block"
    lua_block "$schemes_file" "[\"$scheme_name\"]" > "$scheme_file_block"
    if [ ! -s "$scheme_file_block" ]; then
      add_undetermined "color scheme '$scheme_name' is not defined in this file (it may come from a built-in or an imported module); palette left unresolved"
    else
      local ansi_file brights_file i color
      ansi_file="$WORK_DIR/wezterm-ansi.txt"
      brights_file="$WORK_DIR/wezterm-brights.txt"
      lua_block "$scheme_file_block" "ansi" > "$ansi_file"
      lua_block "$scheme_file_block" "brights" > "$brights_file"
      i=0
      while IFS= read -r color; do
        if [ -n "$color" ]; then
          set_palette_entry "$i" "$(norm_hex "$color")"
          i=$((i + 1))
        fi
      done <<EOF
$(grep -o -E '#[0-9a-fA-F]{6}' "$ansi_file" || true)
EOF
      if [ "$i" -lt 8 ]; then
        add_undetermined "color scheme '$scheme_name' resolved only $i of 8 base colors from its ansi table"
      fi
      i=0
      while IFS= read -r color; do
        if [ -n "$color" ]; then
          set_palette_entry "$((i + 8))" "$(norm_hex "$color")"
          i=$((i + 1))
        fi
      done <<EOF
$(grep -o -E '#[0-9a-fA-F]{6}' "$brights_file" || true)
EOF
      if [ "$i" -lt 8 ]; then
        add_undetermined "color scheme '$scheme_name' resolved only $i of 8 bright colors from its brights table"
      fi
      BG=$(lua_hex_after "$scheme_file_block" "background")
      THEME_BG=$BG
      if [ -n "$BG" ]; then
        BG_ORIGIN="color scheme '$scheme_name'"
      fi
      FG=$(lua_hex_after "$scheme_file_block" "foreground")
      if [ -n "$FG" ]; then
        FG_ORIGIN="color scheme '$scheme_name'"
      fi
      SEL_BG=$(lua_hex_after "$scheme_file_block" "selection_bg")
      SEL_FG=$(lua_hex_after "$scheme_file_block" "selection_fg")
      CURSOR=$(lua_hex_after "$scheme_file_block" "cursor_bg")
    fi
  fi

  local colors_file
  colors_file="$WORK_DIR/wezterm-colors.txt"
  lua_block "$CFG_PATH" "config.colors" > "$colors_file"
  if [ -s "$colors_file" ]; then
    if [ -z "$CURSOR" ]; then
      CURSOR=$(lua_hex_after "$colors_file" "cursor_bg")
    fi
    if [ -z "$SEL_BG" ]; then
      SEL_BG=$(lua_hex_after "$colors_file" "selection_bg")
    fi
  fi
  if [ -z "$BG" ]; then
    add_undetermined "terminal background not resolved; provide it manually before keying"
  fi
  return 0
}

detect_alacritty() {
  local section key value i
  SEARCHED_PATHS="$HOME/.config/alacritty/alacritty.toml
$HOME/.alacritty.toml
$HOME/.config/alacritty/alacritty.yml"
  if [ -n "$OPT_CONFIG" ]; then
    [ -r "$OPT_CONFIG" ] || die "--config is not readable: $OPT_CONFIG"
    CFG_PATH=$(abs_path "$OPT_CONFIG")
  else
    CFG_PATH=$(first_readable_file <<EOF
$SEARCHED_PATHS
EOF
) || CFG_PATH=
    [ -n "$CFG_PATH" ] || return 1
  fi
  case "$CFG_PATH" in
    *.yml|*.yaml)
      add_undetermined "only TOML alacritty configs are parsed; convert or read the YAML by hand: $CFG_PATH"
      return 0
      ;;
  esac

  local normal_seen=0 bright_seen=0
  while IFS=$'\t' read -r section key value; do
    case "$section:$key" in
      font.normal:family) FONT_FAMILY=$value ;;
      font.family) if [ -z "$FONT_FAMILY" ]; then FONT_FAMILY=$value; fi ;;
      font:size|font.size:size) FONT_SIZE=$value ;;
      :import) add_undetermined "import = $value is not followed; re-run with an explicit --config" ;;
      colors.primary:background) BG=$(norm_hex "$value"); BG_ORIGIN=config ;;
      colors.primary:foreground) FG=$(norm_hex "$value"); FG_ORIGIN=config ;;
      colors.cursor:cursor) CURSOR=$(norm_hex "$value") ;;
      colors.selection:background) SEL_BG=$(norm_hex "$value") ;;
      colors.selection:foreground) SEL_FG=$(norm_hex "$value") ;;
      window:opacity) OPACITY=$value ;;
      colors.normal:black) set_palette_entry 0 "$(norm_hex "$value")" ;;
      colors.normal:red) set_palette_entry 1 "$(norm_hex "$value")" ;;
      colors.normal:green) set_palette_entry 2 "$(norm_hex "$value")" ;;
      colors.normal:yellow) set_palette_entry 3 "$(norm_hex "$value")" ;;
      colors.normal:blue) set_palette_entry 4 "$(norm_hex "$value")" ;;
      colors.normal:magenta) set_palette_entry 5 "$(norm_hex "$value")" ;;
      colors.normal:cyan) set_palette_entry 6 "$(norm_hex "$value")" ;;
      colors.normal:white) set_palette_entry 7 "$(norm_hex "$value")" ;;
      colors.bright:black) set_palette_entry 8 "$(norm_hex "$value")" ;;
      colors.bright:red) set_palette_entry 9 "$(norm_hex "$value")" ;;
      colors.bright:green) set_palette_entry 10 "$(norm_hex "$value")" ;;
      colors.bright:yellow) set_palette_entry 11 "$(norm_hex "$value")" ;;
      colors.bright:blue) set_palette_entry 12 "$(norm_hex "$value")" ;;
      colors.bright:magenta) set_palette_entry 13 "$(norm_hex "$value")" ;;
      colors.bright:cyan) set_palette_entry 14 "$(norm_hex "$value")" ;;
      colors.bright:white) set_palette_entry 15 "$(norm_hex "$value")" ;;
    esac
  done <<EOF
$(parse_alacritty_toml < "$CFG_PATH")
EOF

  i=0
  while [ "$i" -le 15 ]; do
    if [ -n "$(palette_value "$i")" ]; then
      if [ "$i" -le 7 ]; then
        normal_seen=$((normal_seen + 1))
      else
        bright_seen=$((bright_seen + 1))
      fi
    fi
    i=$((i + 1))
  done
  if [ "$normal_seen" -lt 8 ] || [ "$bright_seen" -lt 8 ]; then
    add_undetermined "alacritty palette incomplete ($normal_seen/8 normal, $bright_seen/8 bright); unspecified colors fall back to alacritty's built-in defaults"
  fi
  if [ -z "$BG" ]; then
    add_undetermined "colors.primary.background is not set; the default is #000000 only if nothing else overrides it — confirm before keying"
  fi
  return 0
}

detect_kitty() {
  local key value include_path resolved
  SEARCHED_PATHS="$HOME/.config/kitty/kitty.conf"
  if [ -n "${XDG_CONFIG_HOME:-}" ]; then
    SEARCHED_PATHS="$XDG_CONFIG_HOME/kitty/kitty.conf
$SEARCHED_PATHS"
  fi
  SEARCHED_PATHS=$(dedupe_lines "$SEARCHED_PATHS")
  if [ -n "$OPT_CONFIG" ]; then
    [ -r "$OPT_CONFIG" ] || die "--config is not readable: $OPT_CONFIG"
    CFG_PATH=$(abs_path "$OPT_CONFIG")
  else
    CFG_PATH=$(first_readable_file <<EOF
$SEARCHED_PATHS
EOF
) || CFG_PATH=
    [ -n "$CFG_PATH" ] || return 1
  fi

  local config_dir include_note=0
  config_dir=$(dirname -- "$CFG_PATH")
  while IFS=$'\t' read -r key value; do
    case "$key" in
      font_family) if [ -z "$FONT_FAMILY" ]; then FONT_FAMILY=$value; else FONT_FALLBACKS="${FONT_FALLBACKS}${value}"$'\n'; fi ;;
      font_size) FONT_SIZE=$value ;;
      background) BG=$(norm_hex "$value"); BG_ORIGIN=config ;;
      foreground) FG=$(norm_hex "$value"); FG_ORIGIN=config ;;
      cursor) CURSOR=$(norm_hex "$value") ;;
      selection_background) SEL_BG=$(norm_hex "$value") ;;
      background_opacity) OPACITY=$value ;;
      color0|color1|color2|color3|color4|color5|color6|color7|color8|color9|color10|color11|color12|color13|color14|color15)
        set_palette_entry "${key#color}" "$(norm_hex "$value")"
        ;;
      include)
        if [ "$include_note" -eq 0 ]; then
          include_note=1
          # parse_kitty_conf emits the whole include line as the value.
          value=$(printf '%s' "$value" | sed -n 's/^include[[:space:]]*//p')
          include_path=$(expand_tilde "$value")
          case "$include_path" in
            /*) ;;
            *) include_path="$config_dir/$include_path" ;;
          esac
          resolved=$(first_readable_file <<EOF
$include_path
EOF
) || resolved=
          if [ -z "$resolved" ]; then
            add_undetermined "include directive could not be resolved to a readable file: $value"
          elif [ -n "$OPT_THEME_FILE" ]; then
            # An explicit theme file wins over the config's own include.
            THEME_FILE=$(abs_path "$OPT_THEME_FILE")
          else
            THEME_FILE=$resolved
          fi
        fi
        ;;
    esac
  done <<EOF
$(parse_kitty_conf < "$CFG_PATH")
EOF

  if [ -n "$OPT_THEME_FILE" ] && [ -z "$THEME_FILE" ]; then
    [ -r "$OPT_THEME_FILE" ] || die "--theme-file is not readable: $OPT_THEME_FILE"
    THEME_FILE=$(abs_path "$OPT_THEME_FILE")
  fi

  # One level of include only; kitty theme files use "key value" syntax too.
  if [ -n "$THEME_FILE" ]; then
    while IFS=$'\t' read -r key value; do
      case "$key" in
        font_family) if [ -z "$FONT_FAMILY" ]; then FONT_FAMILY=$value; else FONT_FALLBACKS="${FONT_FALLBACKS}${value}"$'\n'; fi ;;
        font_size) if [ -z "$FONT_SIZE" ]; then FONT_SIZE=$value; fi ;;
        background) if [ -z "$BG" ]; then BG=$(norm_hex "$value"); BG_ORIGIN=theme; fi ;;
        foreground) if [ -z "$FG" ]; then FG=$(norm_hex "$value"); FG_ORIGIN=theme; fi ;;
        color0|color1|color2|color3|color4|color5|color6|color7|color8|color9|color10|color11|color12|color13|color14|color15)
          set_palette_entry "${key#color}" "$(norm_hex "$value")"
          ;;
        include) add_undetermined "kitty include inside $THEME_FILE is not followed (one level only)" ;;
      esac
    done <<EOF
$(parse_kitty_conf < "$THEME_FILE")
EOF
  fi

  if [ -z "$BG" ]; then
    add_undetermined "background is not set in $CFG_PATH; kitty's default is #000000 only if no included theme sets it"
  fi
  return 0
}

component_to_hex() { # component_to_hex <r> <g> <b> as 0..1 decimals
  awk -v r="$1" -v g="$2" -v b="$3" 'BEGIN {
    values[1] = r; values[2] = g; values[3] = b
    out = "#"
    for (i = 1; i <= 3; i++) {
      v = values[i] + 0
      if (v < 0) v = 0
      if (v > 1) v = 1
      out = out sprintf("%02x", int(v * 255 + 0.5))
    }
    print out
  }'
}

iterm2_component() { # iterm2_component <json file> <profile index> <key>
  jq -r --argjson i "$2" --arg k "$3" '
    ."New Bookmarks"[$i][$k] as $c
    | if ($c | type) == "object"
      then "\($c["Red Component"] // 0) \($c["Green Component"] // 0) \($c["Blue Component"] // 0)"
      else empty end' "$1"
}

detect_iterm2() {
  local plist json_file index rgb
  SEARCHED_PATHS="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
  if [ -n "$OPT_CONFIG" ]; then
    [ -r "$OPT_CONFIG" ] || die "--config is not readable: $OPT_CONFIG"
    plist=$(abs_path "$OPT_CONFIG")
  else
    plist=$(first_readable_file <<EOF
$SEARCHED_PATHS
EOF
) || plist=
    [ -n "$plist" ] || return 1
  fi
  CFG_PATH=$plist

  command -v plutil >/dev/null 2>&1 || die "plutil is required to read the iTerm2 plist; check installed tools before installing"
  command -v jq >/dev/null 2>&1 || die "jq is required to read the iTerm2 plist; check installed tools before installing"

  json_file="$WORK_DIR/iterm2.json"
  plutil -convert json -o - "$plist" > "$json_file" 2>/dev/null || \
    die "plutil could not convert the iTerm2 plist to JSON: $plist"

  index=0
  local default_guid
  default_guid=$(jq -r '."Default Bookmark Guid" // empty' "$json_file")
  if [ -n "$default_guid" ]; then
    local matched
    matched=$(jq -r --arg g "$default_guid" '
      ."New Bookmarks" | to_entries | map(select(.value.Guid == $g)) | .[0].key // empty' "$json_file")
    if [ -n "$matched" ]; then
      index=$matched
    fi
  fi

  add_note "iTerm2 has no named theme; colors come from profile $index of $SEARCHED_PATHS"

  local normal_font
  normal_font=$(jq -r --argjson i "$index" '."New Bookmarks"[$i]."Normal Font" // empty' "$json_file")
  if [ -n "$normal_font" ]; then
    case "$normal_font" in
      *' '[0-9]*)
        FONT_SIZE=${normal_font##* }
        FONT_FAMILY=${normal_font% *}
        ;;
      *) FONT_FAMILY=$normal_font ;;
    esac
  else
    add_undetermined "profile $index has no 'Normal Font' entry"
  fi

  local use_non_ascii
  use_non_ascii=$(jq -r --argjson i "$index" '."New Bookmarks"[$i]."Use Non-ASCII Font" // false' "$json_file")
  if [ "$use_non_ascii" = "true" ]; then
    local non_ascii
    non_ascii=$(jq -r --argjson i "$index" '."New Bookmarks"[$i]."Non Ascii Font" // empty' "$json_file")
    if [ -n "$non_ascii" ]; then
      FONT_FALLBACKS="${FONT_FALLBACKS}${non_ascii}"$'\n'
    fi
  fi

  rgb=$(iterm2_component "$json_file" "$index" "Background Color")
  if [ -n "$rgb" ]; then BG=$(component_to_hex $rgb); BG_ORIGIN=profile; fi
  rgb=$(iterm2_component "$json_file" "$index" "Foreground Color")
  if [ -n "$rgb" ]; then FG=$(component_to_hex $rgb); FG_ORIGIN=profile; fi
  rgb=$(iterm2_component "$json_file" "$index" "Cursor Color")
  if [ -n "$rgb" ]; then CURSOR=$(component_to_hex $rgb); fi
  rgb=$(iterm2_component "$json_file" "$index" "Selection Color")
  if [ -n "$rgb" ]; then SEL_BG=$(component_to_hex $rgb); fi

  local i ansi_key
  i=0
  for ansi_key in "ANSI Black Color" "ANSI Red Color" "ANSI Green Color" "ANSI Yellow Color" \
    "ANSI Blue Color" "ANSI Magenta Color" "ANSI Cyan Color" "ANSI White Color" \
    "ANSI Bright Black Color" "ANSI Bright Red Color" "ANSI Bright Green Color" "ANSI Bright Yellow Color" \
    "ANSI Bright Blue Color" "ANSI Bright Magenta Color" "ANSI Bright Cyan Color" "ANSI Bright White Color"; do
    rgb=$(iterm2_component "$json_file" "$index" "$ansi_key")
    if [ -n "$rgb" ]; then
      set_palette_entry "$i" "$(component_to_hex $rgb)"
    fi
    i=$((i + 1))
  done

  local transparency
  transparency=$(jq -r --argjson i "$index" '."New Bookmarks"[$i].Transparency // empty' "$json_file")
  if [ -n "$transparency" ]; then
    OPACITY=$(awk -v t="$transparency" 'BEGIN { printf "%.4f", 1 - t }')
    add_note "iTerm2 Transparency $transparency was converted to opacity $OPACITY; confirm the convention in your iTerm2 version"
  else
    add_note "no Transparency key in profile $index; iTerm2 opacity defaults are version-dependent. Measure alpha from the capture."
  fi
  local blur
  blur=$(jq -r --argjson i "$index" '."New Bookmarks"[$i].Blur // false' "$json_file")
  if [ "$blur" = "true" ]; then
    add_unreproducible "iTerm2 background blur is enabled in profile $index; a browser rasterizer cannot reproduce it"
  fi
  return 0
}

# --- records -----------------------------------------------------------------

emit_terminal() {
  local term=$1 i value
  emit terminal name "$term"
  if [ -n "$CFG_PATH" ]; then
    emit source config "$CFG_PATH"
  fi
  emit_lines searched path "$SEARCHED_PATHS"
  if [ -n "$BEST_EFFORT" ]; then
    emit value best_effort true
  fi
  if [ -n "$FONT_FAMILY" ]; then emit value font_family "$FONT_FAMILY"; fi
  emit_lines value font_fallback "$FONT_FALLBACKS"
  if [ -n "$FONT_SIZE" ]; then emit value font_size "$FONT_SIZE"; fi
  if [ -n "$FONT_FEATURES" ]; then emit value font_features "$FONT_FEATURES"; fi
  if [ -n "$FONT_THICKEN" ]; then emit value font_thicken "$FONT_THICKEN"; fi
  if [ -n "$FONT_THICKEN_STRENGTH" ]; then emit value font_thicken_strength "$FONT_THICKEN_STRENGTH"; fi
  if [ -n "$THEME_NAME" ]; then emit value theme_name "$THEME_NAME"; fi
  if [ -n "$THEME_FILE" ]; then emit value theme_file "$THEME_FILE"; fi
  if [ -n "$THEME_BG" ]; then emit value theme_background "$THEME_BG"; fi
  if [ -n "$BG" ]; then emit value background "$BG"; fi
  if [ -n "$BG_ORIGIN" ]; then emit value background_origin "$BG_ORIGIN"; fi
  if [ -n "$FG" ]; then emit value foreground "$FG"; fi
  if [ -n "$FG_ORIGIN" ]; then emit value foreground_origin "$FG_ORIGIN"; fi
  if [ -n "$CURSOR" ]; then emit value cursor "$CURSOR"; fi
  if [ -n "$SEL_BG" ]; then emit value selection_background "$SEL_BG"; fi
  if [ -n "$SEL_FG" ]; then emit value selection_foreground "$SEL_FG"; fi
  if [ -n "$OPACITY" ]; then emit value background_opacity "$OPACITY"; fi
  i=0
  local unresolved=
  while [ "$i" -le 15 ]; do
    value=$(palette_value "$i")
    if [ -n "$value" ]; then
      emit value "palette_$i" "$value"
    else
      unresolved="$unresolved$i,"
    fi
    i=$((i + 1))
  done
  if [ -n "$unresolved" ]; then
    add_undetermined "palette entries ${unresolved%,} are unresolved; the VHS theme below omits them and VHS keeps its own defaults for those indices, which will not match $term"
  fi
  emit_lines warning any "$WARNINGS"
  emit_lines unreproducible any "$UNREPRODUCIBLE"
  emit_lines undetermined any "$UNDETERMINED"
  emit_lines note any "$NOTES"
}

vhs_theme_json() { # compact JSON object for "Set Theme"; prints nothing when no color is known
  local i value key out emitted=0
  local bg fg cursor sel name
  bg=$(record_value value background)
  fg=$(record_value value foreground)
  cursor=$(record_value value cursor)
  sel=$(record_value value selection_background)
  name=$(record_value terminal name)
  if [ -n "$(record_value value theme_name)" ]; then
    name="$name $(record_value value theme_name)"
  fi

  out='{ "name": '"$(json_string "$name")"
  i=0
  for key in black red green yellow blue purple cyan white brightBlack brightRed brightGreen brightYellow brightBlue brightPurple brightCyan brightWhite; do
    value=$(record_value value "palette_$i")
    if [ -n "$value" ]; then
      out="$out, \"$key\": $(json_string "$value")"
      emitted=$((emitted + 1))
    fi
    i=$((i + 1))
  done
  if [ -n "$bg" ]; then out="$out, \"background\": $(json_string "$bg")"; emitted=$((emitted + 1)); fi
  if [ -n "$fg" ]; then out="$out, \"foreground\": $(json_string "$fg")"; emitted=$((emitted + 1)); fi
  if [ -n "$cursor" ]; then out="$out, \"cursor\": $(json_string "$cursor")"; emitted=$((emitted + 1)); fi
  if [ -n "$sel" ]; then out="$out, \"selection\": $(json_string "$sel")"; emitted=$((emitted + 1)); fi
  if [ "$emitted" -eq 0 ]; then
    return 0
  fi
  printf '%s }' "$out"
}

vhs_has_theme() {
  vhs_theme_json
}

# --- renderers ---------------------------------------------------------------

render_terminal_text() {
  local term cfg i value vhs_theme
  term=$(record_value terminal name)
  cfg=$(record_value source config)
  printf '\n== %s ==\n' "$term"
  if [ -n "$cfg" ]; then
    printf 'config: %s\n' "$cfg"
  else
    printf 'config: NOT FOUND\n'
    while IFS= read -r line; do
      if [ -n "$line" ]; then
        printf '  searched: %s\n' "$line"
      fi
    done <<EOF
$(record_lines searched path)
EOF
  fi
  if [ -n "$(record_value value best_effort)" ]; then
    printf 'parsing: BEST-EFFORT (pattern match, not a %s interpreter)\n' "$term"
  fi
  if [ -n "$(record_value value font_family)" ]; then
    printf 'font-family: %s\n' "$(record_value value font_family)"
  fi
  while IFS= read -r line; do
    if [ -n "$line" ]; then
      printf 'font-family fallback: %s\n' "$line"
    fi
  done <<EOF
$(record_lines value font_fallback)
EOF
  if [ -n "$(record_value value font_size)" ]; then
    printf 'font-size: %s\n' "$(record_value value font_size)"
  fi
  if [ -n "$(record_value value font_features)" ]; then
    printf 'font-feature: %s\n' "$(record_value value font_features)"
  fi
  if [ -n "$(record_value value font_thicken)" ]; then
    printf 'font-thicken: %s' "$(record_value value font_thicken)"
    if [ -n "$(record_value value font_thicken_strength)" ]; then
      printf ' (strength %s)' "$(record_value value font_thicken_strength)"
    fi
    printf '\n'
  fi
  if [ -n "$(record_value value theme_name)" ]; then
    printf 'theme: %s\n' "$(record_value value theme_name)"
  fi
  if [ -n "$(record_value value theme_file)" ]; then
    printf 'theme-file: %s\n' "$(record_value value theme_file)"
  fi
  if [ -n "$(record_value value background)" ]; then
    printf 'background: %s' "$(record_value value background)"
    if [ -n "$(record_value value background_origin)" ]; then
      printf ' (from %s)' "$(record_value value background_origin)"
    fi
    printf '\n'
  else
    printf 'background: UNDETERMINED\n'
  fi
  if [ -n "$(record_value value theme_background)" ]; then
    if [ "$(record_value value theme_background)" != "$(record_value value background)" ]; then
      printf 'theme background: %s (overridden by the value above)\n' "$(record_value value theme_background)"
    fi
  fi
  if [ -n "$(record_value value foreground)" ]; then
    printf 'foreground: %s' "$(record_value value foreground)"
    if [ -n "$(record_value value foreground_origin)" ]; then
      printf ' (from %s)' "$(record_value value foreground_origin)"
    fi
    printf '\n'
  fi
  if [ -n "$(record_value value cursor)" ]; then
    printf 'cursor: %s\n' "$(record_value value cursor)"
  fi
  if [ -n "$(record_value value selection_background)" ]; then
    printf 'selection-background: %s\n' "$(record_value value selection_background)"
  fi
  if [ -n "$(record_value value selection_foreground)" ]; then
    printf 'selection-foreground: %s\n' "$(record_value value selection_foreground)"
  fi
  if [ -n "$(record_value value background_opacity)" ]; then
    printf 'configured background-opacity: %s\n' "$(record_value value background_opacity)"
  fi
  printf 'palette ANSI 0-15:\n'
  i=0
  while [ "$i" -le 15 ]; do
    value=$(record_value value "palette_$i")
    if [ -z "$value" ]; then
      value=UNRESOLVED
    fi
    printf '%3d %s' "$i" "$value"
    if [ $((i % 4)) -eq 3 ]; then
      printf '\n'
    else
      printf '  '
    fi
    i=$((i + 1))
  done
  while IFS= read -r line; do
    if [ -n "$line" ]; then
      printf 'WARNING: %s\n' "$line"
    fi
  done <<EOF
$(record_lines warning any)
EOF
  while IFS= read -r line; do
    if [ -n "$line" ]; then
      printf 'WARNING (not reproducible by a browser rasterizer): %s\n' "$line"
    fi
  done <<EOF
$(record_lines unreproducible any)
EOF
  while IFS= read -r line; do
    if [ -n "$line" ]; then
      printf 'UNDETERMINED: %s\n' "$line"
    fi
  done <<EOF
$(record_lines undetermined any)
EOF
  while IFS= read -r line; do
    if [ -n "$line" ]; then
      printf 'NOTE: %s\n' "$line"
    fi
  done <<EOF
$(record_lines note any)
EOF

  printf '\nvhs block (%s):\n' "$term"
  if [ -n "$(record_value value font_family)" ]; then
    printf 'Set FontFamily "%s"\n' "$(record_value value font_family)"
  else
    printf '# no Set FontFamily: font family unresolved\n'
  fi
  if [ -n "$(record_value value font_size)" ]; then
    printf 'Set FontSize %s\n' "$(record_value value font_size)"
  else
    printf '# no Set FontSize: font size unresolved\n'
  fi
  vhs_theme=$(vhs_has_theme)
  if [ -n "$vhs_theme" ]; then
    printf 'Set Theme %s\n' "$vhs_theme"
  else
    printf '# no Set Theme: background/foreground unresolved\n'
  fi
}

render_terminal_json() {
  local term
  term=$(record_value terminal name)
  printf '    {\n'
  printf '      "terminal": %s,\n' "$(json_string "$term")"
  printf '      "config_path": %s,\n' "$(json_string_or_null "$(record_value source config)")"
  printf '      "config_searched": [%s],\n' "$(json_string_list searched path)"
  printf '      "best_effort": %s,\n' "$(json_bool_or_null "$(record_value value best_effort)")"
  printf '      "font": {\n'
  printf '        "family": %s,\n' "$(json_string_or_null "$(record_value value font_family)")"
  printf '        "fallbacks": [%s],\n' "$(json_string_list value font_fallback)"
  printf '        "size": %s,\n' "$(json_number_or_null "$(record_value value font_size)")"
  printf '        "features": %s,\n' "$(json_string_or_null "$(record_value value font_features)")"
  printf '        "thicken": %s,\n' "$(json_bool_or_null "$(record_value value font_thicken)")"
  printf '        "thicken_strength": %s\n' "$(json_number_or_null "$(record_value value font_thicken_strength)")"
  printf '      },\n'
  printf '      "theme": {\n'
  printf '        "name": %s,\n' "$(json_string_or_null "$(record_value value theme_name)")"
  printf '        "file": %s,\n' "$(json_string_or_null "$(record_value value theme_file)")"
  printf '        "background": %s\n' "$(json_string_or_null "$(record_value value theme_background)")"
  printf '      },\n'
  printf '      "colors": {\n'
  printf '        "background": %s,\n' "$(json_string_or_null "$(record_value value background)")"
  printf '        "background_origin": %s,\n' "$(json_string_or_null "$(record_value value background_origin)")"
  printf '        "foreground": %s,\n' "$(json_string_or_null "$(record_value value foreground)")"
  printf '        "cursor": %s,\n' "$(json_string_or_null "$(record_value value cursor)")"
  printf '        "selection_background": %s,\n' "$(json_string_or_null "$(record_value value selection_background)")"
  printf '        "selection_foreground": %s,\n' "$(json_string_or_null "$(record_value value selection_foreground)")"
  printf '        "palette": [%s]\n' "$(json_palette_list)"
  printf '      },\n'
  printf '      "window": {"background_opacity": %s},\n' "$(json_number_or_null "$(record_value value background_opacity)")"
  printf '      "warnings": [%s],\n' "$(json_string_list warning any)"
  printf '      "unreproducible": [%s],\n' "$(json_string_list unreproducible any)"
  printf '      "undetermined": [%s],\n' "$(json_string_list undetermined any)"
  printf '      "notes": [%s],\n' "$(json_string_list note any)"
  printf '      "vhs": {"font_family": %s, "font_size": %s, "theme": %s}\n' \
    "$(json_string_or_null "$(record_value value font_family)")" \
    "$(json_number_or_null "$(record_value value font_size)")" \
    "$(vhs_has_theme_or_null)"
  printf '    }'
}

json_string_list() { # json_string_list <kind> <key>
  local out= v= first=1
  while IFS= read -r v; do
    if [ -n "$v" ]; then
      if [ "$first" -eq 0 ]; then
        out="$out, "
      fi
      out="$out$(json_string "$v")"
      first=0
    fi
  done <<EOF
$(record_lines "$1" "$2")
EOF
  printf '%s' "$out"
}

json_palette_list() {
  local i value out= first=1
  i=0
  while [ "$i" -le 15 ]; do
    value=$(record_value value "palette_$i")
    if [ "$first" -eq 0 ]; then
      out="$out, "
    fi
    out="$out$(json_string_or_null "$value")"
    first=0
    i=$((i + 1))
  done
  printf '%s' "$out"
}

vhs_has_theme_or_null() {
  local json
  json=$(vhs_has_theme)
  if [ -n "$json" ]; then
    printf '%s' "$json"
  else
    printf 'null'
  fi
}

render_json() {
  local names=$1 total=0 term first=1
  printf '{\n'
  printf '  "ambiguous": %s,\n' "$2"
  printf '  "terminals": [\n'
  for term in $names; do
    RECORD_FILE="$WORK_DIR/records-$term"
    if [ "$first" -eq 0 ]; then
      printf ',\n'
    fi
    render_terminal_json
    first=0
    total=$((total + 1))
  done
  if [ "$total" -gt 0 ]; then
    printf '\n'
  fi
  printf '  ]\n'
  printf '}\n'
}

expect_text() { # expect_text <label> <haystack> <needle>
  case "$2" in
    *"$3"*) ;;
    *) die "self-check: $1 is missing expected text: $3" ;;
  esac
}

# --- self-check --------------------------------------------------------------

run_self_check() {
  local h ghostty_cfg ghostty_theme decoy_theme out
  # Global on purpose: the EXIT trap runs after this function's locals are gone.
  SELF_CHECK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/terminal-theme-self-check.XXXXXX")
  trap 'rm -rf -- "$SELF_CHECK_DIR"' EXIT INT TERM

  h="$SELF_CHECK_DIR/home"
  mkdir -p "$h/.config/ghostty/themes" "$h/.config/wezterm" "$h/.config/kitty" "$SELF_CHECK_DIR/resources/themes"

  ghostty_cfg="$h/.config/ghostty/config"
  cat > "$ghostty_cfg" <<'EOF'
font-family = Fixture Mono NL
font-family = Fixture Fallback
font-size = 15
font-feature = -calt,-liga
font-thicken = true
font-thicken-strength = 40
theme = Self Check Theme
background = #101020
EOF
  ghostty_theme="$h/.config/ghostty/themes/Self Check Theme"
  cat > "$ghostty_theme" <<'EOF'
palette = 0=#000000
palette = 1=#aa0000
palette = 2=#00aa00
palette = 3=#aa5500
palette = 4=#0000aa
palette = 5=#aa00aa
palette = 6=#00aaaa
palette = 7=#aaaaaa
palette = 8=#555555
palette = 9=#ff5555
palette = 10=#55ff55
palette = 11=#ffff55
palette = 12=#5555ff
palette = 13=#ABCDEF
palette = 14=#55ffff
palette = 15=#ffffff
background = #202030
foreground = #d0d0d0
cursor-color = #e0e0e0
selection-background = #303040
EOF
  decoy_theme="$SELF_CHECK_DIR/resources/themes/Self Check Theme"
  cat > "$decoy_theme" <<'EOF'
palette = 13=#000001
background = #000002
foreground = #000003
EOF

  local before after
  before=$(shasum -a 256 "$ghostty_cfg" "$ghostty_theme" | awk '{print $1}' | tr '\n' ' ')

  if ! out=$(HOME="$h" XDG_CONFIG_HOME="$h/.config" \
      GHOSTTY_RESOURCES_DIR="$SELF_CHECK_DIR/resources" \
      bash "$SCRIPT_PATH" --terminal ghostty); then
    die "self-check: ghostty fixture run failed"
  fi
  after=$(shasum -a 256 "$ghostty_cfg" "$ghostty_theme" | awk '{print $1}' | tr '\n' ' ')
  [ "$before" = "$after" ] || die "self-check: a config file was modified"

  expect_text "ghostty first font family" "$out" "font-family: Fixture Mono NL"
  expect_text "ghostty fallback family" "$out" "font-family fallback: Fixture Fallback"
  expect_text "ghostty font size" "$out" "font-size: 15"
  expect_text "ghostty theme name" "$out" "theme: Self Check Theme"
  expect_text "ghostty config background" "$out" "background: #101020 (from config)"
  expect_text "ghostty theme background override" "$out" "theme background: #202030 (overridden by the value above)"
  expect_text "ghostty foreground" "$out" "foreground: #d0d0d0"
  expect_text "ghostty local theme before app resources" "$out" " 13 #abcdef"
  expect_text "ghostty font-thicken warning" "$out" "font-thicken"
  expect_text "ghostty thicken strength" "$out" "strength 40"
  expect_text "ghostty vhs font family" "$out" 'Set FontFamily "Fixture Mono NL"'
  expect_text "ghostty vhs font size" "$out" "Set FontSize 15"
  case "$out" in
    *"#000001"*) die "self-check: a decoy theme in GHOSTTY_RESOURCES_DIR won over the local theme" ;;
  esac
  case "$out" in
    *"UNRESOLVED"*) die "self-check: ghostty fixture palette should be fully resolved" ;;
  esac

  # A config palette line must override the theme's own palette entry.
  cat >> "$ghostty_cfg" <<'EOF'
palette = 13=#123456
EOF
  if ! out=$(HOME="$h" XDG_CONFIG_HOME="$h/.config" \
      GHOSTTY_RESOURCES_DIR="$SELF_CHECK_DIR/resources" \
      bash "$SCRIPT_PATH" --terminal ghostty); then
    die "self-check: ghostty palette override run failed"
  fi
  expect_text "ghostty config palette override" "$out" " 13 #123456"
  cat > "$ghostty_cfg" <<'EOF'
font-family = Fixture Mono NL
font-family = Fixture Fallback
font-size = 15
theme = Missing Theme
background = #101020
EOF

  # An unresolvable theme must be reported, never invented.
  if ! out=$(HOME="$h" XDG_CONFIG_HOME="$h/.config" \
      GHOSTTY_RESOURCES_DIR="$SELF_CHECK_DIR/resources" \
      bash "$SCRIPT_PATH" --terminal ghostty); then
    die "self-check: ghostty missing-theme run failed"
  fi
  expect_text "ghostty unresolved theme" "$out" "UNDETERMINED: theme 'Missing Theme' did not resolve"
  expect_text "ghostty unresolved palette" "$out" " 13 UNRESOLVED"
  expect_text "ghostty kept config background" "$out" "background: #101020"

  # --theme-file overrides theme resolution.
  cat > "$SELF_CHECK_DIR/override-theme" <<'EOF'
palette = 13=#0a0b0c
background = #0d0e0f
foreground = #101112
EOF
  if ! out=$(HOME="$h" XDG_CONFIG_HOME="$h/.config" \
      GHOSTTY_RESOURCES_DIR="$SELF_CHECK_DIR/resources" \
      bash "$SCRIPT_PATH" --terminal ghostty --config "$ghostty_cfg" \
      --theme-file "$SELF_CHECK_DIR/override-theme"); then
    die "self-check: ghostty --theme-file run failed"
  fi
  expect_text "ghostty --theme-file palette" "$out" " 13 #0a0b0c"
  expect_text "ghostty --theme-file background is overridden" "$out" "theme background: #0d0e0f (overridden by the value above)"
  expect_text "ghostty --theme-file path" "$out" "theme-file: $SELF_CHECK_DIR/override-theme"

  # Read-only: a write-protected config must still be readable.
  chmod 400 "$ghostty_cfg"
  if ! out=$(HOME="$h" XDG_CONFIG_HOME="$h/.config" \
      GHOSTTY_RESOURCES_DIR="$SELF_CHECK_DIR/resources" \
      bash "$SCRIPT_PATH" --terminal ghostty --json); then
    die "self-check: read-only config run failed"
  fi
  chmod 600 "$ghostty_cfg"

  # JSON validity and shape.
  if command -v jq >/dev/null 2>&1; then
    if ! printf '%s' "$out" | jq -e '.terminals[0].font.family == "Fixture Mono NL"' >/dev/null; then
      die "self-check: --json did not report the fixture font family"
    fi
    if ! printf '%s' "$out" | jq -e '.terminals[0].colors.palette[13] == "#123456" or .terminals[0].colors.palette[13] == null' >/dev/null; then
      die "self-check: --json palette entry is neither resolved nor null"
    fi
    if ! printf '%s' "$out" | jq -e '.terminals[0].window.background_opacity == null' >/dev/null; then
      die "self-check: --json should report an unset opacity as null"
    fi
    if ! printf '%s' "$out" | jq -e '(.terminals[0].unreproducible | length) == 0' >/dev/null; then
      die "self-check: --json should not claim unreproducible settings that are absent"
    fi
  fi

  # Ambiguity: two configured terminals are both reported.
  local wezterm_cfg
  wezterm_cfg="$h/.config/wezterm/wezterm.lua"
  cat > "$wezterm_cfg" <<'EOF'
local wezterm = require("wezterm")
local config = {}
config.font = wezterm.font_with_fallback({
	{ family = "Fixture Wez Mono" },
	{ family = "Fixture Symbols" },
})
config.font_size = 14.5
config.window_background_opacity = 1
config.macos_window_background_blur = 12
config.color_schemes = {
	["Fixture Scheme"] = {
		ansi = { "#000010", "#100000", "#001000", "#101000", "#000020", "#100010", "#001010", "#101010" },
		brights = { "#202020", "#300000", "#003000", "#303000", "#000030", "#300030", "#003030", "#303030" },
		background = "#0a0a14",
		foreground = "#eeeeee",
		selection_bg = "#303040",
		selection_fg = "#eeeeee",
		cursor_bg = "#dddddd",
	},
}
config.color_scheme = "Fixture Scheme"
return config
EOF
  if ! out=$(HOME="$h" XDG_CONFIG_HOME="$h/.config" \
      GHOSTTY_RESOURCES_DIR="$SELF_CHECK_DIR/resources" \
      bash "$SCRIPT_PATH" --terminal wezterm); then
    die "self-check: wezterm fixture run failed"
  fi
  expect_text "wezterm primary family" "$out" "font-family: Fixture Wez Mono"
  expect_text "wezterm fallback family" "$out" "font-family fallback: Fixture Symbols"
  expect_text "wezterm font size" "$out" "font-size: 14.5"
  expect_text "wezterm scheme name" "$out" "theme: Fixture Scheme"
  expect_text "wezterm scheme background" "$out" "background: #0a0a14"
  expect_text "wezterm base palette" "$out" "  0 #000010"
  expect_text "wezterm bright palette" "$out" " 15 #303030"
  expect_text "wezterm best-effort warning" "$out" "BEST-EFFORT"
  expect_text "wezterm blur warning" "$out" "background blur"
  expect_text "wezterm opacity" "$out" "configured background-opacity: 1"

  if ! out=$(HOME="$h" XDG_CONFIG_HOME="$h/.config" \
      GHOSTTY_RESOURCES_DIR="$SELF_CHECK_DIR/resources" \
      bash "$SCRIPT_PATH"); then
    die "self-check: auto-detect run failed"
  fi
  expect_text "auto-detect ghostty" "$out" "== ghostty =="
  expect_text "auto-detect wezterm" "$out" "== wezterm =="
  expect_text "auto-detect ambiguity" "$out" "ambiguous"

  # alacritty
  local alacritty_cfg
  alacritty_cfg="$h/.config/alacritty/alacritty.toml"
  mkdir -p "$h/.config/alacritty"
  cat > "$alacritty_cfg" <<'EOF'
[font]
size = 13.5

[font.normal]
family = "Fixture Alac Mono"

[colors.primary]
background = "#010203"
foreground = "#fefefe"

[colors.normal]
black = "#000000"
red = "#aa0000"
green = "#00aa00"
yellow = "#aaaa00"
blue = "#0000aa"
magenta = "#aa00aa"
cyan = "#00aaaa"
white = "#aaaaaa"

[colors.bright]
black = "#555555"
red = "#ff5555"
green = "#55ff55"
yellow = "#ffff55"
blue = "#5555ff"
magenta = "#ff55ff"
cyan = "#55ffff"
white = "#ffffff"

[window]
opacity = 0.9
EOF
  if ! out=$(HOME="$h" XDG_CONFIG_HOME="$h/.config" \
      bash "$SCRIPT_PATH" --terminal alacritty); then
    die "self-check: alacritty fixture run failed"
  fi
  expect_text "alacritty family" "$out" "font-family: Fixture Alac Mono"
  expect_text "alacritty size" "$out" "font-size: 13.5"
  expect_text "alacritty background" "$out" "background: #010203"
  expect_text "alacritty palette 5" "$out" "  5 #aa00aa"
  expect_text "alacritty palette 8" "$out" "  8 #555555"
  expect_text "alacritty opacity" "$out" "configured background-opacity: 0.9"

  # kitty with a one-level include
  local kitty_cfg
  kitty_cfg="$h/.config/kitty/kitty.conf"
  cat > "$kitty_cfg" <<'EOF'
# fixture kitty config
font_family Fixture Kitty Mono
font_size 12
background_opacity 0.85
include fixture-theme.conf
EOF
  cat > "$h/.config/kitty/fixture-theme.conf" <<'EOF'
background #0b0b0b
foreground #f0f0f0
color0 #000000
color1 #aa0000
color2 #00aa00
color3 #aaaa00
color4 #0000aa
color5 #aa00aa
color6 #00aaaa
color7 #aaaaaa
color8 #555555
color9 #ff5555
color10 #55ff55
color11 #ffff55
color12 #5555ff
color13 #ff55ff
color14 #55ffff
color15 #ffffff
EOF
  if ! out=$(HOME="$h" XDG_CONFIG_HOME="$h/.config" \
      bash "$SCRIPT_PATH" --terminal kitty); then
    die "self-check: kitty fixture run failed"
  fi
  expect_text "kitty family" "$out" "font-family: Fixture Kitty Mono"
  expect_text "kitty size" "$out" "font-size: 12"
  expect_text "kitty include background" "$out" "background: #0b0b0b (from theme)"
  expect_text "kitty include palette" "$out" " 13 #ff55ff"
  expect_text "kitty opacity" "$out" "configured background-opacity: 0.85"

  # XDG_CONFIG_HOME unset must not abort the run (set -u).
  if ! out=$(env -u XDG_CONFIG_HOME HOME="$h" bash "$SCRIPT_PATH" \
      --terminal kitty --config "$kitty_cfg"); then
    die "self-check: kitty run failed with XDG_CONFIG_HOME unset"
  fi
  expect_text "kitty without XDG_CONFIG_HOME" "$out" "font-family: Fixture Kitty Mono"
  if ! out=$(env -u XDG_CONFIG_HOME HOME="$h" bash "$SCRIPT_PATH" \
      --terminal ghostty --config "$ghostty_cfg"); then
    die "self-check: ghostty run failed with XDG_CONFIG_HOME unset"
  fi

  # iterm2 profile plist
  if command -v plutil >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    local iterm_plist
    iterm_plist="$SELF_CHECK_DIR/iterm2.plist"
    cat > "$iterm_plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Default Bookmark Guid</key>
  <string>guid-default</string>
  <key>New Bookmarks</key>
  <array>
    <dict>
      <key>Name</key>
      <string>Secondary</string>
      <key>Guid</key>
      <string>guid-secondary</string>
      <key>Normal Font</key>
      <string>Secondary Font 9</string>
      <key>Background Color</key>
      <dict>
        <key>Red Component</key><real>1.0</real>
        <key>Green Component</key><real>0.0</real>
        <key>Blue Component</key><real>0.0</real>
      </dict>
    </dict>
    <dict>
      <key>Name</key>
      <string>Fixture</string>
      <key>Guid</key>
      <string>guid-default</string>
      <key>Normal Font</key>
      <string>Fixture Iterm Mono 15</string>
      <key>Use Non-ASCII Font</key><true/>
      <key>Non Ascii Font</key>
      <string>Fixture Symbols 15</string>
      <key>Blur</key><true/>
      <key>Transparency</key><real>0.2</real>
      <key>Background Color</key>
      <dict>
        <key>Red Component</key><real>0.06666666666666667</real>
        <key>Green Component</key><real>0.06666666666666667</real>
        <key>Blue Component</key><real>0.10588235294117647</real>
        <key>Alpha Component</key><real>1.0</real>
      </dict>
      <key>Foreground Color</key>
      <dict>
        <key>Red Component</key><real>0.803921568627451</real>
        <key>Green Component</key><real>0.8392156862745098</real>
        <key>Blue Component</key><real>0.9568627450980393</real>
      </dict>
      <key>Cursor Color</key>
      <dict>
        <key>Red Component</key><real>0.9607843137254902</real>
        <key>Green Component</key><real>0.8784313725490196</real>
        <key>Blue Component</key><real>0.8627450980392157</real>
      </dict>
      <key>Selection Color</key>
      <dict>
        <key>Red Component</key><real>0.3450980392156863</real>
        <key>Green Component</key><real>0.3568627450980392</real>
        <key>Blue Component</key><real>0.4392156862745098</real>
      </dict>
      <key>ANSI Black Color</key>
      <dict><key>Red Component</key><real>0.2705882352941176</real><key>Green Component</key><real>0.2784313725490196</real><key>Blue Component</key><real>0.3529411764705883</real></dict>
      <key>ANSI Red Color</key>
      <dict><key>Red Component</key><real>0.9529411764705882</real><key>Green Component</key><real>0.5450980392156862</real><key>Blue Component</key><real>0.6588235294117647</real></dict>
      <key>ANSI Green Color</key>
      <dict><key>Red Component</key><real>0.6509803921568628</real><key>Green Component</key><real>0.8901960784313725</real><key>Blue Component</key><real>0.6313725490196078</real></dict>
      <key>ANSI Yellow Color</key>
      <dict><key>Red Component</key><real>0.9764705882352941</real><key>Green Component</key><real>0.8862745098039215</real><key>Blue Component</key><real>0.6862745098039216</real></dict>
      <key>ANSI Blue Color</key>
      <dict><key>Red Component</key><real>0.5372549019607843</real><key>Green Component</key><real>0.7058823529411765</real><key>Blue Component</key><real>0.9803921568627451</real></dict>
      <key>ANSI Magenta Color</key>
      <dict><key>Red Component</key><real>0.9607843137254902</real><key>Green Component</key><real>0.7607843137254902</real><key>Blue Component</key><real>0.9058823529411765</real></dict>
      <key>ANSI Cyan Color</key>
      <dict><key>Red Component</key><real>0.5803921568627451</real><key>Green Component</key><real>0.8862745098039215</real><key>Blue Component</key><real>0.8352941176470589</real></dict>
      <key>ANSI White Color</key>
      <dict><key>Red Component</key><real>0.6509803921568628</real><key>Green Component</key><real>0.6784313725490196</real><key>Blue Component</key><real>0.7843137254901961</real></dict>
      <key>ANSI Bright Black Color</key>
      <dict><key>Red Component</key><real>0.3450980392156863</real><key>Green Component</key><real>0.3568627450980392</real><key>Blue Component</key><real>0.4392156862745098</real></dict>
      <key>ANSI Bright Red Color</key>
      <dict><key>Red Component</key><real>0.9529411764705882</real><key>Green Component</key><real>0.4666666666666667</real><key>Blue Component</key><real>0.6</real></dict>
      <key>ANSI Bright Green Color</key>
      <dict><key>Red Component</key><real>0.5372549019607843</real><key>Green Component</key><real>0.8470588235294118</real><key>Blue Component</key><real>0.5450980392156862</real></dict>
      <key>ANSI Bright Yellow Color</key>
      <dict><key>Red Component</key><real>0.9215686274509803</real><key>Green Component</key><real>0.8274509803921568</real><key>Blue Component</key><real>0.5686274509803921</real></dict>
      <key>ANSI Bright Blue Color</key>
      <dict><key>Red Component</key><real>0.4549019607843137</real><key>Green Component</key><real>0.6588235294117647</real><key>Blue Component</key><real>0.9882352941176471</real></dict>
      <key>ANSI Bright Magenta Color</key>
      <dict><key>Red Component</key><real>0.9490196078431372</real><key>Green Component</key><real>0.6823529411764706</real><key>Blue Component</key><real>0.8705882352941177</real></dict>
      <key>ANSI Bright Cyan Color</key>
      <dict><key>Red Component</key><real>0.4196078431372549</real><key>Green Component</key><real>0.8431372549019608</real><key>Blue Component</key><real>0.792156862745098</real></dict>
      <key>ANSI Bright White Color</key>
      <dict><key>Red Component</key><real>0.7294117647058823</real><key>Green Component</key><real>0.7607843137254902</real><key>Blue Component</key><real>0.8705882352941177</real></dict>
    </dict>
  </array>
</dict>
</plist>
EOF
    if ! out=$(HOME="$h" XDG_CONFIG_HOME="$h/.config" \
        bash "$SCRIPT_PATH" --terminal iterm2 --config "$iterm_plist"); then
      die "self-check: iterm2 fixture run failed"
    fi
    expect_text "iterm2 default profile font" "$out" "font-family: Fixture Iterm Mono"
    expect_text "iterm2 font size" "$out" "font-size: 15"
    expect_text "iterm2 non-ascii fallback" "$out" "font-family fallback: Fixture Symbols 15"
    expect_text "iterm2 background" "$out" "background: #11111b"
    expect_text "iterm2 foreground" "$out" "foreground: #cdd6f4"
    expect_text "iterm2 ansi 13" "$out" " 13 #f2aede"
    expect_text "iterm2 ansi 8" "$out" "  8 #585b70"
    expect_text "iterm2 opacity conversion" "$out" "configured background-opacity: 0.8000"
    expect_text "iterm2 blur warning" "$out" "blur"
    case "$out" in
      *"Secondary Font 9"*) die "self-check: iterm2 read a non-default profile" ;;
    esac
    if ! out=$(HOME="$h" XDG_CONFIG_HOME="$h/.config" \
        bash "$SCRIPT_PATH" --terminal iterm2 --config "$iterm_plist" --json); then
      die "self-check: iterm2 --json run failed"
    fi
    if ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
      die "self-check: iterm2 --json output was not valid JSON"
    fi
    if ! printf '%s' "$out" | jq -e '.terminals[0].colors.palette[13] == "#f2aede"' >/dev/null; then
      die "self-check: iterm2 --json palette mismatch"
    fi
  fi

  # No config at all must be stated plainly, not invented.
  if HOME="$SELF_CHECK_DIR/elsewhere" XDG_CONFIG_HOME="$SELF_CHECK_DIR/elsewhere/.config" \
      GHOSTTY_RESOURCES_DIR="$SELF_CHECK_DIR/elsewhere/resources" \
      bash "$SCRIPT_PATH" > "$SELF_CHECK_DIR/empty.txt" 2>&1; then
    die "self-check: expected a non-zero exit when no terminal config exists"
  fi
  out=$(cat "$SELF_CHECK_DIR/empty.txt")
  expect_text "no-config message" "$out" "no terminal configuration found"

  # Option validation.
  if bash "$SCRIPT_PATH" --config "$ghostty_cfg" >/dev/null 2>&1; then
    die "self-check: --config without --terminal was accepted"
  fi
  if bash "$SCRIPT_PATH" --terminal alacritty --theme-file "$ghostty_theme" >/dev/null 2>&1; then
    die "self-check: --theme-file was accepted for a terminal without theme files"
  fi
  if bash "$SCRIPT_PATH" --terminal nope >/dev/null 2>&1; then
    die "self-check: an unknown --terminal was accepted"
  fi

  printf 'self-check passed: ghostty/wezterm/alacritty/kitty/iterm2 fixtures, font fallback chains, --config/--theme-file overrides, theme-file precedence over GHOSTTY_RESOURCES_DIR, config-over-theme precedence, unresolved-theme reporting, JSON shape, ambiguity, no-config exit, unset XDG_CONFIG_HOME, read-only shasum invariant, option validation\n'
}

# --- main --------------------------------------------------------------------

OPT_TERMINAL=
OPT_CONFIG=
OPT_THEME_FILE=
OPT_JSON=0
RUN_SELF_CHECK=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --terminal) need_value "$@"; OPT_TERMINAL=$2; shift 2 ;;
    --config) need_value "$@"; OPT_CONFIG=$2; shift 2 ;;
    --theme-file) need_value "$@"; OPT_THEME_FILE=$2; shift 2 ;;
    --json) OPT_JSON=1; shift ;;
    --self-check) RUN_SELF_CHECK=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; [ "$#" -eq 0 ] || die "unexpected positional arguments: $*" ;;
    -*) die "unknown option: $1" ;;
    *) die "unexpected positional argument: $1" ;;
  esac
done

if [ "$RUN_SELF_CHECK" -eq 1 ]; then
  run_self_check
  exit 0
fi

if [ -n "$OPT_TERMINAL" ]; then
  case " $TERMINALS " in
    *" $OPT_TERMINAL "*) ;;
    *) die "--terminal must be one of: $TERMINALS" ;;
  esac
fi
if [ -n "$OPT_CONFIG" ] && [ -z "$OPT_TERMINAL" ]; then
  die "--config requires --terminal"
fi
if [ -n "$OPT_THEME_FILE" ]; then
  case "$OPT_TERMINAL" in
    ghostty|kitty) ;;
    *) die "--theme-file requires --terminal ghostty or --terminal kitty" ;;
  esac
  [ -r "$OPT_THEME_FILE" ] || die "--theme-file is not readable: $OPT_THEME_FILE"
fi

WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/terminal-theme.XXXXXX")
trap 'rm -rf -- "$WORK_DIR"' EXIT INT TERM

DETECTED=
RECORD_FILE=
for terminal in $TERMINALS; do
  if [ -n "$OPT_TERMINAL" ] && [ "$OPT_TERMINAL" != "$terminal" ]; then
    continue
  fi
  RECORD_FILE="$WORK_DIR/records-$terminal"
  : > "$RECORD_FILE"
  reset_terminal_state
  PALETTE_FILE="$WORK_DIR/palette-$terminal.txt"
  : > "$PALETTE_FILE"
  if "detect_$terminal"; then
    emit_terminal "$terminal"
    DETECTED="$DETECTED $terminal"
  else
    # Keep the searched paths so the "nothing found" report can name them.
    emit_lines searched path "$SEARCHED_PATHS"
  fi
done

if [ -z "$DETECTED" ]; then
  if [ "$OPT_JSON" -eq 1 ]; then
    printf '{\n  "ambiguous": false,\n  "terminals": [],\n  "note": %s\n}\n' \
      "$(json_string "no terminal configuration found; no theme is reported")"
  else
    if [ -n "$OPT_TERMINAL" ]; then
      printf 'no %s configuration found; nothing is reported rather than inventing a theme.\n' "$OPT_TERMINAL"
    else
      printf 'no terminal configuration found; nothing is reported rather than inventing a theme.\n'
    fi
    printf 'searched:\n'
    for terminal in $TERMINALS; do
      if [ -n "$OPT_TERMINAL" ] && [ "$OPT_TERMINAL" != "$terminal" ]; then
        continue
      fi
      RECORD_FILE="$WORK_DIR/records-$terminal"
      while IFS= read -r line; do
        if [ -n "$line" ]; then
          printf '  %s: %s\n' "$terminal" "$line"
        fi
      done <<EOF
$(record_lines searched path)
EOF
    done
  fi
  exit 1
fi

DETECTED=${DETECTED# }
COUNT=0
for terminal in $DETECTED; do
  COUNT=$((COUNT + 1))
done
if [ "$COUNT" -gt 1 ]; then
  AMBIGUOUS=true
else
  AMBIGUOUS=false
fi

if [ "$OPT_JSON" -eq 1 ]; then
  render_json "$DETECTED" "$AMBIGUOUS"
  exit 0
fi

if [ "$AMBIGUOUS" = true ]; then
  printf 'WARNING: ambiguous source — %s are all configured, so the capture could come from any of them.\n' "$(printf '%s' "$DETECTED" | sed 's/ /, /g')"
  printf 'Every terminal is reported below. Confirm which one produced the capture, or re-run with --terminal NAME.\n'
fi

for terminal in $DETECTED; do
  RECORD_FILE="$WORK_DIR/records-$terminal"
  render_terminal_text
done
