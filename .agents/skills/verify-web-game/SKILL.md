---
name: verify-web-game
description: Verify browser game behavior with Playwright replay artifacts (screenshots, text-state JSON, and error logs), with WebGPU-first checks and agent-driven pass/fail judgment. Use when validating game UI flows, interaction regressions, rendering mismatches, or release readiness for web games.
---

# Verify Web Game

Run reproducible game replays and judge outcomes from artifacts.

## Set Skill Paths Once

```bash
export VERIFY_WEB_GAME_HOME="$PROJECT_ROOT/.agents/skills/verify-web-game"
export WEB_GAME_CLIENT="$VERIFY_WEB_GAME_HOME/scripts/web_game_playwright_client.js"
export WEB_GAME_ACTIONS_TEMPLATE="$VERIFY_WEB_GAME_HOME/references/action_sequences.template.json"
```

## Required Game Hooks

Expose these browser globals before verification:

- `window.render_game_to_text(): string` returning concise JSON string.
- Prefer `window.advanceTime(ms)` for deterministic stepping.
- Provide stable clickable IDs through your console/debug API for reusable action sequences.

## Replay Workflow

1. Start game server/dev server.
2. Prepare an action sequence JSON (copy from template).
3. Reuse one stable `--profile-dir` across related runs (`pre`/`post`/rerun) for the same scenario; do not create a fresh profile each time unless intentionally testing first-run state.
4. Prefer console ID clicks (`console_ui_click`) over raw pixel click to reduce flakiness.
5. Insert explicit waits (`wait_ui`, `wait_state`) between key actions; do not assume one click immediately reaches next phase.
6. Check both runtime errors and network errors (`bad-responses-*.json`).
7. If a run times out, inspect `action-trace-*.json` first to find the exact failed step.
8. For map-entity validation (NPC/Mob), prefer `console_cmd("temp_set_field_enter", mapId, portalId)` as the entry action.
9. Run replay client for each stage (`pre`, `post`, or more scenarios).
10. Keep replay bounded with `wait_state(max_frames=...)`; never wait without timeout.
11. Open generated screenshots and verify visuals.
12. Compare `state-i.json` with screenshot content.
13. Check `errors-i.json`; fail on new `console.error` or `pageerror`.

Example:

```bash
node "$WEB_GAME_CLIENT" \
  --url http://127.0.0.1:8080 \
  --profile-dir ./output/web-game/profile/default \
  --actions-file ./tmp/create-character-actions.json \
  --iterations 2 \
  --pause-ms 350 \
  --headless 0 \
  --screenshot-dir ./output/web-game/create-character/post
```

Each iteration generates:

- `shot-i.png`
- `state-i.json` (when `render_game_to_text` exists)
- `errors-i.json` (when errors appear)
- `bad-responses-i.json` (when HTTP >= 400 occurs)
- `action-trace-i.json` (executed steps with click/wait results)

In the client script, one `i` means one replay loop (`for (let i = 0; i < iterations; i++)`).

## Action DSL (Recommended)

In addition to legacy `{ buttons, frames }`, script now supports:

- `{ "type": "console_ui_click", "package": "select_char", "name": "new_character", "step_frames": 8 }`
- `{ "type": "console_cmd", "name": "temp_set_field_enter", "args": ["103000000", "0"], "expected_code": "SET_FIELD_SENT", "step_frames": 12 }`
- `{ "type": "wait_ui", "package": "explorer_creation", "name": "gender_male", "max_frames": 1200, "step_frames": 10 }`
- `{ "type": "wait_state", "path": "phase", "equals": "ExplorerCharacterCreation", "max_frames": 1800 }`
- `{ "type": "wait_state", "path": "explorer_creation.stage.0", "equals": "ConfirmingName" }`
- `{ "type": "console_step", "frames": 30 }`
- `{ "type": "sleep", "ms": 300 }`

`console_ui_click` defaults to strict mode: if click result is not `QUEUED`, replay fails immediately.
`console_cmd` also defaults to strict mode: if `result.ok == false` or `expected_code` mismatch, replay fails immediately.

`temp_set_field_enter` note:
- This command is registered by `local_server` (not select_char_ui).
- It triggers server-side `SET_FIELD` and map spawn chain, so it is suitable for NPC visibility verification.

## Debug Heuristics

When chain fails, prioritize these checks:

1. `action-trace-*.json`: did click return `QUEUED`? did `wait_state` timeout?
2. `state-*.json`: did phase/stage actually advance?
3. `errors-*.json`:
   - `Missing field ...` usually means client/server proto mismatch.
   - `invalid '#'-framed syntax ... set offset` usually means resource not reanimated to `__off`.
4. `bad-responses-*.json`: repeated 404 usually indicates missing/misaligned assets path.

## Agent Acceptance Standard

Declare **PASS** only when all are true:

1. Target screen is visibly correct in screenshot (not blank/black/wrong UI).
2. `state-last.json` confirms expected phase/state transition.
3. No new runtime error in `errors-last.json`.
4. Result is reproducible for at least 2 iterations.
5. For NPC scenarios, at least one NPC is visible in `shot-last.png`.

If any condition fails, declare **FAIL**, point to exact artifact paths, apply minimal fix, and rerun.

## Reporting Format

Return a concise report containing:

1. Scenario and action file used.
2. Artifact evidence paths:
   - screenshot
   - state
   - error
3. PASS/FAIL verdict and reason.
4. Next minimal fix if failed.

## References

- Action templates: `references/action_sequences.template.json`
- Report template: `references/verification_report_template.md`
