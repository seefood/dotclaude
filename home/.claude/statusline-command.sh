#!/usr/bin/env bash
# Claude Code status line
# ~/path [branch #42 *+↑2] | ctx:45% (90k / 100k▶cmp) | 5h:67% ↺20:00 | 7d:23% | 30d:45%

input=$(cat)
parts=()

# Format a raw token count as Xk or X.Xm
fmt_k() {
	local n=$1
	if ((n >= 1000000)); then
		awk -v n="$n" 'BEGIN{printf "%.1fm", n/1000000}'
	elif ((n >= 1000)); then
		printf '%dk' $((n / 1000))
	else
		printf '%d' "$n"
	fi
}

# --- CWD + git status ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')

if [[ -n "$cwd" ]]; then
	display_dir="${cwd/#$HOME/\~}"
	git_part=""

	if git -C "$cwd" rev-parse --git-dir &>/dev/null 2>&1; then
		export GIT_OPTIONAL_LOCKS=0

		branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null ||
			git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
		indicators=""

		git -C "$cwd" diff --quiet 2>/dev/null || indicators+="*"
		git -C "$cwd" diff --cached --quiet 2>/dev/null || indicators+="+"

		untracked=$(git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null)
		[[ -n "$untracked" ]] && indicators+="?"

		stash_n=$(git -C "$cwd" stash list 2>/dev/null | wc -l)
		((stash_n > 0)) && indicators+="\$${stash_n}"

		upstream=$(git -C "$cwd" rev-parse --abbrev-ref "@{upstream}" 2>/dev/null)
		if [[ -n "$upstream" ]]; then
			ahead=$(git -C "$cwd" rev-list --count "@{upstream}..HEAD" 2>/dev/null || echo 0)
			behind=$(git -C "$cwd" rev-list --count "HEAD..@{upstream}" 2>/dev/null || echo 0)
			((ahead > 0)) && indicators+="↑${ahead}"
			((behind > 0)) && indicators+="↓${behind}"
		fi

		git_dir=$(git -C "$cwd" rev-parse --git-dir 2>/dev/null)
		if [[ -f "$git_dir/MERGE_HEAD" ]]; then
			indicators+="|MERGE"
		elif [[ -d "$git_dir/rebase-merge" || -d "$git_dir/rebase-apply" ]]; then
			indicators+="|REBASE"
		elif [[ -f "$git_dir/CHERRY_PICK_HEAD" ]]; then
			indicators+="|CHERRY"
		elif [[ -f "$git_dir/REVERT_HEAD" ]]; then
			indicators+="|REVERT"
		fi

		# PR number via gh (fast; uses local cache)
		pr_num=""
		if [[ "$branch" != "master" && "$branch" != "main" ]]; then
			pr_num=$(cd "$cwd" && timeout 2 gh pr view --json number -q '.number' 2>/dev/null)
		fi

		label="${branch}"
		[[ -n "$pr_num" ]] && label+=" #${pr_num}"
		if [[ -n "$indicators" ]]; then
			git_part=" [${label} ${indicators}]"
		else
			git_part=" [${label}]"
		fi
	fi

	parts+=("${display_dir}${git_part}")
fi

# --- Context window ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
win_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

if [[ -n "$used_pct" && -n "$win_size" && "$win_size" -gt 0 ]]; then
	used_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')

	# Auto-compact threshold: explicit env var or 95% of window
	compact_at="${CLAUDE_CODE_AUTO_COMPACT_WINDOW:-}"
	if [[ -z "$compact_at" || "$compact_at" -le 0 ]]; then
		compact_at=$((win_size * 95 / 100))
	fi

	pct_str=$(printf '%.0f' "$used_pct")
	used_str=$(fmt_k "$used_tokens")
	remaining=$((compact_at - used_tokens))
	if [[ "$remaining" -le 0 ]]; then
		cmp_str="▶cmp!"
	else
		cmp_str="$(fmt_k "$remaining")▶cmp"
	fi

	parts+=("ctx:${pct_str}% (${used_str} / ${cmp_str})")
fi

# --- 5h rate limit + next window start ---
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')

if [[ -n "$five_pct" ]]; then
	five_used=$(printf '%.0f' "$five_pct")

	next_window=$(
		python3 - <<'PYEOF'
import datetime
now = datetime.datetime.now(datetime.timezone.utc)
next_h = (now.hour // 5 + 1) * 5
if next_h >= 24:
    d = (now + datetime.timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)
else:
    d = now.replace(hour=next_h, minute=0, second=0, microsecond=0)
print(datetime.datetime.fromtimestamp(d.timestamp()).strftime('%H:%M'))
PYEOF
	)
	part="5h:${five_used}%"
	[[ -n "$next_window" ]] && part+=" ↺${next_window}"
	parts+=("$part")
fi

# --- 7-day rate limit ---
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
[[ -n "$week_pct" ]] && parts+=("7d:$(printf '%.0f' "$week_pct")%")

# --- Monthly rate limit (present on some plans) ---
month_pct=$(echo "$input" | jq -r '.rate_limits.monthly.used_percentage // empty')
[[ -n "$month_pct" ]] && parts+=("30d:$(printf '%.0f' "$month_pct")%")

# --- Assemble ---
if [[ "${#parts[@]}" -gt 0 ]]; then
	printf '%s' "${parts[0]}"
	for ((i = 1; i < ${#parts[@]}; i++)); do
		printf ' | %s' "${parts[$i]}"
	done
	printf '\n'
fi
