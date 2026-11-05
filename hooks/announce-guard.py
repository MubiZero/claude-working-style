#!/usr/bin/env python3
"""Stop hook: the turn may not end long (more than 2-3 lines unasked) or on an announced next step («Дальше беру X», «Начинаю Y») that was never started.

The owner noticed the pattern: an approved next step is announced in the last message and the turn stops there. If the
last assistant text ends with such an announcement (and is not a question), stopping is blocked once with a reason;
stop_hook_active lets the second stop through, so it never loops. No model call: a regex over the transcript.
"""
import json
import os
import re
import sys

NOTE = os.path.expanduser("~/.claude/hooks/.last-answer-long")

VERBS = r"(беру|берусь|делаю|начинаю|займусь|приступаю|перехожу|запускаю|чиню|сделаю|начну|возьмусь|запущу|подключу)"
# An announcement opens its sentence: «Начинаю D3.», «Дальше беру склад», «Сейчас запущу агента». A verb in the middle of a
# sentence that describes a rule («workflow я запускаю, только когда…») is not one.
ANNOUNCE = re.compile(
    r"^\W*((дальше|далее|следующ\w*|теперь|сейчас|затем|потом)\W+(\w+\W+){0,2})?" + VERBS + r"\b",
    re.IGNORECASE,
)


def last_text(path):
    text = ""
    with open(path, encoding="utf-8") as f:
        for line in f:
            try:
                e = json.loads(line)
            except ValueError:
                continue
            if e.get("type") != "assistant":
                continue
            parts = [c.get("text", "") for c in e.get("message", {}).get("content", []) if isinstance(c, dict) and c.get("type") == "text"]
            if any(p.strip() for p in parts):
                text = "\n".join(parts)
    return text.strip()


ASKED_DETAIL = re.compile(r"подробн|почему|детал|распиши|полност|объясни|зачем|explain|detail|why", re.IGNORECASE)


def last_user_text(path):
    text = ""
    with open(path, encoding="utf-8") as f:
        for line in f:
            try:
                e = json.loads(line)
            except ValueError:
                continue
            if e.get("type") != "user":
                continue
            c = e.get("message", {}).get("content")
            if isinstance(c, str):
                text = c
            elif isinstance(c, list):
                parts = [p.get("text", "") for p in c if isinstance(p, dict) and p.get("type") == "text"]
                if any(p.strip() for p in parts):
                    text = "\n".join(parts)
    return text


def too_long(text):
    """More than four non-empty lines or about 450 characters: the owner reads two or three lines."""
    lines = [l for l in text.splitlines() if l.strip()]
    return len(lines) > 4 or len(text) > 450


def main():
    data = json.load(sys.stdin)
    if data.get("stop_hook_active"):
        return 0
    try:
        text = last_text(data["transcript_path"])
    except (KeyError, OSError):
        return 0
    if not text:
        return 0
    if too_long(text) and not ASKED_DETAIL.search(last_user_text(data["transcript_path"])):
        # Not a block: the long answer is already on screen, and a forced rewrite only says it twice. The note is read by
        # the prompt hook (length-note.py) before the next answer.
        with open(NOTE, "w") as f:
            f.write("1")
    if text.rstrip().endswith("?"):
        return 0
    last = [x for x in re.split(r"(?<=[.!])\s+|\n+", text) if x.strip()][-2:]  # the last two sentences
    if any(ANNOUNCE.search(x) for x in last):
        print(
            "Ход заканчивается объявлением следующего шага, который не начат. Если шаг одобрен — начни его сейчас "
            "(вызов инструмента или агента) и закончи результатом; если нужен ответ владельца — задай вопрос; "
            "если шаг уже идёт у агента — скажи «идёт», а не «беру».",
            file=sys.stderr,
        )
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
