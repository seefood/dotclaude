#!/bin/bash

# Read JSON input from Claude Code
input=$(cat)

# Extract working directory
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Function to get comprehensive git status
get_git_status() {
	local dir="$1"

	# Check if we're in a git repository
	if ! git -C "$dir" rev-parse --git-dir &>/dev/null 2>&1; then
		return
	fi

	# Get current branch or commit
	local branch
	branch=$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null || git -C "$dir" rev-parse --short HEAD 2>/dev/null)

	# Initialize status indicators
	local indicators=""

	# Skip optional locks for git commands (faster in some situations)
	export GIT_OPTIONAL_LOCKS=0

	# Check for uncommitted changes (unstaged)
	if ! git -C "$dir" diff --quiet 2>/dev/null; then
		indicators="${indicators}*" # Unstaged changes
	fi

	# Check for staged changes
	if ! git -C "$dir" diff --cached --quiet 2>/dev/null; then
		indicators="${indicators}+" # Staged changes
	fi

	# Check for untracked files
	if [ -n "$(git -C "$dir" ls-files --others --exclude-standard 2>/dev/null)" ]; then
		indicators="${indicators}?" # Untracked files
	fi

	# Check for stashed changes
	if git -C "$dir" rev-parse --verify refs/stash &>/dev/null 2>&1; then
		local stash_count
		stash_count=$(git -C "$dir" stash list 2>/dev/null | wc -l)
		if [ "$stash_count" -gt 0 ]; then
			indicators="${indicators}\$$stash_count" # Stashes
		fi
	fi

	# Check ahead/behind remote
	local upstream
	upstream=$(git -C "$dir" rev-parse --abbrev-ref @{upstream} 2>/dev/null)

	if [ -n "$upstream" ]; then
		local ahead behind
		ahead=$(git -C "$dir" rev-list --count @{upstream}..HEAD 2>/dev/null || echo "0")
		behind=$(git -C "$dir" rev-list --count HEAD..@{upstream} 2>/dev/null || echo "0")

		if [ "$ahead" -gt 0 ]; then
			indicators="${indicators}↑$ahead" # Ahead of remote
		fi

		if [ "$behind" -gt 0 ]; then
			indicators="${indicators}↓$behind" # Behind remote
		fi
	fi

	# Check for merge/rebase in progress
	local git_dir
	git_dir=$(git -C "$dir" rev-parse --git-dir 2>/dev/null)

	if [ -f "$git_dir/MERGE_HEAD" ]; then
		indicators="${indicators}|MERGE"
	elif [ -d "$git_dir/rebase-merge" ] || [ -d "$git_dir/rebase-apply" ]; then
		indicators="${indicators}|REBASE"
	elif [ -f "$git_dir/CHERRY_PICK_HEAD" ]; then
		indicators="${indicators}|CHERRY-PICK"
	elif [ -f "$git_dir/REVERT_HEAD" ]; then
		indicators="${indicators}|REVERT"
	fi

	# Output git status
	if [ -n "$indicators" ]; then
		printf " [%s %s]" "$branch" "$indicators"
	else
		printf " [%s]" "$branch"
	fi
}

# Build status line with full path and comprehensive git status
git_status=$(get_git_status "$cwd")
printf "%s%s" "$cwd" "$git_status"
