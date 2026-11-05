# Cursor deep links skill

An agent skill for Claude Code and Codex that gives you clickable `cursor://` links to files and folders, both on your own machine and on remote hosts you reach through Cursor's Remote-SSH.

A remote link only works if it names the SSH alias you use for that host in your own `~/.ssh/config`, and the agent can't see that from the remote side. So the first time the agent needs a link on a machine it doesn't know, it asks you for the alias and saves it in `~/.config/cursor-deep-links/hosts` on that machine. Every link after that is generated without asking.

## Install

Clone the repo and link the skill into your agent's skills folder, on every machine where you run the agent:

```sh
git clone https://github.com/RunFMe/cursor-deep-links.git ~/cursor-deep-links
mkdir -p ~/.claude/skills ~/.codex/skills
ln -s ~/cursor-deep-links/creating-cursor-deep-links ~/.claude/skills/   # Claude Code
ln -s ~/cursor-deep-links/creating-cursor-deep-links ~/.codex/skills/    # Codex
```

## Use it yourself

```sh
creating-cursor-deep-links/scripts/cursor_link.sh src/main.py 42
# cursor://vscode-remote/ssh-remote+devbox/home/me/project/src/main.py:42

creating-cursor-deep-links/scripts/cursor_link.sh --remember devbox            # save this machine's alias
creating-cursor-deep-links/scripts/cursor_link.sh --remember local             # Cursor runs on this machine
creating-cursor-deep-links/scripts/cursor_link.sh --remember gpu '*.hpc.example.org'  # every node of a cluster
creating-cursor-deep-links/scripts/cursor_link.sh --whoami
```

The hosts table is plain text, one `<glob pattern> <alias>` per line, matched against the machine's hostname, full hostname and DNS search domains. Set `CURSOR_LINK_HOSTS` to keep it somewhere else, or `CURSOR_SSH_HOST` to override it for one call.
