---
name: codex-task-completion-sound
description: Make Windows Codex burst a crisp default coin sound once when a user-owned main task finishes, or configure, troubleshoot, and conversationally replace that sound. Use for installing the default coin, choosing, previewing, replacing, restoring, disabling, or enabling completion audio; duplicate sounds; startup or mid-run alerts; notify filtering; or packaging this setup. Do not use for general Windows sounds or ordinary media playback.
---

# Codex Coin Burst · Codex 爆金币

Make Codex completion feel like collecting a coin, without treating invisible helper work as a finished user task.

## Default coin sound

Use [assets/default-coin.wav](assets/default-coin.wav) when the user asks to install the completion sound without providing another file, or explicitly asks for the default coin sound. It is an original code-synthesized asset distributed with this repository, not audio copied from a commercial game or anime.

During first-time setup, copy the bundled asset to `<Codex home>\task-complete.wav`. Do not require the user to find an audio file unless they request a custom sound.

## Conversational sound service

When the user asks to view, preview, replace, reset to the default coin, restore, disable, or enable the sound, read [references/conversational-sound-service.md](references/conversational-sound-service.md) and use [scripts/manage-sound.ps1](scripts/manage-sound.ps1). Interpret natural-language requests instead of requiring the user to know command syntax.

Keep the interaction short:

- If the action and source file are clear, perform the requested action and report the result.
- If a custom replacement is requested without a file, ask only for a local path or attachment. If the user asks for the default coin, use the bundled asset without asking for a file.
- Preview the new sound after replacement unless the user asks not to.
- An explicit request to replace, reset to default, restore, disable, or enable the sound authorizes that exact sound-file change. It does not authorize unrelated Codex configuration changes.
- Never download or redistribute copyrighted commercial game audio. The user may supply a file they have the right to use.

## Required outcome

- Play only for an exact `agent-turn-complete` notification.
- Accept only a user-owned main task; reject summaries, reviews, guardians, and subagents.
- Deduplicate by both `thread-id` and `turn-id`.
- Preserve Codex's existing native desktop notification chain.
- Never play merely because Codex starts, a tool returns, or background work finishes.
- Default to the bundled original coin sound. For custom audio, use a file the user owns or may legally use. Do not distribute commercial game audio with this skill.

## Workflow

1. Check the current official Codex notification documentation before changing configuration. Notification fields and supported configuration can change.
2. Inspect the current Codex home, `config.toml`, existing `notify` command, available Python runtime, sound file, and state database. Do not assume another machine matches the paths from a prior installation.
3. Read [references/windows-implementation.md](references/windows-implementation.md) before implementing, repairing, or packaging the Windows setup.
4. Reuse [scripts/task-complete-notify.ps1](scripts/task-complete-notify.ps1), [scripts/user_thread_filter.py](scripts/user_thread_filter.py), and the bundled [assets/default-coin.wav](assets/default-coin.wav). Stage adapted copies in a writable workspace before requesting permission to install them into the user's Codex home. Keep `manage-sound.ps1` inside the Skill and invoke it for later conversational management.
5. Back up the exact configuration and scripts that will be replaced. Preserve unrelated settings and any existing native notifier.
6. Validate the TOML, PowerShell syntax, Python syntax, thread classification, deduplication, and a fake internal-thread event before installation. Test the WAV separately only with the user's permission.
7. Install only after the user authorizes writes outside the workspace. Treat the next real main-task completion as the end-to-end test.

## Diagnostic rules

- If the WAV plays manually but no task alert occurs, verify whether the configured callback actually ran before changing audio code.
- If the sound fires during execution or twice, inspect the notification's thread identity. Do not weaken the event or deduplication checks.
- Treat internal state-database structure as implementation detail. Discover and validate the schema, and fail silently if reliable classification is unavailable.
- Do not assume a configured `Stop` or `PermissionRequest` hook executes. Prove hook execution with an isolated test before relying on it; otherwise use the documented completion notification path.
- When evidence is inconclusive, leave notifications silent and report the blocker rather than creating false alerts.
