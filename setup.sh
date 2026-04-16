#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

log()  { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33mWARN: %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m ok: %s\033[0m\n' "$*"; }

# ============================================================
# 1. DNF packages
# ============================================================
log "Installing packages from packages.list"
sudo dnf install -y $(grep -v '^\s*#' "$REPO/packages.list" | grep -v '^\s*$' | tr '\n' ' ')

# ============================================================
# 2. Special packages
# ============================================================
log "Installing glab (via COPR)"
if ! command -v glab &>/dev/null; then
    sudo dnf copr enable -y atim/glab
    sudo dnf install -y glab
else
    ok "glab already installed"
fi

log "Installing Rust toolchain via rustup"
if ! command -v rustup &>/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    source "$HOME/.cargo/env"
    rustup component add rustfmt clippy
    cargo install xargo
else
    ok "rustup already installed"
fi

log "Installing claude-code via npm"
if ! command -v claude &>/dev/null; then
    sudo npm install -g @anthropic-ai/claude-code
else
    ok "claude-code already installed"
fi

log "Installing Obsidian via Flatpak"
if ! flatpak info md.obsidian.Obsidian &>/dev/null 2>&1; then
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install -y flathub md.obsidian.Obsidian
else
    ok "Obsidian already installed"
fi

log "Installing Zed via Flatpak"
if ! flatpak info dev.zed.Zed &>/dev/null 2>&1; then
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install -y flathub dev.zed.Zed
else
    ok "Zed already installed"
fi

# ============================================================
# 3. Config symlinks (~/.config/* → repo/config/*)
# ============================================================
log "Deploying config symlinks"
for dir in vim ghostty zsh git; do
    src="$REPO/config/$dir"
    dst="$CONFIG_HOME/$dir"
    if [[ -L "$dst" ]]; then
        ln -sfn "$src" "$dst"
        ok "symlink updated: $dst"
    elif [[ -e "$dst" ]]; then
        warn "$dst exists and is not a symlink — backing up to ${dst}.bak"
        mv "$dst" "${dst}.bak"
        ln -sfn "$src" "$dst"
        ok "symlink created: $dst (original backed up)"
    else
        ln -sfn "$src" "$dst"
        ok "symlink created: $dst"
    fi
done

# ============================================================
# 4. ~/.zshenv bootstrap (sets ZDOTDIR for SSH / non-Ghostty)
# ============================================================
log "Deploying ~/.zshenv and ~/.CLAUDE.md"
ln -sf "$REPO/home/.zshenv" "$HOME/.zshenv"
ok "~/.zshenv -> $REPO/home/.zshenv"
ln -sf "$REPO/home/.CLAUDE.md" "$HOME/.CLAUDE.md"
ok "~/.CLAUDE.md -> $REPO/home/.CLAUDE.md"

log "Deploying Claude Code config"
mkdir -p "$HOME/.claude/agents"
ln -sf "$REPO/home/.claude/settings.json" "$HOME/.claude/settings.json"
ok "~/.claude/settings.json -> $REPO/home/.claude/settings.json"
ln -sf "$REPO/home/.claude/agents/shell-runner.md" "$HOME/.claude/agents/shell-runner.md"
ok "~/.claude/agents/shell-runner.md -> $REPO/home/.claude/agents/shell-runner.md"

# ============================================================
# 5. System files
# ============================================================
log "Deploying system files"

sudo cp "$REPO/system/modules-load.d/l2tp.conf" /etc/modules-load.d/l2tp.conf
ok "/etc/modules-load.d/l2tp.conf"

sudo cp "$REPO/system/modprobe.d/l2tp-unblacklist.conf" /etc/modprobe.d/l2tp-unblacklist.conf
ok "/etc/modprobe.d/l2tp-unblacklist.conf"

sudo cp "$REPO/system/sudoers.d/wheel-nopasswd" /etc/sudoers.d/wheel-nopasswd
sudo chmod 440 /etc/sudoers.d/wheel-nopasswd
ok "/etc/sudoers.d/wheel-nopasswd"

sudo cp "$REPO/system/NetworkManager/dispatcher.d/99-cn-split-tunnel.sh" \
    /etc/NetworkManager/dispatcher.d/99-cn-split-tunnel.sh
sudo chmod 755 /etc/NetworkManager/dispatcher.d/99-cn-split-tunnel.sh
ok "/etc/NetworkManager/dispatcher.d/99-cn-split-tunnel.sh"

sudo cp "$REPO/system/systemd/system-sleep/iwlwifi-reset.sh" \
    /usr/lib/systemd/system-sleep/iwlwifi-reset.sh
sudo chmod 755 /usr/lib/systemd/system-sleep/iwlwifi-reset.sh
ok "/usr/lib/systemd/system-sleep/iwlwifi-reset.sh"

if ! lsmod | grep -q l2tp_core; then
    sudo modprobe l2tp_core l2tp_netlink l2tp_ppp l2tp_ip
    ok "l2tp modules loaded"
fi

if [[ ! -f /etc/chnroute.txt ]]; then
    warn "/etc/chnroute.txt not found — split-tunnel VPN routing will not work."
    warn "Fetch it with: curl -o /etc/chnroute.txt https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt"
fi

# ============================================================
# 6. Zsh plugins (cloned into ~/.config/zsh/, excluded from git)
# ============================================================
log "Installing Zsh plugins"
ZSH_DIR="$CONFIG_HOME/zsh"

clone_if_missing() {
    local name="$1" url="$2"
    if [[ ! -d "$ZSH_DIR/$name" ]]; then
        git clone --depth=1 "$url" "$ZSH_DIR/$name"
        ok "cloned $name"
    else
        ok "$name already present"
    fi
}

clone_if_missing zsh-autosuggestions        https://github.com/zsh-users/zsh-autosuggestions
clone_if_missing spaceship                   https://github.com/spaceship-prompt/spaceship-prompt
clone_if_missing zsh-syntax-highlighting     https://github.com/zsh-users/zsh-syntax-highlighting
clone_if_missing zsh-history-substring-search https://github.com/zsh-users/zsh-history-substring-search

# ============================================================
# 7. Vim plugins (vim-plug bootstraps itself via vimrc)
# ============================================================
log "Bootstrapping Vim plugins"
VIMINIT="set rtp+=~/.config/vim | source ~/.config/vim/vimrc" \
    vim -es -u "$CONFIG_HOME/vim/vimrc" +PlugInstall +qall || true
ok "vim plugins installed"

# ============================================================
log "Setup complete."
echo ""
echo "Next steps:"
echo "  - Log out and back in for group changes to take effect (libvirt, kvm)"
echo "  - Run 'gh auth login' to authenticate the GitHub CLI"
echo "  - Run 'glab auth login' to authenticate GitLab CLI"
echo "  - Add GNOME Keyring entries for shell secrets (ANTHROPIC_VERTEX_PROJECT_ID, GH_TOKEN, etc.)"
if [[ ! -f /etc/chnroute.txt ]]; then
    echo "  - Fetch /etc/chnroute.txt for VPN split tunnelling (see WARN above)"
fi
