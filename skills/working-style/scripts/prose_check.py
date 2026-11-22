#!/usr/bin/env python3
"""prose_check.py — fast deterministic linter for the 4 Anti-Slop prose classes (symbols, wording, syntax).
Skips fenced code blocks (```...```), inline code (`...`), URLs, and blockquotes (> ...).
Usage: python3 prose_check.py <file1> [<file2> ...]
Exits 1 if any violations are found, 0 if clean.
"""
import re
import sys

RULES = [
    ("symbols", "длинное тире «—» (замени на запятую, двоеточие или точку)", re.compile(r"—")),
    ("symbols", "декоративный эмодзи в прозе", re.compile(r"[\U0001F300-\U0001FAFF\u2728\U0001F680]")),
    (
        "wording",
        "вводная мета-фраза или штамп («стоит отметить», «в этой статье», «как уже говорилось», «безусловно»)",
        re.compile(
            r"\b(стоит отметить|в этой статье|как уже говорилось|не секрет,? что|важно понимать,? что|само собой разумеется)\b",
            re.IGNORECASE,
        ),
    ),
    (
        "wording",
        "рекламная абстракция или канцелярит («инновационный», «осуществляется», «оптимизация процессов»)",
        re.compile(
            r"\b(инновационн\w+|высокоэффективн\w+|уникальн\w+ решени\w+|осуществляется\b|производится выполнение|оптимизаци\w+ процессов)\b",
            re.IGNORECASE,
        ),
    ),
    (
        "syntax",
        "риторический штамп ИИ («не просто X, а Y» / «не только X, но и Y»)",
        re.compile(r"\b(не просто\s+\S+[^.!?]{1,50},\s*а\s+|не только\s+\S+[^.!?]{1,50},\s*но и\s+)", re.IGNORECASE),
    ),
]

INLINE_SKIP = re.compile(r"`[^`]*`|https?://\S+|\[[^\]]*\]\([^)]*\)")


def strip_protected(line):
    return INLINE_SKIP.sub("", line)


def check_file(path):
    in_fence = False
    findings = []
    with open(path, encoding="utf-8") as f:
        for idx, raw in enumerate(f, 1):
            stripped = raw.strip()
            if stripped.startswith("```"):
                in_fence = not in_fence
                continue
            if in_fence or stripped.startswith(">") or stripped.startswith("<!--"):
                continue
            clean = strip_protected(raw)
            for cls, msg, rx in RULES:
                m = rx.search(clean)
                if m:
                    findings.append((idx, cls, msg, m.group(0)))
    return findings


def main():
    if len(sys.argv) < 2:
        print("usage: prose_check.py <file> [...]", file=sys.stderr)
        return 2
    total = 0
    for p in sys.argv[1:]:
        for line_no, cls, msg, snippet in check_file(p):
            print(f"{p}:{line_no}: [{cls}] {msg} -> «{snippet}»")
            total += 1
    if total == 0:
        print("OK: anti-slop prose check clean")
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
