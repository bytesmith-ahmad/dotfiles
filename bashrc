
############################
#    MY MODIFIED BASHRC    #
############################

# default values
#----------------------------------------------
THIS_SCRIPT=$(readlink -f "${BASH_SOURCE[0]}")
LOGS="${LOGS:-$HOME/logs}"
LOGFILE="$LOGS/bashrc.log"
ENV="$HOME/.env"
#----------------------------------------------

# The entire bashrc script is summarized here in main()
main() {
    run_default
    check_logs_dir_exists
    read_env              2>>"$LOGFILE"
    read_aliases          2>>"$LOGFILE"
    load_functions        2>>"$LOGFILE"
    read_PATH             2>>"$LOGFILE"
    run_startup_script    2>>"$LOGFILE"
    update_repos          2>>"$LOGFILE" # TODO:
    echo -e "\033[1;32mSuccess:\033[0m \033[1mScript\033[0m \033[33m${THIS_SCRIPT}\033[0m \033[1mcompleted.\033[0m \033[3mSee results in:\033[0m \033[33m${LOGFILE}\033[0m\n"
}

check_logs_dir_exists() {
    # Check if the directory exists
    if [ ! -d "$LOGS" ]; then
        # Directory does not exist, so create it
        mkdir -p "$LOGS"
        echo "Created directory: $LOGS" > "$LOGFILE"
    else
        # Directory exists
        echo "LOGS ARE STORED IN: $LOGS" > "$LOGFILE"
    fi
    
    return "$?"
}

read_env() {

    # Check if the .env file exists
    if [ ! -f "$ENV" ]; then
        echo "Warning: file $ENV does not exist. Create or link one in $HOME." # | tee -a /dev/stderr
		exit 99
    fi
    
    # Read the .env file line by line
    while IFS= read -r line; do
        # Ignore empty lines
        if [[ -n "$line" ]]; then
            # Remove comments (everything after a #)
            line=$(echo "$line" | sed 's/#.*//')

            # Trim leading and trailing whitespace
            line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

            # Skip empty lines after trimming
            if [[ -n "$line" ]]; then
                # Export environment variables
                # Use `eval` to ensure correct handling of quotes and special characters
                eval export "$line"
                >&2 echo "$line"
            fi
        fi
    done < "$ENV"
    
    return "$?"
}

read_aliases() {
	# check if env variable is defined
	if [ -z "$SHELL_ALIASES" ]; then
		echo -e "Warning: variable SHELL_ALIASES is not defined." | tee -a /dev/stderr
		return 1
	fi

    # Check if the file defined exists
    if [ ! -f "$SHELL_ALIASES" ]; then
        echo "Error: file $SHELL_ALIASES (\$SHELL_ALIASES) does not exist. Edit $ENV" | tee -a /dev/stderr
		return 2
    fi

    # past this line, SHELL_ALIASES is defined and real

    # Create a temporary file to store alias commands
    local temp_file=$(mktemp)

    # Read the file line by line
    while IFS= read -r line; do
        # Ignore empty lines and comments
        if [[ -n "$line" && ! "$line" =~ ^# ]]; then
            # Remove comments (everything after a #)
            line=$(echo "$line" | sed 's/#.*//')

            # Trim leading and trailing whitespace
            line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

            # Skip empty lines after trimming
            if [[ -n "$line" ]]; then
                # Prepend 'alias ' to each line and write to the temp file
                echo "alias $line" >> "$temp_file"
            fi
        fi
    done < "$SHELL_ALIASES"

    # Source the temp file to set aliases in the current shell
    # Note: This will only work if the function is run in the current shell session
    >&2 cat "$temp_file"
    source "$temp_file"

    # Clean up
    rm "$temp_file"
    
    return "$?"
}

read_PATH() {
	# check if env variable is defined
	if [ -z "$SHELL_XPATH" ]; then
		echo -e "Warning: variable SHELL_XPATH is not defined." | tee -a /dev/stderr
		return 1
	fi

    # Check if the file defined exists
    if [ ! -f "$SHELL_XPATH" ]; then
        echo "Error: file $SHELL_XPATH (\$SHELL_XPATH) does not exist. Edit $ENV" | tee -a /dev/stderr
		return 2
    fi

    # past this line, SHELL_XPATH is defined and real
    
    # Read the file, concatenate paths with ':' separator, and store in a variable
    EXTENDED_PATH=$(tr '\n' ':' < "$SHELL_XPATH" | sed 's/:$//')

    # Update the $PATH environment variable
    export PATH="$EXTENDED_PATH:$PATH"
    >&2 echo "Updated PATH: $PATH"
    
    return "$?"
}

load_functions() {
	# check if env variable is defined
	if [ -z "$SHELL_FUNCTIONS" ]; then
		echo -e "Warning: variable SHELL_FUNCTIONS is not defined." | tee -a /dev/stderr
		return 1
	fi

    # Check if the file defined exists
    if [ ! -f "$SHELL_FUNCTIONS" ]; then
        echo "Error: file $SHELL_FUNCTIONS (\$SHELL_FUNCTIONS) does not exist. Edit $ENV" | tee -a /dev/stderr
		return 2
    fi

 	source "$SHELL_FUNCTIONS" >&2 echo "loaded functions"
 	return "$?"
}

run_startup_script() {
    if [ -n "$STARTUP_SCRIPT" ]; then
        source "$STARTUP_SCRIPT"
        >&2 echo $?
    else
        >&2 echo "No startup script detected."
    fi
}

# default bashrc on debian
run_default() {

  # If not running interactively, don't do anything
  [[ $- != *i* ]] && return

  # don't put duplicate lines or lines starting with space in the history.
  # See bash(1) for more options
  HISTCONTROL=ignoreboth

  # append to the history file, don't overwrite it
  shopt -s histappend

  # IMPORTANT, this allows aliases to propagate from current shell to subshell
  shopt -s expand_aliases
  
  # for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
  HISTSIZE=1000
  HISTFILESIZE=2000

  # check the window size after each command and, if necessary,
  # update the values of LINES and COLUMNS.
  shopt -s checkwinsize

  # set a fancy prompt (non-color, unless we know we "want" color)
  case "$TERM" in
      xterm-color|*-256color) color_prompt=yes;;
  esac

  # uncomment for a colored prompt, if the terminal has the capability
  force_color_prompt=yes

  if [ -n "$force_color_prompt" ]; then
      if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    # We have color support; assume it's compliant with Ecma-48
    # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
    # a case would tend to support setf rather than setaf.)
    color_prompt=yes
      else
    color_prompt=
      fi
  fi
  unset color_prompt force_color_prompt

  # enable color support of ls and also add handy aliases
  if [ -x /usr/bin/dircolors ]; then
      test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
      alias ls='ls --color=auto'
      #alias dir='dir --color=auto'
      #alias vdir='vdir --color=auto'

      #alias grep='grep --color=auto'
      #alias fgrep='fgrep --color=auto'
      #alias egrep='egrep --color=auto'
  fi

  # enable programmable completion features (you don't need to enable
  # this, if it's already enabled in /etc/bash.bashrc and /etc/profile
  # sources /etc/bash.bashrc).
  if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
      . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
      . /etc/bash_completion
    fi
  fi
}

main
