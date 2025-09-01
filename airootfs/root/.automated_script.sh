#!/usr/bin/env bash

script_cmdline() {
    local param
    for param in $(</proc/cmdline); do
        case "${param}" in
            script=*)
                echo "${param#*=}"
                return 0
                ;;
        esac
    done
}

automated_script() {
	wget -qO- https://raw.githubusercontent.com/Coding4Hours/dotfiles/refs/heads/main/install.sh | bash
}

if [[ $(tty) == "/dev/tty1" ]]; then
    automated_script
fi
