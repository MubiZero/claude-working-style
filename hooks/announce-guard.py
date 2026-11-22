#!/usr/bin/env python3
"""Stop hook (Claude Code & Antigravity):
1) The turn may not end long (>4 lines or >450 chars unasked) -> marks note for next turn reminder.
2) The turn may not offer choices as plain text («1) … 2) …») instead of AskUserQuestion / ask_question.
3) The turn may not end on an announced next step («Дальше беру X», «Начинаю Y») that was never started.
4) R1 stale-verification guard: if files were edited in this turn AFTER the last verification command (or with no
   verification command after the edit) and the response claims completion («Готово», «Починил», «Исправил», «Всё работает»)
   without stating what was not checked («тесты не гонял», «не проверял», «проверено анализатором»), block stop once.
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

TEXT_OPTIONS = re.compile(r"(?:^|[\s(])1\)\s+\S.*?(?:\n|\s)2\)\s+\S", re.DOTALL)

DONE_CLAIM = re.compile(r"(?:^|[\s.,!«\"])(готово|починил|исправил|всё работает|задача выполнена)(?:$|[\s.,!—:»\"])", re.IGNORECASE)
HONEST_UNCHECKED = re.compile(
    r"(не гонял|не проверял|не запускал|без прогона|без проверки|не проверено|проверено анализатором|анализатор чист)",
    re.IGNORECASE,
)

EDIT_TOOLS = {"edit_file", "write_file", "Edit", "MultiEdit", "Write", "NotebookEdit"}
VERIFY_TOOLS = {"run_command", "Bash"}


def note_path(session_id):
    if session_id:
        safe = re.sub(r"[^A-Za-z0-9_.-]", "_", str(session_id))
        return os.path.join(NOTE_DIR, f".last-answer-long.{safe}")
    return LEGACY_NOTE


def parse_transcript(path):
    """Returns (last_assistant_text, last_user_text, edited_after_verify_in_current_turn)."""
    text = ""
    user_text = ""
    edited_since_verify = False

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
                    user_text = c
                    edited_since_verify = False
                elif isinstance(c, list):
                    txts = [p.get("text", "") for p in c if isinstance(p, dict) and p.get("type") == "text"]
                    if any(p.strip() for p in txts):
                        user_text = "\n".join(txts)
                        edited_since_verify = False
            elif t == "USER_INPUT":
                c = e.get("content", "")
                if isinstance(c, str) and c.strip():
                    user_text = c
                    edited_since_verify = False
            elif t == "assistant":
                content = e.get("message", {}).get("content", [])
                parts = []
                for c in content:
                    if not isinstance(c, dict):
                        continue
                    if c.get("type") == "text":
                        parts.append(c.get("text", ""))
                    elif c.get("type") == "tool_use":
                        tname = c.get("name", "")
                        if tname in EDIT_TOOLS:
                            edited_since_verify = True
                        elif tname in VERIFY_TOOLS:
                            edited_since_verify = False
                if any(p.strip() for p in parts):
                    text = "\n".join(parts)
            elif t == "PLANNER_RESPONSE":
                c = e.get("content", "")
                if isinstance(c, str) and c.strip():
                    text = c
                for tc in e.get("tool_calls", []) or []:
                    if not isinstance(tc, dict):
                        continue
                    tname = tc.get("name", "") or tc.get("tool_name", "")
                    if tname in EDIT_TOOLS:
                        edited_since_verify = True
                    elif tname in VERIFY_TOOLS:
                        edited_since_verify = False

    return text.strip(), user_text, edited_since_verify


def too_long(text):
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
        text, user_txt, edited_since_verify = parse_transcript(t_path)
    except OSError:
        return allow(is_agy)
    if not text:
        return allow(is_agy)

    if not user_txt:
        user_txt = data.get("lastUserInput", "")

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

    if edited_since_verify and DONE_CLAIM.search(text) and not HONEST_UNCHECKED.search(text):
        return block(
            is_agy,
            "R1: После последней правки файла в этом ходе не было проверки (команды теста/сборки/анализатора), но в ответе заявлено «Готово»/«Починил». "
            "Либо прогони проверку после последней правки сейчас, либо прямо напиши в ответе, что не проверял («тесты не гонял»).",
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
