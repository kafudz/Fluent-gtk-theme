#!/bin/bash

set -euo pipefail

SASSC_OPT=('-M' '-t' 'expanded')

_COLOR_VARIANTS=('' '-Light' '-Dark')
_SIZE_VARIANTS=('' '-compact')

if [[ -n "${COLOR_VARIANTS:-}" ]]; then
  IFS=', ' read -r -a _COLOR_VARIANTS <<< "${COLOR_VARIANTS}"
fi

if [[ -n "${SIZE_VARIANTS:-}" ]]; then
  IFS=', ' read -r -a _SIZE_VARIANTS <<< "${SIZE_VARIANTS}"
fi

# Check command availability
has_command() {
  command -v "$1" >/dev/null 2>&1
}

# Install needed packages
install_package() {
  if has_command sassc; then
    return
  fi

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

  if ! has_command sassc; then
    echo "ERROR: sassc could not be installed. Please install it manually." >&2
    exit 1
  fi
}

compile() {
  local input="$1"
  local output="$2"

  if ! sassc "${SASSC_OPT[@]}" "$input" "$output"; then
    echo "ERROR: failed to compile '$input'." >&2
    exit 1
  fi
}

install_package

echo "== Generating the CSS..."

cp -f src/_sass/_tweaks.scss src/_sass/_tweaks-temp.scss
cp -f src/gnome-shell/sass/_tweaks.scss src/gnome-shell/sass/_tweaks-temp.scss

if has_command gnome-shell; then
  gnome-shell --version || true
  SHELL_VERSION="$(gnome-shell --version 2>/dev/null | cut -d ' ' -f 3 | cut -d . -f -1 || true)"
  SHELL_VERSION="${SHELL_VERSION//[!0-9]/}"  # strip non-numeric chars

  if [[ "${SHELL_VERSION:-0}" -ge 45 ]]; then
    sed -i "/\$activities:/s/icon/default/" src/gnome-shell/sass/_tweaks-temp.scss
  fi
fi

for color in "${_COLOR_VARIANTS[@]}"; do
  for size in "${_SIZE_VARIANTS[@]}"; do
    compile "src/gtk/3.0/gtk$color$size.scss" "src/gtk/3.0/gtk$color$size.css"
    compile "src/gtk/4.0/gtk$color$size.scss" "src/gtk/4.0/gtk$color$size.css"
    compile "src/gnome-shell/shell-3-28/gnome-shell$color$size.scss" "src/gnome-shell/shell-3-28/gnome-shell$color$size.css"
    compile "src/gnome-shell/shell-40-0/gnome-shell$color$size.scss" "src/gnome-shell/shell-40-0/gnome-shell$color$size.css"
    compile "src/gnome-shell/shell-42-0/gnome-shell$color$size.scss" "src/gnome-shell/shell-42-0/gnome-shell$color$size.css"
    compile "src/gnome-shell/shell-44-0/gnome-shell$color$size.scss" "src/gnome-shell/shell-44-0/gnome-shell$color$size.css"
    compile "src/gnome-shell/shell-46-0/gnome-shell$color$size.scss" "src/gnome-shell/shell-46-0/gnome-shell$color$size.css"
    compile "src/gnome-shell/shell-47-0/gnome-shell$color$size.scss" "src/gnome-shell/shell-47-0/gnome-shell$color$size.css"
    compile "src/gnome-shell/shell-48-0/gnome-shell$color$size.scss" "src/gnome-shell/shell-48-0/gnome-shell$color$size.css"
    compile "src/cinnamon/cinnamon$color$size.scss" "src/cinnamon/cinnamon$color$size.css"
  done
done

echo "== done!"
