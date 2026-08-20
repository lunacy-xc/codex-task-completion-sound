param(
    [Parameter(Position = 0)]
    [string] $PayloadJson
)

if ([string]::IsNullOrWhiteSpace($PayloadJson)) {
    exit 0
}

try {
    $notification = $PayloadJson | ConvertFrom-Json -ErrorAction Stop
    $eventType = [string]$notification.type
    $threadId = [string]$notification.'thread-id'
    $turnId = [string]$notification.'turn-id'
}
catch {
    exit 0
}

if ($eventType -ne 'agent-turn-complete' -or
    [string]::IsNullOrWhiteSpace($threadId) -or
    [string]::IsNullOrWhiteSpace($turnId)) {
    exit 0
}

$codexHome = if (-not [string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
    $env:CODEX_HOME
}
else {
    $PSScriptRoot
}

$filterScript = Join-Path $PSScriptRoot 'user_thread_filter.py'
$runtimePython = Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$pythonPath = $null

if (Test-Path -LiteralPath $runtimePython) {
    $pythonPath = $runtimePython
}
else {
    foreach ($candidate in @('python.exe', 'python3.exe')) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($null -ne $command) {
            $pythonPath = $command.Source
            break
        }
    }
}

if ([string]::IsNullOrWhiteSpace($pythonPath) -or
    -not (Test-Path -LiteralPath $filterScript)) {
    exit 0
}

& $pythonPath $filterScript --codex-home $codexHome --thread-id $threadId
if ($LASTEXITCODE -ne 0) {
    exit 0
}

$statePath = Join-Path $codexHome '.last-user-task-sound.json'
$eventKey = "${threadId}:${turnId}"
$mutex = [System.Threading.Mutex]::new($false, 'Local\CodexUserTaskCompletionSound')
$lockTaken = $false
$shouldPlay = $true

try {
    try {
        $lockTaken = $mutex.WaitOne(3000)
    }
    catch [System.Threading.AbandonedMutexException] {
        $lockTaken = $true
    }

    if (-not $lockTaken) {
        $shouldPlay = $false
    }
    else {
        $lastEventKey = $null
        if (Test-Path -LiteralPath $statePath) {
            try {
                $lastState = Get-Content -LiteralPath $statePath -Raw -ErrorAction Stop |
                    ConvertFrom-Json -ErrorAction Stop
                $lastEventKey = [string]$lastState.eventKey
            }
            catch {
                # Ignore damaged state and allow one clean recovery event.
            }
        }

        $shouldPlay = $eventKey -ne $lastEventKey
        if ($shouldPlay) {
            $state = [ordered]@{
                eventKey = $eventKey
                timestampMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
            }
            $stateJson = $state | ConvertTo-Json -Compress
            [System.IO.File]::WriteAllText(
                $statePath,
                $stateJson,
                [System.Text.UTF8Encoding]::new($false)
            )
        }
    }
}
finally {
    if ($lockTaken) {
        $mutex.ReleaseMutex()
    }
    $mutex.Dispose()
}

if (-not $shouldPlay) {
    exit 0
}

$soundPath = Join-Path $codexHome 'task-complete.wav'
if (Test-Path -LiteralPath $soundPath) {
    $player = New-Object System.Media.SoundPlayer $soundPath
    $player.PlaySync()
}
