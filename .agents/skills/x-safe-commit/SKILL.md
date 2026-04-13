---
name: x-safe-commit
description: Закоммить изменения локально БЕЗ push на remote. Используй вместо стандартного коммита. Триггер — пользователь просит закоммитить, сохранить изменения, сделать commit. АБСОЛЮТНО ЗАПРЕЩЕНО выполнять git push, git push origin, git push --force или любую другую команду, отправляющую код на remote. Только локальные коммиты.
---

# Safe Local Commit

Закоммить изменения ТОЛЬКО локально. Push на remote ЗАПРЕЩЁН.

## ЗАПРЕТ

```
🚫 git push / git push origin / git push --force — ЗАПРЕЩЕНО
🚫 gh pr create / gh pr merge                    — ЗАПРЕЩЕНО
```

Если пользователь просит push — откажи:
> «Push заблокирован скиллом x-safe-commit. Пушь вручную когда будешь готов.»

## Формат сообщения

```
[KORPUTEAM-123]: тип: краткое описание (одна строка)

Описание почему, не больше 5 строк.
```

Типы: `feat`, `fix`, `refactor`, `docs`, `chore`, `perf`

**Описание — только если есть что объяснить. Не лей воду.**

## Процедура

```bash
# 1. Проверь состояние
git status && git diff --stat

# 2. Добавь файлы ПОИМЁННО (не git add -A / git add .)
git add Path/To/File.swift

# 3. Закоммить
git commit -m "[KORPUTEAM-NNN]: feat: краткое описание"

# 4. Подтверди
git log --oneline -1
```

Сообщи пользователю: `✅ <hash> <message> — push не выполнен.`

## Запрещённые файлы

Не добавляй в коммит: `.env*`, `*credentials*`, `*secret*`, `*.p12`, `*.pem`, `*.key`, `Pods/`, `*.xcuserdata`, `DerivedData/`

## Правила

- **НИКОГДА** не выполняй push
- **НИКОГДА** не используй `git add -A` / `git add .`
- Если pre-commit hook упал — исправь и создай НОВЫЙ коммит (не `--amend`)
