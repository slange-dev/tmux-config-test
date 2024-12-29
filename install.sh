#!/usr/bin/env bash

set -e
set -u
set -o pipefail

# Function to check if an app is installed
is_app_installed() {
  type "$1" &>/dev/null
}

REPODIR="$(cd "$(dirname "$0")"; pwd -P)"
cd "$REPODIR"

# Check if tmux is installed
if ! is_app_installed tmux; then
  echo -e "WARNING: \"tmux\" command is not found. Install it first\n"
  exit 1
fi

# Create tmux config directory if not exists
echo -e "Creating tmux config directory\n"
mkdir -p "$HOME/.tmux"

# Check if tmux plugin manager is installed
if [ ! -e "$HOME/.tmux/plugins/tpm" ]; then
  echo -e "WARNING: Cannot found TPM (Tmux Plugin Manager) at default location: \$HOME/.tmux/plugins/tpm.\n"

  # Clone tmux plugin manager (tpm)
  echo -e "Cloning tmux plugin manager (tpm)\n"
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# Check if tmux config file exists, then backup the file
if [ -e "$HOME/.tmux.conf" ]; then
  echo -e "Found existing .tmux.conf in your \$HOME directory. Creating a backup at $HOME/.tmux.conf.bak\n"

  # Backup tmux config file
  echo -e "Backing up tmux config file\n"
  cp -f "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak" 2>/dev/null || true
fi

# Copy tmux configuration files from the current directory to ~/.tmux/
echo -e "Copying tmux configuration files to ~/.tmux/\n"
cp -f "$HOME/tmux-config-test/tmux/.tmux.template.conf" "$HOME/.tmux/.tmux.template.conf"
cp -f "$HOME/tmux-config-test/tmux/tmux.conf" "$HOME/.tmux/tmux.conf"
cp -f "$HOME/tmux-config-test/tmux/tmux.remote.conf" "$HOME/.tmux/tmux.remote.conf"
cp -f "$HOME/tmux-config-test/tmux/yank.sh" "$HOME/.tmux/yank.sh"
cp -f "$HOME/tmux-config-test/tmux/renew_env.sh" "$HOME/.tmux/renew_env.sh"
cp -f "$HOME/tmux-config-test/tmux/tmux-update-display.sh" "$HOME/.tmux/tmux-update-display.sh"

# Symlink tmux config files
echo -e "Creating symlinks for tmux config files\n"
ln -sf "$HOME/.tmux/tmux.conf" "$HOME/.tmux.conf"
ln -sf "$HOME/.tmux/tmux.remote.conf" "$HOME/.tmux.remote.conf"

# Create tmux script directory if not exists
echo -e "Creating tmux script directory\n"
mkdir -p "$HOME/.bin/tmux"

# Symlink tmux scripts
echo -e "Creating symlinks for tmux scripts\n"
ln -sf "$HOME/.tmux/yank.sh" "$HOME/.bin/tmux/yank.sh"
ln -sf "$HOME/.tmux/renew_env.sh" "$HOME/.bin/tmux/renew_env.sh"
ln -sf "$HOME/.tmux/tmux-update-display.sh" "$HOME/.bin/tmux/tmux-update-display.sh"

# Set execute permissions for tmux scripts
echo -e "Setting execute permissions on tmux scripts\n"
chmod -R +x "$HOME/.bin/tmux"

# Install TPM plugins
echo -e "Installing TPM plugins\n"
# TPM requires running tmux server
# If `tmux start-server` doesn't work, create a dummy session, install plugins, and then kill it
tmux new -d -s __noop >/dev/null 2>&1 || true
tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins"
"$HOME/.tmux/plugins/tpm/bin/install_plugins" || true
tmux kill-session -t __noop >/dev/null 2>&1 || true

# Finish!
echo -e "OK: Tmux installation completed\n"
