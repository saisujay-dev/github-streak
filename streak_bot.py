#!/usr/bin/env python3
"""
GitHub Streak Bot
-----------------
Automatically commits to this repo every day to keep your GitHub streak alive.
• Always creates a dummy commit (streak log) so the streak is NEVER broken.
• Also stages & commits any real changes if they exist.
• Pushes everything to origin/main.

Usage (called by daily_commit.bat via Task Scheduler):
    python streak_bot.py
"""

import os
import sys
import subprocess
import json
import datetime
import random

# ── Config ──────────────────────────────────────────────────────────────────
STREAK_FILE   = "streak_log.json"
README_FILE   = "README.md"
COMMIT_PREFIX = "chore: daily streak"

# Fun motivational messages rotated each day
MESSAGES = [
    "🔥 Keeping the streak alive!",
    "💪 Another day, another commit.",
    "🚀 Consistency is key!",
    "⚡ Showing up every single day.",
    "🎯 Small steps, big progress.",
    "🌱 Growing day by day.",
    "✨ The streak continues!",
    "🏆 Champions commit daily.",
    "🦾 Grinding in silence.",
    "🌟 One commit at a time.",
]

# ── Helpers ──────────────────────────────────────────────────────────────────

def run(cmd: list[str], capture: bool = False) -> subprocess.CompletedProcess:
    """Run a shell command and return the result."""
    return subprocess.run(
        cmd,
        capture_output=capture,
        text=True,
        encoding="utf-8",
        errors="replace",
    )


def log(msg: str) -> None:
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    # Safe print: replace unencodable chars (emojis) for Windows console
    try:
        print(line)
    except UnicodeEncodeError:
        print(line.encode(sys.stdout.encoding or "utf-8", errors="replace").decode(sys.stdout.encoding or "utf-8"))
    with open("bot_run.log", "a", encoding="utf-8") as f:
        f.write(line + "\n")


def has_real_changes() -> bool:
    """Check if there are any uncommitted changes in the repo."""
    result = run(["git", "status", "--porcelain"], capture=True)
    return bool(result.stdout.strip())


def load_streak_data() -> dict:
    if os.path.exists(STREAK_FILE):
        with open(STREAK_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return {"streak": 0, "longest_streak": 0, "last_commit": None, "total_commits": 0, "history": []}


def save_streak_data(data: dict) -> None:
    with open(STREAK_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)


def update_streak(data: dict) -> dict:
    today = datetime.date.today().isoformat()
    last  = data.get("last_commit")

    if last == today:
        log("Already committed today — skipping streak update.")
        return data

    yesterday = (datetime.date.today() - datetime.timedelta(days=1)).isoformat()
    if last == yesterday:
        data["streak"] += 1
    else:
        data["streak"] = 1  # reset streak

    data["longest_streak"] = max(data["streak"], data.get("longest_streak", 0))
    data["last_commit"]     = today
    data["total_commits"]   = data.get("total_commits", 0) + 1
    data.setdefault("history", []).append(today)

    return data


def update_readme(data: dict) -> None:
    today   = datetime.date.today().isoformat()
    streak  = data["streak"]
    longest = data["longest_streak"]
    total   = data["total_commits"]
    bar     = "🟩" * min(streak, 30) + "⬜" * max(0, 30 - streak)

    readme = f"""# 🔥 GitHub Streak Bot

> Auto-maintained by **streak_bot.py** — committed every single day.

## 📊 Stats

| Metric | Value |
|--------|-------|
| 🔥 Current Streak | **{streak} days** |
| 🏆 Longest Streak | **{longest} days** |
| 📅 Total Commits | **{total}** |
| 📆 Last Commit | `{today}` |

## 🗓️ Streak Visualization (last 30 days)

{bar}

## 💬 Today's Message

> {random.choice(MESSAGES)}

---
*Last updated: {datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}*
"""
    with open(README_FILE, "w", encoding="utf-8") as f:
        f.write(readme)


def has_remote_origin() -> bool:
    res = run(["git", "remote"], capture=True)
    return "origin" in res.stdout.split()


# ── Main ─────────────────────────────────────────────────────────────────────

def main() -> None:
    log("=" * 50)
    log("GitHub Streak Bot started")

    repo_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(repo_dir)
    log(f"Working in: {repo_dir}")

    force = "--force" in sys.argv or "-f" in sys.argv

    # ── 1. Load streak data & update ─────────────────────────────────────
    data = load_streak_data()
    today = datetime.date.today().isoformat()

    if data.get("last_commit") == today and not force and not has_real_changes():
        log("Already ran today and no new changes — skipping to prevent duplicate commits.")
        log("Tip: Pass --force (or 'python streak_bot.py --force') to force a run.")
        sys.exit(0)

    if data.get("last_commit") != today or force:
        data = update_streak(data)

    # ── 2. Stage any real changes in the repo ────────────────────────────
    if has_real_changes():
        log("Real changes detected — staging them.")
        run(["git", "add", "-A"])

    # ── 3. Update the streak log files (always) ──────────────────────────
    save_streak_data(data)
    update_readme(data)
    run(["git", "add", STREAK_FILE, README_FILE])
    log("Streak log and README updated.")

    # ── 4. Commit ─────────────────────────────────────────────────────────
    msg = f"{COMMIT_PREFIX} [{today}] — {data['streak']} day streak"
    result = run(["git", "commit", "-m", msg])
    if result.returncode != 0:
        if not has_real_changes():
            log("Nothing new to commit.")
        else:
            log("ERROR: git commit failed.")
            sys.exit(1)
    else:
        log(f"Committed: {msg}")

    # ── 5. Push ───────────────────────────────────────────────────────────
    if not has_remote_origin():
        log("[INFO] No git remote 'origin' configured yet.")
        log("Commit has been recorded locally in C:\\github-streak.")
        log("To connect to GitHub:")
        log("  1. Create a repo at https://github.com/new (e.g. 'github-streak')")
        log("  2. In terminal run: cd C:\\github-streak && git remote add origin <your-repo-url>")
        log("  3. Run: git push -u origin main")
    else:
        log("Pushing to origin...")
        result = run(["git", "push", "origin", "main"])
        if result.returncode != 0:
            log("Push to 'main' failed, trying 'master'...")
            result = run(["git", "push", "origin", "master"])
            if result.returncode != 0:
                log("ERROR: Push failed! Commit is saved locally.")
                sys.exit(1)
            else:
                log("Pushed to origin/master successfully.")
        else:
            log("Pushed to origin/main successfully.")

    log(f"Done! Streak: {data['streak']} days | Longest: {data['longest_streak']} days")
    log("=" * 50)


if __name__ == "__main__":
    main()
