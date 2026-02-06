<div align="center">

<img src="assets/logo.png" alt="tmux-ghostcomplete logo" width="400">

# tmux-ghostcomplete

**Screen-aware autocomplete for your terminal**

Complete text from anywhere visible in your tmux pane with a fuzzy finder popup.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell: Zsh](https://img.shields.io/badge/Shell-Zsh-green.svg)](https://www.zsh.org/)
[![tmux](https://img.shields.io/badge/tmux-required-orange.svg)](https://github.com/tmux/tmux)

---

### 🤖 Built entirely with AI

This project was created from scratch through conversation with [Claude](https://www.anthropic.com/claude) using [OpenCode](https://github.com/anomalyco/opencode) - no code was written manually.

---

</div>

## Demo

<!-- Demo GIF -->
![tmux-ghostcomplete demo](assets/demo.gif)


---

## What is this?

Ever had a long path, URL, or identifier on screen and wished you could just autocomplete it without copy-pasting? **tmux-ghostcomplete** does exactly that.

Press `Ctrl+n` and a popup appears with all the text tokens visible in your current tmux pane. Start typing to filter, press Enter to insert the selection into your command line.

### Features

- **Screen-aware** - Extracts all visible text from your tmux pane
- **Exact matching** - Uses fzf with exact substring matching (no fuzzy)
- **Smart completion** - Intelligently handles delimiters to avoid duplication
- **Styled floating popup** - Subtle rounded borders with Kanagawa-themed colors
- **Single Escape to close** - Press Escape once to dismiss the popup
- **Search at top** - Clean, intuitive layout with search input at the top
- **Clipboard integration** - Selected text is also copied to your Wayland clipboard
- **Fast** - Optimized with `sh` and single `awk` for minimal latency
- **Command line editor** - Press Ctrl+x to edit your command in nvim

## Requirements

- [tmux](https://github.com/tmux/tmux) (with `display-popup` support, v3.2+)
- [fzf](https://github.com/junegunn/fzf)
- [zsh](https://www.zsh.org/)
- [wl-copy](https://github.com/bugaevc/wl-clipboard) (optional, for Wayland clipboard)

## Installation

### Manual

1. Clone the repository:
   ```bash
   git clone https://github.com/bechampion/tmux-ghostcomplete.git ~/.zsh/plugins/tmux-ghostcomplete
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
git clone https://github.com/bechampion/tmux-ghostcomplete.git /tmp/tmux-ghostcomplete
cd /tmp/tmux-ghostcomplete && ./install.sh
```

### Using a Plugin Manager

<details>
<summary><b>zinit</b></summary>

```bash
zinit light bechampion/tmux-ghostcomplete
```
</details>

<details>
<summary><b>zplug</b></summary>

```bash
zplug "bechampion/tmux-ghostcomplete"
```
</details>

<details>
<summary><b>antigen</b></summary>

```bash
antigen bundle bechampion/tmux-ghostcomplete
```
</details>

## Usage

1. Open a tmux session
2. Have some text visible on screen (commands, output, logs, etc.)
3. Press `Ctrl+n`
4. Type to filter the tokens (exact matching)
5. Press `Enter` to insert the selection
6. Press `Escape` to cancel (single press!)

The selected text is also copied to your clipboard (Wayland).

---

## Popup Appearance

The popup uses tmux's native styling for a clean, minimal look:

```
╭─ 👻 GhostComplete ────────────────╮
│ ❯ search query                    │
│ ▸ matching-token-1                │
│   matching-token-2                │
│   matching-token-3                │
╰───────────────────────────────────╯
```

### Features

| Element | Description |
|---------|-------------|
| **Rounded border** | Subtle `╭╮╰╯` corners |
| **Dim border color** | `#54546D` - doesn't distract |
| **Dark background** | `#1F1F28` - Kanagawa sumiInk1 |
| **Title in border** | `👻 GhostComplete` |
| **Search at top** | `--reverse` layout |
| **Single Escape** | `--bind 'esc:abort'` |
| **Compact size** | 35% width, 30% height |

---

## Smart Completion Behavior

The plugin intelligently handles text insertion based on delimiters to avoid duplication.


![Smart completion demo](assets/smart-completion-demo.gif)

### Delimiters

The following characters are recognized as delimiters:

```
/ : , @ ( ) [ ] = " '
```

### How It Works

When you press `Ctrl+n`, the plugin looks at what you've typed and:

1. **Extracts the query** - Uses only the text after the last delimiter for filtering
2. **Avoids duplication** - When inserting, strips any overlapping prefix
3. **Query changes** - If you modify the query in the popup, the selection replaces your typed word

### Examples

#### Building URLs

```
# You type:
curl http://

# Popup shows all tokens (no filter since you ended with /)
# You select: 192.168.1.100

# Result:
curl http://192.168.1.100
```

```
# You type:
curl http://192

# Popup filters to tokens containing "192"
# You select: 192.168.1.100

# Result (192 is stripped to avoid duplication):
curl http://192.168.1.100
```

#### Building Paths

```
# You type:
cd /home/user/

# Popup shows all tokens (no filter)
# You select: Projects

# Result:
cd /home/user/Projects
```

```
# You type:
cat /var/log/sys

# Popup filters to tokens containing "sys"
# You select: syslog

# Result:
cat /var/log/syslog
```

#### Email Addresses

```
# You type:
git config user.email user@

# Popup shows all tokens (no filter)
# You select: example.com

# Result:
git config user.email user@example.com
```

#### Simple Completion (No Delimiters)

```
# You type:
kubectl get dep

# Popup filters to tokens containing "dep"
# You select: deployments

# Result:
kubectl get deployments
```

```
# You type (empty):
git clone 

# Popup shows all tokens
# You select: git@github.com:user/repo.git

# Result:
git clone git@github.com:user/repo.git
```

#### Changing Query in Popup

```
# You type:
curl http://192

# Popup opens with "192" as query
# You delete the query and type "example"
# You select: example.com

# Result (replaces the whole word since query changed):
curl example.com
```

```
# You type:
kubectl get serv

# Popup opens with "serv" as query
# You clear query and select: deployments

# Result (replaces "serv" with selection):
kubectl get deployments
```

### Customizing Delimiters

You can modify the delimiter list in `tmux-ghostcomplete.plugin.zsh`:

```zsh
# Default delimiters
local delimiters='/:,@()[]="'"'"

# Add more delimiters (e.g., #, ?, &, -)
local delimiters='/:,@()[]="'"'"'#?&-'
```

---

### Token Exceptions

The tokenizer preserves certain patterns intact instead of splitting them. These are defined in `bin/tmux-ghostcomplete`:

| Exception | Pattern | Example |
|-----------|---------|---------|
| HTTP URLs | `http://...`, `https://...` | `https://github.com/user/repo` |
| Git SSH | `git@...` | `git@github.com:user/repo.git` |
| FTP URLs | `ftp://...` | `ftp://files.example.com/path` |
| File URLs | `file://...` | `file:///home/user/doc.txt` |
| IPv6 addresses | `xxxx:xxxx:...` | `2001:0db8:85a3::8a2e:0370:7334` |

**Adding New Exceptions:**

Edit `bin/tmux-ghostcomplete` and add patterns to the regex:

```awk
# Current pattern (in the while match line):
/https?:\/\/[^ \t\[\]()]+|git@[^ \t\[\]()]+|ftp:\/\/[^ \t\[\]()]+|file:\/\/[^ \t\[\]()]+/

# To add s3:// URLs:
/https?:\/\/[^ \t\[\]()]+|git@[^ \t\[\]()]+|ftp:\/\/[^ \t\[\]()]+|file:\/\/[^ \t\[\]()]+|s3:\/\/[^ \t\[\]()]+/
```

**Potential future exceptions to consider:**

- `s3://bucket/path` - AWS S3 URLs
- `gs://bucket/path` - Google Cloud Storage URLs  
- `docker://image:tag` - Docker image references
- `mailto:user@example.com` - Email links
- `ssh://user@host` - SSH URLs
- `redis://host:port` - Redis connection strings
- `postgres://...` - Database connection strings
- `arn:aws:...` - AWS ARNs
- IP addresses with ports - `192.168.1.1:8080`

To request a new exception, open an issue on GitHub!

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
# Default: 35% width, 30% height, centered
tmux display-popup -E -w 35% -h 30% \
    -b rounded \
    -S 'fg=#54546D' \
    -s 'bg=#1F1F28' \
    -T ' 👻 GhostComplete '
```

Options:
- `-w` - Width (percentage or columns)
- `-h` - Height (percentage or rows)
- `-b` - Border style: `single`, `rounded`, `double`, `heavy`, `none`
- `-S` - Border style (fg/bg colors)
- `-s` - Content style (fg/bg colors)
- `-T` - Title displayed in border

### Colors (Kanagawa Theme)

The popup uses tmux border styling + fzf colors that match [Kanagawa](https://github.com/rebelot/kanagawa.nvim):

**tmux popup:**
```bash
-S 'fg=#54546D'      # Border color (sumiInk6 - dim)
-s 'bg=#1F1F28'      # Background (sumiInk1 - dark)
```

**fzf colors:**
```bash
--color='bg:#1F1F28,fg:#DCD7BA,bg+:#2A2A37,fg+:#DCD7BA,hl:#E6C384,hl+:#E6C384,pointer:#E6C384,prompt:#957FB8,gutter:#1F1F28'
```

| Element | Color | Description |
|---------|-------|-------------|
| `bg` | `#1F1F28` | Background (sumiInk1) |
| `fg` | `#DCD7BA` | Default text (fujiWhite) |
| `bg+` | `#2A2A37` | Selected line background (sumiInk4) |
| `fg+` | `#DCD7BA` | Selected line text (fujiWhite) |
| `hl` | `#E6C384` | Match highlight (carpYellow) |
| `hl+` | `#E6C384` | Selected match highlight (carpYellow) |
| `pointer` | `#E6C384` | Pointer color (carpYellow) |
| `prompt` | `#957FB8` | Prompt color (oniViolet) |
| `gutter` | `#1F1F28` | Gutter background (sumiInk1) |

---

## The Tokenizer

The tokenizer (`bin/tmux-ghostcomplete`) is responsible for extracting meaningful text from your terminal. It's written in POSIX `sh` with a single `awk` process for maximum performance.

### How It Works

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  tmux capture   │────▶│   awk process   │────▶│  unique tokens  │
│  (visible pane) │     │  (tokenize)     │     │  (to fzf)       │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

1. **Capture**: `tmux capture-pane -p` grabs all visible text from the current pane
2. **Clean**: Removes brackets `[]`, parentheses `()`, colons `:`, and quotes `"`
3. **Split**: Breaks text into whitespace-separated words
4. **Filter**: Only keeps tokens longer than 4 characters
5. **Dedupe**: Uses awk's associative array to output each unique token once

### Source Code

```sh
#!/bin/sh
target_pane="$2"

if [ -n "$target_pane" ]; then
    tmux capture-pane -t "$target_pane" -p
else
    tmux capture-pane -p
fi | awk '
{
    # Replace brackets, parens, colons, quotes with spaces
    gsub(/[\[\]():"]/, " ")
    # Split into words
    n = split($0, words)
    for (i = 1; i <= n; i++) {
        w = words[i]
        # Only output tokens > 4 chars, deduplicated
        if (length(w) > 4 && !seen[w]++) {
            print w
        }
    }
}'
```

### Customization

#### Minimum Token Length

Change `> 4` to your preferred minimum:

```awk
# Show tokens with 2+ characters
if (length(w) > 1 && !seen[w]++) {

# Show tokens with 8+ characters  
if (length(w) > 7 && !seen[w]++) {
```

#### Additional Characters to Strip

Add more characters to the `gsub` pattern:

```awk
# Also remove angle brackets, semicolons, commas
gsub(/[\[\]():"<>;,]/, " ")
```

#### Keep Certain Patterns Intact

To preserve URLs or paths, you could modify the tokenizer:

```awk
# Don't split on colons for URLs
gsub(/[\[\]()"]/, " ")
```

#### Performance

The tokenizer is optimized for speed:
- Uses `/bin/sh` instead of bash/zsh (faster shell startup)
- Single `awk` process (no pipes between sed, tr, grep, sort)
- Deduplication happens in-memory during processing
- No temporary files

On a typical terminal with ~50-100 lines visible, tokenization completes in **<10ms**.

---
---
## Clipboard History Integration

GhostComplete integrates with [cliphist](https://github.com/sentriz/cliphist) to access your clipboard history directly from the popup.

### How it works

While in the GhostComplete popup:

| Key | Action |
|-----|--------|
| `Tab` | Toggle between **tokens** and **clipboard history** |
| `Ctrl+x` | Open **nvim** to edit the command line |
| `Enter` | Select and insert |
| `Escape` | Close popup |

### Modes

**Tokens mode** (default):
```
╭─ 👻 GhostComplete ────────────────╮
│ ❯ search query                    │
│ ▸ token-from-screen               │
│ ────────────────────────────────  │
│ [ Tab: clipboard | C-x: edit ]    │
╰───────────────────────────────────╯
```

**Clipboard mode** (after pressing Tab):
```
╭─ 👻 GhostComplete ────────────────╮
│ 📋 search query                   │
│ ▸ clipboard-entry-1               │
│ ────────────────────────────────  │
│ [ Tab: tokens | C-x: edit ]       │
╰───────────────────────────────────╯
```

### Requirements

Clipboard history requires [cliphist](https://github.com/sentriz/cliphist):

<details>
<summary><b>Arch Linux</b></summary>

```bash
pacman -S cliphist
```
</details>

<details>
<summary><b>From source (Go)</b></summary>

```bash
go install go.senan.xyz/cliphist@latest
```
</details>

### Setting up cliphist

cliphist needs to be running to capture clipboard history. Add this to your Sway/Hyprland config:

**Sway:**
```bash
exec wl-paste --type text --watch cliphist store
exec wl-paste --type image --watch cliphist store
```

**Hyprland:**
```bash
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
```

---

## Command Line Editor

Press `Ctrl+x` while in the GhostComplete popup to open your current command line in **nvim** for editing.

### How it works

1. Press `Ctrl+n` to open GhostComplete
2. Press `Ctrl+x` to switch to editor mode
3. nvim opens with your current command line
4. Edit the command as needed
5. Save and quit (`:wq`) to apply changes
6. The edited command replaces your command line

### Example

```
# You have this complex command:
$ kubectl get pods -n production | grep -E "api|web" | awk '{print $1}'

# Press Ctrl+n, then Ctrl+x
# nvim opens with the command
# Edit it freely with full vim motions
# :wq to save and return to shell
```

### nvim Configuration

The editor opens with a minimal configuration:
- No swap files
- No backup files
- No undo files
- No status line (clean look)

This keeps the popup fast and avoids cluttering your filesystem.

### Use Cases

- **Complex pipelines** - Edit long commands with multiple pipes
- **Fix typos** - Use vim motions to quickly fix errors
- **Restructure commands** - Rearrange arguments and flags
- **Multi-cursor editing** - Use vim macros for repetitive edits

---

## Troubleshooting

### Popup doesn't appear
- Make sure you're inside a tmux session
- Check tmux version: `tmux -V` (needs 3.2+)

### No tokens showing
- There might not be any text longer than 4 characters on screen
- Try reducing the minimum token length

### Escape key causes issues
If pressing Escape causes your shell to enter vi command mode or ring a bell, add this to your `~/.zshrc`:

```zsh
bindkey '^[' redisplay
```

This makes Escape do nothing (just redraws the prompt) while preserving Alt+key combinations.

### Slow popup
- The script is already optimized, but very large panes might be slower
- Consider reducing scrollback if you have very large buffers

## Related Projects

- [fzf](https://github.com/junegunn/fzf) - The fuzzy finder powering this plugin
- [cliphist](https://github.com/sentriz/cliphist) - Clipboard history manager
- [tmux](https://github.com/tmux/tmux) - Terminal multiplexer
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) - History-based suggestions
- [kanagawa.nvim](https://github.com/rebelot/kanagawa.nvim) - The colorscheme inspiration

## License

MIT License - See [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

---

## Disclaimer

> **Note**: This project was created entirely through conversation with [Claude](https://www.anthropic.com/claude) (Anthropic's AI assistant) using [OpenCode](https://github.com/anomalyco/opencode). The author prompted and directed the development but did not write the code directly. Use at your own risk - the author assumes no responsibility for any issues, damages, or unexpected behavior that may arise from using this software.

---

<div align="center">
Made with AI-assisted terminal love 🤖
<br><br>
<a href="https://github.com/anomalyco/opencode"><img src="https://img.shields.io/badge/Built%20with-OpenCode-blue?style=for-the-badge" alt="Built with OpenCode"></a>
<a href="https://www.anthropic.com/claude"><img src="https://img.shields.io/badge/Powered%20by-Claude-orange?style=for-the-badge" alt="Powered by Claude"></a>
</div>
