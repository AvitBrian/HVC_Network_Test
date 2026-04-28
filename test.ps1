param(
    [ValidateRange(1, 100)]
    [int]$RunCount = 3
)

$ErrorActionPreference = 'Stop'

function Require-Command {
    param([string]$Name)

    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $command -or $command.CommandType -ne 'Application') {
        throw "Required command '$Name' is not installed or is not an external executable."
    }
}

function Write-StatsLine {
    param(
        [string]$Label,
        [object[]]$Data,
        [string]$Property,
        [string]$Unit
    )

    $average = ($Data | Measure-Object -Property $Property -Average).Average
    $minimum = ($Data | Measure-Object -Property $Property -Minimum).Minimum
    $maximum = ($Data | Measure-Object -Property $Property -Maximum).Maximum

    Write-Host ("{0} avg/min/max: {1:N2} / {2:N2} / {3:N2} {4}" -f $Label, $average, $minimum, $maximum, $Unit)
}

Require-Command speedtest

Write-Host "=== HVC NETWORK TEST ==="
Write-Host ""
Write-Host ("Running official Ookla Speedtest CLI ({0} run(s))..." -f $RunCount)
Write-Host ""

$runs = @()

for ($run = 1; $run -le $RunCount; $run++) {
    try {
        $jsonOutput = speedtest --accept-license --accept-gdpr --format=json
        $result = $jsonOutput | ConvertFrom-Json

        if (
            $null -eq $result.download -or
            $null -eq $result.upload -or
            $null -eq $result.ping -or
            $null -eq $result.download.bandwidth -or
            $null -eq $result.upload.bandwidth -or
            $null -eq $result.ping.latency -or
            $null -eq $result.ping.jitter
        ) {
            throw "Speedtest did not return a valid result payload."
        }
    }
    catch {
        Write-Host ("[Run {0}/{1}] failed: {2}" -f $run, $RunCount, $_.Exception.Message)
        Write-Host ""
        continue
    }

    $downloadMbps = [double]$result.download.bandwidth * 8 / 1000000
    $uploadMbps = [double]$result.upload.bandwidth * 8 / 1000000
    $latencyMs = [double]$result.ping.latency
    $jitterMs = [double]$result.ping.jitter
    $packetLossValue = if ($null -eq $result.packetLoss) { $null } else { [double]$result.packetLoss }
    $packetLossDisplay = if ($null -eq $packetLossValue) { 'N/A' } else { '{0}%' -f $packetLossValue }
    $serverName = if ($result.server.name) { $result.server.name } else { 'Unknown' }
    $serverLocation = if ($result.server.location) { $result.server.location } else { 'Unknown' }
    $serverCountry = if ($result.server.country) { $result.server.country } else { 'Unknown' }
    $resultUrl = if ($result.result.url) { $result.result.url } else { 'N/A' }
    $timestamp = if ($result.timestamp) { $result.timestamp } else { 'N/A' }

    $runs += [pscustomobject]@{
        DownloadMbps = $downloadMbps
        UploadMbps = $uploadMbps
        LatencyMs = $latencyMs
        JitterMs = $jitterMs
        PacketLoss = $packetLossValue
    }

    Write-Host ("[Run {0}/{1}]" -f $run, $RunCount)
    Write-Host ("Timestamp: {0}" -f $timestamp)
    Write-Host ("Server: {0} ({1}, {2})" -f $serverName, $serverLocation, $serverCountry)
    Write-Host ("Latency: {0:N2} ms" -f $latencyMs)
    Write-Host ("Jitter: {0:N2} ms" -f $jitterMs)
    Write-Host ("Packet Loss: {0}" -f $packetLossDisplay)
    Write-Host ("Download: {0:N2} Mbit/s" -f $downloadMbps)
    Write-Host ("Upload: {0:N2} Mbit/s" -f $uploadMbps)
    Write-Host ("Result URL: {0}" -f $resultUrl)
    Write-Host ""
}

if ($runs.Count -eq 0) {
    throw "No successful speedtest runs were completed."
}

Write-Host "=== SUMMARY ==="
Write-StatsLine -Label 'Download' -Data $runs -Property 'DownloadMbps' -Unit 'Mbit/s'
Write-StatsLine -Label 'Upload' -Data $runs -Property 'UploadMbps' -Unit 'Mbit/s'
Write-StatsLine -Label 'Latency' -Data $runs -Property 'LatencyMs' -Unit 'ms'
Write-StatsLine -Label 'Jitter' -Data $runs -Property 'JitterMs' -Unit 'ms'

$packetLossRuns = $runs | Where-Object { $null -ne $_.PacketLoss }
if (@($packetLossRuns).Count -gt 0) {
    Write-StatsLine -Label 'Packet loss' -Data $packetLossRuns -Property 'PacketLoss' -Unit '%'
}
else {
    Write-Host "Packet loss avg/min/max: N/A"
}
