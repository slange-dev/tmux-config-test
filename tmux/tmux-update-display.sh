#!/usr/bin/env bash
# The problem:
# When you `ssh -X` into a machine and attach to an existing tmux session, the session
# contains the old $DISPLAY env variable. In order the x-server/client to work properly,
# you have to update $DISPLAY after connection. For example, the old $DISPLAY=:0 and
# you need to change to DISPLAY=localhost:10.0 for the ssh session to
# perform x-forwarding properly.
# The solution:
# When attaching to tmux session, update $DISPLAY for each tmux pane in that session
# This is performed by using tmux send-keys to the shell.
# This script handles updating $DISPLAY within vim also

# Check if DISPLAY is set
if [ -z "$DISPLAY" ]; then
    echo "Error: DISPLAY environment variable is not set"
    exit 1
fi

# Update NEW_DISPLAY if it differs from DISPLAY
if [[ "$NEW_DISPLAY" != "$DISPLAY" ]]; then
    NEW_DISPLAY="$DISPLAY"
    #NEW_DISPLAY=$(tmux show-env | sed -n 's/^DISPLAY=//p')
fi

# Check if zsh is installed and has renew_tmux_env function
if command -v zsh >/dev/null 2>&1; then
    HAS_RENEW="$(zsh -ci 'type renew_tmux_env 2>/dev/null | grep -q function && echo "yes"')"
else
    HAS_RENEW=""
fi

# Temporarily disable monitoring
tmux set-option -wg monitor-activity off
tmux set-option -wg monitor-bell off

# Process each pane
tmux list-panes -s -F "#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}" | \
while read -r pane_process; do
    # Split into array
    IFS=' ' read -ra pane_parts <<< "$pane_process"
    pane="${pane_parts[0]}"
    cmd="${pane_parts[1]}"

    case "$cmd" in
        "zsh"|"bash")
            if [[ -n "$HAS_RENEW" ]]; then
                tmux send-keys -t "$pane" "export DISPLAY=$NEW_DISPLAY" Enter
                tmux send-keys -t "$pane" Escape
            else
                tmux send-keys -t "$pane" "export DISPLAY=$NEW_DISPLAY" Enter
            fi
            ;;
        *"python"*)
            tmux send-keys -t "$pane" "import os; os.environ['DISPLAY']=\"$NEW_DISPLAY\"" Enter
            ;;
        *"vi"*|*"vim"*)
            tmux send-keys -t "$pane" Escape
            tmux send-keys -t "$pane" ":let \$DISPLAY = \"$NEW_DISPLAY\"" Enter
            # Only run xrestore for vi (not vim)
            if [[ "$cmd" == *"vi" && "$cmd" != *"vim"* ]]; then
                tmux send-keys -t "$pane" ":silent! xrestore" Enter
            fi
            ;;
    esac
done

# Optional delay (uncomment if needed)
#sleep 30

# Re-enable monitoring
tmux set-option -wg monitor-activity on
tmux set-option -wg monitor-bell on
