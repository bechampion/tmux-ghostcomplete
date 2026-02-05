# tmux-ghostcomplete.plugin.zsh
# Screen-aware autocomplete using tmux floating popup + fzf
# Triggered with Ctrl+n

_gc_complete() {
    # Ensure we're in tmux
    [[ -z "$TMUX" ]] && return 0
    
    local word="${LBUFFER##* }"
    local pane_id=$(tmux display-message -p '#{pane_id}')
    local tmpfile=$(mktemp)
    local queryfile=$(mktemp)
    
    # Write word to file to avoid escaping issues
    printf '%s' "$word" > "$queryfile"
    
    # Centered popup
    # --no-sort preserves input order, --tiebreak=index keeps order for equal matches
    tmux display-popup -E -B -w 25% -h 40% -x C -y C \
        "~/.local/bin/tmux-ghostcomplete \"\$(cat '$queryfile')\" '$pane_id' | fzf --reverse --no-sort --tiebreak=index --query=\"\$(cat '$queryfile')\" \
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
        
        if [[ -n "$word" ]]; then
            LBUFFER="${LBUFFER%$word}$selection"
        else
            LBUFFER="${LBUFFER}${selection}"
        fi
    fi
    
    zle redisplay
    return 0
}

zle -N _gc_complete
bindkey '^n' _gc_complete
