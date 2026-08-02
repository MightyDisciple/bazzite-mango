# Restore MightyDisciple's personal configuration from GitHub
[group("MightyDisciple")]
restore-dotfiles:
    #!/usr/bin/bash
    set -euo pipefail

    if [[ "${EUID}" -eq 0 ]]; then
        echo "Run this command as your normal user, without sudo." >&2
        exit 1
    fi

    dotfiles_dir="$HOME/git/dotfiles"
    https_repo="https://github.com/MightyDisciple/dotfiles.git"
    ssh_repo="git@github.com:MightyDisciple/dotfiles.git"

    if [[ -d "$dotfiles_dir/.git" ]]; then
        echo "Updating existing dotfiles checkout..."
        git -C "$dotfiles_dir" pull --ff-only
    elif [[ -e "$dotfiles_dir" ]]; then
        echo "$dotfiles_dir already exists but is not a Git repository." >&2
        echo "Move or remove that directory and run this command again." >&2
        exit 1
    else
        mkdir -p "$(dirname -- "$dotfiles_dir")"
        echo "Downloading dotfiles..."
        if ! GIT_TERMINAL_PROMPT=0 git clone "$https_repo" "$dotfiles_dir"; then
            echo "HTTPS failed; trying your configured GitHub SSH key..."
            git clone "$ssh_repo" "$dotfiles_dir"
        fi
    fi

    "$dotfiles_dir/install.sh"

    echo
    echo "Dotfiles restored. The legacy Noctalia v4 config was intentionally skipped."
