#!/usr/bin/env python3
"""CLI callbacks -> a local Floatty inbox. Never writes to stdout or approves tools."""

import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile
import time


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


def clean(value, limit=200):
    return "".join(c for c in str(value or "") if c.isprintable())[:limit]


def remove_requests(root, env, session, key=None):
    for path in (root / "pending").glob("*.json"):
        try:
            event = json.loads(path.read_text())
            if (
                event.get("kind") == "permission_requested"
                and event.get("instance_id") == env["FLOATTY_INSTANCE_ID"]
                and event.get("term_id") == env["FLOATTY_TERM_ID"]
                and event.get("session_id") == session
                and (key is None or event.get("request_key") in (None, "", key))
            ):
                path.unlink(missing_ok=True)
        except (OSError, ValueError, AttributeError):
            pass


def main():
    mode = sys.argv[1]
    raw = sys.argv[2] if mode == "codex" and len(sys.argv) > 2 else sys.stdin.read()
    payload = json.loads(raw)
    env = os.environ
    required = ("FLOATTY_INSTANCE_ID", "FLOATTY_TERM_ID", "FLOATTY_EVENT_DIR")
    if not isinstance(payload, dict) or not all(env.get(key) for key in required):
        return
    root = Path(env["FLOATTY_EVENT_DIR"])
    session = clean(payload.get("session_id") or payload.get("thread-id") or payload.get("thread_id"))
    if mode == "codex":
        if payload.get("type") != "agent-turn-complete":
            return
        kind = "turn_finished"
    elif payload.get("hook_event_name") == "Stop":
        kind = "turn_finished"
    elif payload.get("hook_event_name") == "PermissionRequest":
        kind = "permission_requested"
    elif payload.get("hook_event_name") == "Notification" and payload.get("notification_type") == "permission_prompt":
        # Includes Claude sandbox-network approvals that bypass PermissionRequest.
        kind = "permission_requested"
    elif payload.get("hook_event_name") == "PostToolUse":
        remove_requests(root, env, session, digest([payload.get("tool_name"), payload.get("tool_input")]))
        return
    else:
        return

    if kind == "turn_finished":
        remove_requests(root, env, session)

    turn = payload.get("turn_id") or payload.get("turn-id")
    if kind == "permission_requested":
        # The official callback runs once per prompt; later identical prompts remain separate.
        identity = payload.get("tool_use_id") or time.time_ns()
    elif turn:
        identity = turn
    else:
        # Metadata only: no transcript or reply text is persisted.
        stamp = None
        transcript = payload.get("transcript_path")
        if transcript:
            try:
                stat = Path(transcript).stat()
                stamp = [stat.st_size, stat.st_mtime_ns]
            except OSError:
                pass
        reply = payload.get("last_assistant_message") or payload.get("last-assistant-message")
        identity = [stamp, digest(reply)] if stamp or reply else time.time_ns()

    event_id = digest([env["FLOATTY_TERM_ID"], session, kind, identity])
    event = {
        "kind": kind,
        "instance_id": env["FLOATTY_INSTANCE_ID"],
        "term_id": env["FLOATTY_TERM_ID"],
        "app_name": clean(env.get("FLOATTY_APP_NAME")),
        "session_id": session,
        "cwd": clean(payload.get("cwd") or env.get("FLOATTY_CWD"), 4096),
        "created_at": time.time(),
    }
    if kind == "permission_requested":
        event["tool"] = clean(payload.get("tool_name"), 80)
        event["request_key"] = (
            "" if payload.get("hook_event_name") == "Notification"
            else digest([payload.get("tool_name"), payload.get("tool_input")])
        )

    if (root / "claimed" / f"{event_id}.json").exists():
        return
    descriptor, temporary = tempfile.mkstemp(prefix=".event-", dir=root / "pending")
    try:
        with os.fdopen(descriptor, "w") as stream:
            json.dump(event, stream, ensure_ascii=False)
        # Hard-link publishes a complete file without overwriting a concurrent event.
        try:
            os.link(temporary, root / "pending" / f"{event_id}.json")
        except FileExistsError:
            pass
    finally:
        Path(temporary).unlink(missing_ok=True)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        # Notification failures must never interrupt the agent or emit hook decisions.
        pass
