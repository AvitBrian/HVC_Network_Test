$ErrorActionPreference = 'Stop'

param(
    [ValidateRange(1, 100)]
    [int]$RunCount = 3
)

function Require-Command {
    param([string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' is not installed."
    }
}

Require-Command speedtest

Write-Host "=== HVC NETWORK TEST ==="
Write-Host ""
Write-Host ("Running official Ookla Speedtest CLI ({0} run(s))..." -f $RunCount)
Write-Host ""

$runs = @()

for ($run = 1; $run -le $RunCount; $run++) {
    $jsonOutput = speedtest --accept-license --accept-gdpr --format=json
    $result = $jsonOutput | ConvertFrom-Json

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

Write-Host "=== SUMMARY ==="
Write-Host ("Download avg/min/max: {0:N2} / {1:N2} / {2:N2} Mbit/s" -f (($runs | Measure-Object -Property DownloadMbps -Average).Average), (($runs | Measure-Object -Property DownloadMbps -Minimum).Minimum), (($runs | Measure-Object -Property DownloadMbps -Maximum).Maximum))
Write-Host ("Upload avg/min/max: {0:N2} / {1:N2} / {2:N2} Mbit/s" -f (($runs | Measure-Object -Property UploadMbps -Average).Average), (($runs | Measure-Object -Property UploadMbps -Minimum).Minimum), (($runs | Measure-Object -Property UploadMbps -Maximum).Maximum))
Write-Host ("Latency avg/min/max: {0:N2} / {1:N2} / {2:N2} ms" -f (($runs | Measure-Object -Property LatencyMs -Average).Average), (($runs | Measure-Object -Property LatencyMs -Minimum).Minimum), (($runs | Measure-Object -Property LatencyMs -Maximum).Maximum))
Write-Host ("Jitter avg/min/max: {0:N2} / {1:N2} / {2:N2} ms" -f (($runs | Measure-Object -Property JitterMs -Average).Average), (($runs | Measure-Object -Property JitterMs -Minimum).Minimum), (($runs | Measure-Object -Property JitterMs -Maximum).Maximum))

$packetLossRuns = $runs | Where-Object { $null -ne $_.PacketLoss }
if ($packetLossRuns.Count -gt 0) {
    Write-Host ("Packet loss avg/min/max: {0:N2}% / {1:N2}% / {2:N2}%" -f (($packetLossRuns | Measure-Object -Property PacketLoss -Average).Average), (($packetLossRuns | Measure-Object -Property PacketLoss -Minimum).Minimum), (($packetLossRuns | Measure-Object -Property PacketLoss -Maximum).Maximum))
} else {
    Write-Host "Packet loss avg/min/max: N/A"
}
