# Windows implementation

Read this reference when configuring, repairing, or packaging the Windows Codex desktop completion sound.

## Notification contract

Use the documented external `notify` callback for completion events. Require all of these payload fields:

- `type` equals `agent-turn-complete`
- `thread-id` is nonempty
- `turn-id` is nonempty

Official references:

- <https://learn.chatgpt.com/docs/config-file/config-advanced#notifications>
- <https://learn.chatgpt.com/docs/hooks>

Hooks and notifications are distinct paths. A valid hook configuration is not proof that the current desktop channel executes it.

## Files installed into the Codex home

Adapt and install these files next to `config.toml`:

- `task-complete-notify.ps1`
- `user_thread_filter.py`
- `task-complete.wav`, copied from the bundled `assets/default-coin.wav` unless the user selects a custom WAV

Keep the source skill unchanged. Stage machine-specific copies before installation.

The bundled default is an original code-synthesized coin sound. Do not make first-time setup depend on the user locating an audio file. A user-provided custom WAV remains optional.

## Configuration integration

Inspect the existing top-level `notify` array before editing it.

- If no notifier exists, point `notify` to Windows PowerShell with `-NoLogo`, `-NoProfile`, `-NonInteractive`, `-WindowStyle Hidden`, `-ExecutionPolicy Bypass`, and `-File <Codex home>\task-complete-notify.ps1`.
- If the Codex desktop native notifier already uses `codex-computer-use.exe turn-ended --previous-notify`, preserve the native command and replace only its nested previous-notify command with the PowerShell wrapper.
- If an unknown notifier exists, do not overwrite it silently. Explain the conflict and ask before replacing or composing it.

Never add duplicate `notify` keys. Parse the resulting TOML before installation.

## Main-task classification

Completion callbacks may also represent invisible helper threads. The included Python helper checks the newest readable `state_*.sqlite` files and accepts only a row whose `threads.thread_source` is `user`.

This database is an internal implementation detail, not a documented API. Therefore:

- Discover the database and required columns instead of hardcoding a versioned filename.
- Open it read-only with a short timeout.
- Fail closed when the database is missing, locked, changed, or inconclusive.
- Confirm one known user task returns exit code `0` and one known internal task returns exit code `3` before installation.

## Verification checklist

1. Validate the WAV independently with `System.Media.SoundPlayer`.
2. Parse the PowerShell file without executing it.
3. Compile the Python source without creating cache files.
4. Parse `config.toml` with a TOML parser.
5. Run the classifier against known user and internal thread IDs.
6. Send a fake internal `agent-turn-complete` payload and confirm it neither plays nor updates the deduplication state.
7. Finish one real user task and confirm exactly one sound.
8. Start or continue background work and confirm silence.

## Failure interpretation

- Manual WAV succeeds, callback absent: configuration or callback chain problem.
- Callback succeeds, classifier unavailable: state database or schema problem; remain silent.
- Internal fake event changes state: filtering is misplaced or bypassed.
- Same event plays twice: deduplication key, state path, or concurrent locking problem.
- Sound appears during a long task: a background thread was accepted; inspect its `thread_source` before changing event timing.
