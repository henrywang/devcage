# ZSH Environment Variables
# This file is sourced by all zsh shells (login, interactive, scripts)
# Place this at ~/.zshenv
#
# Note: ZDOTDIR and PATH are set in ~/.config/environment.d/
# This file is a fallback for non-graphical sessions (SSH, etc.)

# Set ZDOTDIR if not already set (fallback for SSH)
export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

# ============================================================
# Secrets from GNOME Keyring (via libsecret)
# ============================================================
# Secrets are loaded at session startup by load-secrets script.
# This is a fallback for SSH sessions or if secrets weren't loaded yet.
if command -v secret-tool &>/dev/null && [[ -n "$WAYLAND_DISPLAY" || -n "$DISPLAY" ]]; then
    _load_secret() {
        local var_name="$1" service="$2" key="$3"
        # Skip if already set (loaded at session startup)
        [[ -n "${(P)var_name}" ]] && return
        local value
        value=$(secret-tool lookup service "$service" key "$key" 2>/dev/null)
        [[ -n "$value" ]] && export "$var_name"="$value"
    }

    _load_secret ANTHROPIC_VERTEX_PROJECT_ID anthropic project_id
    _load_secret CLOUD_ML_REGION anthropic region
    _load_secret GOOGLE_CLOUD_PROJECT gcloud project_id
    _load_secret GH_TOKEN github token

    unset -f _load_secret
fi
