# tmux-ghostcomplete.plugin.zsh
# Screen-aware autocomplete using styled tmux popup + fzf
# Triggered with Ctrl+n
# Tab switches to clipboard history (requires cliphist)

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
    
    # Get suffix after last delimiter for the fzf query
    # If word ends with delimiter, query is empty
    local query="$word"
    if [[ "$word" == *[$delimiters] ]]; then
        # Ends with delimiter - no query
        query=""
    elif [[ "$word" == *[$delimiters]* ]]; then
        # Has delimiter - use part after last delimiter
        query="${word##*[$delimiters]}"
    fi
    
    # Write query to file to avoid escaping issues
    printf '%s' "$query" > "$queryfile"
    
    # Write current buffer words to exclude file (one per line)
    printf '%s' "$LBUFFER $RBUFFER" | tr ' ' '\n' | grep -v '^$' > "$excludefile"
    
    # Track which mode was used (tokens or clipboard)
    echo "tokens" > "$modefile"
    
    # Create a wrapper script that handles both modes
    local wrapper=$(mktemp)
    cat > "$wrapper" << WRAPPER
#!/bin/bash
modefile="$modefile"
tmpfile="$tmpfile"
queryfile="$queryfile"
pane_id="$pane_id"
excludefile="$excludefile"

mode=\$(cat "\$modefile")

if [[ "\$mode" == "clipboard" ]]; then
    # Clipboard mode
    cliphist list | fzf --exact \\
        --reverse \\
        --no-sort \\
        --bind 'tab:abort' \\
        --bind 'esc:abort' \\
        --no-info \\
        --no-separator \\
        --pointer='▸' \\
        --prompt='📋 ' \\
        --header='[Tab: back to tokens]' \\
        --header-first \\
        --color='bg:#1F1F28,fg:#DCD7BA,bg+:#2A2A37,fg+:#DCD7BA,hl:#E6C384,hl+:#E6C384,pointer:#E6C384,prompt:#957FB8,gutter:#1F1F28,header:#54546D' \\
        > "\$tmpfile" 2>/dev/null
    
    exitcode=\$?
    
    # If Tab was pressed (exit 130), switch back to tokens mode
    if [[ \$exitcode -eq 130 ]]; then
        echo "tokens" > "\$modefile"
        exec "\$0"
    fi
    
    # Decode the cliphist selection
    if [[ -s "\$tmpfile" ]]; then
        selected=\$(cat "\$tmpfile")
        echo "clipboard" > "\$modefile"
        cliphist decode <<< "\$selected" > "\$tmpfile"
    fi
else
    # Tokens mode (default)
    ~/.local/bin/tmux-ghostcomplete "\$(cat "\$queryfile")" "\$pane_id" "\$excludefile" | fzf --exact \\
        --reverse \\
        --no-sort \\
        --track \\
        --print-query \\
        --query="\$(cat "\$queryfile")" \\
        --bind 'tab:abort' \\
        --bind 'esc:abort' \\
        --no-info \\
        --no-separator \\
        --pointer='▸' \\
        --prompt='❯ ' \\
        --header='[Tab: clipboard]' \\
        --header-first \\
        --color='bg:#1F1F28,fg:#DCD7BA,bg+:#2A2A37,fg+:#DCD7BA,hl:#E6C384,hl+:#E6C384,pointer:#E6C384,prompt:#957FB8,gutter:#1F1F28,header:#54546D' \\
        > "\$tmpfile" 2>/dev/null
    
    exitcode=\$?
    
    # If Tab was pressed (exit 130), switch to clipboard mode
    if [[ \$exitcode -eq 130 ]]; then
        echo "clipboard" > "\$modefile"
        exec "\$0"
    fi
fi
WRAPPER
    chmod +x "$wrapper"
    
    # Styled tmux popup
    tmux display-popup -E -w 35% -h 30% \
        -b rounded \
        -S 'fg=#54546D' \
        -s 'bg=#1F1F28' \
        -T ' 👻 GhostComplete ' \
        "$wrapper"
    
    # Read the mode and result
    local mode=$(cat "$modefile" 2>/dev/null)
    local final_query selection
    
    if [[ "$mode" == "clipboard" ]]; then
        # Clipboard mode - entire file is the selection (already decoded)
        selection=$(cat "$tmpfile" 2>/dev/null)
        selection="${selection%%[$'\n\r']*}"
        selection="${selection%"${selection##*[![:space:]]}"}"
        final_query=""
    else
        # Tokens mode - first line is query, second is selection
        final_query=$(sed -n '1p' "$tmpfile" 2>/dev/null)
        selection=$(sed -n '2p' "$tmpfile" 2>/dev/null)
        final_query="${final_query%%[$'\n\r']*}"
        final_query="${final_query%"${final_query##*[![:space:]]}"}"
        selection="${selection%%[$'\n\r']*}"
        selection="${selection%"${selection##*[![:space:]]}"}"
    fi
    
    rm -f "$tmpfile" "$queryfile" "$excludefile" "$modefile" "$wrapper"
    
    if [[ -n "$selection" ]]; then
        # Copy to wayland clipboard
        printf '%s' "$selection" | wl-copy 2>/dev/null
        
        # If from clipboard mode, just append
        if [[ "$mode" == "clipboard" ]]; then
            LBUFFER="${LBUFFER}${selection}"
        # If selection contains what we typed, replace the whole word
        elif [[ -n "$word" && "$selection" == *"$word"* ]]; then
            LBUFFER="${LBUFFER%$word}$selection"
        # If user changed the query (deleted/modified it), replace just the query part
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
