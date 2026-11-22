#!/usr/bin/env python3
"""Stop hook (Claude Code & Antigravity): the turn may not end long (more than 2-3 lines unasked) or on an announced next step («Дальше беру X», «Начинаю Y») that was never started.

Supports both contracts:
- Claude Code: stdin has `transcript_path`, `stop_hook_active`, `session_id`; blocks with exit code 2 and stderr message.
- Antigravity: stdin has `transcriptPath`, `continuationActive`, `conversationId`, `terminationReason`, `lastUserInput`; blocks with exit code 0 and JSON `{"decision": "continue", "reason": "..."}` on stdout.
"""
import json
import os
import re
import sys

NOTE_DIR = os.path.expanduser("~/.claude/hooks")
LEGACY_NOTE = os.path.join(NOTE_DIR, ".last-answer-long")

VERBS = r"(беру|берусь|делаю|начинаю|займусь|приступаю|перехожу|запускаю|чиню|сделаю|начну|возьмусь|запущу|подключу)"
ANNOUNCE = re.compile(
    r"^\W*((дальше|далее|следующ\w*|теперь|сейчас|затем|потом)\W+(\w+\W+){0,2})?" + VERBS + r"\b",
    re.IGNORECASE,
)

ASKED_DETAIL = re.compile(
    r"подробн|почему|детал|распиши|полност|объясни|зачем|хронолог|отч[её]т|разбор|сравни|составь|предложи|найди корень"
    r"|explain|detail|why|report|compare",
    re.IGNORECASE,
)

# A question that offers choices as text («1) … 2) …» in a line or as a list) instead of AskUserQuestion / ask_question.
TEXT_OPTIONS = re.compile(r"(?:^|[\s(])1\)\s+\S.*?(?:\n|\s)2\)\s+\S", re.DOTALL)


def note_path(session_id):
    if session_id:
        safe = re.sub(r"[^A-Za-z0-9_.-]", "_", str(session_id))
        return os.path.join(NOTE_DIR, f".last-answer-long.{safe}")
    return LEGACY_NOTE


def last_text(path):
    text = ""
    with open(path, encoding="utf-8") as f:
        for line in f:
            try:
                e = json.loads(line)
            except ValueError:
                continue
            t = e.get("type")
            if t == "assistant":
                parts = [
                    c.get("text", "")
                    for c in e.get("message", {}).get("content", [])
                    if isinstance(c, dict) and c.get("type") == "text"
                ]
                if any(p.strip() for p in parts):
                    text = "\n".join(parts)
            elif t == "PLANNER_RESPONSE":
                c = e.get("content", "")
                if isinstance(c, str) and c.strip():
                    text = c
    return text.strip()


def last_user_text(path, fallback=""):
    text = fallback or ""
    try:
        with open(path, encoding="utf-8") as f:
            for line in f:
                try:
                    e = json.loads(line)
                except ValueError:
                    continue
                t = e.get("type")
                if t == "user":
                    c = e.get("message", {}).get("content")
                    if isinstance(c, str):
                        text = c
                    elif isinstance(c, list):
                        parts = [p.get("text", "") for p in c if isinstance(p, dict) and p.get("type") == "text"]
                        if any(p.strip() for p in parts):
                            text = "\n".join(parts)
                elif t == "USER_INPUT":
                    c = e.get("content", "")
                    if isinstance(c, str) and c.strip():
                        text = c
    except OSError:
        pass
    return text


def too_long(text):
    """More than four non-empty lines or about 450 characters: the owner reads two or three lines."""
    lines = [l for l in text.splitlines() if l.strip()]
    return len(lines) > 4 or len(text) > 450


def allow(is_agy):
    if is_agy:
        print(json.dumps({"decision": "allow"}))
    return 0


def block(is_agy, reason):
    if is_agy:
        print(json.dumps({"decision": "continue", "reason": reason}, ensure_ascii=False))
        return 0
    print(reason, file=sys.stderr)
    return 2


def main():
    try:
        data = json.load(sys.stdin)
    except ValueError:
        return 0

    is_agy = "transcriptPath" in data or "continuationActive" in data or "terminationReason" in data

    if data.get("stop_hook_active") or data.get("continuationActive"):
        return allow(is_agy)

    if is_agy and data.get("terminationReason", "NO_TOOL_CALL") != "NO_TOOL_CALL":
        return allow(is_agy)

    t_path = data.get("transcriptPath") or data.get("transcript_path")
    if not t_path:
        return allow(is_agy)
    try:
        text = last_text(t_path)
    except OSError:
        return allow(is_agy)
    if not text:
        return allow(is_agy)

    user_txt = last_user_text(t_path, data.get("lastUserInput", ""))
    sid = data.get("conversationId") or data.get("session_id")
    if too_long(text) and not ASKED_DETAIL.search(user_txt):
        os.makedirs(NOTE_DIR, exist_ok=True)
        with open(note_path(sid), "w", encoding="utf-8") as f:
            f.write("1")
        if sid:
            with open(LEGACY_NOTE, "w", encoding="utf-8") as f:
                f.write("1")

    tail = text[-600:]
    if "?" in tail and TEXT_OPTIONS.search(tail):
        return block(
            is_agy,
            "Вопрос с вариантами написан текстом «1) … 2) …». Развилку задают интерфейсом: вызови AskUserQuestion / ask_question "
            "(2–4 варианта, твой выбор первым с «(Recommended)», при необходимости preview) и спрашивай про цель, а не про шаг.",
        )
    if text.rstrip().endswith("?"):
        return allow(is_agy)
    last = [x for x in re.split(r"(?<=[.!])\s+|\n+", text) if x.strip()][-2:]
    if any(ANNOUNCE.search(x) for x in last):
        return block(
            is_agy,
            "Ход заканчивается объявлением следующего шага, который не начат. Если шаг одобрен — начни его сейчас "
            "(вызов инструмента или агента) и закончи результатом; если нужен ответ владельца — задай вопрос; "
            "если шаг уже идёт у агента — скажи «идёт», а не «беру».",
        )
    return allow(is_agy)


if __name__ == "__main__":
    sys.exit(main())
