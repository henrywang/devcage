default: setup

# Run full setup
setup: packages configs system-files zsh-plugins vim-plugins
    @echo ""
    @echo "Setup complete. See setup.sh output for next steps."

# Install all packages (DNF + special)
packages:
    sudo dnf install -y $(grep -v '^\s*#' packages.list | grep -v '^\s*$' | tr '\n' ' ')
    # glab
    command -v glab || (sudo dnf copr enable -y atim/glab && sudo dnf install -y glab)
    # claude-code
    command -v claude || sudo npm install -g @anthropic-ai/claude-code
    # Rust
    command -v rustup || (curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path)
    # Flatpak apps
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install -y --noninteractive flathub md.obsidian.Obsidian dev.zed.Zed || true

# Symlink config dirs into ~/.config
configs:
    #!/usr/bin/env bash
    set -euo pipefail
    REPO="$(pwd)"
    CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
    for dir in vim ghostty zsh git; do
        src="$REPO/config/$dir"
        dst="$CFG/$dir"
        [[ -e "$dst" && ! -L "$dst" ]] && mv "$dst" "${dst}.bak"
        ln -sfn "$src" "$dst"
        echo "  $dst -> $src"
    done
    ln -sf "$REPO/home/.zshenv" "$HOME/.zshenv"
    echo "  ~/.zshenv -> $REPO/home/.zshenv"

# Deploy system-level files (requires sudo)
system-files:
    sudo cp system/modules-load.d/l2tp.conf /etc/modules-load.d/l2tp.conf
    sudo cp system/sudoers.d/wheel-nopasswd /etc/sudoers.d/wheel-nopasswd
    sudo chmod 440 /etc/sudoers.d/wheel-nopasswd
    lsmod | grep -q l2tp_core || sudo modprobe l2tp_core l2tp_netlink l2tp_ppp l2tp_ip
    sudo cp system/NetworkManager/dispatcher.d/99-cn-split-tunnel.sh \
        /etc/NetworkManager/dispatcher.d/99-cn-split-tunnel.sh
    sudo chmod 755 /etc/NetworkManager/dispatcher.d/99-cn-split-tunnel.sh

# Clone Zsh plugins into ~/.config/zsh/
zsh-plugins:
    #!/usr/bin/env bash
    set -euo pipefail
    ZSH="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
    clone() { [[ -d "$ZSH/$1" ]] || git clone --depth=1 "$2" "$ZSH/$1"; }
    clone zsh-autosuggestions         https://github.com/zsh-users/zsh-autosuggestions
    clone spaceship                    https://github.com/spaceship-prompt/spaceship-prompt
    clone zsh-syntax-highlighting      https://github.com/zsh-users/zsh-syntax-highlighting
    clone zsh-history-substring-search https://github.com/zsh-users/zsh-history-substring-search

# Bootstrap Vim plugins via vim-plug
vim-plugins:
    vim -es -u "${XDG_CONFIG_HOME:-$HOME/.config}/vim/vimrc" +PlugInstall +qall || true
