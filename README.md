# devcage

Fedora Linux first-boot configuration. Installs packages, deploys dotfiles, and sets up system configs in one command.

## Usage

```bash
git clone https://github.com/xiaofengwang/devcage ~/devcage
cd ~/devcage
./setup.sh
```

Or run individual steps with `just`:

```bash
just packages       # install DNF packages + special tools
just configs        # symlink dotfiles into ~/.config
just system-files   # deploy /etc configs (requires sudo)
just zsh-plugins    # clone zsh plugins
just vim-plugins    # bootstrap vim-plug plugins
```

## What it sets up

**Packages** — zsh, vim, ghostty, chromium, firefox, nodejs, golang, podman, libvirt/qemu, ansible, fzf, ripgrep, and more (see `packages.list`)

**Dotfiles** (symlinked into `~/.config/`)
- `vim/` — vim with vim-plug, coc.nvim, ALE, fzf, NERDTree
- `zsh/` — spaceship prompt, autosuggestions, syntax highlighting, vi mode
- `ghostty/` — terminal config
- `git/` — aliases, colors, gh credential helper

**Home files** (symlinked into `~/`)
- `.zshenv` — sets `ZDOTDIR` for SSH/non-Ghostty sessions
- `.CLAUDE.md` — Claude Code preferences

**System configs**
- `/etc/modules-load.d/l2tp.conf` — L2TP VPN kernel modules
- `/etc/sudoers.d/wheel-nopasswd` — passwordless sudo for wheel group
- `/etc/NetworkManager/dispatcher.d/99-cn-split-tunnel.sh` — split-tunnel routing for VPN

## Post-setup

- Run `gh auth login` and `glab auth login`
- Add secrets to GNOME Keyring (`ANTHROPIC_VERTEX_PROJECT_ID`, `GH_TOKEN`, etc.)
- For VPN split tunnelling, fetch the China IP list:
  ```bash
  sudo curl -o /etc/chnroute.txt https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt
  ```

## License

MIT
