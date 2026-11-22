#!/usr/bin/env python3
"""UserPromptSubmit (Claude Code) & PreInvocation (Antigravity) hook:
after an answer longer than 2-3 lines (marked by announce-guard.py), remind once before the next one.
"""
import json
import os
import re
import sys

NOTE_DIR = os.path.expanduser("~/.claude/hooks")
LEGACY_NOTE = os.path.join(NOTE_DIR, ".last-answer-long")
MSG = (
    "Прошлый ответ был длиннее 2–3 строк. Этот — 2–3 строки, если не просили отчёт или разбор; "
    "вопрос — только интерфейсом AskUserQuestion / ask_question (мой выбор первым), не текстом «1) … 2) …»."
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
