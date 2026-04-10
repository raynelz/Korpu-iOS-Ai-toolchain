# Korpu iOS AI Toolchain

## Быстрый старт

В текущем проекте выполни `make`

## Подключение к целевому проекту

### Вариант 1: Через Taskfile (рекомендуется)

```bash
cd <целевой-проект>
ln -sf ../Korpu-iOS-Ai-toolchain/Taskfile.yml Taskfile.yml
task agents
task agents-claude   # или task agents-codex
```

### Вариант 2: Вручную

```bash
cd <целевой-проект>

# Агенты и скиллы
ln -sf ../Korpu-iOS-Ai-toolchain/.agents .agents
ln -sf ../Korpu-iOS-Ai-toolchain/AGENTS.md AGENTS.md

# Claude Code
echo '@AGENTS.md' > CLAUDE.md
mkdir -p .claude
ln -sf ../.agents/skills .claude/skills
```

### .gitignore

Добавь в `.gitignore` целевого проекта:

```
.agents
AGENTS.md
.claude/skills
CLAUDE.md
CODEX.md
DOD.md
Taskfile.yml
```
