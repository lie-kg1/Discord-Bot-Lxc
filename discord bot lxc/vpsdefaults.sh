#!/bin/bash
exec </dev/tty

# Smart path detection to find where .env actually lives
if [ -f ".env" ] && [ ! -d "vps-deploy" ]; then
    ENV_PATH=".env"
else
    ENV_PATH="vps-deploy/.env"
fi

printf "\033[1;36m🤖 ─────────────────────────────────────────\033[0m\n"
printf "\033[1;36m        VPS DEFAULTS CONFIGURATION (EDIT)     \033[0m\n"
printf "\033[1;36m────────────────────────────────────────────\033[0m\n\n"

if [ ! -f "$ENV_PATH" ]; then
    printf "\033[1;31m⚠️ .env file not found! Please run 'create bot' (createbot.sh) first.\033[0m\n"
    exit 1
fi

# Read current values from .env if they exist
get_env_val() {
    local key="$1" default="$2"
    local val
    val=$(grep "^${key}=" "$ENV_PATH" 2>/dev/null | cut -d '=' -f2-)
    printf '%s' "${val:-$default}"
}

CURRENT_RAM=$(get_env_val "DEPLOY_RAM" "16")
CURRENT_CPU=$(get_env_val "DEPLOY_CPU" "3")
CURRENT_DISK=$(get_env_val "DEPLOY_DISK" "80")
CURRENT_LIMIT=$(get_env_val "VPS_DEPLOY_LIMIT" "2")
CURRENT_SLOT=$(get_env_val "DEPLOY_SLOT" "50")
CURRENT_EXPIRY=$(get_env_val "DEFAULT_VPS_EXPIRATION_DAYS" "30")
CURRENT_WARNING=$(get_env_val "EXPIRATION_WARNING_DAYS" "1")

printf "\033[1;33mCurrent values are shown in brackets [ ]. Press Enter to keep current values.\033[0m\n\n"

# ---- Validation helpers ----
validate_int() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

prompt_int() {
    local label="$1" current="$2" __resultvar="$3"
    local input
    while true; do
        read -p "$label [$current]: " input
        input=${input:-$current}
        if validate_int "$input"; then
            printf -v "$__resultvar" '%s' "$input"
            break
        else
            printf "\033[1;31m  ✗ Invalid value. Enter a whole number.\033[0m\n"
        fi
    done
}

# ---- Prompts ----
prompt_int "🧠  Deploy RAM (GB)"              "$CURRENT_RAM"           NEW_RAM
prompt_int "⚡  Deploy CPU Cores"             "$CURRENT_CPU"           NEW_CPU
prompt_int "💾  Deploy Disk (GB)"            "$CURRENT_DISK"          NEW_DISK
prompt_int "📊  Deploy Limit per user"       "$CURRENT_LIMIT"         NEW_LIMIT
prompt_int "📈  Global Deploy Slot Cap"      "$CURRENT_SLOT"          NEW_SLOT
prompt_int "⏰  Default Expiration Days"     "$CURRENT_EXPIRY"        NEW_EXPIRY
prompt_int "⚠️   Expiration Warning Days"    "$CURRENT_WARNING"       NEW_WARNING

# ---- Safely update the .env file ----
ENV_PATH="$ENV_PATH" \
NEW_RAM="$NEW_RAM" \
NEW_CPU="$NEW_CPU" \
NEW_DISK="$NEW_DISK" \
NEW_LIMIT="$NEW_LIMIT" \
NEW_SLOT="$NEW_SLOT" \
NEW_EXPIRY="$NEW_EXPIRY" \
NEW_WARNING="$NEW_WARNING" \
python3 -c "
import os

env_path = os.environ['ENV_PATH']
updates = {
    'DEPLOY_RAM': os.environ['NEW_RAM'],
    'DEPLOY_CPU': os.environ['NEW_CPU'],
    'DEPLOY_DISK': os.environ['NEW_DISK'],
    'VPS_DEPLOY_LIMIT': os.environ['NEW_LIMIT'],
    'DEPLOY_SLOT': os.environ['NEW_SLOT'],
    'DEFAULT_VPS_EXPIRATION_DAYS': os.environ['NEW_EXPIRY'],
    'EXPIRATION_WARNING_DAYS': os.environ['NEW_WARNING'],
}

with open(env_path, 'r') as f:
    lines = f.readlines()

updated_keys = set()
new_lines = []
for line in lines:
    stripped = line.strip()
    if '=' in stripped and not stripped.startswith('#'):
        key = stripped.split('=')[0].strip()
        if key in updates:
            new_lines.append(f'{key}={updates[key]}\n')
            updated_keys.add(key)
            continue
    new_lines.append(line)

for key, val in updates.items():
    if key not in updated_keys:
        new_lines.append(f'{key}={val}\n')

with open(env_path, 'w') as f:
    f.writelines(new_lines)
"

printf "\n\033[1;32m✅ VPS Defaults successfully updated and saved to %s!\033[0m\n" "$ENV_PATH"
