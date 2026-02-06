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

while true; do
    mode=\$(cat "\$modefile")
    
    if [[ "\$mode" == "clipboard" ]]; then
        # Clipboard mode
        result=\$(cliphist list | fzf --exact \\
            --reverse \\
            --no-sort \\
            --print-query \\
            --query="\$(cat "\$queryfile")" \\
            --bind 'tab:become:echo TAB_PRESSED' \\
            --bind 'esc:abort' \\
            --no-info \\
            --no-separator \\
            --pointer='▸' \\
            --prompt='📋 ' \\
            --border=bottom \\
            --border-label='[ Tab: tokens ]' \\
            --border-label-pos=0:bottom \\
            --color='bg:#1F1F28,fg:#DCD7BA,bg+:#2A2A37,fg+:#DCD7BA,hl:#E6C384,hl+:#E6C384,pointer:#E6C384,prompt:#957FB8,gutter:#1F1F28,border:#54546D,label:#54546D')
        
        if [[ "\$result" == "TAB_PRESSED" ]]; then
            echo "tokens" > "\$modefile"
            continue
        elif [[ -n "\$result" ]]; then
            echo "clipboard" > "\$modefile"
            # First line is query, second is selection - decode the selection
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
        result=\$(~/.local/bin/tmux-ghostcomplete "\$(cat "\$queryfile")" "\$pane_id" "\$excludefile" | fzf --exact \\
            --reverse \\
            --no-sort \\
            --track \\
            --print-query \\
            --query="\$(cat "\$queryfile")" \\
            --bind 'tab:become:echo TAB_PRESSED' \\
            --bind 'esc:abort' \\
            --no-info \\
            --no-separator \\
            --pointer='▸' \\
            --prompt='❯ ' \\
            --border=bottom \\
            --border-label='[ Tab: clipboard ]' \\
            --border-label-pos=0:bottom \\
            --color='bg:#1F1F28,fg:#DCD7BA,bg+:#2A2A37,fg+:#DCD7BA,hl:#E6C384,hl+:#E6C384,pointer:#E6C384,prompt:#957FB8,gutter:#1F1F28,border:#54546D,label:#54546D')
        
        if [[ "\$result" == "TAB_PRESSED" ]]; then
            echo "clipboard" > "\$modefile"
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
    
    # Run in tmux popup
    tmux display-popup -E -w 35% -h 30% \
        -b rounded \
        -S 'fg=#54546D' \
        -s 'bg=#1F1F28' \
        -T ' 👻 GhostComplete ' \
        "$wrapper"
    
    # Read results
    local mode=$(cat "$modefile" 2>/dev/null)
    local final_query selection
    
    if [[ "$mode" == "clipboard" ]]; then
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
    
    rm -f "$tmpfile" "$queryfile" "$excludefile" "$modefile" "$wrapper"
    
    if [[ -n "$selection" ]]; then
        # Copy to clipboard
        printf '%s' "$selection" | wl-copy 2>/dev/null
        
        # Smart insertion logic (same for both modes)
        if [[ -n "$word" && "$selection" == *"$word"* ]]; then
            # Selection contains what we typed - replace whole word
            LBUFFER="${LBUFFER%$word}$selection"
        elif [[ "$final_query" != "$query" ]]; then
            # Query was changed in popup
            if [[ -n "$query" ]]; then
                LBUFFER="${LBUFFER%$query}$selection"
            else
                LBUFFER="${LBUFFER}${selection}"
            fi
        elif [[ -z "$query" ]]; then
            # No query, just append
            LBUFFER="${LBUFFER}${selection}"
        elif [[ "$selection" == "$query"* ]]; then
            # Selection starts with query - strip prefix
            LBUFFER="${LBUFFER}${selection#$query}"
        elif [[ "$selection" == *"$query"* ]]; then
            # Query in middle of selection - replace query
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
