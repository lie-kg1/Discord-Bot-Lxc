# Discord LXC VPS Bot — Fixed Release

## What Was Fixed

### 🔴 Critical Bugs
1. **Environment variable crash** — `int(os.getenv('KEY', '0'))` would crash if `.env` contained empty strings or non-numeric values. Added `_env_int()` helper with safe fallback.
2. **Missing f-string in `!add-resources`** — `lxc stop {vps_id}` was treated as a literal string instead of interpolating the container name.
3. **Missing "Regen Password" button** — The `regen_password` action existed in code but had no UI button, making it unreachable.
4. **Bot uptime was wrong** — Used command execution time instead of actual bot start time. Added `_BOT_START_TIME` tracker.
5. **`!stop-vps-all` was dangerous** — Ran `lxc stop --all --force` which would stop **every** LXC container on the host (including non-VPS ones). Now only stops containers tracked in the bot's database.
6. **Duplicate `get_host_stats` function** — Two identical definitions caused confusion; removed the second (less error-handled) copy.
7. **Missing f-string in `!vps-list`** — Embed field title showed literal `{len(chunks)}` instead of the number.

### 🟡 Compatibility Fixes
8. **Shell scripts were for a different bot** — `createbot.sh` and `vpsdefaults.sh` generated `.env` files with variables like `TOKEN`, `ADMIN_ID`, `DEFAULT_RAM` that `bot.py` doesn't recognize. Completely rewritten to match `bot.py`'s expected format (`DISCORD_TOKEN`, `MAIN_ADMIN_ID`, `DEPLOY_RAM`, etc.).
9. **`requirements.txt` had wrong packages** — Included `docker` (this is an **LXC** bot, not Docker). Replaced with `requests` and correct packages.
10. **`install.sh` installed Docker deps** — Now installs `lxc` and correct Python packages.
11. **`uninstall.sh` missed LXC bot files** — Now also removes `vps.db`, `vps.db-wal`, `vps.db-shm`.
12. **`menu.sh` option 6 did nothing** — Added actual `launch_botpanel` call.

### 🟢 Improvements
13. **`.env.example` created** — Proper template with comments explaining each variable. `YOUR_SERVER_IP` is clearly marked as needing a public IP (not 127.0.0.1).
14. **`MAIN_ADMIN_ID` validation** — `createbot.sh` now validates that you enter a real Discord snowflake ID (15-20 digits), not a role ID.

## File Manifest

| File | Description |
|------|-------------|
| `bot.py` | Main bot (all critical bugs fixed) |
| `.env.example` | Correct environment template |
| `requirements.txt` | Correct Python dependencies |
| `install.sh` | System installer (LXC-aware) |
| `createbot.sh` | Interactive `.env` generator (matches bot.py format) |
| `vpsdefaults.sh` | Interactive defaults editor (matches bot.py format) |
| `menu.sh` | Main menu launcher |
| `247.sh` | 24/7 background process manager |
| `uninstall.sh` | Complete uninstaller |

## Quick Start

```bash
# 1. Extract the zip
cd vps-deploy

# 2. Copy the example env and fill in your values
cp .env.example .env
nano .env

# 3. Install dependencies
pip install -r requirements.txt

# 4. Run the bot
python3 bot.py
```

## Required System Packages

```bash
apt update && apt install -y lxc python3-pip
# Also ensure LXD is initialized:
lxd init
```

## Security Notes

- **Never** commit `.env` to git — it contains your Discord token.
- `chmod 600 .env` is recommended.
- The bot runs as root and executes `lxc` commands. Ensure it runs on a dedicated VPS host.
- `!stop-vps-all` now only affects tracked containers, but still use with caution.
