# tmux-ghostcomplete.plugin.zsh
# Screen-aware autocomplete using tmux floating popup + fzf
# Triggered with Ctrl+n

_gc_complete() {
    # Ensure we're in tmux
    [[ -z "$TMUX" ]] && return 0
    
    # Delimiters that separate "words" within a token
    local delimiters='/:,@()[]='
    
    local word="${LBUFFER##* }"
    local pane_id=$(tmux display-message -p '#{pane_id}')
    local tmpfile=$(mktemp)
    local queryfile=$(mktemp)
    
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
    
    # Centered popup
    # --print-query outputs the final query on first line, selection on second
    tmux display-popup -E -B -w 25% -h 40% -x C -y C \
        "~/.local/bin/tmux-ghostcomplete \"\$(cat '$queryfile')\" '$pane_id' | fzf --exact --reverse --no-sort --track --print-query --query=\"\$(cat '$queryfile')\" \
        --border=rounded \
        --border-label='󰊠 GhostComplete' \
        --border-label-pos=0 \
        --pointer='▶' \
        --prompt='󰓾 ' \
        --color='hl:#7E9CD8,hl+:#E6C384,fg+:#DCD7BA,bg+:#2A2A37,pointer:#E6C384,prompt:#7E9CD8,border:#3B3B4D,label:#7E9CD8' \
        --highlight-line > '$tmpfile' 2>/dev/null; true"
    
    # First line is final query, second line is selection
    local final_query=$(sed -n '1p' "$tmpfile" 2>/dev/null)
    local selection=$(sed -n '2p' "$tmpfile" 2>/dev/null)
    rm -f "$tmpfile" "$queryfile"
    
    if [[ -n "$selection" ]]; then
        # Copy to wayland clipboard
        echo -n "$selection" | wl-copy 2>/dev/null
        
        # If user changed the query (deleted/modified it), replace the whole word
        if [[ "$final_query" != "$query" ]]; then
            # Query was changed - replace the whole word
            if [[ -n "$word" ]]; then
                LBUFFER="${LBUFFER%$word}$selection"
            else
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
