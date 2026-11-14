#!/usr/bin/env python3
"""UserPromptSubmit hook: after an answer longer than 2-3 lines (marked by announce-guard.py), remind once before the next one."""
import os

NOTE = os.path.expanduser("~/.claude/hooks/.last-answer-long")

if os.path.exists(NOTE):
    os.remove(NOTE)
    print(
        "Прошлый ответ был длиннее 2–3 строк. Этот — 2–3 строки, если не просили отчёт или разбор; "
        "вопрос — только интерфейсом AskUserQuestion (мой выбор первым), не текстом «1) … 2) …»."
    )
