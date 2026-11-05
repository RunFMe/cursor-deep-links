---
name: creating-cursor-deep-links
description: Build clickable Cursor deep links (cursor://...) that open a file or folder in the user's Cursor, either on the machine Cursor runs on or over Remote-SSH on a remote host. Use whenever you give the user a link or "open this in Cursor/VS Code" pointer to a file, folder or line, and whenever you would otherwise write a vscode-remote://, vscode:// or cursor:// URL by hand.
---

# Creating Cursor deep links

The user clicks these links on the machine where Cursor runs. For a remote file, Cursor connects through that machine's `~/.ssh/config`, so the host part of the link must be the SSH alias the user has for this machine there, not the name this machine calls itself. You can't work that alias out from here, so the user tells you once and the script remembers it.

## Generate the link

Run `scripts/cursor_link.sh` (path relative to this `SKILL.md`):

```sh
scripts/cursor_link.sh <path> [line [column]]
```

It resolves the path to an absolute one, looks up this machine's alias in its hosts table and prints one link. Paste that link as-is on its own line.

## When the host is unknown

On the first run on a machine, or any machine not yet in the table, the script exits with code 2 and prints the names this machine goes by (hostname, full hostname, DNS search domains). Then:

1. Tell the user you can't tell which SSH alias they use for this machine, and show them those names.
2. Ask for the alias from their `~/.ssh/config` on the machine where Cursor runs, or whether Cursor runs on this very machine (then the alias is `local`).
3. Save it, then rerun the link command:

   ```sh
   scripts/cursor_link.sh --remember <alias> [pattern]
   ```

`pattern` is a shell glob matched against the names above; it defaults to the full hostname. If this machine is one of many nodes that share a home directory (a cluster where you may land on a different login or compute node next time), propose a pattern that covers all of them, such as the DNS search domain or `*.cluster.example.com`, and confirm it with the user. Saving the same pattern again replaces the old alias.

The table lives at `~/.config/cursor-deep-links/hosts` (override with `CURSOR_LINK_HOSTS`), one `<pattern> <alias>` per line, first match wins. `scripts/cursor_link.sh --whoami` shows this machine's names and saved alias. `CURSOR_SSH_HOST=<alias>` overrides the table for one call.

## Format

- Remote file or folder: `cursor://vscode-remote/ssh-remote+<alias>/<absolute path>`
- Remote file at a line: `cursor://vscode-remote/ssh-remote+<alias>/<absolute path>:<line>[:<column>]`
- File on the machine running Cursor: `cursor://file/<absolute path>[:<line>[:<column>]]`

A folder link opens that folder as a workspace; a file link opens the file in a window connected to that host.

## Mistakes to avoid

- Don't guess the alias from `hostname`. The name a machine calls itself often doesn't resolve from the user's machine or doesn't match their SSH config, and Cursor fails with "Unable to resolve resource vscode-remote://ssh-remote+...". Ask instead.
- Don't hand out a bare `vscode-remote://ssh-remote+host/...` URI. That is Cursor's internal resource form, not a link the OS routes to Cursor. Use the `cursor://vscode-remote/...` form above.
- Don't use the `vscode://` scheme; it opens VS Code instead of Cursor.
- Don't drop the line number from a remote file link. Cursor opens a remote path without `:<line>` as a folder workspace, so a file comes up as an empty window. The script adds `:1` when you give no line.
- Don't percent-encode the `+` after `ssh-remote`. The script encodes spaces and other unsafe characters in the path.
- The path must exist on the host the alias points at. On a cluster, a node-local path such as `/tmp` on a compute node won't open through an alias for the login node; shared paths like a network home directory will.
