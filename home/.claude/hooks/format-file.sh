#!/bin/bash

# formatters

if [[ "$CLAUDE_TOOL_FILE_PATH" == *.js ||
	"$CLAUDE_TOOL_FILE_PATH" == *.ts ||
	"$CLAUDE_TOOL_FILE_PATH" == *.jsx ||
	"$CLAUDE_TOOL_FILE_PATH" == *.tsx ||
	"$CLAUDE_TOOL_FILE_PATH" == *.json ||
	"$CLAUDE_TOOL_FILE_PATH" == *.css ||
	"$CLAUDE_TOOL_FILE_PATH" == *.html ]]; then
	npx prettier --write "$CLAUDE_TOOL_FILE_PATH" 2>/dev/null || true
elif [[ "$CLAUDE_TOOL_FILE_PATH" == *.py ]]; then
	black
	"$CLAUDE_TOOL_FILE_PATH" 2>/dev/null || true
elif [[ "$CLAUDE_TOOL_FILE_PATH" == *.go ]]; then
	gofmt -w "$CLAUDE_TOOL_FILE_PATH" 2>/dev/null || true
elif [[ "$CLAUDE_TOOL_FILE_PATH" == *.rs ]]; then
	rustfmt "$CLAUDE_TOOL_FILE_PATH" 2>/dev/null || true
elif [[ "$CLAUDE_TOOL_FILE_PATH" == *.php ]]; then
	php-cs-fixer fix "$CLAUDE_TOOL_FILE_PATH" 2>/dev/null || true
fi

# linters

if [[ "$CLAUDE_TOOL_FILE_PATH" == *.js ||
	"$CLAUDE_TOOL_FILE_PATH" == *.ts ||
	"$CLAUDE_TOOL_FILE_PATH" == *.jsx ||
	"$CLAUDE_TOOL_FILE_PATH" == *.tsx ]]; then
	npx eslint "$CLAUDE_TOOL_FILE_PATH" --fix 2>/dev/null || true
elif [[ "$CLAUDE_TOOL_FILE_PATH" == *.py ]]; then
	pylint "$CLAUDE_TOOL_FILE_PATH" 2>/dev/null || true
elif [[ "$CLAUDE_TOOL_FILE_PATH" == *.rb ]]; then
	rubocop "$CLAUDE_TOOL_FILE_PATH" --auto-correct 2>/dev/null || true
fi
