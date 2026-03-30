# HVC Network Test

Cross-platform network test wrappers built around the official Ookla `speedtest` CLI.

This project measures:
- Download throughput
- Upload throughput
- Latency
- Jitter
- Packet loss
- Test server details
- Result URL
- Multi-run summary with average, minimum, and maximum values

## Why this uses Ookla

The earlier version mixed `speedtest-cli`, `ping`, and a manual download test. That approach was fragile for three reasons:
- `ping` output differs across macOS, Linux, and Windows.
- Jitter and latency parsing done in shell is easy to get wrong.
- The old Python `speedtest-cli` is not the same tool as Ookla's official CLI.

This version uses one measurement source end to end:
- Official Ookla CLI for the test itself
- `jq` for JSON parsing on macOS/Linux
- native PowerShell JSON parsing on Windows 11

## Files

- `test.sh`: macOS/Linux runner
- `test.ps1`: Windows PowerShell runner

## Requirements

### macOS

Install the official Ookla CLI and `jq`:

```bash
brew uninstall speedtest-cli --force
brew tap teamookla/speedtest
brew install speedtest
brew install jq
```

Verify that the correct binary is installed:

```bash
speedtest --version
```

If the output contains `speedtest-cli 2.x`, that is the wrong tool. Remove it and install Ookla's official CLI.

### Windows 11

Expected dependency state on a standard Windows 11 machine:
- PowerShell is already available
- `speedtest` is not installed by default
- no extra JSON parser is needed for `test.ps1`

Install the official Ookla CLI for Windows from:
- https://www.speedtest.net/apps/cli

## Usage

### macOS / Linux

Run the script with the default `3` tests:

```bash
chmod +x ./test.sh
./test.sh
```

Run more tests for a better packet-loss sample:

```bash
./test.sh 5
./test.sh 10
```

### Windows 11

Open PowerShell in this folder and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\test.ps1
```

Run more tests:

```powershell
powershell -ExecutionPolicy Bypass -File .\test.ps1 -RunCount 5
powershell -ExecutionPolicy Bypass -File .\test.ps1 -RunCount 10
```

## Output

Each run prints:
- timestamp
- server name and location
- latency
- jitter
- packet loss
- download speed
- upload speed
- Ookla result URL

At the end, the script prints a summary:
- average download, upload, latency, jitter, and packet loss
- minimum and maximum values for each metric

## Validation Guidance

What is solid here:
- Download and upload are reported by the official Ookla service.
- Latency, jitter, and packet loss are taken from the same official test output.
- Multi-run results are more useful than a single snapshot.

What this does not prove:
- performance to every website or service
- latency under heavy local load
- bufferbloat behavior
- Wi-Fi roaming or access-point handoff quality

If you need latency-under-load or bufferbloat validation, use one of these separately:
- Waveform Bufferbloat Test: https://www.waveform.com/tools/bufferbloat
- Cloudflare Speed Test: https://speed.cloudflare.com/

## Interpreting Packet Loss

A repeated `0%` packet loss result is plausible. It usually means the path between your device and the chosen Ookla test server was clean during those runs.

It does not mean:
- every destination on the internet has `0%` packet loss
- the connection is perfect under all load conditions
- there are no intermittent Wi-Fi issues outside the short test window

If packet loss is your main concern:
- run `5` to `10` tests
- keep the same network and physical location
- avoid VPNs and background downloads
- compare with a second service such as Cloudflare or Waveform

## Notes

- The scripts pass Ookla's documented license and GDPR acceptance flags automatically.
- Results will vary with server selection, Wi-Fi quality, ISP congestion, VPN use, and whether the device is on Ethernet or wireless.
- For Windows reproduction, `test.ps1` is the preferred path because it does not require `jq`.
