# 🧭 Keymapping

## ✏️ Neovim

| **Function**                                                                                         | **Shortcut**                                             |
| ---------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| **Cursor Movement**                                                                                  |                                                          |
| Arrow Keys                                                                                           | `h`, `j`, `k`, `l`                                       |
| Next / Previous Word                                                                                 | `w`, `b`                                                 |
| Next / Previous End of Word                                                                          | `e`, `ge`                                                |
| Move Forward / Backward to Character                                                                 | `f[char]`, `F[char]`                                     |
| Start / End of Line                                                                                  | `0`, `$`                                                 |
| First Non-Blank Character of Line                                                                    | `_`, or `^`                                              |
| Move Down / Up Half a Page                                                                           | `Ctrl` + `d` / `u`                                       |
| Next / Previous Blank Line                                                                           | `}`, `{`                                                 |
| Top / Bottom of File                                                                                 | `gg`, `G`                                                |
| Goto Line                                                                                            | `:[num]<cr>`                                             |
| Goto Definition, Reference, Implementation                                                           | `gd`, `gr`, `gI`                                         |
| LSP Hover Documentation                                                                              | `K`                                                      |
| Scroll LSP Hover Documentation                                                                       | `<Ctrl` + `f` / `b`                                      |
| **Editing**                                                                                          |                                                          |
| Undo / Undo Tree                                                                                     | `u` / `<leader>u`                                        |
| Redo                                                                                                 | `Ctrl` + `r`                                             |
| Insert Mode At / After Cursor                                                                        | `i`, `a`                                                 |
| Insert Mode at Beginning / End of Line                                                               | `I`, `A`                                                 |
| Insert Blank Line After / Above                                                                      | `o`, `O`                                                 |
| Delete Current Character                                                                             | `x`                                                      |
| Delete / Delete into Void Register                                                                   | `d`, `<leader>d`                                         |
| Delete Line / Delete Line into Void Register                                                         | `dd`, `<leader>dd`                                       |
| Delete then Start Insert Mode                                                                        | `c`                                                      |
| Delete Line then Start Insert Mode                                                                   | `cc`                                                     |
| Change...                                                                                            | `c` + `[char]`                                           |
| Surrounding...                                                                                       | `s` + `[char]`                                           |
| Yank / Yank into Void Register                                                                       | `y`, `<leader>y`                                         |
| Yank Line / Yank Line into Void Register                                                             | `yy`, `<leader>yy`                                       |
| Paste After / Before Cursor                                                                          | `p`, `P`                                                 |
| Replace Current Word                                                                                 | `<leader>rw`                                             |
| Rename using LSP                                                                                     | `<leader>rn`                                             |
| Replace All Old with New within Buffer (with confirmations)                                          | `:%s/old/new/g` (+`c`)                                   |
| In Visual Mode, Move Highlighted Text Up / Down                                                      | `J`, `K`                                                 |
| **Searching, Git, File Tree, Splits and Windows**                                                    |                                                          |
| Search Within Current Buffer / Search Backwards                                                      | `/[query]`, `?[query]`                                   |
| Repeat Search in Same / Opposite Direction                                                           | `n`, `N`                                                 |
| Search Files, Recent Files, Open Files, Grep, Diagnostics, Help, Keymaps, Neovim Files, Zoxide, etc. | `<leader>s` + `f`, `.`, `/`, `g`, `d`, `h`, `k`, `z` `n` |
| Add Buffer to Harpoon                                                                                | `<leader>a`                                              |
| Open Harpoon Quick Menu                                                                              | `<leader>h`                                              |
| Harpoon Quick Navigate                                                                               | `<leader>` + `1`, `2`, `3`, `4`, `5`                     |
| Open in `oil.nvim`                                                                                   | `\`                                                      |
| Open in `neo-tree.nvim`                                                                              | `<leader>` + `-`                                         |
| Open, Split Windows...                                                                               | `Ctrl` + `w` + `[char]`                                  |
| Close Split                                                                                          | `Ctrl` + `w` +`q`                                        |
| Navigate Splits                                                                                      | `Ctrl` + `h`, `j`, `k`, `l`                              |
| Diagnostic Messages / Quickfix / Trouble                                                             | `<leader>` + `e` / `q` / `x`                             |
| Previous / Next Tab Page                                                                             | `Shift + Tab` / `Tab`                                    |
| Close Tab                                                                                            | `Ctrl` + `q`                                             |

![neovim](./assets/nvim.png)

## 🔎 fzf

| **Function**           | **Shortcut**                          |
| ---------------------- | ------------------------------------- |
| Search Files           | `Ctrl` + `t` and type the search term |
| Search Command History | `Ctrl` + `r` and type the search term |
| Search Directories     | `Alt` + `c` and type the search term  |
| Trigger Fuzzy Find     | `**` + `Tab` and type the search term |

## 💻 Wezterm

```bash
# Display key bindings
wezterm show-keys
```

```bash
# Connect to NAS
wezterm connect tnas
```

| **Function**                          | **Modifier**      |                 | **Key**                                                                      |
| ------------------------------------- | ----------------- | --------------- | ---------------------------------------------------------------------------- |
|                                       | **Windows**       | **Mac**         |                                                                              |
| Toggle Full Screen                    | `Alt`             | `Alt`           | `Enter`                                                                      |
| Scroll Up / Down                      | `Ctrl` + `Shift`  | `⌘` + `Shift`   | `k` / `j`                                                                    |
| Font Size Increase / Decrease / Reset | `Ctrl` + `Shift`  | `Super`         | `+` / `-` /  `0`                                                             |
| **Sessions**                          |                   |                 |                                                                              |
| Save Session                          | `Ctrl` + `Shift`  | `⌘` + `Shift`   | `s`                                                                          |
| Restore Session                       | `Ctrl` + `Shift`  | `⌘` + `Shift`   | `o`                                                                          |
| **Workspaces**                        |                   |                 |                                                                              |
| Switch Workspace                      | `Alt`             | `Alt`           | `s`                                                                          |
| **Splitting**                         |                   |                 |                                                                              |
| Smart Split                           | `Ctrl` + `Shift`  | `⌘` + `Shift`   | `Enter`                                                                      |
| Split Vertically                      | `Ctrl` + `Shift`  | `⌘` + `Shift`   | `\|`                                                                         |
| Split Horizontally                    | `Ctrl` + `Shift`  | `⌘` + `Shift`   | `_`                                                                          |
| Close Split                           | `Ctrl` or `Alt`   | `Ctrl` or `Alt` | `Bac kspace`                                                                 |
| Activate Left / Down / Up / Right     | `Ctrl`            | `Ctrl`          | `h`, `j` / `k` / `l`                                                         |
| Resize Left / Down / Up / Right       | `Alt`             | `Alt`           | `h`, `j` / `k` / `l` or<br>`LeftArrow`, `DownArrow`, `UpArrow`, `RightArrow` |
| Zoom (Maximize) Pane                  | `Alt`             | `Alt`           | `m`                                                                          |
| Rotate Panes                          | `Ctrl` + `Shift`  | `⌘` + `Shift`   | `r`                                                                          |
| **Tabs**                              |                   |                 |                                                                              |
| New Tab                               | `Ctrl` + `Shift`  | `⌘`             | `t`                                                                          |
| Close Tab                             | `Ctrl` + `Shift`  | `⌘`             | `w`                                                                          |
| Select Tab                            | `Ctrl`            | `Ctrl`          | `#`                                                                          |
| Tab Previous / Tab Next               | `Ctrl` + `Shift`  | `⌘` + `Shift`   | `h` / `l`                                                                    |
| Move Tab Left / Right                 | `Ctrl` + `Shift`  | `⌘` + `Shift`   | `<` / `>`                                                                    |
| **Clipboard**                         |                   |                 |                                                                              |
| Copy                                  | `Ctrl` + `Shift`  | `⌘`             | `c`                                                                          |
| Paste                                 | `Ctrl` + `Shift`  | `⌘`             | `v`                                                                          |
| Quick Select                          | `Ctrl` + `Shift`  | `⌘` + `Shift`   | `:`                                                                          |
| Copy Mode                             | `Ctrl` + `Shift`  | `⌘` + `Shift`   | `x`                                                                          |
| Search                                | `Ctrl` + `Shift`  | `⌘` + `Shift`   | `f`                                                                          |
| Command Palette                       | `Ctrl` + `Shift`v | `⌘` + `Shift`   | `p`                                                                          |
| Debug Overlay                         | `Ctrl` + `Shift`  | `⌘` + `Shift`   | `d`                                                                          |

## 🦆 Yazi

| **Function**                                               | **Shortcut**                        |
| ---------------------------------------------------------  | ----------------------------------- |
| **Navigation**                                             |                                     |
| Navigation with Vim keybinds                               | e.g. `h`, `j`, `k`, `l` and motions |
| **Selection**                                              |                                     |
| Toggle selection of hovered file/directory                 | `Space`                             |
| Enter visual mode / visual unset mode                      | `v` / `V`                           |
| Select all files                                           | `Ctrl` + `a`                        |
| Inverse selection of all files                             | `Ctrl` + `r`                        |
| Cancel selection                                           | `Esc`                               |
| **File/directory operations**                              |                                     |
| Open the selected files                                    | `o` or `Enter`                      |
| Open the selected files interactively                      | `O` or `Ctrl` + `Enter`             |
| Yank the selected files (copy)                             | `y`                                 |
| Yank the selected files (cut)                              | `x`                                 |
| Paste the yanked files                                     | `p`                                 |
| Paste the yanked files (overwrite if destination exists)   | `P`                                 |
| Cancel the yank state (unyank)                             | `Y` or `X`                          |
| Create a symbolic link to the yanked files (absolute path) | `-`                                 |
| Create a symbolic link to the yanked files (relative path) | `_`                                 |
| Move the files to the trash                                | `d`                                 |
| Permanently delete the files                               | `D`                                 |
| Create a file or directory (ends with "/" for directories) | `a`                                 |
| Rename a file or directory                                 | `r`                                 |
| Run a shell command                                        | `;`                                 |
| Run a shell command (block UI until command finishes)      | `:`                                 |
| Toggle the visibility of hidden files                      | `.`                                 |
| Jump to a directory using zoxide                           | `z`                                 |
| Jump to a directory, or reveal a file using fzf            | `Z`                                 |
| **Copying paths**                                          |                                     |
| Copy absolute path                                         | `c` + `c`                           |
| Copy absolute path of the parent directory                 | `c` + `d`                           |
| Copy the name of a file                                    | `c` + `f`                           |
| Copy the name of a file without extension                  | `c` + `n`                           |
| **Filtering/searching files/directories**                  |                                     |
| Filter the files/directories in CWD                        | `f`                                 |
| Forward find file/directory in CWD                         | `/`                                 |
| Backward find file/directory in CWD                        | `?`                                 |
| Jump to next occurence                                     | `n`                                 |
| Jump to previous occurence                                 | `N`                                 |
| Search files by name using fd                              | `s`                                 |
| Search files by name using fzf                             | `S`                                 |
| Cancel the ongoing search                                  | `Ctrl` + `s`                        |
| **Sorting**                                                |                                     |
| Sort by modified time                                      | `,` + `m`                           |
| Sort by modified time (reverse)                            | `,` + `M`                           |
| Sort by creation time                                      | `,` + `c`                           |
| Sort by creation time (reverse)                            | `,` + `C`                           |
| Sort by extension                                          | `,` + `e`                           |
| Sort by extension (reverse)                                | `,` + `E`                           |
| Sort alphabetically                                        | `,` + `a`                           |
| Sort alphabetically (reverse)                              | `,` + `A`                           |
| Sort naturally                                             | `,` + `n`                           |
| Sort naturally (reverse)                                   | `,` + `N`                           |
| Sort by size                                               | `,` + `s`                           |
| Sort by size (reverse)                                     | `,` + `S`                           |

## 🪁 Yabai and Skhd

| **Function**                                 | **Shortcut**                                  |
| -------------------------------------------  | --------------------------------------------- |
| Activate Left / Down / Up / Right            | `Ctrl` + `h`, `j`, `k`, `l`                   |
| Switch to Workspace 1 / 2 / 3 / 4 / 5        | `⌘` + `1` / `2` / `3` / `4` / `5`             |
| Move Window to Workspace 1 / 2 / 3 / 4 / 5   | `Shift` + `Alt` + `1` / `2` / `3` / `4` / `5` |
| Toggle Full Screen                           | `Alt` + `Enter`                               |
| Rotate Clockwise                             | `Shift` + `Alt` + `r`                         |
| Mirror x / y Axis                            | `Shift` + `Alt` + `x` / `y`                   |
| Toggle Float                                 | `Shift` + `Alt` + `Space`                     |
| Rebalance Workspace                          | `Alt` + `e`                                   |
| Resize Left / Down / Up / Right              | `Alt` + `h`, `j`, `k`, `l`                    |
| Swap Left / Down / Up / Right                | `Shift` + `Alt` + `h`, `j`, `k`, `l`          |
| Move Window and Tile with Existing Workspace | `Ctrl` + `Alt` + `h`, `j`, `k`, `l`           |
| Stop Yabai Service                           | `Ctrl` + `Alt` + `q`                          |
| Start Yabai Service                          | `Ctrl` + `Alt` + `s`                          |
| Restart Yabai Service                        | `Ctrl` + `Alt` + `r`                          |
| Launch WezTerm                               | `⌘` + `Enter`                                 |
| Launch Arc                                   | `⌘` + `Shift` + `Enter`                       |

## 🔷 GlazeWM

| **Function**                                 | **Shortcut**                                  |
| -------------------------------------------  | --------------------------------------------- |
| Activate Left / Down / Up / Right            | `Alt` + `h`, `j`, `k`, `l`                    |
| Switch to Workspace 1 - 9                    | `Alt` + `1 - 9`                               |
| Move Window to Workspace 1 - 9               | `Alt` + `Shift` + `1 - 9`                     |
| Move Workspace to Left / Right               | `Alt` + `a`, `f`                              |
| Toggle Full Screen                           | `Alt` + `x`                                   |
| Change toggle direction                      | `Alt` + `v`                                   |
| Focus recent workspace                       | `Alt` + `y`                                   |
| Toggle Float                                 | `Alt` + `Shift` + `Space`                     |
| Close Window                                 | `Alt` + `Shift` + `q`                         |
| Minimize Window                              | `Alt` + `Shift` + `m`                         |
| Resize: Left / Down / Up / Right             | `Alt` + `r`, then `h`, `j`, `k`, `l`          |
| Swap Left / Down / Up / Right                | `Alt` + `Shift` + `h`, `j`, `k`, `l`          |
| Stop GlazeWM                                 | `Alt` + `Shift` + `e`                         |
| Restart GlazeWM                              | `Alt` + `Shift` + `r`                         |
| Launch WezTerm                               | `Alt` + `Enter`                               |
| Launch Chrome                                | `Alt` + `Shift` + `Enter`                     |

## 💧 Hyprland

| **Function**                                | **Shortcut**                           |
| ------------------------------------------- | ---------------------------------------|
| **Applications**                            |                                        |
| Launch terminal                             | `Super` + `Return`                     |
| Launch browser                              | `Super` + `b`                          |
| Launch Thunar file manager                  | `Super` + `e`                          |
| Launch Yazi file manager                    | `Super` + `y`                          |
| Launch color picker                         | `Super` + `Shift` + `c`                |
| **Workspaces / Windows**                    |                                        |
| Switch to Workspace 1 - 9                   | `Super` + `1 - 9`                      |
| Move Window to Workspace 1 - 9              | `Super` + `Shift` + `1 - 9`            |
| Move Workspace to Left / Down / Up / Right  | `Super` + `Shift` + `h`, `j`, `k`, `l` |
| Kill active window                          | `Super` + `q`                          |
| Set active window to fullscreen             | `Super` + `f`                          |
| Toggle floating                             | `Super` + `Shift` + `t`                |
| Toggle split                                | `Super` + `s`                          |
| Toggle window group                         | `Super` + `g`                          |
| Tab between windows in group                | `Super` + `Tab`                        |
| Resize                                      | `Alt` + `r`, then `h`, `j`, `k`, `l`   |
| **Actions**                                 |                                        |
| Logout                                      | `Super` + `Ctrl` + `q`                 |
| Lock screen                                 | `Super` + `Ctrl` + `l`                 |
| Open notification center                    | `Super` + `Shift` + `n`                |
| Open application launcher                   | `Super` + `Space`                      |
| Open emoji picker                           | `Super` + `;`                          |
| Show keybindings                            | `Super` + `/`                          |
| Reload Hyprland config                      | `Super` + `Shift` + `r`                |
| Reload Waybar config                        | `Super` + `Shift` + `b`                |
| Smart paste                                 | `Super` + `Shift` + `v`                |
| Screenshot                                  | `Print`                                |
| Capture Window / Capture Region             | `Super` + `Print` / `Shift` + `Print`  |
