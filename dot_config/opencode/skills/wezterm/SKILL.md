---
name: wezterm
description: Interact with an ALREADY-RUNNING WezTerm GUI session by sending text to and reading from its existing panes. Use ONLY when the user explicitly asks you to drive a command inside a WezTerm window they have open (e.g. "run this in wezterm"). Do NOT use for ordinary command execution, reading output, or monitoring processes — the agent's own bash tool covers those. If WezTerm is not running, do not use this skill.
tags:
  - terminal
  - wezterm
---

# WezTerm Terminal Control

Interact with existing WezTerm panes via the CLI. WezTerm must be running and on PATH.

---

## Preconditions — check before anything else

This skill applies ONLY when a WezTerm GUI instance is already running.

1. Verify: `wezterm cli list --format json` — fails or returns nothing if WezTerm isn't running.
2. If WezTerm is not running, STOP. Do not launch it, do not use `wezterm start`. Ordinary commands belong in your own bash tool.
3. Never reach for this skill just because you need to run a command, read terminal output, or watch a process.

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
