#!/usr/bin/env bash

set -e

FONT_DIR=""
OS_TYPE="$(uname)"
ZIP_URLS=(
  "Agave.zip"
  "AnonymousPro.zip"
  "CascadiaCode.zip"
  "CascadiaMono.zip"
  "CodeNewRoman.zip"
  "ComicShannsMono.zip"
  "DejaVuSansMono.zip"
  "FiraCode.zip"
  "FiraMono.zip"
  "Gohu.zip"
  "HeavyData.zip"
  "JetBrainsMono.zip"
  "Monofur.zip"
  "Monoid.zip"
  "NerdFontsSymbolsOnly.zip"
  "Noto.zip"
  "OpenDyslexic.zip"
  "ProFont.zip"
  "Recursive.zip"
  "RobotoMono.zip"
  "SpaceMono.zip"
  "Ubuntu.zip"
  "UbuntuMono.zip"
  "UbuntuSans.zip"
  "ZedMono.zip"
)
BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0"

# Detect OS and set font directory
if [[ "$OS_TYPE" == "Darwin" ]]; then
  FONT_DIR="$HOME/Library/Fonts"
elif [[ "$OS_TYPE" == "Linux" ]]; then
  FONT_DIR="$HOME/.local/share/fonts"
else
  echo -e "\nUnsupported OS: $OS_TYPE"
  exit 1
fi

mkdir -p "$FONT_DIR"
TMP_DIR="$(mktemp -d)"
echo -e "\n🧩 Installing Nerd Fonts to: $FONT_DIR"
INSTALLED_FONTS=()

# Check for fc-cache and install fontconfig if missing
if [[ "$OS_TYPE" == "Linux" || "$OS_TYPE" == "Darwin" ]]; then
  if ! command -v fc-cache >/dev/null 2>&1; then
    echo -e "\n⚠️  'fc-cache' not found. Attempting to install fontconfig..."
    if [[ "$OS_TYPE" == "Linux" ]]; then
      if command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y fontconfig
      elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y fontconfig
      elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm fontconfig
      fi
    elif [[ "$OS_TYPE" == "Darwin" && -x "$(command -v brew)" ]]; then
      brew install fontconfig
    fi
    if ! command -v fc-cache >/dev/null 2>&1; then
      echo -e "\n⚠️  Still no 'fc-cache'. Fonts may require restart to appear."
      HAS_FONT_CACHE=0
    else
      HAS_FONT_CACHE=1
    fi
  else
    HAS_FONT_CACHE=1
  fi
else
  HAS_FONT_CACHE=0
fi

for ZIP in "${ZIP_URLS[@]}"; do
  NAME="${ZIP%.zip}"
  if find "$FONT_DIR" -iname "${NAME}*.ttf" -o -iname "${NAME}*.otf" | grep -q .; then
    echo -e "\n✅ $NAME already installed. Skipping."
    continue
  fi

  echo -e "\n⬇️  Downloading $NAME..."
  curl -sSL -o "$TMP_DIR/$ZIP" "$BASE_URL/$ZIP"

  echo -e "\n📦 Extracting $NAME..."
  unzip -qq "$TMP_DIR/$ZIP" -d "$TMP_DIR/$NAME"

  echo -e "\n📁 Installing $NAME..."
  find "$TMP_DIR/$NAME" -iname "*.ttf" -o -iname "*.otf" -exec cp {} "$FONT_DIR/" \;

  INSTALLED_FONTS+=("$NAME")
  echo -e "\n✨ Successfully installed: $NAME"
done

if [[ "$HAS_FONT_CACHE" -eq 1 ]]; then
  echo -e "\n🔄 Refreshing font cache..."
  fc-cache -fv "$FONT_DIR"
fi

# Clean up temporary files
rm -rf "$TMP_DIR"

# Show installed fonts
if [[ ${#INSTALLED_FONTS[@]} -gt 0 ]]; then
  echo -e "\n🎉 Installed fonts:"
  for FONT in "${INSTALLED_FONTS[@]}"; do
    echo -e "   - $FONT"
  done
else
  echo -e "\n✅ All fonts were already installed."
fi

# Notify user to reload terminal if necessary
if [[ "$OS_TYPE" == "Linux" || "$OS_TYPE" == "Darwin" ]]; then
  echo -e "\n🔁 Please restart your terminal or run: source ~/.bashrc (or reopen terminal)"
fi

