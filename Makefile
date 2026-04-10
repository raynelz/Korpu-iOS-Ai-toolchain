# Установка зависимостей проекта
.PHONY: all
all:
	brew install go-task
	task
	@echo ---
	@bash scripts/task-auto.sh
