#!/usr/bin/env bash

set -e
set -u
set -o pipefail

is_app_installed() {
  type "$1" &>/dev/null
}

REPODIR="$(cd "$(dirname "$0")"; pwd -P)"
cd "$REPODIR";

if ! is_app_installed tmux; then
  echo -e "WARNING: \"tmux\" command is not found. Install it first\n"
  exit 1
fi

if [ ! -e "/root/.tmux/plugins/tpm" ]; then
  echo -e "WARNING: Cannot found TPM (Tmux Plugin Manager) at default location: \$HOME/.tmux/plugins/tpm.\n"
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

if [ -e "/root/.tmux.conf" ]; then
  echo -e "Found existing .tmux.conf in your \$HOME directory. Will create a backup at $HOME/.tmux.conf.bak\n"
fi

cp -f /root/.tmux.conf /root/.tmux.conf.bak 2>/dev/null || true
cp -a ./tmux/. /root/.tmux/
ln -sf .tmux/tmux.conf /root/.tmux.conf;

# Install TPM plugins.
# TPM requires running tmux server, as soon as `tmux start-server` does not work
# create dump __noop session in detached mode, and kill it when plugins are installed
echo -e "Install TPM plugins\n"
tmux new -d -s __noop >/dev/null 2>&1 || true 
tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "~/.tmux/plugins"
/root/.tmux/plugins/tpm/bin/install_plugins || true
tmux kill-session -t __noop >/dev/null 2>&1 || true

echo -e "OK: Completed\n"
