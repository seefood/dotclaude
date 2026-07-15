#!/usr/bin/env python3
"""
Fork-bomb watchdog for Claude Code.

Runs as a LaunchAgent (already in memory). Uses psutil C extension
(sysctl syscall, no fork) to enumerate processes, os.kill() (kill(2)
syscall, no fork) to terminate offenders. Never spawns child processes.
"""

import logging
import os
import signal
import time

import psutil

# Baseline on this machine is ~392 (Firefox plugin-containers, macOS helpers, etc.)
# Trigger on EITHER condition — whichever fires first:
#   1. Total user proc count spikes (general fork bomb)
#   2. node proc count spikes (Claude Code subagent storm specifically)
TOTAL_PROC_THRESHOLD = 600  # ~200 above observed baseline
NODE_PROC_THRESHOLD = 40  # normal claude session uses <10 node procs

# Don't re-trigger within this many seconds after a kill sweep.
COOLDOWN_SECONDS = 10
POLL_INTERVAL = 2

LOG_PATH = os.path.expanduser("~/.claude/watchdog.log")
TARGET_NAMES = {"node", "claude", "claude-code"}

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)

MY_UID = os.getuid()


def scan_processes() -> tuple[int, list[int]]:
    """Return (total_user_count, list_of_target_pids). Uses sysctl, no fork."""
    total = 0
    target_pids = []
    for proc in psutil.process_iter(["pid", "name", "uids"]):
        try:
            uids = proc.info["uids"]
            if not (uids and uids.real == MY_UID):
                continue
            total += 1
            if proc.info["name"] in TARGET_NAMES:
                target_pids.append(proc.info["pid"])
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass
    return total, target_pids


def kill_pids(pids: list[int]) -> int:
    """Send SIGTERM to a list of PIDs. Uses kill(2) syscall directly, no fork."""
    killed = 0
    for pid in pids:
        try:
            os.kill(pid, signal.SIGTERM)
            killed += 1
        except (ProcessLookupError, PermissionError):
            pass
    return killed


def main() -> None:
    logging.info(
        "Claude watchdog started (uid=%d, total_threshold=%d, node_threshold=%d)",
        MY_UID,
        TOTAL_PROC_THRESHOLD,
        NODE_PROC_THRESHOLD,
    )
    last_kill_time = 0.0

    while True:
        try:
            total, target_pids = scan_processes()
            node_count = len(target_pids)

            total_trigger = total > TOTAL_PROC_THRESHOLD
            node_trigger = node_count > NODE_PROC_THRESHOLD

            if total_trigger or node_trigger:
                now = time.monotonic()
                if now - last_kill_time > COOLDOWN_SECONDS:
                    reason = f"total={total}>{TOTAL_PROC_THRESHOLD}" if total_trigger else f"node={node_count}>{NODE_PROC_THRESHOLD}"
                    logging.warning("Fork bomb detected (%s). Killing %d targets.", reason, len(target_pids))
                    killed = kill_pids(target_pids)
                    logging.warning("Sent SIGTERM to %d processes.", killed)
                    last_kill_time = now

        except Exception as exc:
            logging.error("Watchdog error: %s", exc)

        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    main()
