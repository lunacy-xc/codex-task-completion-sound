# Default coin sound

`default-coin.wav` is the bundled sound used when a user installs Codex Coin Burst without choosing a custom WAV.

The sound is original and algorithmically synthesized by `../scripts/generate-default-coin.ps1`. It does not sample or reproduce audio from Dota 2, anime, or another commercial work.

The WAV and its generator are distributed under the repository's MIT License.

To reproduce the asset from the repository root on Windows:

```powershell
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\plugins\codex-task-completion-sound\skills\codex-task-completion-sound\scripts\generate-default-coin.ps1
```
