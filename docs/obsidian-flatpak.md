# Obsidian (Flatpak) — known issues and fixes

Obsidian is installed from Flathub (`md.obsidian.Obsidian`). The Flatpak
sandbox introduces two quirks that don't exist with the AppImage build.

## 1. Zoom level / UI scale resets between launches

**Symptom.** Ctrl+= / Ctrl+- changes the zoom, but the new value is
forgotten the next time Obsidian starts.

**Cause.** Under XWayland, Electron can't persist per-window scale state
reliably. Native Wayland fixes it.

**Fix.** Grant the sandbox the Wayland socket and hint Electron to pick
Wayland:

```bash
flatpak override --user \
    --socket=wayland \
    --env=ELECTRON_OZONE_PLATFORM_HINT=auto \
    md.obsidian.Obsidian
```

Already wired into [`setup.sh`](../setup.sh) (see commit `f539785`).

## 2. `obsidian` CLI can't find Obsidian

**Symptom.**

```
$ obsidian daily
The CLI is unable to find Obsidian. Please make sure Obsidian is running and try again.
```

…even though Obsidian is running and the built-in CLI is enabled
(`"cli": true` in `~/.var/app/md.obsidian.Obsidian/config/obsidian/obsidian.json`).

**Cause.** Obsidian's CLI talks to the running app through a Unix socket
at `$XDG_RUNTIME_DIR/.obsidian-cli.sock`. Inside the Flatpak sandbox,
`XDG_RUNTIME_DIR` is remapped, so the plugin creates the socket at:

```
/run/user/$UID/.flatpak/md.obsidian.Obsidian/xdg-run/.obsidian-cli.sock
```

A CLI invoked on the host looks in `/run/user/$UID/` and sees nothing.

**Fix.** Wrap the CLI so it looks inside the sandbox's runtime dir. The
Flatpak already ships the `obsidian-cli` binary at a stable path, so no
manual extraction is needed.

Drop this into `~/.local/bin/obsidian` (must come before any other
`obsidian` shim in `$PATH`):

```bash
#!/usr/bin/env bash
set -eu
export XDG_RUNTIME_DIR="/run/user/$(id -u)/.flatpak/md.obsidian.Obsidian/xdg-run"
exec "$HOME/.local/share/flatpak/app/md.obsidian.Obsidian/current/active/files/obsidian-cli" "$@"
```

Make it executable (`chmod +x ~/.local/bin/obsidian`) and confirm:

```bash
obsidian daily     # should open today's daily note
```

Verify the socket exists first if the wrapper still fails:

```bash
ls /run/user/$(id -u)/.flatpak/md.obsidian.Obsidian/xdg-run/.obsidian-cli.sock
```

Missing socket means Obsidian isn't running, or the in-app CLI toggle is
off — turn it on under Settings → General → Command-line interface.

### Alternative without a wrapper

If you don't want a wrapper, invoke the CLI via `flatpak run` each time
(≈90 ms startup overhead):

```bash
flatpak run --command=/app/obsidian-cli md.obsidian.Obsidian daily
```
