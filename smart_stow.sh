#!/usr/bin/env bash

# =============================
# Smart Dotfiles Stow Script
# =============================

DOTFILES_DIR="$(pwd)"  # Use current folder as dotfiles dir
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m)"

echo "🔹 Starting smart stow..."
echo "Dotfiles folder: $DOTFILES_DIR"
echo "Backup folder for existing configs: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Detect current desktop/session
ENV=$(echo "${XDG_CURRENT_DESKTOP,,}")  # lowercase

# Arrays for summary
declare -a SYMLINKED
declare -a BACKED_UP
declare -a IGNORED

# Iterate over each package in dotfiles
for pkg in "$DOTFILES_DIR"/*; do
    [ -d "$pkg" ] || continue
    pkg_name=$(basename "$pkg")

    # Skip the script itself
    [ "$pkg_name" == "smart_stow.sh" ] && continue

    # Skip environment-specific packages
    case "$pkg_name" in
        hyprland|waybar)
            if [[ "$ENV" != "hyprland" ]]; then
                echo " Skipping $pkg_name for this session ($ENV)"
                IGNORED+=("$pkg_name")
                continue
            fi
            ;;
        kde|plasma)
            if [[ "$ENV" != "plasma" ]]; then
                echo " Skipping $pkg_name for this session ($ENV)"
                IGNORED+=("$pkg_name")
                continue
            fi
            ;;
    esac

    # Handle packages with .config
    if [ -d "$pkg/.config" ]; then
        for conf in "$pkg/.config"/*; do
            target="$HOME/.config/$(basename "$conf")"
            if [ -e "$target" ] || [ -L "$target" ]; then
                echo "󰩐  Backing up existing config: $target"
                mkdir -p "$BACKUP_DIR/.config"
                mv "$target" "$BACKUP_DIR/.config/"
                BACKED_UP+=("$target")
            fi
        done
    fi

    # Handle top-level dotfiles (only files, skip folders)
    for file in "$pkg"/*; do
        [ -f "$file" ] || continue
        target="$HOME/$(basename "$file")"
        if [ -e "$target" ] || [ -L "$target" ]; then
            echo "󰩐  Backing up existing file: $target"
            mv "$target" "$BACKUP_DIR/"
            BACKED_UP+=("$target")
        fi
    done

    # Stow the package
    echo " Stowing $pkg_name..."
    stow -v -t ~ "$pkg_name"
    SYMLINKED+=("$pkg_name")
done

# =============================
# Print Summary Table
# =============================
# Define your arrays first (assuming they are already defined earlier in your script)
# SYMLINKED=("config/nvim" ".zshrc" "my_very_long_dotfile_name.conf")
# BACKED_UP=(".bash_profile")
# IGNORED=("README.md" "LICENSE")

# 1. Initialize maximum column widths based on the column headers
MAX_PKG_LEN=12  # Length of "Package/File"
MAX_STATUS_LEN=9 # Length of "Symlinked" (the longest status text)

# 2. Iterate through all items to find the true maximum length
for p in "${SYMLINKED[@]}" "${BACKED_UP[@]}" "${IGNORED[@]}"; do
    if ((${#p} > MAX_PKG_LEN)); then
        MAX_PKG_LEN=${#p}
    fi
done

# 3. Calculate final column widths (add padding for aesthetics)
# We add 2 characters of padding for space around the text.
PKG_WIDTH=$((MAX_PKG_LEN + 2))