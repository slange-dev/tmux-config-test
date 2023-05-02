#!/usr/bin/env bash

#
set -e
set -u
set -o pipefail

#
is_app_installed() {
  type "$1" &>/dev/null
}

#
REPODIR="$(cd "$(dirname "$0")"; pwd -P)"
cd "$REPODIR";

#
if ! is_app_installed tmux; then
  echo -e "WARNING: \"tmux\" command is not found. Install it first\n"
  exit 1
fi

# Check if tmux plugin manager is installed
if [ ! -e "~/.tmux/plugins/tpm" ]; then
  echo -e "WARNING: Cannot found TPM (Tmux Plugin Manager) at default location: \$HOME/.tmux/plugins/tpm.\n"

  # Clone tmux plugin manager (tpm)
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Check if tmux config file exist, then backup config file
if [ -e "~/.tmux.conf" ]; then
  echo -e "Found existing .tmux.conf in your \$HOME directory. Will create a backup at $HOME/.tmux.conf.bak\n"
  
  # Backup tmux config file
  cp -f ~/.tmux.conf ~/.tmux.conf.bak 2>/dev/null || true
fi

# Copy tmux config
#cp -a ./.tmux/. /root/.tmux/

# Symlink tmux config
ln -sf ~/.tmux/tmux.conf ~/.tmux.conf

# Install TPM plugins.
# TPM requires running tmux server, as soon as `tmux start-server` does not work
# create dump __noop session in detached mode, and kill it when plugins are installed
echo -e "Install TPM plugins\n"

#
tmux new -d -s __noop >/dev/null 2>&1 || true 
tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "~/.tmux/plugins"
~/.tmux/plugins/tpm/bin/install_plugins || true
tmux kill-session -t __noop >/dev/null 2>&1 || true

# Finish!
echo -e "OK: Completed\n"
