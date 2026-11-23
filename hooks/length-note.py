#!/usr/bin/env python3
"""Prompt/PreInvocation hook (Antigravity, Claude Code, and compatible harnesses):
after an answer longer than 2-3 lines (marked by announce-guard.py), remind once before the next one.
"""
import json
import os
import re
import sys


def resolve_state_dir():
    env_data = os.environ.get("PLUGIN_DATA", "").strip()
    if env_data:
        return env_data
    xdg = os.environ.get("XDG_STATE_HOME", "").strip() or os.path.expanduser("~/.local/state")
    return os.path.join(xdg, "working-style")


NOTE_DIR = resolve_state_dir()
LEGACY_NOTE = os.path.join(NOTE_DIR, ".last-answer-long")
MSG = (
    "Прошлый ответ был длиннее 2–3 строк. Этот держи в 2–3 строках, если не просили отчёт или разбор; "
    "вопрос задавай интерфейсом хоста (мой выбор первым), а не текстом «1) … 2) …»."
)


def note_path(session_id):
    if session_id:
        safe = re.sub(r"[^A-Za-z0-9_.-]", "_", str(session_id))
        return os.path.join(NOTE_DIR, f".last-answer-long.{safe}")
    return LEGACY_NOTE


def main():
    raw = sys.stdin.read().strip() if not sys.stdin.isatty() else ""
    data = {}
    if raw:
        try:
            data = json.loads(raw)
        except ValueError:
            data = {}

    is_agy = "conversationId" in data or "invocationNum" in data or data.get("hookEventName") == "PreInvocation"
    sid = data.get("conversationId") or data.get("session_id")
    candidates = [note_path(sid), LEGACY_NOTE] if sid else [LEGACY_NOTE]

    triggered = False
    for p in candidates:
        if os.path.exists(p):
            try:
                os.remove(p)
            except OSError:
                pass
            triggered = True

    if is_agy:
        if triggered:
            print(
                json.dumps(
                    {"injectSteps": [{"systemMessage": {"systemMessage": MSG}}]},
                    ensure_ascii=False,
                )
            )
        else:
            print("{}")
        return 0

    if triggered:
        print(MSG)
    return 0


if __name__ == "__main__":
    sys.exit(main())
