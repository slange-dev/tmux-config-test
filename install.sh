#!/usr/bin/env bash

#
set -e
set -u
set -o pipefail

# Function to check if a app is installed
is_app_installed() {
  type "$1" &>/dev/null
}

#
REPODIR="$(cd "$(dirname "$0")"; pwd -P)"
cd "$REPODIR";

# Check if tmux is installed
if ! is_app_installed tmux; then
  echo -e "WARNING: \"tmux\" command is not found. Install it first\n"
  exit 1
fi

# Check if tmux plugin manager is installed
if [ ! -e "~/.tmux/plugins/tpm" ]; then
  echo -e "WARNING: Cannot found TPM (Tmux Plugin Manager) at default location: \$HOME/.tmux/plugins/tpm.\n"

# Clone tmux plugin manager (tpm)
echo -e "Clone tmux plugin manager (tpm)\n"
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Check if tmux config file exist, then backup the file
if [ -e "~/.tmux.conf" ]; then
  echo -e "Found existing .tmux.conf in your \$HOME directory. Will create a backup at $HOME/.tmux.conf.bak\n"
  
# Backup tmux config file
echo -e "Backup tmux config file\n"
cp -f ~/.tmux.conf ~/.tmux.conf.bak 2>/dev/null || true
fi

# Symlink tmux config files
echo -e "Symlink tmux config files\n"
ln -sf ~/.tmux/tmux/tmux.conf ~/.tmux.conf
ln -sf ~/.tmux/tmux/tmux.remote.conf ~/.tmux.remote.conf

# Create tmux script directory
echo -e "Create tmux script directory\n"
mkdir -p ~/.scripts/tmux

# Symlink tmux scripts
echo -e "Symlink tmux scripts\n"
ln -sf ~/.tmux/tmux/yank.sh ~/.scripts/tmux/yank.sh
#ln -sf ~/.tmux/tmux.conf ~/.scripts/
ln -sf ~/.tmux/tmux/tmux-update-display.sh ~/.scripts/tmux/tmux-update-display.sh

# Chmod tmux scripts to +x
echo -e "Chmod tmux scripts\n"
chmod -R +x ~/.scripts

# Install TPM plugins
echo -e "Install TPM plugins\n"
# TPM requires running tmux server,
# as soon as `tmux start-server` does not work,
# create dump __noop session in detached mode
# and kill it when plugins are installed
tmux new -d -s __noop >/dev/null 2>&1 || true 
tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "~/.tmux/plugins"
~/.tmux/plugins/tpm/bin/install_plugins || true
tmux kill-session -t __noop >/dev/null 2>&1 || true

# Finish!
echo -e "OK: Tmux installation completed\n"
