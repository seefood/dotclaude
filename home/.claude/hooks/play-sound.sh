#!/bin/bash
set -e

# Get command line argument for sound type
sound_type="${1:-default}"

# Get platform-specific sound command and file
get_sound_config() {
	local type="${1:-default}"
	local platform
	platform="$(uname -s)"

	case "${platform}" in
	Darwin)
		# macOS
		case "${type}" in
		notification)
			echo "afplay" "/System/Library/Sounds/Blow.aiff"
			;;
		done)
			echo "afplay" "/System/Library/Sounds/Frog.aiff"
			;;
		*)
			echo "afplay" "/System/Library/Sounds/Funk.aiff"
			;;
		esac
		;;
	Linux)
		# Try multiple Linux sound players in order of preference
		local cmd=""
		if hash paplay 2>/dev/null; then
			cmd="paplay"
		elif hash aplay 2>/dev/null; then
			cmd="aplay"
		elif hash play 2>/dev/null; then
			cmd="play"
		else
			return 1
		fi

		case "${type}" in
		notification)
			echo "${cmd}" "/usr/share/sounds/freedesktop/stereo/message.oga"
			;;
		done)
			echo "${cmd}" "/usr/share/sounds/freedesktop/stereo/service-logout.oga"
			;;
		*)
			echo "${cmd}" "/usr/share/sounds/freedesktop/stereo/message-new-instant.oga"
			;;
		esac
		;;
	MINGW* | MSYS* | CYGWIN*)
		# Windows
		case "${type}" in
		notification)
			echo "powershell" "-c (New-Object Media.SoundPlayer 'C:\\Windows\\Media\\Windows Notify.wav').PlaySync()"
			;;
		done)
			echo "powershell" "-c (New-Object Media.SoundPlayer 'C:\\Windows\\Media\\Windows Ding.wav').PlaySync()"
			;;
		*)
			echo "powershell" "-c (New-Object Media.SoundPlayer 'C:\\Windows\\Media\\tada.wav').PlaySync()"
			;;
		esac
		;;
	*)
		[[ -n "${DEBUG}" ]] && echo "Unsupported platform: ${platform}" >&2
		return 1
		;;
	esac
}

# Play the sound with error handling
play_sound() {
	local config
	local output
	output="$(get_sound_config "${sound_type}")" || {
		[[ -n "${DEBUG}" ]] && echo "Failed to get sound config" >&2
		return 0 # Silent fail
	}
	# shellcheck disable=SC2206
	config=($output)

	local cmd="${config[0]}"
	local sound_file="${config[1]}"

	# Check if sound file exists (skip for Windows PowerShell commands)
	if [[ -n "${sound_file}" ]] && [[ "${sound_file}" != "-c" ]] && [[ ! -f "${sound_file}" ]]; then
		[[ -n "${DEBUG}" ]] && echo "Sound file not found: ${sound_file}" >&2
		return 0 # Silent fail
	fi

	# Execute the command
	if [[ -n "${sound_file}" ]] && [[ "${sound_file}" != "-c" ]]; then
		"${cmd}" "${sound_file}" 2>/dev/null || {
			[[ -n "${DEBUG}" ]] && echo "Sound playback failed" >&2
			return 0 # Silent fail
		}
	else
		# For Windows PowerShell commands
		"${cmd}" "${sound_file}" "${config[@]:2}" 2>/dev/null || {
			[[ -n "${DEBUG}" ]] && echo "Sound playback failed" >&2
			return 0 # Silent fail
		}
	fi
}

# Execute with error handling
play_sound || exit 0 # Always exit successfully to not interrupt workflow
