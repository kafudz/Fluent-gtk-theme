#!/bin/bash

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$REPO_DIR/src"

ROOT_UID=0
DEST_DIR=""

# For tweaks
opacity=""
panel=""
window=""
blur=""
outline=""
titlebutton=""
icon="-default"
accent=""
libadwaita=""
uninstall=""
dest=""
name=""
GS_VERSION=""

# Destination directory
if [[ "$UID" -eq "$ROOT_UID" ]]; then
  DEST_DIR="/usr/share/themes"
elif [[ -n "${XDG_DATA_HOME:-}" ]]; then
  DEST_DIR="$XDG_DATA_HOME/themes"
elif [[ -d "$HOME/.themes" ]]; then
  DEST_DIR="$HOME/.themes"
elif [[ -d "$HOME/.local/share/themes" ]]; then
  DEST_DIR="$HOME/.local/share/themes"
else
  DEST_DIR="$HOME/.themes"
fi

SASSC_OPT=('-M' '-t' 'expanded')

THEME_NAME="Fluent"
THEME_VARIANTS=('' '-purple' '-pink' '-red' '-orange' '-yellow' '-green' '-teal' '-grey')
COLOR_VARIANTS=('' '-Light' '-Dark')
SIZE_VARIANTS=('' '-compact')

if command -v gnome-shell >/dev/null 2>&1; then
  gnome-shell --version
  SHELL_VERSION="$(gnome-shell --version 2>/dev/null | cut -d ' ' -f 3 | cut -d . -f -1)"
  SHELL_VERSION="${SHELL_VERSION//[!0-9]/}"  # strip non-numeric chars
  if [[ "${SHELL_VERSION:-0}" -ge 48 ]]; then
    GS_VERSION="48-0"
  elif [[ "${SHELL_VERSION:-0}" -ge 47 ]]; then
    GS_VERSION="47-0"
  elif [[ "${SHELL_VERSION:-0}" -ge 46 ]]; then
    GS_VERSION="46-0"
  elif [[ "${SHELL_VERSION:-0}" -ge 44 ]]; then
    GS_VERSION="44-0"
  elif [[ "${SHELL_VERSION:-0}" -ge 42 ]]; then
    GS_VERSION="42-0"
  elif [[ "${SHELL_VERSION:-0}" -ge 40 ]]; then
    GS_VERSION="40-0"
  else
    GS_VERSION="3-28"
  fi
else
  echo "'gnome-shell' not found, using styles for last gnome-shell version available."
  GS_VERSION="48-0"
fi

usage() {
cat << EOF
Usage: $0 [OPTION]...

OPTIONS:
  -d, --dest DIR          Specify destination directory (Default: $DEST_DIR)

  -n, --name NAME         Specify theme name (Default: $THEME_NAME)

  -t, --theme VARIANT     Specify theme color variant(s) [default|purple|pink|red|orange|yellow|green|teal|grey|all] (Default: default)

  -c, --color VARIANT     Specify color variant(s) [standard|light|dark] (Default: All variants)

  -s, --size VARIANT      Specify size variant [standard|compact] (Default: All variants)

  -i, --icon VARIANT      Specify icon variant(s) for shell panel
                          [default|apple|simple|gnome|ubuntu|arch|manjaro|fedora|debian|void|opensuse|popos|mxlinux|zorin|endeavouros|tux|nixos]
                          (Default: Windows)

  -l, --libadwaita        Install link to gtk4 config for theming libadwaita

  -r, --remove
  -u, --uninstall         Uninstall/remove themes or link for libadwaita

  --tweaks                Specify versions for tweaks [solid|float|round|blur|noborder|square]
                          solid:    no transparency version
                          float:    floating panel
                          round:    rounded windows
                          blur:     blur version for 'Blur-Me'
                          noborder: windows and menu with no border
                          square:   square windows button

  -h, --help              Show help
EOF
}

# Check command availability
has_command() {
  command -v "$1" >/dev/null 2>&1
}

# Compile a stylesheet and stop if the compiler fails
compile_css() {
  local input="$1"
  local output="$2"

  if ! sassc "${SASSC_OPT[@]}" "$input" "$output"; then
    echo "ERROR: failed to compile '$input'." >&2
    exit 1
  fi
}

# Install needed packages
install_package() {
  if ! has_command sassc; then
    echo "sassc needs to be installed to generate the css."
    if has_command zypper; then
      sudo zypper --non-interactive in sassc
    elif has_command apt-get; then
      sudo apt-get install -y sassc
    elif has_command apt; then
      sudo apt install -y sassc
    elif has_command dnf; then
      sudo dnf install -y sassc
    elif has_command yum; then
      sudo yum install -y sassc
    elif has_command pacman; then
      sudo pacman -S --noconfirm --needed sassc
    elif has_command xbps-install; then
      sudo xbps-install -y sassc
    fi
  fi
  if ! has_command sassc; then
    echo "ERROR: sassc could not be installed. Please install it manually." >&2
    exit 1
  fi
}

tweaks_temp() {
  cp -f "$SRC_DIR/_sass/_tweaks.scss" "$SRC_DIR/_sass/_tweaks-temp.scss"
  cp -f "$SRC_DIR/gnome-shell/sass/_tweaks.scss" "$SRC_DIR/gnome-shell/sass/_tweaks-temp.scss"
}

install_float_panel() {
  sed -i "/\$panel_style:/s/compact/float/" "$SRC_DIR/gnome-shell/sass/_tweaks-temp.scss"
  sed -i "/\$panel_style:/s/compact/float/" "$SRC_DIR/_sass/_tweaks-temp.scss"
}

install_solid() {
  sed -i "/\$opacity:/s/default/solid/" "$SRC_DIR/gnome-shell/sass/_tweaks-temp.scss"
  sed -i "/\$opacity:/s/default/solid/" "$SRC_DIR/_sass/_tweaks-temp.scss"
  echo -e "Install solid version ..."
}

install_round() {
  sed -i "/\$window:/s/default/round/" "$SRC_DIR/gnome-shell/sass/_tweaks-temp.scss"
  sed -i "/\$window:/s/default/round/" "$SRC_DIR/_sass/_tweaks-temp.scss"
}

install_blur() {
  sed -i "/\$blur:/s/false/true/" "$SRC_DIR/gnome-shell/sass/_tweaks-temp.scss"
  sed -i "/\$blur:/s/false/true/" "$SRC_DIR/_sass/_tweaks-temp.scss"
}

install_noborder() {
  sed -i "/\$outline:/s/true/false/" "$SRC_DIR/gnome-shell/sass/_tweaks-temp.scss"
  sed -i "/\$outline:/s/true/false/" "$SRC_DIR/_sass/_tweaks-temp.scss"
}

install_square() {
  sed -i "/\$titlebutton:/s/circular/square/" "$SRC_DIR/_sass/_tweaks-temp.scss"
}

activities_style() {
  sed -i "/\$activities:/s/default/icon/" "$SRC_DIR/gnome-shell/sass/_tweaks-temp.scss"
}

install_theme_color() {
  local theme="$1"
  local theme_color=""

  [[ -z "$theme" ]] && return

  case "$theme" in
    -purple) theme_color='purple' ;;
    -pink)   theme_color='pink'   ;;
    -red)    theme_color='red'    ;;
    -orange) theme_color='orange' ;;
    -yellow) theme_color='yellow' ;;
    -green)  theme_color='green'  ;;
    -teal)   theme_color='teal'   ;;
    -grey)   theme_color='grey'   ;;
  esac

  [[ -z "$theme_color" ]] && return

  sed -i "/\$theme:/s/default/${theme_color}/" "$SRC_DIR/gnome-shell/sass/_tweaks-temp.scss"
  sed -i "/\$theme:/s/default/${theme_color}/" "$SRC_DIR/_sass/_tweaks-temp.scss"
}

theme_tweaks() {
  if [[ "$panel" = "float" || "$opacity" = "solid" || "$window" = "round" \
     || "$accent" = "true" || "$blur" = "true" || "$outline" = "false" \
     || "$titlebutton" = "square" || "$activities" = "icon" ]]; then
    tweaks='true'
    install_package
    tweaks_temp
  fi

  if [[ "$panel" = "float" ]]; then
    install_float_panel
  fi
  if [[ "$opacity" = "solid" ]]; then
    install_solid
  fi
  if [[ "$window" = "round" ]]; then
    install_round
  fi
  if [[ "$blur" = "true" ]]; then
    install_blur
  fi
  if [[ "$outline" = "false" ]]; then
    install_noborder
  fi
  if [[ "$titlebutton" = "square" ]]; then
    install_square
  fi
  if [[ "$activities" = "icon" ]]; then
    activities_style
  fi
}

install() {
  local dest="$1"
  local name="$2"
  local theme="$3"
  local color="$4"
  local size="$5"
  local icon="$6"
  local round=""

  local ELSE_DARK="" ELSE_LIGHT="" ACTIVITIES_ASSETS_SUFFIX=""
  [[ "$color" == '-Dark'  ]] && ELSE_DARK="$color"
  [[ "$color" == '-Light' ]] && ELSE_LIGHT="$color"
  [[ "$color" == '-Dark' || "$color" == '' ]] && ACTIVITIES_ASSETS_SUFFIX="-Dark"

  if [[ "$window" == 'round' ]]; then
    round='-round'
  else
    round=$window
  fi

  local THEME_DIR="$dest/$name$round$theme$color$size"

  [[ -d "$THEME_DIR" ]] && rm -rf "${THEME_DIR:?}"

  theme_tweaks && install_theme_color "$theme"

  echo "Installing '$THEME_DIR'..."

  mkdir -p "$THEME_DIR"
  cp -r "$REPO_DIR/COPYING" "$THEME_DIR"

  cat > "$THEME_DIR/index.theme" <<EOF
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=$name$round$theme$color$size
Comment=An Materia Gtk+ theme based on Elegant Design
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=$name$round$theme$color$size
MetacityTheme=$name$round$theme$color$size
IconTheme=$name${ELSE_DARK:-}
CursorTheme=$name${ELSE_DARK:-}
ButtonLayout=close,minimize,maximize:menu
EOF

  mkdir -p "$THEME_DIR/gnome-shell"
  cp -r "$SRC_DIR/gnome-shell/pad-osd.css" "$THEME_DIR/gnome-shell"

  if [[ "$tweaks" == 'true' ]]; then
    compile_css "$SRC_DIR/gnome-shell/shell-$GS_VERSION/gnome-shell$color$size.scss" "$THEME_DIR/gnome-shell/gnome-shell.css"
  else
    cp -r "$SRC_DIR/gnome-shell/shell-$GS_VERSION/gnome-shell$color$size.css" "$THEME_DIR/gnome-shell/gnome-shell.css"
  fi

  cp -r "$SRC_DIR/gnome-shell/common-assets" "$THEME_DIR/gnome-shell/assets"
  cp -r "$SRC_DIR/gnome-shell/assets${ELSE_DARK:-}/"*.svg "$THEME_DIR/gnome-shell/assets"
  cp -r "$SRC_DIR/gnome-shell/theme$theme/"*.svg "$THEME_DIR/gnome-shell/assets"
  cp -r "$SRC_DIR/gnome-shell/assets${ACTIVITIES_ASSETS_SUFFIX:-}/activities/activities${icon}.svg" "$THEME_DIR/gnome-shell/assets/activities.svg"

  if [[ "$window" = "round" ]]; then
    cp -r "$SRC_DIR/gnome-shell/assets${ELSE_DARK:-}/buttons-round/"*.svg "$THEME_DIR/gnome-shell/assets"
  else
    cp -r "$SRC_DIR/gnome-shell/assets${ELSE_DARK:-}/buttons/"*.svg "$THEME_DIR/gnome-shell/assets"
  fi

  if [[ "$color" = "-Light" ]]; then
    cp -r "$SRC_DIR/gnome-shell/assets-Dark/activities/activities${icon}.svg" "$THEME_DIR/gnome-shell/assets/activities-white.svg"
  fi

  if [[ "$opacity" = "solid" ]]; then
    if [[ "$window" = "round" ]]; then
      if [[ -z "$outline" ]]; then
        cp -r "$SRC_DIR/gnome-shell/assets${ELSE_DARK:-}/solid-round/"*.svg "$THEME_DIR/gnome-shell/assets"
      else
        cp -r "$SRC_DIR/gnome-shell/assets${ELSE_DARK:-}/solid-round-borderless/"*.svg "$THEME_DIR/gnome-shell/assets"
      fi
    else
      if [[ -z "$outline" ]]; then
        cp -r "$SRC_DIR/gnome-shell/assets${ELSE_DARK:-}/solid/"*.svg "$THEME_DIR/gnome-shell/assets"
      else
        cp -r "$SRC_DIR/gnome-shell/assets${ELSE_DARK:-}/solid-borderless/"*.svg "$THEME_DIR/gnome-shell/assets"
      fi
    fi
  else
    if [[ "$window" = "round" ]]; then
      if [[ -z "$outline" ]]; then
        cp -r "$SRC_DIR/gnome-shell/assets${ELSE_DARK:-}/default-round/"*.svg "$THEME_DIR/gnome-shell/assets"
      else
        cp -r "$SRC_DIR/gnome-shell/assets${ELSE_DARK:-}/default-round-borderless/"*.svg "$THEME_DIR/gnome-shell/assets"
      fi
    else
      if [[ -z "$outline" ]]; then
        cp -r "$SRC_DIR/gnome-shell/assets${ELSE_DARK:-}/default/"*.svg "$THEME_DIR/gnome-shell/assets"
      else
        cp -r "$SRC_DIR/gnome-shell/assets${ELSE_DARK:-}/default-borderless/"*.svg "$THEME_DIR/gnome-shell/assets"
      fi
    fi
  fi

  (
    cd "$THEME_DIR/gnome-shell" || exit 1
    ln -sf assets/no-events.svg no-events.svg
    ln -sf assets/process-working.svg process-working.svg
    ln -sf assets/no-notifications.svg no-notifications.svg
  )

  mkdir -p "$THEME_DIR/gtk-2.0"
  cp -r "$SRC_DIR/gtk-2.0/common/"{apps.rc,hacks.rc,main.rc} "$THEME_DIR/gtk-2.0"
  cp -r "$SRC_DIR/gtk-2.0/assets-folder/assets$theme${ELSE_DARK:-}" "$THEME_DIR/gtk-2.0/assets"
  cp -r "$SRC_DIR/gtk-2.0/gtkrc$theme${ELSE_DARK:-}" "$THEME_DIR/gtk-2.0/gtkrc"

  mkdir -p "$THEME_DIR/gtk-3.0"
  cp -r "$SRC_DIR/gtk/assets$theme" "$THEME_DIR/gtk-3.0/assets"
  cp -r "$SRC_DIR/gtk/scalable" "$THEME_DIR/gtk-3.0/assets"
  cp -r "$SRC_DIR/gtk/thumbnail$theme${ELSE_DARK:-}.png" "$THEME_DIR/gtk-3.0/thumbnail.png"

  if [[ "$tweaks" == 'true' ]]; then
    compile_css "$SRC_DIR/gtk/3.0/gtk$color$size.scss" "$THEME_DIR/gtk-3.0/gtk.css"
    compile_css "$SRC_DIR/gtk/3.0/gtk-Dark$size.scss" "$THEME_DIR/gtk-3.0/gtk-dark.css"
  else
    cp -r "$SRC_DIR/gtk/3.0/gtk$theme$color$size.css" "$THEME_DIR/gtk-3.0/gtk.css"
    cp -r "$SRC_DIR/gtk/3.0/gtk$theme-Dark$size.css" "$THEME_DIR/gtk-3.0/gtk-dark.css"
  fi

  mkdir -p "$THEME_DIR/gtk-4.0"
  cp -r "$SRC_DIR/gtk/assets$theme" "$THEME_DIR/gtk-4.0/assets"
  cp -r "$SRC_DIR/gtk/scalable" "$THEME_DIR/gtk-4.0/assets"

  if [[ "$tweaks" == 'true' ]]; then
    compile_css "$SRC_DIR/gtk/4.0/gtk$color$size.scss" "$THEME_DIR/gtk-4.0/gtk.css"
    compile_css "$SRC_DIR/gtk/4.0/gtk-Dark$size.scss" "$THEME_DIR/gtk-4.0/gtk-dark.css"
  else
    cp -r "$SRC_DIR/gtk/4.0/gtk$color$size.css" "$THEME_DIR/gtk-4.0/gtk.css"
    cp -r "$SRC_DIR/gtk/4.0/gtk-Dark$size.css" "$THEME_DIR/gtk-4.0/gtk-dark.css"
  fi

  mkdir -p "$THEME_DIR/cinnamon"
  cp -r "$SRC_DIR/cinnamon/common-assets" "$THEME_DIR/cinnamon/assets"
  cp -r "$SRC_DIR/cinnamon/assets${ELSE_DARK:-}/"*.svg "$THEME_DIR/cinnamon/assets"

  if [[ "$accent" == 'true' || "$opacity" == 'solid' ]]; then
    compile_css "$SRC_DIR/cinnamon/cinnamon$color$size.scss" "$THEME_DIR/cinnamon/cinnamon.css"
  else
    cp -r "$SRC_DIR/cinnamon/cinnamon$color$size.css" "$THEME_DIR/cinnamon/cinnamon.css"
  fi

  cp -r "$SRC_DIR/cinnamon/thumbnail$theme$color.png" "$THEME_DIR/cinnamon/thumbnail.png"

  mkdir -p "$THEME_DIR/xfwm4"
  if [[ "$titlebutton" = "square" ]]; then
    cp -r "$SRC_DIR/xfwm4/assets-square$color/"*.png "$THEME_DIR/xfwm4"
    cp -r "$SRC_DIR/xfwm4/themerc-square${ELSE_LIGHT:-}" "$THEME_DIR/xfwm4/themerc"
  else
    cp -r "$SRC_DIR/xfwm4/assets$color/"*.png "$THEME_DIR/xfwm4"
    cp -r "$SRC_DIR/xfwm4/themerc${ELSE_LIGHT:-}" "$THEME_DIR/xfwm4/themerc"
  fi

  mkdir -p "$THEME_DIR/labwc"
  cp -r "$SRC_DIR/labwc/assets${ELSE_LIGHT:-}/"*.svg "$THEME_DIR/labwc"
  cp -r "$SRC_DIR/labwc/themerc${ELSE_DARK:-}${ELSE_LIGHT:-}" "$THEME_DIR/labwc/themerc"

  mkdir -p "$THEME_DIR/metacity-1"
  cp -r "$SRC_DIR/metacity-1/metacity-theme-2$color.xml" "$THEME_DIR/metacity-1/metacity-theme-2.xml"

  if [[ "$window" = "round" ]]; then
    cp -r "$SRC_DIR/metacity-1/metacity-theme-3-round.xml" "$THEME_DIR/metacity-1/metacity-theme-3.xml"
    cp -r "$SRC_DIR/metacity-1/assets-round" "$THEME_DIR/metacity-1/assets"
  else
    cp -r "$SRC_DIR/metacity-1/metacity-theme-3.xml" "$THEME_DIR/metacity-1"
    cp -r "$SRC_DIR/metacity-1/assets" "$THEME_DIR/metacity-1"
  fi

  cp -r "$SRC_DIR/metacity-1/thumbnail${ELSE_DARK:-}.png" "$THEME_DIR/metacity-1/thumbnail.png"
  ( cd "$THEME_DIR/metacity-1" && ln -sf metacity-theme-2.xml metacity-theme-1.xml )

  mkdir -p "$THEME_DIR/plank"
  cp -r "$SRC_DIR/plank/theme${ELSE_LIGHT:-}/dock.theme" "$THEME_DIR/plank"
}

uninstall() {
  local dest="$1"
  local name="$2"
  local theme="$3"
  local color="$4"
  local size="$5"
  local round=""

  if [[ "$window" == 'round' ]]; then
    round='-round'
  else
    round=$window
  fi

  local THEME_DIR="$dest/$name$round$theme$color$size"

  if [[ -d "$THEME_DIR" ]]; then
    echo -e "Uninstall ${THEME_DIR}... "
    rm -rf "$THEME_DIR"
  fi
}

uninstall_link() {
  rm -rf "${HOME}/.config/gtk-4.0/assets" \
         "${HOME}/.config/gtk-4.0/gtk.css" \
         "${HOME}/.config/gtk-4.0/gtk-dark.css"
}

link_libadwaita() {
  local dest="$1"
  local name="$2"
  local theme="$3"
  local color="$4"
  local size="$5"
  local round=""

  if [[ "$window" == 'round' ]]; then
    round='-round'
  else
    round=$window
  fi

  local THEME_DIR="$dest/$name$round$theme$color$size"

  echo -e "\nLink '$THEME_DIR/gtk-4.0' to '${HOME}/.config/gtk-4.0' for libadwaita..."

  mkdir -p "${HOME}/.config/gtk-4.0"
  ln -sf "${THEME_DIR}/gtk-4.0/assets"      "${HOME}/.config/gtk-4.0/assets"
  ln -sf "${THEME_DIR}/gtk-4.0/gtk.css"     "${HOME}/.config/gtk-4.0/gtk.css"
  ln -sf "${THEME_DIR}/gtk-4.0/gtk-dark.css" "${HOME}/.config/gtk-4.0/gtk-dark.css"
}

clean() {
  local dest="$1"
  local name="$2"
  local round="$3"
  local theme="$4"
  local color="$5"
  local size="$6"

  local THEME_DIR="$dest/$name$round$theme$color$size"

  if [[ -d "$THEME_DIR" ]]; then
    rm -rf "$THEME_DIR"
    echo -e "Find: ${THEME_DIR} ! removing it ..."
  fi
}

theme_dirs() {
  THEME_DIRS=("${dest:-$DEST_DIR}")

  # When using the default theme directory, also use the alternate standard path
  if [[ -z "${dest:-}" ]]; then
    if [[ "$DEST_DIR" == "$HOME/.themes" ]]; then
      THEME_DIRS+=("$HOME/.local/share/themes")
    elif [[ "$DEST_DIR" == "$HOME/.local/share/themes" ]]; then
      THEME_DIRS+=("$HOME/.themes")
    fi
  fi
}

clean_theme() {
  theme_dirs

  local d round theme color size
  for d in "${THEME_DIRS[@]}"; do
    for round in '' '-round'; do
      for theme in "${THEME_VARIANTS[@]}"; do
        for color in "${COLOR_VARIANTS[@]}"; do
          for size in "${SIZE_VARIANTS[@]}"; do
            clean "$d" "${name:-$THEME_NAME}" "$round" "$theme" "$color" "$size"
          done
        done
      done
    done
  done
}

uninstall_theme() {
  theme_dirs

  local d theme color size
  for d in "${THEME_DIRS[@]}"; do
    for theme in "${themes[@]}"; do
      for color in "${colors[@]}"; do
        for size in "${sizes[@]}"; do
          uninstall "$d" "${name:-$THEME_NAME}" "$theme" "$color" "$size"
        done
      done
    done
  done
}

install_theme() {
  local theme color size
  for theme in "${themes[@]}"; do
    for color in "${colors[@]}"; do
      for size in "${sizes[@]}"; do
        install "${dest:-$DEST_DIR}" "${name:-$THEME_NAME}" "$theme" "$color" "$size" "$icon"
      done
    done
  done
}

link_theme() {
  local theme color size
  for theme in "${themes[@]}"; do
    for color in "${lcolors[@]}"; do
      size="${sizes[0]:-}"
      link_libadwaita "${dest:-$DEST_DIR}" "${name:-$THEME_NAME}" "$theme" "$color" "$size"
    done
  done
}

themes=()
colors=()
sizes=()
lcolors=()

# ---- Argument parsing ----
while [[ "$#" -gt 0 ]]; do
  case "${1:-}" in
    -d|--dest)
      if [[ -z "${2:-}" ]]; then
        echo "ERROR: $1 requires a directory argument." >&2
        exit 1
      fi
      dest="$2"
      mkdir -p "$dest"
      shift 2
      ;;
    -n|--name)
      if [[ -z "${2:-}" ]]; then
        echo "ERROR: $1 requires a name argument." >&2
        exit 1
      fi
      name="$2"
      shift 2
      ;;
    -l|--libadwaita)
      libadwaita="true"
      shift
      ;;
    -u|--uninstall|-r|--remove)
      uninstall="true"
      shift
      ;;
    --tweaks)
      shift
      while [[ "$#" -gt 0 && "${1:-}" != -* ]]; do
        case "$1" in
          solid)   opacity="solid";     echo -e "Install solid version ..." ;;
          float)   panel="float";       echo -e "Install floating panel version ..." ;;
          round)   window="round";      echo -e "Install rounded windows version ..." ;;
          blur)    blur="true"; panel="compact"; echo -e "Install blur version ..." ;;
          noborder) outline="false";    echo -e "Install windows without outline version ..." ;;
          square)  titlebutton="square"; echo -e "Install square windows button version ..." ;;
          *)
            echo "ERROR: Unrecognized tweaks variant '$1'." >&2
            echo "Try '$0 --help' for more information." >&2
            exit 1
            ;;
        esac
        shift
      done
      ;;
    -t|--theme)
      accent='true'
      shift
      while [[ "$#" -gt 0 && "${1:-}" != -* ]]; do
        case "$1" in
          default) themes+=("${THEME_VARIANTS[0]}") ;;
          purple)  themes+=("${THEME_VARIANTS[1]}") ;;
          pink)    themes+=("${THEME_VARIANTS[2]}") ;;
          red)     themes+=("${THEME_VARIANTS[3]}") ;;
          orange)  themes+=("${THEME_VARIANTS[4]}") ;;
          yellow)  themes+=("${THEME_VARIANTS[5]}") ;;
          green)   themes+=("${THEME_VARIANTS[6]}") ;;
          teal)    themes+=("${THEME_VARIANTS[7]}") ;;
          grey)    themes+=("${THEME_VARIANTS[8]}") ;;
          all)     themes+=("${THEME_VARIANTS[@]}") ;;
          *)
            echo "ERROR: Unrecognized theme variant '$1'." >&2
            echo "Try '$0 --help' for more information." >&2
            exit 1
            ;;
        esac
        shift
      done
      ;;
    -i|--icon)
      activities='icon'
      shift
      while [[ "$#" -gt 0 && "${1:-}" != -* ]]; do
        case "$1" in
          default)      icon='-default' ;;
          apple)        icon='-apple' ;;
          simple)       icon='-simple' ;;
          gnome)        icon='-gnome' ;;
          ubuntu)       icon='-ubuntu' ;;
          arch)         icon='-arch' ;;
          manjaro)      icon='-manjaro' ;;
          fedora)       icon='-fedora' ;;
          debian)       icon='-debian' ;;
          void)         icon='-void' ;;
          opensuse)     icon='-opensuse' ;;
          popos)        icon='-popos' ;;
          mxlinux)      icon='-mxlinux' ;;
          zorin)        icon='-zorin' ;;
          endeavouros)  icon='-endeavouros' ;;
          tux)          icon='-tux' ;;
          nixos)        icon='-nixos' ;;
          *)
            echo "ERROR: Unrecognized icon variant '$1'." >&2
            echo "Try '$0 --help' for more information." >&2
            exit 1
            ;;
        esac
        echo "Install $1 icon for gnome-shell panel..."
        shift
      done
      ;;
    -c|--color)
      shift
      while [[ "$#" -gt 0 && "${1:-}" != -* ]]; do
        case "$1" in
          standard) colors+=("${COLOR_VARIANTS[0]}"); lcolors+=("${COLOR_VARIANTS[0]}") ;;
          light)    colors+=("${COLOR_VARIANTS[1]}"); lcolors+=("${COLOR_VARIANTS[1]}") ;;
          dark)     colors+=("${COLOR_VARIANTS[2]}"); lcolors+=("${COLOR_VARIANTS[2]}") ;;
          *)
            echo "ERROR: Unrecognized color variant '$1'." >&2
            echo "Try '$0 --help' for more information." >&2
            exit 1
            ;;
        esac
        shift
      done
      ;;
    -s|--size)
      shift
      while [[ "$#" -gt 0 && "${1:-}" != -* ]]; do
        case "$1" in
          standard) sizes+=("${SIZE_VARIANTS[0]}") ;;
          compact)  sizes+=("${SIZE_VARIANTS[1]}") ;;
          *)
            echo "ERROR: Unrecognized size variant '$1'." >&2
            echo "Try '$0 --help' for more information." >&2
            exit 1
            ;;
        esac
        shift
      done
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unrecognized installation option '${1:-}'." >&2
      echo "Try '$0 --help' for more information." >&2
      exit 1
      ;;
  esac
done

# ---- Defaults ----
if [[ "${#themes[@]}" -eq 0 ]]; then
  themes=("${THEME_VARIANTS[0]}")
fi

if [[ "${#colors[@]}" -eq 0 ]]; then
  colors=("${COLOR_VARIANTS[@]}")
fi

if [[ "${#lcolors[@]}" -eq 0 ]]; then
  lcolors=("${COLOR_VARIANTS[1]}")
fi

if [[ "${#sizes[@]}" -eq 0 ]]; then
  sizes=("${SIZE_VARIANTS[@]}")
fi

# ---- Main ----
if [[ "$uninstall" == 'true' ]]; then
  if [[ "$libadwaita" == 'true' ]]; then
    echo -e "\nUninstall ${HOME}/.config/gtk-4.0 links ..."
    uninstall_link
  else
    echo
    uninstall_theme
    uninstall_link
  fi
else
  clean_theme
  install_theme

  if [[ "$libadwaita" == 'true' ]]; then
    uninstall_link
    link_theme
  fi
fi

echo
echo "Done."
