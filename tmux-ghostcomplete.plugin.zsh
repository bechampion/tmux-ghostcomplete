# tmux-ghostcomplete.plugin.zsh
# Screen-aware autocomplete using styled tmux popup + gum
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
    local excludefile=$(mktemp)
    local tokensfile=$(mktemp)
    local modefile=$(mktemp)
    
    # Get suffix after last delimiter for the query
    local query="$word"
    if [[ "$word" == *[$delimiters] ]]; then
        query=""
    elif [[ "$word" == *[$delimiters]* ]]; then
        query="${word##*[$delimiters]}"
    fi
    
    # Write current buffer words to exclude file (one per line)
    printf '%s' "$LBUFFER $RBUFFER" | tr ' ' '\n' | grep -v '^$' > "$excludefile"
    
    # Pre-generate tokens
    ~/.local/bin/tmux-ghostcomplete '' "$pane_id" "$excludefile" | grep -v '^$' > "$tokensfile"
    
    # Track which mode was used
    echo "tokens" > "$modefile"
    
    # Create wrapper script that handles both modes with gum
    local wrapper=$(mktemp)
    cat > "$wrapper" << 'WRAPPER'
#!/bin/bash
modefile="$1"
tmpfile="$2"
tokensfile="$3"
query="$4"

mode=$(cat "$modefile")

run_gum() {
    local input_file="$1"
    local prompt="$2"
    local footer="$3"
    local init_value="$4"
    
    local value_arg=""
    [[ -n "$init_value" ]] && value_arg="--value=$init_value"
    
    # gum filter with footer message appended to input
    (cat "$input_file"; echo ""; echo "$footer") | gum filter \
        --header '' \
        --prompt "$prompt" \
        --prompt.foreground '#957FB8' \
        --indicator '▸' \
        --indicator.foreground '#E6C384' \
        --match.foreground '#E6C384' \
        --text.foreground '#DCD7BA' \
        --cursor-text.foreground '#DCD7BA' \
        --cursor-text.background '#2A2A37' \
        --placeholder 'Filter...' \
        --placeholder.foreground '#54546D' \
        --height 12 \
        --no-fuzzy \
        --strict \
        $value_arg
}

while true; do
    mode=$(cat "$modefile")
    
    if [[ "$mode" == "clipboard" ]]; then
        # Clipboard mode
        cliphist list > /tmp/clip_input.tmp
        result=$(run_gum "/tmp/clip_input.tmp" "📋 " "[Tab: tokens]" "")
        rm -f /tmp/clip_input.tmp
        
        if [[ "$result" == "[Tab: tokens]" ]]; then
            echo "tokens" > "$modefile"
            continue
        elif [[ -n "$result" ]]; then
            echo "clipboard" > "$modefile"
            cliphist decode <<< "$result" > "$tmpfile"
            break
        else
            break
        fi
    else
        # Tokens mode
        result=$(run_gum "$tokensfile" "❯ " "[Tab: clipboard]" "$query")
        
        if [[ "$result" == "[Tab: clipboard]" ]]; then
            echo "clipboard" > "$modefile"
            continue
        elif [[ -n "$result" ]]; then
            echo "$result" > "$tmpfile"
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
        "$wrapper '$modefile' '$tmpfile' '$tokensfile' '$query'"
    
    # Read results
    local mode=$(cat "$modefile" 2>/dev/null)
    local selection=$(cat "$tmpfile" 2>/dev/null)
    selection="${selection%%[$'\n\r']*}"
    selection="${selection%"${selection##*[![:space:]]}"}"
    
    rm -f "$tmpfile" "$excludefile" "$tokensfile" "$modefile" "$wrapper"
    
    if [[ -n "$selection" ]]; then
        # Copy to clipboard
        printf '%s' "$selection" | wl-copy 2>/dev/null
        
        # Insert logic
        if [[ "$mode" == "clipboard" ]]; then
            LBUFFER="${LBUFFER}${selection}"
        elif [[ -n "$word" && "$selection" == *"$word"* ]]; then
            LBUFFER="${LBUFFER%$word}$selection"
        elif [[ -n "$query" && "$selection" == "$query"* ]]; then
            LBUFFER="${LBUFFER}${selection#$query}"
        elif [[ -n "$query" && "$selection" == *"$query"* ]]; then
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
