if status is-interactive
	/home/linuxbrew/.linuxbrew/bin/fastfetch -l /home/idiom/Pictures/boxOS.jpg 
        export EDITOR="vim"
# Commands to run in interactive sessions can go here
end
set fish_greeting

alias update='ujust update && brew update && brew upgrade'

alias packinstall-arch='distrobox enter Arch -- sudo pacman -S'
alias packremove-arch='distrobox enter Arch -- sudo pacman -Rs'

alias packinstall-ubuntu='distrobox enter a -- sudo apt install'
alias packremove-ubuntu='distrobox enter a -- sudo apt remove'

function box-ship
    # 1. Get Flatpak results from 'bxg'
    set flatpaks (flatpak remote-ls bxg --columns=name,application | awk -F'\t' '{print $1 " (Flatpak: " $2 ")"}' 2>/dev/null)

    # 2. Get Homebrew results
    if test -z "$argv"
        set brews (printf "%s (Brew)\n" (brew formulae) 2>/dev/null)
    else
        set brews (brew search $argv 2>&1 | grep -v "Error: No formulae or casks found..." | awk '{print $1 " (Brew)"}' 2>/dev/null)
    end

    # Define the dynamic fzf preview command
    set preview_cmd '
        if echo {} | grep -q "Flatpak:"; then
            id=$(echo {} | awk -F"Flatpak: " "{print \$2}" | tr -d ")");
            flatpak remote-info bxg "$id" 2>/dev/null || echo "No info available for $id";
        else
            id=$(echo {} | awk "{print \$1}");
            brew info "$id" 2>/dev/null || echo "No info available for $id";
        fi
    '

    # 3. Combine and send to fzf
    if test -n "$argv"
        set selection (printf "%s\n" $flatpaks $brews | grep -Fi "$argv" | fzf \
            -m \
            --header "Install from bxg or Brew (Tab to multi-select):" \
            --height 60% \
            --layout=reverse \
            --preview $preview_cmd \
            --preview-window=right:60%:wrap)
    else
        set selection (printf "%s\n" $flatpaks $brews | fzf \
            -m \
            --header "Browse all packages (Tab to multi-select):" \
            --height 60% \
            --layout=reverse \
            --preview $preview_cmd \
            --preview-window=right:60%:wrap)
    end

    # 4. Process selections
    if test -n "$selection"
        echo -e "\nYou have selected the following packages to INSTALL:"
        for item in $selection
            test -z "$item"; and continue
            echo "  - $item"
        end

        # Single confirmation check
        # -n 1 returns immediately after typing 1 character without needing Enter
        read -l -n 1 -P "Proceed with installation? [y/N]: " confirm
        echo "" # Moves to a clean new line right away

        if string match -ri '^(y|yes)$' "$confirm"
            for item in $selection
                test -z "$item"; and continue

                if string match -q "*Flatpak: *" "$item"
                    set app_id (echo "$item" | awk -F'Flatpak: ' '{print $2}' | tr -d '()' | awk '{print $1}')
                    echo "--> Installing Flatpak: $app_id..."
                    flatpak install -y bxg -- $app_id
                else
                    set brew_id (echo "$item" | awk '{print $1}')
                    echo "--> Installing Brew package: $brew_id..."
                    brew install -- $brew_id
                end
            end
        else
            echo "Installation cancelled."
        end
    else
        echo "No package selected."
    end
end


function box-return
    # 1. List installed items
    set flatpaks (flatpak list --app --columns=name,application,origin | awk -F'\t' '{print $1 " (Flatpak: " $2 ")"}' 2>/dev/null)
    set brews (brew list -1 | awk '{print $1 " (Brew)"}' 2>/dev/null)

    # 2. Combine and Filter with grep before sending to fzf
    set selection (printf "%s\n" $flatpaks $brews | grep -Fi "$argv" | fzf \
        -m \
        --header "Select packages to UNINSTALL & CLEAN (Tab to multi-select):" \
        --height 40% \
        --layout=reverse)

    # 3. Process selections
    if test -n "$selection"
        echo -e "\nYou have selected the following packages to UNINSTALL:"
        for item in $selection
            test -z "$item"; and continue
            echo "  - $item"
        end

        # Single confirmation check
        # -n 1 returns immediately after typing 1 character without needing Enter
        read -l -n 1 -P "Are you absolutely sure you want to uninstall these? [y/N]: " confirm
        echo "" # Moves to a clean new line right away

        if string match -ri '^(y|yes)$' "$confirm"
            for item in $selection
                test -z "$item"; and continue

                if string match -q "*Flatpak: *" "$item"
                    set app_id (echo "$item" | awk -F'Flatpak: ' '{print $2}' | tr -d '()' | awk '{print $1}')
                    echo "--> Uninstalling Flatpak: $app_id..."
                    flatpak uninstall -y --delete-data -- $app_id
                else
                    set brew_id (echo "$item" | awk '{print $1}')
                    echo "--> Uninstalling Brew package: $brew_id..."
                    brew uninstall -- $brew_id
                end
            end

            # Post-uninstall cleanup step runs once at the very end
            echo "--> Running post-uninstall system cleanup..."
            flatpak uninstall --unused -y 2>/dev/null
            brew autoremove 2>/dev/null
            echo "--> System cleanup complete!"
        else
            echo "Uninstallation cancelled."
        end
    else
        echo "No matching package selected."
    end
end

eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
