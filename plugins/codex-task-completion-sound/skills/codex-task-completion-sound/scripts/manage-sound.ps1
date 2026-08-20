[CmdletBinding()]
param(
    [ValidateSet('status', 'preview', 'default', 'replace', 'restore', 'disable', 'enable')]
    [string] $Action = 'status',

    [string] $SourcePath,

    [string] $CodexHome,

    [switch] $NoPreview
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($CodexHome)) {
    if (-not [string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
        $CodexHome = $env:CODEX_HOME
    }
    else {
        $userProfilePath = [Environment]::GetFolderPath('UserProfile')
        $CodexHome = Join-Path $userProfilePath '.codex'
    }
}

$CodexHome = [System.IO.Path]::GetFullPath($CodexHome)
$activePath = Join-Path $CodexHome 'task-complete.wav'
$previousPath = Join-Path $CodexHome 'task-complete.previous.wav'
$disabledPath = Join-Path $CodexHome 'task-complete.disabled.wav'

function Test-PlayableWav {
    param([Parameter(Mandatory = $true)][string] $Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Sound file not found: $Path"
    }
    if ([System.IO.Path]::GetExtension($Path) -ine '.wav') {
        throw 'Only WAV files are supported.'
    }

    $player = New-Object System.Media.SoundPlayer $Path
    try {
        $player.Load()
    }
    finally {
        $player.Dispose()
    }
}

function Play-Wav {
    param([Parameter(Mandatory = $true)][string] $Path)

    Test-PlayableWav -Path $Path
    $player = New-Object System.Media.SoundPlayer $Path
    try {
        $player.PlaySync()
    }
    finally {
        $player.Dispose()
    }
}

function Get-SoundState {
    if (Test-Path -LiteralPath $activePath -PathType Leaf) {
        return 'active'
    }
    if (Test-Path -LiteralPath $disabledPath -PathType Leaf) {
        return 'disabled'
    }
    return 'missing'
}

function Write-ServiceResult {
    param(
        [Parameter(Mandatory = $true)][string] $ResultAction,
        [Parameter(Mandatory = $true)][string] $Message,
        [bool] $Previewed = $false
    )

    $state = Get-SoundState
    $selectedPath = if ($state -eq 'active') {
        $activePath
    }
    elseif ($state -eq 'disabled') {
        $disabledPath
    }
    else {
        $null
    }

    $result = [ordered]@{
        action = $ResultAction
        state = $state
        message = $Message
        soundPath = $selectedPath
        previousAvailable = Test-Path -LiteralPath $previousPath -PathType Leaf
        previewed = $Previewed
    }
    $result | ConvertTo-Json -Compress
}

function Install-ManagedSound {
    param(
        [Parameter(Mandatory = $true)][string] $ResolvedSource,
        [Parameter(Mandatory = $true)][string] $ResultAction,
        [Parameter(Mandatory = $true)][string] $Message
    )

    Test-PlayableWav -Path $ResolvedSource
    New-Item -ItemType Directory -Path $CodexHome -Force | Out-Null

    if (Test-Path -LiteralPath $activePath -PathType Leaf) {
        Copy-Item -LiteralPath $activePath -Destination $previousPath -Force
    }
    elseif (Test-Path -LiteralPath $disabledPath -PathType Leaf) {
        Copy-Item -LiteralPath $disabledPath -Destination $previousPath -Force
    }

    $temporaryPath = Join-Path $CodexHome ("task-complete.{0}.wav" -f [Guid]::NewGuid().ToString('N'))
    try {
        Copy-Item -LiteralPath $ResolvedSource -Destination $temporaryPath -Force
        Test-PlayableWav -Path $temporaryPath
        Move-Item -LiteralPath $temporaryPath -Destination $activePath -Force
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }

    if (Test-Path -LiteralPath $disabledPath -PathType Leaf) {
        Remove-Item -LiteralPath $disabledPath -Force
    }

    $previewed = $false
    if (-not $NoPreview) {
        Play-Wav -Path $activePath
        $previewed = $true
    }
    Write-ServiceResult -ResultAction $ResultAction -Message $Message -Previewed $previewed
}

switch ($Action) {
    'status' {
        Write-ServiceResult -ResultAction 'status' -Message "Sound state: $(Get-SoundState)."
        break
    }

    'preview' {
        $previewPath = if (Test-Path -LiteralPath $activePath -PathType Leaf) {
            $activePath
        }
        elseif (Test-Path -LiteralPath $disabledPath -PathType Leaf) {
            $disabledPath
        }
        else {
            throw 'No completion sound is available to preview.'
        }
        Play-Wav -Path $previewPath
        Write-ServiceResult -ResultAction 'preview' -Message 'Preview completed.' -Previewed $true
        break
    }

    'default' {
        $skillRoot = Split-Path -Parent $PSScriptRoot
        $defaultSource = Join-Path $skillRoot 'assets\default-coin.wav'
        $resolvedDefault = (Resolve-Path -LiteralPath $defaultSource -ErrorAction Stop).Path
        Install-ManagedSound -ResolvedSource $resolvedDefault -ResultAction 'default' -Message 'Bundled default coin sound activated.'
        break
    }

    'replace' {
        if ([string]::IsNullOrWhiteSpace($SourcePath)) {
            throw 'SourcePath is required for replacement.'
        }

        $resolvedSource = (Resolve-Path -LiteralPath $SourcePath -ErrorAction Stop).Path
        Install-ManagedSound -ResolvedSource $resolvedSource -ResultAction 'replace' -Message "Sound replaced from $resolvedSource."
        break
    }

    'restore' {
        if (-not (Test-Path -LiteralPath $previousPath -PathType Leaf)) {
            throw 'No previous completion sound is available.'
        }
        Test-PlayableWav -Path $previousPath

        $swapPath = Join-Path $CodexHome ("task-complete.swap.{0}.wav" -f [Guid]::NewGuid().ToString('N'))
        try {
            if (Test-Path -LiteralPath $activePath -PathType Leaf) {
                Copy-Item -LiteralPath $activePath -Destination $swapPath -Force
            }
            elseif (Test-Path -LiteralPath $disabledPath -PathType Leaf) {
                Copy-Item -LiteralPath $disabledPath -Destination $swapPath -Force
            }

            Copy-Item -LiteralPath $previousPath -Destination $activePath -Force
            if (Test-Path -LiteralPath $swapPath -PathType Leaf) {
                Move-Item -LiteralPath $swapPath -Destination $previousPath -Force
            }
        }
        finally {
            if (Test-Path -LiteralPath $swapPath) {
                Remove-Item -LiteralPath $swapPath -Force
            }
        }

        if (Test-Path -LiteralPath $disabledPath -PathType Leaf) {
            Remove-Item -LiteralPath $disabledPath -Force
        }

        $previewed = $false
        if (-not $NoPreview) {
            Play-Wav -Path $activePath
            $previewed = $true
        }
        Write-ServiceResult -ResultAction 'restore' -Message 'Previous sound restored.' -Previewed $previewed
        break
    }

    'disable' {
        if (Test-Path -LiteralPath $activePath -PathType Leaf) {
            Move-Item -LiteralPath $activePath -Destination $disabledPath -Force
            Write-ServiceResult -ResultAction 'disable' -Message 'Completion sound disabled.'
        }
        elseif (Test-Path -LiteralPath $disabledPath -PathType Leaf) {
            Write-ServiceResult -ResultAction 'disable' -Message 'Completion sound was already disabled.'
        }
        else {
            throw 'No completion sound is installed.'
        }
        break
    }

    'enable' {
        if (Test-Path -LiteralPath $activePath -PathType Leaf) {
            Write-ServiceResult -ResultAction 'enable' -Message 'Completion sound was already enabled.'
        }
        elseif (Test-Path -LiteralPath $disabledPath -PathType Leaf) {
            Move-Item -LiteralPath $disabledPath -Destination $activePath -Force
            Write-ServiceResult -ResultAction 'enable' -Message 'Completion sound enabled.'
        }
        else {
            throw 'No completion sound is installed.'
        }
        break
    }
}
