# Conversational sound service

Read this reference when the user wants to manage the completion sound through natural language.

## Intent mapping

Map the user's request to one action in `scripts/manage-sound.ps1`:

| User intent | Action | Source file required |
| --- | --- | --- |
| “现在用的什么声音？” / “查看状态” | `status` | No |
| “试听一下” / “播放当前声音” | `preview` | No |
| “换成这个声音” / “使用 C:\sounds\coin.wav” | `replace` | Yes |
| “换回刚才那个” / “恢复上一个” | `restore` | No |
| “暂时别响” / “关闭提示音” | `disable` | No |
| “重新开启声音” | `enable` | No |

If the intent is ambiguous, ask one short question. Do not present command syntax unless the user asks for it.

## Invocation

Run the script with Windows PowerShell and bypass only the process execution policy:

```powershell
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File <skill-path>\scripts\manage-sound.ps1 -Action status
```

For replacement, also pass `-SourcePath <absolute-wav-path>`. Use `-NoPreview` only when the user asks not to hear it immediately. Pass `-CodexHome` only when discovery is incorrect or the user selected a non-default Codex home.

The script returns compact JSON. Report the human meaning rather than dumping raw JSON.

## Replacement rules

- Accept only a local `.wav` file that `System.Media.SoundPlayer` can load.
- Resolve the exact source path before writing anything.
- The script backs up the active or disabled sound as `task-complete.previous.wav` before replacement.
- Replacement enables the new sound and previews it by default.
- If the user supplies MP3, OGG, AAC, or another format, explain that the callback needs WAV. Use an already-installed trusted converter only with the user's approval; do not silently install software.
- If the requested source is a commercial game or anime sound, do not search for or redistribute it. Accept a file supplied by the user or offer a legally usable alternative.

## Result messages

Keep confirmations concise and state what changed:

- Replaced: identify the source filename, confirm backup, and say whether preview succeeded.
- Restored: confirm the previous sound is active and the replaced sound remains available for another restore.
- Disabled: say completion detection remains installed but audio is paused.
- Enabled: say the stored sound is active again.
- Status: report active, disabled, or missing, plus the active filename when present.

If an action fails, do not claim partial success. Preserve the previous sound and report the exact user action needed next.
