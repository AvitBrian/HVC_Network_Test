# HVC Network Test

Cross-platform wrappers for the official Ookla `speedtest` CLI.

## Files

- `test.sh`: macOS/Linux
- `test.ps1`: Windows PowerShell

## What it reports

- Download: receive speed
- Upload: send speed
- Latency: response time
- Jitter: variation in latency
- Packet loss: dropped packets during the test
- Server details
- Result URL
- Summary across multiple runs

## macOS Setup

Install the official Ookla CLI and `jq`:

```bash
brew uninstall speedtest-cli --force
brew tap teamookla/speedtest
brew install speedtest
brew install jq
```

Verify the installed binary:

```bash
speedtest --version
```

If the output contains `speedtest-cli 2.x`, that is the wrong tool.

## Windows 11 Setup

Install the official Ookla CLI:

- https://www.speedtest.net/apps/cli

Then run the PowerShell script from this folder.

## Usage

macOS / Linux:

```bash
chmod +x ./test.sh
./test.sh
./test.sh 5
./test.sh 10
```

Windows 11:

```powershell
powershell -ExecutionPolicy Bypass -File .\test.ps1
powershell -ExecutionPolicy Bypass -File .\test.ps1 -RunCount 5
powershell -ExecutionPolicy Bypass -File .\test.ps1 -RunCount 10
```

## Notes

- `test.sh` requires `jq`, a command-line JSON parser used to read the `speedtest` results.
- `test.ps1` does not require `jq`.
- Multiple runs are better than a single run, especially for packet loss.
- A `0%` packet loss result can be valid, but it only reflects the test path and time window.
