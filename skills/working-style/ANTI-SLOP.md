# Anti-Slop Prose Protocol & Cited Fact-Check

Applies to all editable human-facing prose (UI copy, READMEs, docs, PR descriptions, issues, public pages). Code, verbatim quotes, math, URLs, identifiers, and Markdown syntax are exempt.

Automated linter:
```bash
python3 skills/working-style/scripts/prose_check.py <file.md>
```

## 1. Four Prose Classes

1. **Symbols (`symbols`):** No em-dashes (`—`), decorative emojis, stars, or exclamation marks for effect in editable prose or UI copy. Replace `—` with a comma, colon, period, or two lines.
2. **Wording & Precision (`wording`):**
   - Lock meaning first: preserve numbers, dates, exact titles, negations, and uncertainty qualifiers ("may", "preliminary"). Never turn "14 days" into "about two weeks" or turn a qualifier into a confident claim.
   - Cut filler and meta-intros ("стоит отметить", "в этой статье", "как уже говорилось", "на самом деле", "довольно").
   - Cut hype and bureaucratic nominalizations ("инновационный", "эффективный", "оптимизация процессов", "осуществляется выполнение")—replace with the concrete action or number supported by the source.
3. **Syntax (`syntax`):**
   - Name the actor and use the active voice when known ("Система проверяет подпись", not "Осуществляется проверка подписи системой"). Keep impersonal passive only when the actor is unknown.
   - Dismantle AI rhetorical templates: **"не просто X, а Y"**, slogan **"не X, а Y"**, **"не только X, но и Y"**. Rebuild as direct assertions. Preserve informative technical contrast ("counts tokens, not words").
4. **Coherence (`coherence`):** Connect adjacent sentences by cause, consequence, contrast, or clarification; keep one topic per paragraph; merge choppy sentences ("Сборка запускается после каждого коммита и занимает 30 секунд").

## 2. Cited Fact-Check & Hypothesis Protocol

1. **Search snippets are only leads:** open and read the primary source before citing versions, limits, or standards.
2. **Numbers and tables require conditions:** quote any table number together with its column header, unit, and row condition.
3. **Include counterevidence:** state caveats or contrary cases from the source alongside the main finding.
4. **Fact vs Inference vs Hypothesis:**
   - **Fact:** direct observation (`file:line`, command output, opened URL).
   - **Inference:** premises + warrant + conclusion.
   - **Hypothesis:** pre-verification claim; must carry an explicit **falsifier** (what observation would disprove it).
