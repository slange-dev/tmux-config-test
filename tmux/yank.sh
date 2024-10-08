#!/usr/bin/env bash
##################################################################################
# @Version       :
# @Author        : Sebastian Lange
# @Contact       : 
# @License       :
# @ReadME        :
# @Copyright     : Copyright: (c) 2022 Sebastian Lange, Home Developments
# @Created       :
# @File          :
# @Description   :
# @TODO          :
# @Other         :
# @Resource      : https://medium.com/hackernoon/tmux-in-practice-copy-text-from-remote-session-using-ssh-remote-tunnel-and-systemd-service-dd3c51bca1fa
##################################################################################

#
#-e     When this option is on, if a simple command fails for any of the reasons listed in Consequences of
#       Shell  Errors or returns an exit status value >0, and is not part of the compound list following a
#       while, until, or if keyword, and is not a part of an AND  or  OR  list,  and  is  not  a  pipeline
#       preceded by the ! reserved word, then the shell shall immediately exit.
#
#-u     The shell shall write a message to standard error when it tries to expand a variable that  is  not
#       set and immediately exit. An interactive shell shall not exit.
set -eu

# Function to check if a app is installed
is_app_installed() {
  type "$1" &>/dev/null
}

# Get data either form stdin or from file
buf=$(cat "$@")

# Remote tunnel port
copy_backend_remote_tunnel_port=$(tmux show-option -gvq "@copy_backend_remote_tunnel_port")

# OSC52 fallback option
copy_use_osc52_fallback=$(tmux show-option -gvq "@copy_use_osc52_fallback")

# Resolve copy backend for:
# pbcopy (OSX)
# reattach-to-user-namespace (OSX)
# xsel (Linux)
# xclip (Linux)
# clip.exe (Windows)
# wl-copy (Linux)
# netstat (Linux)
copy_backend=""

# pbcopy clipboard command
if is_app_installed pbcopy; then
  copy_backend="pbcopy"
# reattach-to-user-namespace is recommended on OS X
elif is_app_installed reattach-to-user-namespace; then
  copy_backend="reattach-to-user-namespace pbcopy"
# xsel clipboard command
elif [ -n "${DISPLAY-}" ] && is_app_installed xsel; then
  copy_backend="xsel -i --clipboard"
# xclip clipboard command
elif [ -n "${DISPLAY-}" ] && is_app_installed xclip; then
  copy_backend="xclip -i -f -selection primary | xclip -i -selection clipboard &> /dev/null"
# WSL clipboard command
elif [ -n "${DISPLAY-}" ] && is_app_installed clip.exe; then
  copy_backend="cat | clip.exe"
# wl-clipboard: Wayland clipboard utilities
elif [ -n "${DISPLAY-}" ] && is_app_installed wl-copy; then
copy_backend="wl-copy"
# cygwin clipboard command
elif [ -n "${DISPLAY-}" ] && is_app_installed putclip; then
copy_backend="putclip"
# ssh remote tunnel
elif [ -n "${copy_backend_remote_tunnel_port-}" ] \
    && (netstat -f inet -nl 2>/dev/null || netstat -4 -nl 2>/dev/null) \
      | grep -q "[.:]$copy_backend_remote_tunnel_port"; then
  copy_backend="nc localhost $copy_backend_remote_tunnel_port"
fi

# If copy backend is resolved, copy and exit
if [ -n "$copy_backend" ]; then
  printf "%s" "$buf" | eval "$copy_backend"
  exit;
fi

# If no copy backends were eligible,
# decide to fallback to OSC 52 escape sequences
# Note: Most terminals do not handle OSC!
if [ "$copy_use_osc52_fallback" == "off" ]; then
  exit;
fi

# Copy via OSC 52 ANSI escape sequence to controlling terminal
buflen=$( printf %s "$buf" | wc -c )

# https://sunaku.github.io/tmux-yank-osc52.html
# The maximum length of an OSC 52 escape sequence is 100_000 bytes,
# of which 7 bytes are occupied by a "\033]52;c;" header,
# 1 byte by a "\a" footer,
# and 99_992 bytes by the base64-encoded result of 74_994 bytes of copyable text
maxlen=74994

# Warn if exceeds maxlen
if [ "$buflen" -gt "$maxlen" ]; then
  printf "Input is %d bytes too long!" "$(( buflen - maxlen ))" >&2
fi

# Build up OSC 52 ANSI escape sequence
esc="\033]52;c;$( printf %s "$buf" | head -c $maxlen | base64 | tr -d '\r\n' )\a"
esc="\033Ptmux;\033$esc\033\\"

# Resolve target terminal to send escape sequence
# if we are on remote machine send directly to SSH_TTY
# to transport escape sequence to terminal on local machine,
# so data lands in clipboard on our local machine
pane_active_tty=$(tmux list-panes -F "#{pane_active} #{pane_tty}" | awk '$1=="1" { print $2 }')
target_tty="${SSH_TTY:-$pane_active_tty}"

#
printf "$esc" > "$target_tty"
