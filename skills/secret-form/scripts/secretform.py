#!/usr/bin/env python3
"""Serve one page, write the answers to a dotenv file, exit.

    python3 secretform.py --name OPENAI_API_KEY --env .env.local

Binds 127.0.0.1, prints the URL, blocks until the user saves or cancels, then
writes the file with mode 0600 (merging keys that already exist) and prints a
one-line summary. It never prints a value.
"""

from __future__ import annotations

import argparse
import html
import os
import re
import secrets
import sys
import threading
import urllib.parse
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

NAME_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
ASSIGN_RE = re.compile(r"^(\s*(?:export\s+)?)([A-Za-z_][A-Za-z0-9_]*)\s*=")
PLAIN_RE = re.compile(r"^[A-Za-z0-9_@%+=:,./-]*$")
MAX_VALUE = 16 * 1024
TEMPLATE = Path(__file__).resolve().parent.parent / "template.html"


def quote(value: str) -> str:
    if PLAIN_RE.match(value):
        return value
    escaped = (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("$", "\\$")
        .replace("`", "\\`")
    )
    return f'"{escaped}"'


def write_dotenv(path: Path, values: dict[str, str]) -> None:
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True) if path.exists() else []
    seen: set[str] = set()
    out: list[str] = []
    for line in lines:
        match = ASSIGN_RE.match(line)
        if match and match.group(2) in values:
            name = match.group(2)
            ending = "\n" if line.endswith("\n") else ""
            out.append(f"{match.group(1)}{name}={quote(values[name])}{ending}")
            seen.add(name)
        else:
            out.append(line)
    if out and not out[-1].endswith("\n"):
        out[-1] += "\n"
    for name, value in values.items():
        if name not in seen:
            out.append(f"{name}={quote(value)}\n")

    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(f".{path.name}.{os.getpid()}.tmp")
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write("".join(out))
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp, path)
        os.chmod(path, 0o600)
    except BaseException:
        tmp.unlink(missing_ok=True)
        raise


def existing_keys(path: Path) -> set[str]:
    if not path.exists():
        return set()
    return {
        match.group(2)
        for match in (ASSIGN_RE.match(line) for line in path.read_text(errors="replace").splitlines())
        if match
    }


def field_html(name: str, label: str, already: bool) -> str:
    safe = html.escape(name)
    tag = '<span class="tag">already set</span>' if already else ""
    hint = (
        f'<p class="hint" id="h-{safe}">{html.escape(label)}</p>'
        if label
        else ""
    )
    described = f' aria-describedby="h-{safe}"' if label else ""
    return f"""    <div class="field">
      <div class="field-head">
        <label class="field-name" for="f-{safe}">{safe}</label>{tag}
      </div>
      {hint}
      <div class="row">
        <input id="f-{safe}" name="{safe}" type="password" required{described}
               autocomplete="off" autocapitalize="none" autocorrect="off" spellcheck="false">
        <button type="button" class="reveal" data-for="f-{safe}" aria-pressed="false"
                aria-label="Show {safe}">Show</button>
      </div>
    </div>"""


def render(template: str, names, labels, purpose, destination, action, footer,
           already: set[str] | None = None) -> str:
    already = already or set()
    fields = "\n".join(field_html(n, labels.get(n, ""), n in already) for n in names)
    return (
        template.replace("{{TITLE}}", "Secrets requested")
        .replace("{{PURPOSE}}", html.escape(purpose))
        .replace("{{DESTINATION}}", destination)
        .replace("{{ACTION}}", html.escape(action))
        .replace("{{FOOTER}}", html.escape(footer))
        .replace("{{FIELDS}}", fields)
    )


MESSAGE_PAGE = """<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<style>
  :root {{ color-scheme: light dark; --canvas:#fbfbfa; --ink:#111111;
          --muted:#6b6b66; --border:#eeeeec;
          --font-sans:"Geist","Geist Sans",ui-sans-serif,system-ui,-apple-system,"Segoe UI",sans-serif; }}
  @media (prefers-color-scheme: dark) {{
    :root {{ --canvas:#0b0b0c; --ink:#ededed; --muted:#9d9da4; --border:#1f1f23; }}
  }}
  body {{ margin:0; padding:64px 24px; background:var(--canvas); color:var(--ink);
         font-family:var(--font-sans); font-size:15px; line-height:1.55;
         -webkit-font-smoothing:antialiased; }}
  main {{ max-width:520px; margin:0 auto; }}
  h1 {{ font-size:1.75rem; line-height:1.15; letter-spacing:-0.02em; font-weight:600;
       margin:0 0 8px; }}
  p {{ color:var(--muted); margin:0; padding-top:16px; border-top:1px solid var(--border); }}
</style></head>
<body><main><h1>{title}</h1><p>{body}</p></main></body></html>"""


class State:
    def __init__(self):
        self.values: dict[str, str] = {}
        self.result = "pending"  # pending | saved | cancelled
        self.done = threading.Event()


def build_handler(state: State, token: str, page: str, names: list[str]):
    class Handler(BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"

        def log_message(self, format, *args):  # noqa: A002 - base class signature
            return

        def send(self, code: int, body: str):
            data = body.encode()
            self.send_response(code)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.send_header("Referrer-Policy", "no-referrer")
            self.send_header("X-Frame-Options", "DENY")
            self.send_header("Connection", "close")
            self.end_headers()
            self.wfile.write(data)
            self.close_connection = True

        def message(self, title: str, text: str):
            self.send(
                200 if title != "Not found" else 404,
                MESSAGE_PAGE.format(
                    title=html.escape(title), body=html.escape(text)
                ),
            )

        def do_GET(self):
            if urllib.parse.urlsplit(self.path).path != f"/{token}":
                return self.message("Not found", "This link is not valid.")
            self.send(200, page)

        def do_POST(self):
            if urllib.parse.urlsplit(self.path).path != f"/{token}":
                return self.message("Not found", "This link is not valid.")
            if state.done.is_set():
                return self.message("Already answered", "This request was already answered.")
            try:
                length = int(self.headers.get("Content-Length", "0"))
            except ValueError:
                length = 0
            if length < 0 or length > 1 << 20:
                return self.message("Too large", "The form body is too large.")
            form = urllib.parse.parse_qs(
                self.rfile.read(length).decode("utf-8", "replace"), keep_blank_values=True
            )
            if form.get("action", ["submit"])[0] == "cancel":
                state.result = "cancelled"
                state.done.set()
                return self.message("Cancelled", "Nothing was saved. You can close this tab.")

            values, errors = {}, []
            for name in names:
                value = form.get(name, [""])[0].strip("\r\n")
                if not value:
                    errors.append(f"{name} is empty")
                elif "\n" in value or "\r" in value or "\x00" in value:
                    errors.append(f"{name} must be one line")
                elif len(value.encode()) > MAX_VALUE:
                    errors.append(f"{name} is too long")
                else:
                    values[name] = value
            if errors:
                return self.message("Not saved", "; ".join(errors) + ". Go back and retry.")
            state.values = values
            state.result = "saved"
            state.done.set()
            self.message("Saved", "You can close this tab and return to the agent.")

    return Handler


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        prog="secretform",
        description="Serve one page, write the answers to a dotenv file, exit.",
    )
    parser.add_argument("--name", action="append", default=[], metavar="KEY")
    parser.add_argument("--label", action="append", default=[], metavar="KEY=TEXT")
    parser.add_argument("--purpose", default="")
    parser.add_argument("--env", metavar="PATH", help="dotenv file to write")
    parser.add_argument("--ephemeral", action="store_true",
                        help="write to a random file under $XDG_RUNTIME_DIR instead of the project")
    parser.add_argument("--timeout", type=int, default=600)
    parser.add_argument("--open", action="store_true")
    parser.add_argument("--check", action="store_true", help="self-test, then exit")
    args = parser.parse_args(argv)

    if args.check:
        return self_test()

    if not args.name:
        sys.stderr.write("secretform: at least one --name KEY is required\n")
        return 2

    for name in args.name:
        if not NAME_RE.match(name):
            sys.stderr.write(f"secretform: invalid name {name!r}\n")
            return 2
    if not args.env and not args.ephemeral:
        sys.stderr.write("secretform: pass --env PATH or --ephemeral\n")
        return 2

    labels = dict(pair.split("=", 1) for pair in args.label if "=" in pair)
    if args.env:
        target = Path(args.env).expanduser().resolve()
    else:
        runtime = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp"))
        target = runtime / "secret-form" / f"{secrets.token_hex(6)}.env"

    token = secrets.token_hex(24)
    state = State()
    destination = (
        f"Saved to <code>{html.escape(str(target))}</code> with mode 0600."
        if args.env
        else "Saved to a temporary file outside the project, mode 0600."
    )
    page = render(
        TEMPLATE.read_text(encoding="utf-8"),
        args.name,
        labels,
        args.purpose,
        destination,
        f"/{token}",
        f"requested by pid {os.getpid()} in {os.getcwd()}",
        existing_keys(target),
    )

    httpd = ThreadingHTTPServer(("127.0.0.1", 0), build_handler(state, token, page, args.name))
    httpd.daemon_threads = True
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    url = f"http://127.0.0.1:{httpd.server_address[1]}/{token}"
    sys.stdout.write(f"Open: {url}\n")
    sys.stdout.flush()
    if args.open:
        try:
            webbrowser.open(url)
        except Exception:
            pass

    state.done.wait(args.timeout)
    httpd.shutdown()
    httpd.server_close()

    if state.result != "saved":
        reason = {
            "cancelled": "cancelled by the user",
            "pending": f"no answer within {args.timeout}s",
        }.get(state.result, state.result)
        sys.stderr.write(f"secretform: {reason}\n")
        return 3 if state.result == "cancelled" else 4
    write_dotenv(target, state.values)
    sys.stdout.write(f"secretform: saved {len(state.values)} value(s) to {target} (0600)\n")
    return 0


def self_test() -> int:
    failures = []

    def expect(label, got, want):
        if got != want:
            failures.append(f"{label}: got {got!r}, want {want!r}")

    import tempfile

    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / ".env"
        path.write_text("KEEP=1\nA=old\n")
        write_dotenv(path, {"A": "new", "B": "x y$z"})
        text = path.read_text()
        expect("keep", "KEEP=1\n" in text, True)
        expect("replace", "A=new\n" in text, True)
        expect("append+quote", 'B="x y\\$z"\n' in text, True)
        expect("mode", oct(path.stat().st_mode & 0o777), "0o600")

    page = render("<p>{{PURPOSE}}</p>{{FIELDS}}", ["K"],
                  {"K": "<script>x</script>"}, "<a href=x>", "d", "/t", "f")
    expect("escaped label", "<script>x</script>" in page, False)
    expect("escaped purpose", "<a href=x>" in page, False)

    for failure in failures:
        sys.stderr.write(f"check failed: {failure}\n")
        return 1
    sys.stdout.write("secretform: self-test passed\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
