#!/bin/bash
set -e

REPO_RAW="https://raw.githubusercontent.com/lie-kg1/1.0-Bot-lxc/refs/heads/main"

printf "\033[1;36m🚀 Setting up clean vps-deploy directory...\033[0m\n"

# Fix any nested vps-deploy/vps-deploy corruption if present
if [ -d "vps-deploy/vps-deploy" ]; then
    printf "\033[1;33m🧹 Cleaning up nested directories...\033[0m\n"
    if cp -r vps-deploy/vps-deploy/* vps-deploy/ 2>/dev/null; then
        rm -rf vps-deploy/vps-deploy
    else
        printf "\033[1;31m✗ Failed to merge nested vps-deploy directory — leaving it in place for manual review.\033[0m\n"
        printf "\033[1;31m  Not deleting vps-deploy/vps-deploy to avoid losing data.\033[0m\n"
    fi
fi

mkdir -p vps-deploy

# Helper: download a file and verify it actually succeeded and isn't empty
fetch_file() {
    local url="$1" dest="$2" label="$3"
    if curl -fsSL "$url" -o "$dest"; then
        if [ -s "$dest" ]; then
            printf "\033[1;32m✅ Downloaded %s\033[0m\n" "$label"
        else
            printf "\033[1;31m✗ Downloaded %s but the file is empty. Aborting.\033[0m\n" "$label"
            exit 1
        fi
    else
        printf "\033[1;31m✗ Failed to download %s from %s\033[0m\n" "$label" "$url"
        exit 1
    fi
}

# Handle .env configuration safely
if [ -f ".env" ]; then
    cp .env vps-deploy/.env
    printf "\033[1;32m✅ Copied local .env to vps-deploy/.env\033[0m\n"
elif [ -f "vps-deploy/.env" ]; then
    printf "\033[1;32m✅ Existing .env configuration found!\033[0m\n"
else
    fetch_file "$REPO_RAW/bot/.env.example" "vps-deploy/.env" ".env configuration"
    printf "\033[1;33m⚠️  Edit vps-deploy/.env and set your DISCORD_TOKEN and MAIN_ADMIN_ID before starting the bot!\033[0m\n"
fi

# Handle requirements.txt
if [ -f "requirements.txt" ]; then
    cp requirements.txt vps-deploy/
else
    fetch_file "$REPO_RAW/bot/requirements.txt" "vps-deploy/requirements.txt" "requirements.txt"
fi

# Handle bot.py
if [ -f "bot.py" ]; then
    cp bot.py vps-deploy/
else
    fetch_file "$REPO_RAW/bot/bot.py" "vps-deploy/bot.py" "bot.py"
fi

printf "\033[1;36m📦 Installing system dependencies and Python packages...\033[0m\n"

if ! command -v sudo >/dev/null 2>&1; then
    printf "\033[1;31m✗ 'sudo' not found. This script expects a Debian/Ubuntu system with sudo available.\033[0m\n"
    exit 1
fi
if ! command -v apt >/dev/null 2>&1; then
    printf "\033[1;31m✗ 'apt' not found. This script only supports Debian/Ubuntu-based systems.\033[0m\n"
    exit 1
fi

sudo apt update -y && sudo apt install -y python3-pip lxc

# Move into vps-deploy to install python packages
cd vps-deploy || exit 1

# Install requirements if present
if [ -f "requirements.txt" ]; then
    python3 -m pip install -r requirements.txt --quiet
fi

python3 -m pip install --upgrade --quiet \
    discord.py python-dotenv requests PyNaCl aiofiles

printf "\033[1;36m⚙️ Checking environment capabilities...\033[0m\n"
if command -v lxc >/dev/null 2>&1; then
    printf "\033[1;32m✅ LXC CLI detected.\033[0m\n"
else
    printf "\033[1;33m⚠️ Note: LXC CLI not found. Ensure LXD is installed and initialized (lxd init).\033[0m\n"
fi

printf "\033[1;32m✨ Installation completed successfully!\033[0m\n"
printf "\033[1;33m👉 Next steps:\033[0m\n"
printf "  1. Edit vps-deploy/.env with your real token and admin ID\n"
printf "  2. Run: cd vps-deploy && python3 bot.py\n"
