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
    # --no-sort keeps input order, --tiebreak=index preserves order for equal scores
    # --track keeps selected item in view while filtering
    # --exact disables fuzzy matching
    tmux display-popup -E -B -w 25% -h 40% -x C -y C \
        "~/.local/bin/tmux-ghostcomplete \"\$(cat '$queryfile')\" '$pane_id' | fzf --exact --reverse --no-sort --track --query=\"\$(cat '$queryfile')\" \
        --border=rounded \
        --border-label='󰊠 GhostComplete' \
        --border-label-pos=0 \
        --pointer='▶' \
        --prompt='󰓾 ' \
        --color='hl:#7E9CD8,hl+:#E6C384,fg+:#DCD7BA,bg+:#2A2A37,pointer:#E6C384,prompt:#7E9CD8,border:#3B3B4D,label:#7E9CD8' \
        --highlight-line > '$tmpfile' 2>/dev/null; true"
    
    local selection=$(cat "$tmpfile" 2>/dev/null)
    rm -f "$tmpfile" "$queryfile"
    
    if [[ -n "$selection" ]]; then
        # Copy to wayland clipboard
        echo -n "$selection" | wl-copy 2>/dev/null
        
        # Determine how to insert the selection:
        # 1. If selection starts with query -> strip query prefix and append
        # 2. If query is in the middle of selection -> replace the query with full selection
        # 3. Otherwise -> just append
        
        if [[ -z "$query" ]]; then
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
