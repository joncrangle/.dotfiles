# Wez's Terminal

<img height="128" alt="WezTerm Icon" src="https://raw.githubusercontent.com/wez/wezterm/main/assets/icon/wezterm-icon.svg" align="left"> *A GPU-accelerated cross-platform terminal emulator and multiplexer written by <a href="https://github.com/wez">@wez</a> and implemented in <a href="https://www.rust-lang.org/">Rust</a>*

User facing docs and guide at: <https://wezfurlong.org/wezterm/>

![Screenshot](https://raw.githubusercontent.com/wez/wezterm/main/docs/screenshots/two.png)

*Screenshot of wezterm on macOS, running vim*

## Install Wezterm Nightly

### Mac

Use [Homebrew](https://brew.sh/) to install Wezterm.

```bash
brew tap homebrew/cask-versions
brew install --cask wezterm-nightly
```

Upgrade

```bash
brew upgrade --cask wezterm-nightly --no-quarantine --greedy-latest
```

### Windows

Use [Scoop](https://scoop.sh/) to install Wezterm.

```powershell
scoop bucket add versions
scoop install wezterm-nightly
```
