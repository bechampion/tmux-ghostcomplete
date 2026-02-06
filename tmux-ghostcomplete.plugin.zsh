# tmux-ghostcomplete.plugin.zsh
# Screen-aware autocomplete using styled tmux popup + fzf
# Triggered with Ctrl+n

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
    
    # Styled tmux popup with fzf
    # -b rounded = subtle rounded border
    # -S = border style (dim gray)
    # -s = popup content style (dark background)
    # -T = title in border
    # --reverse = search at top
    # --bind 'esc:abort' = single Escape to close
    tmux display-popup -E -w 35% -h 30% \
        -b rounded \
        -S 'fg=#54546D' \
        -s 'bg=#1F1F28' \
        -T ' 👻 GhostComplete ' \
        "~/.local/bin/tmux-ghostcomplete \"\$(cat '$queryfile')\" '$pane_id' '$excludefile' | fzf --exact \
            --reverse \
            --no-sort \
            --track \
            --print-query \
            --query=\"\$(cat '$queryfile')\" \
            --bind 'esc:abort' \
            --no-info \
            --no-separator \
            --pointer='▸' \
            --prompt='❯ ' \
            --color='bg:#1F1F28,fg:#DCD7BA,bg+:#2A2A37,fg+:#DCD7BA,hl:#E6C384,hl+:#E6C384,pointer:#E6C384,prompt:#957FB8,gutter:#1F1F28' \
            > '$tmpfile' 2>/dev/null; true"
    
    # First line is final query, second line is selection
    # Strip any newlines/carriage returns to prevent accidental execution
    local final_query=$(sed -n '1p' "$tmpfile" 2>/dev/null | tr -d '\n\r')
    local selection=$(sed -n '2p' "$tmpfile" 2>/dev/null | tr -d '\n\r')
    rm -f "$tmpfile" "$queryfile" "$excludefile"
    
    if [[ -n "$selection" ]]; then
        # Copy to wayland clipboard
        printf '%s' "$selection" | wl-copy 2>/dev/null
        
        # If selection contains what we typed, replace the whole word
        # (e.g., typed "http://" and selected "https://example.com" which contains "http")
        if [[ -n "$word" && "$selection" == *"$word"* ]]; then
            LBUFFER="${LBUFFER%$word}$selection"
        # If user changed the query (deleted/modified it), replace just the query part
        elif [[ "$final_query" != "$query" ]]; then
            # Query was changed - replace just the query (suffix), keep prefix
            if [[ -n "$query" ]]; then
                # Had a query, replace it
                LBUFFER="${LBUFFER%$query}$selection"
            else
                # No query (ended with delimiter), just append
                LBUFFER="${LBUFFER}${selection}"
            fi
        # Original query logic
        elif [[ -z "$query" ]]; then
            # No query, just append
            LBUFFER="${LBUFFER}${selection}"
        elif [[ "$selection" == "$query"* ]]; then
            # Selection starts with query - strip prefix and append
            LBUFFER="${LBUFFER}${selection#$query}"
        elif [[ "$selection" == *"$query"* ]]; then
            # Query is in the middle of selection - replace query with full selection
            LBUFFER="${LBUFFER%$query}$selection"
        else
            # No match, just append
            LBUFFER="${LBUFFER}${selection}"
        fi
    fi
    
    zle redisplay
    return 0
}

zle -N _gc_complete
bindkey '^n' _gc_complete
