#!/usr/bin/env bash
###########################
### Start TMUX function ###
###########################
#
function start_tmux() {
    # Create sessionname
    local sessionName="$USER"

    # Check for existing Tmux session for the User by user name
    # If there is one: attach the existing one
    # If there is none: create a new one and then attach it
    if [[ "$(command tmux ls | grep -o "$sessionName")" == "$sessionName" ]]; then
		# Session found and attach for the user
		command tmux attach-session -t "$sessionName"
    else 
        # If it wasn't a session for the user then start a default(new)
        command tmux new-session -s "$sessionName" -d

        # Session template for user root
        if [[ "$sessionName" == root ]]; then

        # Template config for root
        . ~/.tmux/.tmux.template.conf
        fi

            # Check if term is set to use 256 colours
            if [ $TERM == '*256color' ]; then
				# Force tmux to using 256 colours
				command tmux -2 -u attach-session -d
            else
				# Force tmux to using 88 colours
				force using 88 colours
				command tmux -8 -u attach-session -d
            fi
    fi
}
