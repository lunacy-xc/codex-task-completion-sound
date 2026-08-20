# Codex Task Completion Sound

A Windows Codex Skill and Plugin that plays one completion sound only when a user-owned main task finishes, with conversational sound replacement and rollback.

It filters completion events from background summaries, automatic reviews, guardians, and subagents, and deduplicates repeated callbacks from the same turn.

## Why this exists

Long Codex tasks may finish while you are looking elsewhere. A normal completion callback can also fire for invisible helper work, which creates sounds at startup, during execution, or more than once. This workflow adds three gates:

1. Require the exact `agent-turn-complete` event.
2. Accept only a user-owned task thread.
3. Deduplicate by `thread-id` and `turn-id`.

## Install from GitHub

Add this repository as a Codex marketplace:

```powershell
codex plugin marketplace add lunacy-xc/codex-task-completion-sound
```

Install the plugin:

```powershell
codex plugin add codex-task-completion-sound@codex-task-completion-sound
```

Start a new Codex task and invoke:

```text
$codex-task-completion-sound
```

Provide a local PCM WAV file that you own or are permitted to use. The Skill will inspect the current Codex configuration, preserve the native desktop notifier, stage and validate machine-specific files, and ask before writing to the user configuration directory.

After setup, manage the sound in ordinary conversation. For example:

```text
预览当前音效
把提示音换成 C:\sounds\coin.wav
恢复上一个音效
暂时关闭完成提示音
重新开启提示音
```

The Skill validates the WAV, backs up the current sound, applies the change atomically, previews the replacement, and can restore the previous sound.

## What is included

- A focused `SKILL.md` workflow.
- A PowerShell completion callback.
- A conversational sound manager for status, preview, replacement, restore, disable, and enable actions.
- A read-only Python classifier for user-owned versus internal tasks.
- Windows implementation and verification guidance.
- A Codex Plugin manifest and repository marketplace entry.

## Privacy and safety

- No sound file is included.
- No Dota 2 or other commercial game asset is redistributed.
- The classifier reads Codex's local state database in read-only mode.
- Classification fails closed: when the task source cannot be verified, it stays silent.
- The Skill requires approval before changing files outside the active workspace.

## Platform

- Windows 10 or Windows 11
- Codex desktop or Codex CLI with external notifications
- Windows PowerShell
- Python 3.10 or newer; the Codex bundled Python runtime is supported

## Repository layout

```text
.agents/plugins/marketplace.json
plugins/codex-task-completion-sound/
  .codex-plugin/plugin.json
  skills/codex-task-completion-sound/
    SKILL.md
    agents/openai.yaml
    references/windows-implementation.md
    references/conversational-sound-service.md
    scripts/manage-sound.ps1
    scripts/task-complete-notify.ps1
    scripts/user_thread_filter.py
```

## License

MIT. Audio files remain subject to their own licenses and are intentionally excluded.

---

## 中文说明

这是一个面向 Windows Codex 的任务完成提示音 Skill/Plugin。它只在用户可见的主任务真正结束时播放一次声音，并过滤后台摘要、自动检查和子任务通知。安装后可直接通过对话完成试听、更换、恢复、暂停和重新开启。

安装后，在新的 Codex 任务中调用 `$codex-task-completion-sound`，再提供一个你有权使用的 PCM WAV 文件即可。仓库不会附带 Dota 2 或其他商业游戏音效。
