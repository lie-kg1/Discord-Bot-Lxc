#!/bin/bash
exec </dev/tty

# Smart path detection
if [ -d "vps-deploy" ]; then
    ENV_DIR="vps-deploy"
elif [ -f "bot.py" ] || [ -f "requirements.txt" ]; then
    ENV_DIR="."
else
    ENV_DIR="vps-deploy"
    mkdir -p "$ENV_DIR"
fi
ENV_PATH="$ENV_DIR/.env"

printf "\033[1;36m🤖 ─────────────────────────────────────────\033[0m\n"
printf "\033[1;36m        DISCORD BOT SETUP (LXC VPS BOT)        \033[0m\n"
printf "\033[1;36m────────────────────────────────────────────\033[0m\n\n"

if [ -f "$ENV_PATH" ]; then
    printf "\033[1;33m⚠️ An existing configuration was found at %s\033[0m\n" "$ENV_PATH"
    read -p "Overwrite it? [y/N]: " OVERWRITE
    if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
        printf "\033[1;33mAborted. Existing configuration left untouched.\033[0m\n"
        exit 0
    fi
    echo
fi

# ---- Validation helpers ----
validate_discord_id() {
    # Discord snowflake IDs are numeric, typically 17-20 digits
    [[ "$1" =~ ^[0-9]{15,20}$ ]]
}
validate_token_shape() {
    # Loose sanity check: Discord bot tokens are non-empty, no spaces, reasonably long
    [ -n "$1" ] && [[ "$1" != *' '* ]] && [ "${#1}" -ge 20 ]
}
validate_ip() {
    [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

prompt_required() {
    local label="$1" __resultvar="$2" validator="$3" hint="$4"
    local input
    while true; do
        read -p "$label: " input
        if [ -z "$input" ]; then
            printf "\033[1;31m  ✗ This field is required.\033[0m\n"
            continue
        fi
        if [ -n "$validator" ] && ! "$validator" "$input"; then
            printf "\033[1;31m  ✗ %s\033[0m\n" "$hint"
            continue
        fi
        printf -v "$__resultvar" '%s' "$input"
        break
    done
}

prompt_with_default() {
    local label="$1" current="$2" __resultvar="$3" validator="$4" hint="$5"
    local input
    while true; do
        read -p "$label [$current]: " input
        input=${input:-$current}
        if [ -n "$validator" ] && ! "$validator" "$input"; then
            printf "\033[1;31m  ✗ %s\033[0m\n" "$hint"
            continue
        fi
        printf -v "$__resultvar" '%s' "$input"
        break
    done
}

# ---- Bot identity ----
read -s -p "🔑  Enter your Discord Bot Token (hidden): " BOT_TOKEN
echo
if ! validate_token_shape "$BOT_TOKEN"; then
    printf "\033[1;31m✗ That doesn't look like a valid bot token (too short or contains spaces). Aborting.\033[0m\n"
    exit 1
fi

prompt_required "👤  Enter your Discord User ID (Main Admin)" MAIN_ADMIN_ID validate_discord_id \
    "Discord IDs are numeric, 15-20 digits. Right-click your user in Discord (Developer Mode on) → Copy User ID."

prompt_with_default "🏷️  Enter Bot Name" "PapiaGamerz VMS" BOT_NAME "" ""
prompt_with_default "💬  Enter Command Prefix" "!" PREFIX "" ""
prompt_required "🌐  Enter your Server Public IP" YOUR_SERVER_IP validate_ip \
    "Must be a valid IPv4 address (e.g. 192.168.1.100). NOT 127.0.0.1."

printf "\n\033[1;33m⚙️  --- VPS DEPLOY DEFAULTS ---\033[0m\n"
prompt_with_default "🧠  Deploy RAM (GB)" "16" DEPLOY_RAM "" ""
prompt_with_default "⚡  Deploy CPU Cores" "3" DEPLOY_CPU "" ""
prompt_with_default "💾  Deploy Disk (GB)" "80" DEPLOY_DISK "" ""
prompt_with_default "📊  Deploy Limit per user" "2" VPS_DEPLOY_LIMIT "" ""
prompt_with_default "📈  Global Deploy Slot Cap (0=unlimited)" "50" DEPLOY_SLOT "" ""
prompt_with_default "⏰  Default Expiration Days" "30" DEFAULT_VPS_EXPIRATION_DAYS "" ""

cat <<EOF > "$ENV_PATH"
DISCORD_TOKEN=$BOT_TOKEN
BOT_NAME=$BOT_NAME
PREFIX=$PREFIX
YOUR_SERVER_IP=$YOUR_SERVER_IP
MAIN_ADMIN_ID=$MAIN_ADMIN_ID
VPS_USER_ROLE_ID=0
DEFAULT_STORAGE_POOL=default
BOT_VERSION=8.0-PRO
BOT_DEVELOPER=PapiaGamerz
BOT_THUMBNAIL_URL=https://i.imgur.com/Tv3clt0.jpeg
BOT_ICON_URL=https://i.imgur.com/Tv3clt0.jpeg
DEFAULT_VPS_EXPIRATION_DAYS=$DEFAULT_VPS_EXPIRATION_DAYS
EXPIRATION_WARNING_DAYS=1
DEPLOY_RAM=$DEPLOY_RAM
DEPLOY_CPU=$DEPLOY_CPU
DEPLOY_DISK=$DEPLOY_DISK
DEPLOY_ROLE_ID=0
VPS_DEPLOY_LIMIT=$VPS_DEPLOY_LIMIT
DEPLOY_SLOT=$DEPLOY_SLOT
HOST_MOTD=
EOF

chmod 600 "$ENV_PATH"

printf "\n\033[1;32m✅  Configuration successfully saved to %s!\033[0m\n" "$ENV_PATH"
printf "\033[1;32m🔒  File permissions set to owner-read/write only (chmod 600).\033[0m\n"
printf "\033[1;32m🚀  You can now run your bot using: cd %s && python3 bot.py\033[0m\n" "$ENV_DIR"
