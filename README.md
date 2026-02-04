<div align="center">

# tmux-ghostcomplete

**Screen-aware autocomplete for your terminal**

Complete text from anywhere visible in your tmux pane with a fuzzy finder popup.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell: Zsh](https://img.shields.io/badge/Shell-Zsh-green.svg)](https://www.zsh.org/)
[![tmux](https://img.shields.io/badge/tmux-required-orange.svg)](https://github.com/tmux/tmux)

</div>

---

## Demo

https://github.com/user-attachments/assets/demo.mp4

<video src="assets/demo.mp4" controls width="100%"></video>

https://github.com/jeronimo-garcia1/tmux-ghostcomplete/raw/main/assets/demo.mp4

---

## What is this?

Ever had a long path, URL, or identifier on screen and wished you could just autocomplete it without copy-pasting? **tmux-ghostcomplete** does exactly that.

Press `Ctrl+n` and a fuzzy finder popup appears with all the text tokens visible in your current tmux pane. Start typing to filter, press Enter to insert the selection into your command line.

### Features

- **Screen-aware** - Extracts all visible text from your tmux pane
- **Fuzzy matching** - Uses fzf for fast, fuzzy filtering
- **Floating popup** - Clean, centered popup that doesn't disrupt your workflow
- **Clipboard integration** - Selected text is also copied to your Wayland clipboard
- **Fast** - Optimized with `sh` and single `awk` for minimal latency
- **Kanagawa themed** - Beautiful colors that match the Kanagawa colorscheme (customizable)

## Requirements

- [tmux](https://github.com/tmux/tmux) (with `display-popup` support, v3.2+)
- [fzf](https://github.com/junegunn/fzf)
- [zsh](https://www.zsh.org/)
- [wl-copy](https://github.com/bugaevc/wl-clipboard) (optional, for Wayland clipboard)

## Installation

### Manual

1. Clone the repository:
   ```bash
   git clone https://github.com/jeronimo-garcia1/tmux-ghostcomplete.git ~/.zsh/plugins/tmux-ghostcomplete
   ```

2. Copy the tokenizer script:
   ```bash
   cp ~/.zsh/plugins/tmux-ghostcomplete/bin/tmux-ghostcomplete ~/.local/bin/
   chmod +x ~/.local/bin/tmux-ghostcomplete
   ```

3. Add to your `~/.zshrc`:
   ```bash
   source ~/.zsh/plugins/tmux-ghostcomplete/tmux-ghostcomplete.plugin.zsh
   ```

4. Reload your shell:
   ```bash
   source ~/.zshrc
   ```

### Quick Install

```bash
git clone https://github.com/jeronimo-garcia1/tmux-ghostcomplete.git /tmp/tmux-ghostcomplete
cd /tmp/tmux-ghostcomplete && ./install.sh
```

### Using a Plugin Manager

<details>
<summary><b>zinit</b></summary>

```bash
zinit light jeronimo-garcia1/tmux-ghostcomplete
```
</details>

<details>
<summary><b>zplug</b></summary>

```bash
zplug "jeronimo-garcia1/tmux-ghostcomplete"
```
</details>

<details>
<summary><b>antigen</b></summary>

```bash
antigen bundle jeronimo-garcia1/tmux-ghostcomplete
```
</details>

## Usage

1. Open a tmux session
2. Have some text visible on screen (commands, output, logs, etc.)
3. Press `Ctrl+n`
4. Type to fuzzy filter the tokens
5. Press `Enter` to insert the selection
6. Press `Escape` to cancel

The selected text is also copied to your clipboard (Wayland).

## Configuration

### Key Binding

Change the trigger key by modifying the `bindkey` line in the plugin file:

```bash
# Default: Ctrl+n
bindkey '^n' _gc_complete

# Example: Ctrl+Space
bindkey '^ ' _gc_complete

# Example: Alt+c
bindkey '^[c' _gc_complete
```

### Popup Size and Position

Modify these values in `tmux-ghostcomplete.plugin.zsh`:

```bash
# Width: 25%, Height: 40%, Centered
tmux display-popup -E -B -w 25% -h 40% -x C -y C
```

Options:
- `-w` - Width (percentage or columns)
- `-h` - Height (percentage or rows)
- `-x` - X position (`C` for center, `R` for right, or number)
- `-y` - Y position (`C` for center, `S` for bottom, or number)

### Colors (Kanagawa Theme)

The default colors match the [Kanagawa](https://github.com/rebelot/kanagawa.nvim) colorscheme:

```bash
--color='hl:#7E9CD8,hl+:#E6C384,fg+:#DCD7BA,bg+:#2A2A37,pointer:#E6C384,prompt:#7E9CD8,border:#3B3B4D'
```

| Element | Color | Description |
|---------|-------|-------------|
| `hl` | `#7E9CD8` | Match highlight (crystalBlue) |
| `hl+` | `#E6C384` | Selected match highlight (carpYellow) |
| `fg+` | `#DCD7BA` | Selected line text (fujiWhite) |
| `bg+` | `#2A2A37` | Selected line background (sumiInk4) |
| `pointer` | `#E6C384` | Pointer color (carpYellow) |
| `prompt` | `#7E9CD8` | Prompt color (crystalBlue) |
| `border` | `#3B3B4D` | Border color (sumiInk5) |

### Token Filtering

By default, only tokens longer than 4 characters are shown. Modify in `bin/tmux-ghostcomplete`:

```awk
# Change '> 4' to your preferred minimum length
if (length(w) > 4 && !seen[w]++) {
    print w
}
```

### Disable Clipboard

Remove or comment out this line in the plugin:

```bash
echo -n "$selection" | wl-copy 2>/dev/null
```

For X11, replace with:
```bash
echo -n "$selection" | xclip -selection clipboard 2>/dev/null
```

## How It Works

1. **Capture** - Uses `tmux capture-pane` to get all visible text
2. **Tokenize** - A fast `awk` script extracts words, removing brackets/punctuation
3. **Filter** - `fzf` provides fuzzy matching in a floating popup
4. **Insert** - Selected text replaces the current word in your command line

## Troubleshooting

### Popup doesn't appear
- Make sure you're inside a tmux session
- Check tmux version: `tmux -V` (needs 3.2+)

### No tokens showing
- There might not be any text longer than 4 characters on screen
- Try reducing the minimum token length

### Slow popup
- The script is already optimized, but very large panes might be slower
- Consider reducing scrollback if you have very large buffers

## Related Projects

- [fzf](https://github.com/junegunn/fzf) - The fuzzy finder powering this plugin
- [tmux](https://github.com/tmux/tmux) - Terminal multiplexer
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) - History-based suggestions
- [kanagawa.nvim](https://github.com/rebelot/kanagawa.nvim) - The colorscheme inspiration

## License

MIT License - See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

---

<div align="center">
Made with terminal love
</div>
