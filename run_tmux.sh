#!/usr/bin/env bash

###########################
### Start TMUX function ###
###########################

function start_tmux() {
    # Create sessionname
    local sessionName="$USER"

    # Check for existing Tmux session for the User by user name
    # If there is one: attach the existing one
    # If there is none: create a new one and then attach it
    if tmux has-session -t "$sessionName" 2>/dev/null; then
        # Session found and attach for the user
        echo "Attaching to existing tmux session: $sessionName"
        tmux attach-session -t "$sessionName"
    else
        # If it wasn't a session for the user, start a new one
        echo "Starting new tmux session: $sessionName"
        tmux new-session -s "$sessionName" -d

        # Session template for user root
        if [[ "$sessionName" == "root" ]]; then
            # Check if tmux template file exists
            if [[ -f "$HOME/.tmux/.tmux.template.conf" ]]; then
                echo "Loading tmux configuration for root"
                . "$HOME/.tmux/.tmux.template.conf"
            else
                echo "Template configuration not found for root"
            fi
        fi

        # Check if TERM is set to use 256 colours
        if [[ "$TERM" =~ 256color ]]; then
            # Force tmux to use 256 colours
            echo "Using 256 colors in tmux"
            tmux -2 attach-session -t "$sessionName"
        else
            # Force tmux to use 88 colours
            echo "Using 88 colors in tmux"
            tmux -8 attach-session -t "$sessionName"
        fi
    fi
}

# Call the function
start_tmux
