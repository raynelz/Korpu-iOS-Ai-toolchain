---
name: x-safe-commit
description: Закоммить изменения локально БЕЗ push на remote. Используй вместо стандартного коммита. Триггер — пользователь просит закоммитить, сохранить изменения, сделать commit. АБСОЛЮТНО ЗАПРЕЩЕНО выполнять git push, git push origin, git push --force или любую другую команду, отправляющую код на remote. Только локальные коммиты.
---

# Safe Local Commit

Закоммить изменения ТОЛЬКО локально. Push на remote ЗАПРЕЩЁН.

## ЗАПРЕТ

```
🚫 git push                    — ЗАПРЕЩЕНО
🚫 git push origin             — ЗАПРЕЩЕНО
🚫 git push -u origin          — ЗАПРЕЩЕНО
🚫 git push --force            — ЗАПРЕЩЕНО
🚫 git push origin main        — ЗАПРЕЩЕНО
🚫 git push origin <любая>     — ЗАПРЕЩЕНО
🚫 gh pr create                — ЗАПРЕЩЕНО (создаёт push)
🚫 gh pr merge                 — ЗАПРЕЩЕНО
```

**Любая команда, отправляющая данные на remote — ЗАПРЕЩЕНА.**

Если пользователь просит push — откажи и напомни:
> «Push заблокирован скиллом x-safe-commit. Проверь изменения и выполни push вручную, когда будешь готов.»

## Процедура коммита

### Шаг 1: Проверь состояние

```bash
git status
git diff --stat
```

### Шаг 2: Покажи изменения пользователю

Выведи краткую сводку:
- Какие файлы изменены
- Какие файлы добавлены (untracked)
- Какие файлы удалены

### Шаг 3: Проверь на опасные файлы

Перед добавлением проверь, что в коммит НЕ попадут:

```
🚫 .env / .env.local / .env.*
🚫 *credentials* / *secret* / *token*
🚫 *.p12 / *.pem / *.key / *.cer
🚫 Pods/ (если в .gitignore)
🚫 *.xcuserdata
🚫 DerivedData/
🚫 .DS_Store
```

Если обнаружены — предупреди пользователя и НЕ добавляй эти файлы.

### Шаг 4: Добавь файлы поимённо

```bash
# Добавляй конкретные файлы, НЕ используй git add -A или git add .
git add Korpu/Modules/Feature/FeatureModule.swift
git add Korpu/Modules/Feature/FeaturePresenter.swift
git add Korpu/Modules/Feature/FeatureViewController.swift
```

### Шаг 5: Закоммить

```bash
git commit -m "$(cat <<'EOF'
feat: краткое описание изменений

Подробности если нужны.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

### Шаг 6: Подтверди результат

```bash
git log --oneline -1
git status
```

Выведи пользователю:
```
✅ Коммит создан локально: <hash> <message>
⏸️ Push НЕ выполнен. Проверь изменения и пушь вручную когда будешь готов.
```

## Формат коммитов

```
<type>: <описание>
```

Типы: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`

## Правила

- **НИКОГДА** не выполняй push — ни явно, ни неявно
- **НИКОГДА** не используй `git add -A` или `git add .` — только поимённо
- **НИКОГДА** не коммить файлы с секретами
- **ВСЕГДА** показывай diff/status перед коммитом
- **ВСЕГДА** после коммита напоминай, что push не выполнен
- Если pre-commit hook упал — исправь проблему и создай НОВЫЙ коммит (не amend)
