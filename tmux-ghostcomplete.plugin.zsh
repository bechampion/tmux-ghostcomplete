# tmux-ghostcomplete.plugin.zsh
# Screen-aware autocomplete using styled tmux popup + fzf
# Ctrl+n: Token completion from visible pane
# Ctrl+f: Simple history search (type text, Enter searches in tmux)
# Tab switches to clipboard history (requires cliphist)
# Ctrl+x opens nvim to edit command

# Store last exit code before it gets overwritten
__gc_last_exit_code=0
__gc_precmd() {
    __gc_last_exit_code=$?
}
precmd_functions+=(__gc_precmd)

# History search function - Ctrl+f
# Simple text input, Enter searches in tmux copy-mode
_gc_history_search() {
    [[ -z "$TMUX" ]] && return 0
    
    local pane_id=$(tmux display-message -p '#{pane_id}')
    local tmpfile=$(mktemp)
    
    # Wrapper with custom key handling (Escape, Ctrl+f, Ctrl+c to close)
    local wrapper=$(mktemp)
    cat > "$wrapper" << WRAPPER
#!/bin/bash
tmpfile="$tmpfile"
prompt=\$'\e[38;2;149;127;184m❯ \e[0m'
printf "%s" "\$prompt"
input=""
while IFS= read -r -n1 -s char; do
    case "\$char" in
        \$'\x1b') exit 0 ;;  # Escape
        \$'\x06') exit 0 ;;  # Ctrl+f
        \$'\x7f'|\$'\x08')   # Backspace
            if [[ -n "\$input" ]]; then
                input="\${input%?}"
                printf '\b \b'
            fi
            ;;
        '')                  # Enter
            echo "\$input" > "\$tmpfile"
            exit 0
            ;;
        *)
            input+="\$char"
            printf '%s' "\$char"
            ;;
    esac
done
WRAPPER
    chmod +x "$wrapper"
    
    tmux display-popup -E -w 20% -h 3 \
        -b rounded \
        -S 'fg=#54546D' \
        -s 'bg=#1F1F28' \
        -T " 📜 History Search " \
        "$wrapper"
    
    local search_term=$(cat "$tmpfile" 2>/dev/null)
    rm -f "$tmpfile" "$wrapper"
    
    # Clean up whitespace
    search_term="${search_term%%[$'\n\r']*}"
    search_term="${search_term%"${search_term##*[![:space:]]}"}"
    
    if [[ -n "$search_term" ]]; then
        # Check if term exists in pane history before searching
        if tmux capture-pane -t "$pane_id" -p -S - | grep -qF "$search_term"; then
            # Set Kanagawa-themed highlight colors
            tmux set-option -p -t "$pane_id" copy-mode-current-match-style "fg=#00FF00,bg=#000000,underscore"
            tmux set-option -p -t "$pane_id" copy-mode-match-style "fg=#E6C384,bg=#2d2d2d"
            tmux copy-mode -t "$pane_id"
            tmux send-keys -t "$pane_id" -X search-backward "$search_term"
        fi
    fi
    
    zle redisplay
    return 0
}

zle -N _gc_history_search
bindkey '^f' _gc_history_search

# Token completion function - Ctrl+n
_gc_complete() {
    # Ensure we're in tmux
    [[ -z "$TMUX" ]] && return 0
    
    # Delimiters that separate "words" within a token
    local delimiters='/:,@()[]="'"'"
    
    local word="${LBUFFER##* }"
    local pane_id=$(tmux display-message -p '#{pane_id}')
    local tmpfile=$(mktemp)
    local queryfile=$(mktemp)
    local excludefile=$(mktemp)
    local modefile=$(mktemp)
    local cmdfile=$(mktemp)
    local titlefile=$(mktemp)
    
    # Get suffix after last delimiter for the query
    local query="$word"
    if [[ "$word" == *[$delimiters] ]]; then
        query=""
    elif [[ "$word" == *[$delimiters]* ]]; then
        query="${word##*[$delimiters]}"
    fi
    
    # Write query to file to avoid escaping issues
    printf '%s' "$query" > "$queryfile"
    
    # Write current buffer words to exclude file (one per line)
    printf '%s' "$LBUFFER $RBUFFER" | tr ' ' '\n' | grep -v '^$' > "$excludefile"
    
    # Determine command to edit:
    # - If prompt has content, use that
    # - If prompt is empty AND last command failed, use last command from history
    local current_cmd="${LBUFFER}${RBUFFER}"
    local editing_last_cmd=0
    
    if [[ -z "$current_cmd" && $__gc_last_exit_code -ne 0 ]]; then
        # Prompt is empty AND last command failed - get the last command from history
        local last_cmd=$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')
        printf '%s' "$last_cmd" > "$cmdfile"
        editing_last_cmd=1
    else
        printf '%s' "$current_cmd" > "$cmdfile"
    fi
    
    # Set title based on whether we're editing last failed command
    if [[ $editing_last_cmd -eq 1 ]]; then
        echo " 👻 GhostComplete " > "$titlefile"
    else
        echo " 👻 GhostComplete " > "$titlefile"
    fi
    
    # Track which mode was used
    echo "tokens" > "$modefile"
    
    # Create wrapper script
    local wrapper=$(mktemp)
    cat > "$wrapper" << WRAPPER
#!/bin/bash
modefile="$modefile"
tmpfile="$tmpfile"
queryfile="$queryfile"
pane_id="$pane_id"
excludefile="$excludefile"
cmdfile="$cmdfile"
editing_last_cmd="$editing_last_cmd"
lbuffer="$LBUFFER"
word="$word"
query="$query"

# Helper script for highlighting - only highlights within visible pane area
highlighter=\$(mktemp)
cat > "\$highlighter" << HLSCRIPT
#!/bin/bash
pane="\\\$1"
term="\\\$2"
[[ -z "\\\$term" ]] && { tmux send-keys -t "\\\$pane" -X cancel 2>/dev/null; exit 0; }


# Only search within VISIBLE pane content (no scrollback)
visible_content=\\\$(tmux capture-pane -t "\\\$pane" -p)
if ! echo "\\\$visible_content" | grep -qF "\\\$term"; then
    tmux send-keys -t "\\\$pane" -X cancel 2>/dev/null
    exit 0
fi

# Set Kanagawa-themed highlight colors before entering copy-mode
# Bright green for current match (underlined), dim yellow for others
tmux set-option -p -t "\\\$pane" copy-mode-current-match-style "fg=#00FF00,bg=#000000,underscore"
tmux set-option -p -t "\\\$pane" copy-mode-match-style "fg=#E6C384,bg=#2d2d2d"

# Enter copy-mode
tmux copy-mode -t "\\\$pane" 2>/dev/null

# Go to bottom of visible area and search backward
# This makes the bottom-most match the "current" one (purple highlight)
tmux send-keys -t "\\\$pane" -X bottom-line
tmux send-keys -t "\\\$pane" -X end-of-line
tmux send-keys -t "\\\$pane" -X search-backward "\\\$term" 2>/dev/null
HLSCRIPT
chmod +x "\$highlighter"

# Cleanup helper
cleanup_search() {
    tmux send-keys -t "\$pane_id" -X cancel 2>/dev/null || true
    rm -f "\$highlighter" 2>/dev/null
}
trap cleanup_search EXIT

while true; do
    mode=\$(cat "\$modefile")
    
    if [[ "\$mode" == "editor" ]]; then
        # Editor mode - open nvim to edit command
        # If editing last failed command, add explanatory comment at top
        if [[ "\$editing_last_cmd" == "1" ]]; then
            # Prepend comment to cmdfile
            original_cmd=\$(cat "\$cmdfile")
            {
                echo "# This command failed (exit code non-zero). Edit and save to retry."
                echo "\$original_cmd"
            } > "\$cmdfile"
        fi
        # Build nvim command - add cursor positioning for failed command editing
        nvim_opts=(-u NONE
            -c "set noswapfile"
            -c "set nobackup"
            -c "set noundofile"
            -c "set laststatus=0"
            -c "set noruler"
            -c "set noshowcmd"
            -c "set shortmess+=F"
            -c "set filetype=sh"
            -c "syntax on"
        )
        if [[ "\$editing_last_cmd" == "1" ]]; then
            nvim_opts+=(-c "2")  # Move cursor to line 2 (the command)
        fi
        nvim "\${nvim_opts[@]}" "\$cmdfile"
        # Remove comment line if still present
        if [[ "\$editing_last_cmd" == "1" ]]; then
            sed -i '1{/^# This command failed/d}' "\$cmdfile"
        fi
        break
    elif [[ "\$mode" == "clipboard" ]]; then
        # Clipboard mode
        result=\$(cliphist list | fzf --exact \\
            --reverse \\
            --no-sort \\
            --print-query \\
            --query="\$(cat "\$queryfile")" \\
            --bind 'tab:become:echo TAB_PRESSED' \\
            --bind 'ctrl-x:become:echo EDITOR_PRESSED; echo {q}; echo {}' \\
            --bind 'esc:abort' \
            --bind 'ctrl-n:abort' \\
            --no-info \\
            --no-separator \\
            --pointer='▸' \\
            --prompt='📋 ' \\
            --with-nth=2.. \\
            --delimiter='\t' \\
            --border=bottom \\
            --border-label='[ Tab: tokens | C-x: edit ]' \\
            --border-label-pos=0:bottom \\
            --color='bg:#1F1F28,fg:#DCD7BA,bg+:#2A2A37,fg+:#DCD7BA,hl:#E6C384,hl+:#E6C384,pointer:#E6C384,prompt:#957FB8,gutter:#1F1F28,border:#54546D,label:#54546D')
        
        first_line=\$(echo "\$result" | head -1)
        if [[ "\$first_line" == "TAB_PRESSED" ]]; then
            echo "tokens" > "\$modefile"
            continue
        elif [[ "\$first_line" == "EDITOR_PRESSED" ]]; then
            # Capture the selected clipboard item (line 3) and decode it for editing
            clip_entry=\$(echo "\$result" | sed -n '3p')
            if [[ -n "\$clip_entry" ]]; then
                selected=\$(cliphist decode <<< "\$clip_entry")
                # Build the full command: replace the word/query with selection
                if [[ -n "\$word" && "\$selected" == *"\$word"* ]]; then
                    full_cmd="\${lbuffer%\$word}\$selected"
                elif [[ -n "\$query" ]]; then
                    full_cmd="\${lbuffer%\$query}\$selected"
                else
                    full_cmd="\${lbuffer}\$selected"
                fi
                echo "\$full_cmd" > "\$cmdfile"
                editing_last_cmd=0
            fi
            echo "editor" > "\$modefile"
            continue
        elif [[ -n "\$result" ]]; then
            echo "clipboard" > "\$modefile"
            clip_selection=\$(echo "\$result" | sed -n '2p')
            if [[ -n "\$clip_selection" ]]; then
                echo "\$result" | head -1 > "\$tmpfile.query"
                cliphist decode <<< "\$clip_selection" > "\$tmpfile"
                cat "\$tmpfile.query" >> "\$tmpfile"
                rm -f "\$tmpfile.query"
            fi
            break
        else
            break
        fi
    else
        # Tokens mode
        label='[ Tab: clipboard | C-x: edit ]'
        
        result=\$(~/.local/bin/tmux-ghostcomplete "\$(cat "\$queryfile")" "\$pane_id" "\$excludefile" | tac | fzf --exact \\
            --reverse \\
            --no-sort \\
            --track \\
            --print-query \\
            --query="\$(cat "\$queryfile")" \\
            --bind 'tab:become:echo TAB_PRESSED' \\
            --bind "focus:execute-silent(\$highlighter \$pane_id {})" \\
            --bind "result:transform:[ \$(echo {} | wc -c) -gt 1 ] && echo execute-silent:\$highlighter\ \$pane_id\ {} || echo execute-silent:tmux\ send-keys\ -t\ \$pane_id\ -X\ cancel" \\
            --bind 'ctrl-x:become:echo EDITOR_PRESSED; echo {q}; echo {}' \\
            --bind 'esc:abort' \
            --bind 'ctrl-n:abort' \\
            --no-info \\
            --no-separator \\
            --pointer='▸' \\
            --prompt='❯ ' \\
            --border=bottom \\
            --border-label="\$label" \\
            --border-label-pos=0:bottom \\
            --color='bg:#1F1F28,fg:#DCD7BA,bg+:#2A2A37,fg+:#DCD7BA,hl:#E6C384,hl+:#E6C384,pointer:#E6C384,prompt:#957FB8,gutter:#1F1F28,border:#54546D,label:#54546D')
        
        first_line=\$(echo "\$result" | head -1)
        if [[ "\$first_line" == "TAB_PRESSED" ]]; then
            echo "clipboard" > "\$modefile"
            continue
        elif [[ "\$first_line" == "EDITOR_PRESSED" ]]; then
            # Capture the selected item (line 3) and build full command with it
            selected=\$(echo "\$result" | sed -n '3p')
            if [[ -n "\$selected" ]]; then
                # Build the full command: replace the word/query with selection
                if [[ -n "\$word" && "\$selected" == *"\$word"* ]]; then
                    # Selection contains the word, replace word with selection
                    full_cmd="\${lbuffer%\$word}\$selected"
                elif [[ -n "\$query" ]]; then
                    # Replace query portion with selection
                    full_cmd="\${lbuffer%\$query}\$selected"
                else
                    # Just append selection
                    full_cmd="\${lbuffer}\$selected"
                fi
                echo "\$full_cmd" > "\$cmdfile"
                editing_last_cmd=0  # Not editing a failed command, editing a selection
            fi
            echo "editor" > "\$modefile"
            continue
        elif [[ -n "\$result" ]]; then
            echo "\$result" > "\$tmpfile"
            break
        else
            break
        fi
    fi
done
WRAPPER
    chmod +x "$wrapper"
    
    # Run in tmux popup with dynamic title
    local popup_title=$(cat "$titlefile")
    tmux display-popup -E -w 35% -h 30% \
        -b rounded \
        -S 'fg=#54546D' \
        -s 'bg=#1F1F28' \
        -T "$popup_title" \
        "$wrapper"
    
    # Read results
    local mode=$(cat "$modefile" 2>/dev/null)
    local final_query selection
    
    if [[ "$mode" == "editor" ]]; then
        # Editor mode - replace entire command line with edited content
        local edited=$(cat "$cmdfile" 2>/dev/null)
        edited="${edited%%[$'\n\r']*}"
        LBUFFER="$edited"
        RBUFFER=""
        rm -f "$tmpfile" "$queryfile" "$excludefile" "$modefile" "$wrapper" "$cmdfile" "$titlefile"
        zle redisplay
        return 0
    elif [[ "$mode" == "clipboard" ]]; then
        # Clipboard: first line is decoded content, second line is final query
        selection=$(sed -n '1p' "$tmpfile" 2>/dev/null)
        final_query=$(sed -n '2p' "$tmpfile" 2>/dev/null)
    else
        # Tokens: first line is final query, second is selection
        final_query=$(sed -n '1p' "$tmpfile" 2>/dev/null)
        selection=$(sed -n '2p' "$tmpfile" 2>/dev/null)
    fi
    
    # Clean up whitespace
    final_query="${final_query%%[$'\n\r']*}"
    final_query="${final_query%"${final_query##*[![:space:]]}"}"
    selection="${selection%%[$'\n\r']*}"
    selection="${selection%"${selection##*[![:space:]]}"}"
    
    rm -f "$tmpfile" "$queryfile" "$excludefile" "$modefile" "$wrapper" "$cmdfile" "$titlefile"
    
    if [[ -n "$selection" ]]; then
        # Copy to clipboard
        printf '%s' "$selection" | wl-copy 2>/dev/null
        
        # Smart insertion logic (same for both modes)
        if [[ -n "$word" && "$selection" == *"$word"* ]]; then
            LBUFFER="${LBUFFER%$word}$selection"
        elif [[ "$final_query" != "$query" ]]; then
            if [[ -n "$query" ]]; then
                LBUFFER="${LBUFFER%$query}$selection"
            else
                LBUFFER="${LBUFFER}${selection}"
            fi
        elif [[ -z "$query" ]]; then
            LBUFFER="${LBUFFER}${selection}"
        elif [[ "$selection" == "$query"* ]]; then
            LBUFFER="${LBUFFER}${selection#$query}"
        elif [[ "$selection" == *"$query"* ]]; then
            LBUFFER="${LBUFFER%$query}$selection"
        else
            LBUFFER="${LBUFFER}${selection}"
        fi
    fi
    
    zle redisplay
    return 0
}

zle -N _gc_complete
bindkey '^n' _gc_complete
