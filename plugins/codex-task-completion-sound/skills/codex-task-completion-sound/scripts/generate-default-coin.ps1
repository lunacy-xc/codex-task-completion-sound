[CmdletBinding()]
param(
    [string] $OutputPath,
    [ValidateRange(8000, 192000)]
    [int] $SampleRate = 44100
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $skillRoot = Split-Path -Parent $PSScriptRoot
    $OutputPath = Join-Path $skillRoot 'assets\default-coin.wav'
}

$OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
$outputDirectory = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

$durationSeconds = 0.48
$sampleCount = [int][Math]::Ceiling($durationSeconds * $SampleRate)
$samples = New-Object 'double[]' $sampleCount
$maximum = 0.0
$twoPi = 2.0 * [Math]::PI

for ($index = 0; $index -lt $sampleCount; $index++) {
    $time = $index / [double]$SampleRate

    $firstAttack = [Math]::Min(1.0, $time / 0.0025)
    $firstEnvelope = $firstAttack * [Math]::Exp(-13.5 * $time)
    $firstTone = (
        0.66 * [Math]::Sin($twoPi * 1318.51 * $time) +
        0.24 * [Math]::Sin($twoPi * 1975.53 * $time) +
        0.10 * [Math]::Sin($twoPi * 2637.02 * $time)
    ) * $firstEnvelope

    $secondTone = 0.0
    $secondStart = 0.078
    if ($time -ge $secondStart) {
        $localTime = $time - $secondStart
        $secondAttack = [Math]::Min(1.0, $localTime / 0.002)
        $secondEnvelope = $secondAttack * [Math]::Exp(-11.8 * $localTime)
        $secondTone = (
            0.62 * [Math]::Sin($twoPi * 1760.00 * $localTime) +
            0.25 * [Math]::Sin($twoPi * 2637.02 * $localTime) +
            0.13 * [Math]::Sin($twoPi * 3520.00 * $localTime)
        ) * $secondEnvelope
    }

    $sparkle = 0.0
    if ($time -lt 0.024) {
        $sparkle = 0.16 * [Math]::Sin($twoPi * 6200.0 * $time) * [Math]::Exp(-145.0 * $time)
    }

    $sample = (0.46 * $firstTone) + (0.66 * $secondTone) + $sparkle
    $samples[$index] = $sample
    $absolute = [Math]::Abs($sample)
    if ($absolute -gt $maximum) {
        $maximum = $absolute
    }
}

if ($maximum -le 0.0) {
    throw 'Generated audio was silent.'
}

$channelCount = 1
$bitsPerSample = 16
$bytesPerSample = $bitsPerSample / 8
$byteRate = $SampleRate * $channelCount * $bytesPerSample
$blockAlign = $channelCount * $bytesPerSample
$dataSize = $sampleCount * $bytesPerSample
$riffSize = 36 + $dataSize
$scale = 0.84 * [int16]::MaxValue / $maximum

$stream = [System.IO.File]::Open($OutputPath, [System.IO.FileMode]::Create)
$writer = New-Object System.IO.BinaryWriter $stream
try {
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes('RIFF'))
    $writer.Write([int]$riffSize)
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes('WAVE'))
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes('fmt '))
    $writer.Write([int]16)
    $writer.Write([int16]1)
    $writer.Write([int16]$channelCount)
    $writer.Write([int]$SampleRate)
    $writer.Write([int]$byteRate)
    $writer.Write([int16]$blockAlign)
    $writer.Write([int16]$bitsPerSample)
    $writer.Write([System.Text.Encoding]::ASCII.GetBytes('data'))
    $writer.Write([int]$dataSize)

    foreach ($sample in $samples) {
        $pcm = [int16][Math]::Round($sample * $scale)
        $writer.Write($pcm)
    }
}
finally {
    $writer.Dispose()
    $stream.Dispose()
}

$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $OutputPath).Hash.ToLowerInvariant()
[ordered]@{
    outputPath = $OutputPath
    durationSeconds = $durationSeconds
    sampleRate = $SampleRate
    channels = $channelCount
    bitsPerSample = $bitsPerSample
    sha256 = $hash
} | ConvertTo-Json -Compress
