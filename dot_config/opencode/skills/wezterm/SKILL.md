---
name: wezterm
description: Control and inspect WezTerm terminal panes. Use when terminal interaction, command execution, reading terminal output, monitoring running processes, or working with existing shell sessions is required.
tags:
  - terminal
  - shell
  - wezterm
  - development
---

# WezTerm Terminal Control

Interact with existing WezTerm panes via the CLI. WezTerm must be running and on PATH.

---

## Workflow

**Always read before acting. Always read after acting.**

1. List panes to find the right target
2. Read pane contents to confirm state
3. Send command
4. Read again to verify output

---

## List Panes

```bash
wezterm cli list --format json
```

Returns `pane_id`, `tab_id`, `window_id`, `title`, and current working directory. Run this first unless a pane ID is already known.

**Pane selection priority:**

1. Working directory matches the target repo
2. Title references the current project
3. Interactive shell prompt is visible

---

## Read a Pane

```bash
wezterm cli get-text --pane-id <PANE_ID>
```

Use to inspect output, check for running processes, confirm command completion, or locate errors.

---

## Send a Command

```bash
wezterm cli send-text --pane-id <PANE_ID> --no-paste "<COMMAND>\r"
```

`\r` executes the command. Omitting it inserts text without running it.

---

## Create a New Pane

```bash
wezterm cli split-pane --right    # horizontal split
wezterm cli split-pane --bottom   # vertical split
```

Returns the new pane ID. Prefer reusing existing panes.

---

## Focus a Pane

```bash
wezterm cli activate-pane --pane-id <PANE_ID>
```

---

## Monitoring Long-Running Commands

Poll until completion is observed in output — do not assume success.

```bash
wezterm cli send-text --pane-id <PANE_ID> --no-paste "npm test\r"
sleep 2
wezterm cli get-text --pane-id <PANE_ID>
# repeat until done
```

---

## Caution

Inspect state before running destructive commands:

```
rm -rf  |  git clean -fdx  |  git reset --hard
docker system prune  |  terraform destroy  |  kubectl delete  |  drop database
```

Never assume these are safe. Read first.
