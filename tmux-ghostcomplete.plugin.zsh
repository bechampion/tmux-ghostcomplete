# tmux-ghostcomplete.plugin.zsh
# Screen-aware autocomplete using tmux floating popup + fzf
# Triggered with Ctrl+n

_gc_complete() {
    [[ -z "$TMUX" ]] && return
    
    local word="${LBUFFER##* }"
    local pane_id=$(tmux display-message -p '#{pane_id}')
    local tmpfile=$(mktemp)
    
    # Centered popup, use sh -c for lighter subshell
    # --no-sort preserves input order, --tiebreak=index keeps order for equal matches
    tmux display-popup -E -B -w 25% -h 40% -x C -y C \
        "sh -c '~/.local/bin/tmux-ghostcomplete \"$word\" \"$pane_id\" | fzf --reverse --no-sort --tiebreak=index --query=\"$word\" \
        --border=rounded \
        --pointer=\"▶\" \
        --prompt=\"󰊠 \" \
        --color=\"hl:#7E9CD8,hl+:#E6C384,fg+:#DCD7BA,bg+:#2A2A37,pointer:#E6C384,prompt:#7E9CD8,border:#3B3B4D\" \
        --highlight-line > \"$tmpfile\"'"
    
    local selection=$(cat "$tmpfile")
    rm -f "$tmpfile"
    
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
}

zle -N _gc_complete
bindkey '^n' _gc_complete
