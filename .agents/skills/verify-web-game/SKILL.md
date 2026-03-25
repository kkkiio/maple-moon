---
name: verify-web-game
description: Verify browser game behavior with Playwright replay artifacts (screenshots, text-state JSON, and error logs), with WebGPU-first checks and agent-driven pass/fail judgment. Use when validating game UI flows, interaction regressions, rendering mismatches, or release readiness for web games.
---

# Verify Web Game

Run reproducible game replays and judge outcomes from artifacts.

## Set Skill Paths Once

```bash
export PROJECT_ROOT="/Users/xieziheng/projects/maple-moon"
export VERIFY_WEB_GAME_HOME="$PROJECT_ROOT/.agents/skills/verify-web-game"
export WEB_GAME_CLIENT="$VERIFY_WEB_GAME_HOME/scripts/web_game_playwright_client.js"
export WEB_GAME_WEBGPU_PROBE="$VERIFY_WEB_GAME_HOME/scripts/check_playwright_webgpu.js"
export WEB_GAME_ACTIONS_TEMPLATE="$VERIFY_WEB_GAME_HOME/references/action_sequences.template.json"
```

## Required Game Hooks

Expose these browser globals before verification:

- `window.render_game_to_text(): string` returning concise JSON string.
- Prefer `window.advanceTime(ms)` for deterministic stepping.
- Provide stable clickable IDs through your console/debug API for reusable action sequences.

## WebGPU-First Precheck

Always check WebGPU in the same Playwright context before replay:

```bash
node "$WEB_GAME_WEBGPU_PROBE" --url http://127.0.0.1:8080 --headless 0
```

Then run headless precheck if needed:

```bash
node "$WEB_GAME_WEBGPU_PROBE" --url http://127.0.0.1:8080 --headless 1
```

Probe output includes `navigator_gpu`, `adapter_found`, `adapter_features`, `adapter_limits`.

If headed is `true` and headless is `false`, treat this as environment mismatch. Continue replay in headed mode and record that in the report.

## Replay Workflow

1. Start game server/dev server.
2. Prepare an action sequence JSON (copy from template).
3. Run replay client for each stage (`pre`, `post`, or more scenarios).
4. Open generated screenshots and verify visuals.
5. Compare `state-i.json` with screenshot content.
6. Check `errors-i.json`; fail on new `console.error` or `pageerror`.

Example:

```bash
node "$WEB_GAME_CLIENT" \
  --url http://127.0.0.1:8080 \
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

In the client script, one `i` means one replay loop (`for (let i = 0; i < iterations; i++)`).

## Agent Acceptance Standard

Declare **PASS** only when all are true:

1. Target screen is visibly correct in screenshot (not blank/black/wrong UI).
2. `state-last.json` confirms expected phase/state transition.
3. No new runtime error in `errors-last.json`.
4. Result is reproducible for at least 2 iterations.

If any condition fails, declare **FAIL**, point to exact artifact paths, apply minimal fix, and rerun.

## Reporting Format

Return a concise report containing:

1. Scenario and action file used.
2. WebGPU probe result (headed/headless).
3. Artifact evidence paths:
   - screenshot
   - state
   - error
4. PASS/FAIL verdict and reason.
5. Next minimal fix if failed.

## References

- Action templates: `references/action_sequences.template.json`
- Report template: `references/verification_report_template.md`
