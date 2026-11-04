---
name: secret-form
description: "Ask the human for a password, passphrase, API key, or .env values through a local web form, and write them to a dotenv file without the values entering the chat transcript. Use when a task needs a secret the environment does not have: SSH or key passphrase, sudo password, LUKS unlock, API tokens, env files. Do not use when the value is already in the environment, ssh-agent, or a keychain."
license: MIT
metadata:
  version: "0.1.0"
---

# Secret Form

The user types secrets into a page served on localhost. The page writes them to
a dotenv file; the agent never sees or prints them.

**Never ask for a secret in chat.** A value pasted into a prompt, a question
tool, or `read -s` inside a tool call is part of the transcript.

## Use it

```bash
python3 scripts/secretform.py --name OPENAI_API_KEY --name RESEND_API_KEY \
  --purpose "Local development" --env .env.local
```

It prints `Open: http://127.0.0.1:PORT/TOKEN` and blocks. Give that URL to the
user as a link. On save it writes the file (mode 0600, atomic, existing keys
replaced in place, everything else preserved) and prints a one-line summary.

Run it in the background when the harness supports that (pi: `run_in_background`;
Claude Code backgrounds on timeout), so the user can click while the turn stays
alive. Exit codes: `0` saved, `3` cancelled, `4` timed out.

Use `--ephemeral` for a one-off secret that should not sit in the project. It
writes to `$XDG_RUNTIME_DIR/secret-form/*.env` and prints the path; delete it
after use.

Other flags: `--label KEY="text"` for a hint under a field, `--open` to launch a
browser, `--timeout SECONDS` (default 600), `--check` to self-test.

The page is [`template.html`](template.html); edit it to change wording or style.
It is rendered by the script, so a caller can only supply escaped text, never
markup or a form target.

## After the file is written

Use the file; do not print it. Keep the values out of argv (they are visible in
`ps`) and out of anything that echoes:

```bash
set -a; . .env.local; set +a          # load into this shell only
gh release create v1.2.0             # reads GH_TOKEN from the environment
docker compose up                    # passes its environment to containers
printf '%s' "$SUDOPASS" | sudo -S -p '' systemctl restart nginx
```

For SSH key passphrases and sudo, an askpass helper keeps the value out of argv:

```bash
scripts/askpass   # 8 lines; prints $ANSWER_VAR, diagnostics to stderr
```

```bash
set -a; . .env.local; set +a
ANSWER_VAR=KEYPASS SSH_ASKPASS=$PWD/scripts/askpass SSH_ASKPASS_REQUIRE=force \
  setsid -w ssh-add ~/.ssh/id_prod

set -a; . .env.local; set +a
ANSWER_VAR=SUDOPASS SUDO_ASKPASS=$PWD/scripts/askpass sudo -A systemctl restart nginx
```

For LUKS, `printf %s` (no trailing newline) into `--key-file -`:

```bash
printf %s "$LUKSPASS" | cryptsetup open --key-file - /dev/sdb1 crypt
```

Delete the file when the task is done if it is not a project `.env`:

```bash
rm -f "$envfile"
```

## Limits

The file is readable by anything running as the user, including the agent, so
treat a written `.env` as a normal project secret. The guarantee here is about
the transcript: the value never passes through chat, argv, or tool output. For a
hard boundary, run the consumer outside the agent's user or let the user run the
command themselves.

Do not `cat`, `grep`, `env`, `set -x`, or `curl -d @` a file that holds these
values; if one is already in the environment, pass it through without printing.
