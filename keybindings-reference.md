# 🔥 Randy's Terminal Setup Reference

## 🚀 Neovim Keybindings

```
<Space>                - Leader key                 | <leader>sf             - Search files
<C-h/j/k/l>            - Move windows              | <S-h/l>                - Buffer prev/next
grn                    - Rename                    | grd                    - Go to definition
grr                    - Find references           | gra                    - Code actions
<leader>f              - Format code               | <C-y>                  - Accept completion
<Tab>/<S-Tab>          - Snippet navigation        | <C-space>              - Open completion
<leader>e              - Toggle file explorer      | <leader>x              - Close buffer
<leader>qs             - Restore session           | <leader>ql             - Last session
<leader>sg             - Live grep                 | <leader>sh             - Search help
gO                     - Document symbols          | gW                     - Workspace symbols
<leader>th             - Toggle hints              | <leader>q              - Diagnostics
<Esc>                  - Clear search              | <leader>ef             - Find in explorer
```

## 🖥️ Tmux Keybindings

```
<C-Space>              - Prefix                    | <prefix>s              - Split horizontal
<prefix>v              - Split vertical            | <M-h/j/k/l>            - Move panes
<prefix>n              - New window                | <prefix>h/l            - Window prev/next
<prefix>k              - Copy mode                 | v → y                  - Select → Copy
<C-l>                  - Clear screen              | <prefix>e              - File explorer
<prefix>f              - Find file                 | <prefix>r              - Reload config
<prefix>S              - Choose session            | <prefix>!              - New session
<prefix>X              - Kill session              | <prefix>H/J/K/L        - Resize panes
```

## 💻 Bash Aliases & Functions

```
ls                     - ls -la --color            | ..                     - cd ..
...                    - cd ../..                  | ....                   - cd ../../..
gs                     - git status                | ga                     - git add
gc                     - git commit                | gp                     - git push
gl                     - git log --oneline         | gb                     - git branch
gco                    - git checkout              | gd                     - git diff
rm/cp/mv               - Safe with -i              | mkdir                  - mkdir -pv
tree                   - tree -C                   | df/du/free             - Human readable -h
cat → bat              - Syntax highlighting       | find → fd              - Faster find
grep → rg              - Ripgrep                   | top → htop             - Better process view
extract <file>         - Extract any archive       | mkcd <dir>             - Make and cd
killp <proc>           - Kill by name              | serve [port]           - HTTP server
now/nowdate            - Current time/date         | path                   - Show PATH nicely
```

## 🎨 Theme & Status

**Theme:** Atom One Dark Pro  
**Prompt:** `[green_user:blue_host]:(gray_git):/purple_dir $`  
**Tmux Status:** 📁 path | 🔥 CPU | 🧠 RAM | ⚡ load | 🕐 time | 📅 date

---
*Auto-generated reference - Last updated: $(date '+%Y-%m-%d %H:%M')*