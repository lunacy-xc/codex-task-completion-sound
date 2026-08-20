# Codex Coin Burst · Codex 爆金币 🪙

> Codex 完成任务，就清脆地爆一次金币。<br>
> Your Codex finishes the task. A crisp coin pops.

[中文](#中文) · [English](#english)

## 中文

### 这是什么？

**Codex Coin Burst（Codex 爆金币）**是一个面向 Windows Codex 的任务完成提示音 Skill 和 Plugin。

当你交给 Codex 的主任务真正完成时，它会播放一次内置的原创清脆金币声：像游戏里完成任务、拿到奖励一样。启动 Codex、任务运行中、后台摘要、自动检查和子任务结束时都不会乱响；同一个任务也不会重复爆金币。

一句话：**让你的 Codex 干完活就爆金币。**

### 核心特性

- 🪙 默认自带原创清脆金币音效，安装后无需自己寻找音频。
- ✅ 只在用户主任务真正结束时播放一次。
- 🤫 过滤启动、运行中工具调用、后台摘要、自动检查和子任务通知。
- 🔂 按任务和轮次去重，避免连续播放两次。
- 💬 支持对话式试听、更换、恢复、暂停和重新开启。
- 🔔 保留 Codex 原有桌面通知链，不抢占原生提醒。

### 30 秒安装

在 PowerShell 中运行：

```powershell
codex plugin marketplace add lunacy-xc/codex-task-completion-sound --ref main
```

重启 Codex，打开 Plugins Directory（插件目录），选择 **Codex Coin Burst · 爆金币** 并安装。然后开启一个新任务并说：

```text
使用 $codex-task-completion-sound 安装默认爆金币提示音
```

Skill 会检查当前 Codex 通知配置，保留原有通知器，先验证再请求你的授权，将完成提醒安装到用户配置目录。第一次真正完成主任务时，你就会听到金币声。

### 直接用对话管理音效

```text
试听默认金币声
把提示音换成 C:\sounds\my-coin.wav
换回默认金币声
恢复上一个提示音
暂时关闭爆金币
重新开启爆金币
```

自定义音效目前使用本地 WAV 文件。更换前会验证文件并备份当前音效，失败时不会破坏原来的声音。

### 它如何避免乱响？

一次声音必须同时通过三道门：

1. 通知事件必须是 `agent-turn-complete`。
2. 任务必须属于用户发起的主任务。
3. 当前 `thread-id` 和 `turn-id` 组合尚未播放过。

无法可靠判断时，它会保持安静，而不是制造误报。

### 默认金币声与版权

仓库内的 `default-coin.wav` 是为本项目通过代码原创合成的声音，可随本仓库的 MIT License 使用和分发。它不是 Dota 2、动漫或其他商业作品的音频。

你可以换成自己拥有或获准使用的 WAV，但请不要重新分发无授权的商业游戏音效。

### 支持环境

- Windows 10 或 Windows 11
- ChatGPT 桌面版中的 Codex，或支持外部通知的 Codex CLI
- Windows PowerShell
- Python 3.10 或更新版本；支持 Codex 自带的 Python 运行时

---

## English

### What is it?

**Codex Coin Burst** is a Windows Codex Skill and Plugin that turns task completion into a tiny coin reward.

When your user-owned main task actually finishes, Codex plays one bundled, original, crisp coin sound. It stays silent when Codex starts, while tools are running, and when background summaries, automatic reviews, or subagents finish. The same turn cannot trigger the coin twice.

In one line: **make your Codex burst a coin when the work is done.**

### Highlights

- 🪙 Includes an original crisp coin sound by default—no audio hunt required.
- ✅ Plays once only when a user-owned main task finishes.
- 🤫 Filters startup, tool activity, background summaries, automatic reviews, and subagent completions.
- 🔂 Deduplicates by task and turn to prevent double playback.
- 💬 Lets you preview, replace, restore, disable, or enable the sound in conversation.
- 🔔 Preserves the existing native Codex desktop notification chain.

### Install in 30 seconds

Run in PowerShell:

```powershell
codex plugin marketplace add lunacy-xc/codex-task-completion-sound --ref main
```

Restart Codex, open the Plugins Directory, select **Codex Coin Burst · 爆金币**, and install it. Then start a new task and say:

```text
Use $codex-task-completion-sound to install the default coin completion sound.
```

The Skill inspects your current Codex notification setup, preserves the existing notifier, validates the installation, and asks before writing to your user configuration directory. The next real main-task completion is the end-to-end test.

### Manage it in conversation

```text
Preview the default coin sound.
Replace my completion sound with C:\sounds\my-coin.wav.
Switch back to the default coin sound.
Restore the previous sound.
Disable coin bursts for now.
Enable coin bursts again.
```

Custom sounds currently use local WAV files. A replacement is validated and the active sound is backed up before anything changes.

### How false alerts are prevented

A sound must pass three gates:

1. The event is exactly `agent-turn-complete`.
2. The task is a user-owned main task.
3. The `thread-id` and `turn-id` pair has not already played.

If classification is inconclusive, the notifier fails closed and stays silent.

### Default sound and licensing

The bundled `default-coin.wav` is an original, code-synthesized sound created for this project and distributed under the repository's MIT License. It is not audio from Dota 2, anime, or another commercial work.

You may replace it with a WAV you own or are allowed to use. Do not redistribute copyrighted commercial audio without permission.

### Requirements

- Windows 10 or Windows 11
- Codex in the ChatGPT desktop app, or Codex CLI with external notifications
- Windows PowerShell
- Python 3.10 or newer; the bundled Codex Python runtime is supported

---

## Repository layout

```text
.agents/plugins/marketplace.json
plugins/codex-task-completion-sound/
  .codex-plugin/plugin.json
  skills/codex-task-completion-sound/
    SKILL.md
    agents/openai.yaml
    assets/default-coin.wav
    assets/README.md
    references/windows-implementation.md
    references/conversational-sound-service.md
    scripts/generate-default-coin.ps1
    scripts/manage-sound.ps1
    scripts/task-complete-notify.ps1
    scripts/user_thread_filter.py
```

## License

MIT. See [LICENSE](LICENSE).
