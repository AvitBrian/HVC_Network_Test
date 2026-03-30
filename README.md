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
brew tap teamookla/speedtest
brew install speedtest
brew install jq
```

Verify the installed binary:

```bash
speedtest --version
```

## Windows 11 Setup

Install the official Ookla CLI:

- https://www.speedtest.net/apps/cli

Then run the PowerShell script from this folder. Note: # are comments

## Usage

macOS / Linux:

```bash
chmod +x ./test.sh
./test.sh #runs 1 test
./test.sh 3 #runs 3 tests
./test.sh 10 #runs 10 tests
```

Windows 11:

```powershell
powershell -ExecutionPolicy Bypass -File .\test.ps1 #runs 1 test
powershell -ExecutionPolicy Bypass -File .\test.ps1 -RunCount 5 #runs 5 tests
powershell -ExecutionPolicy Bypass -File .\test.ps1 -RunCount 10 #runs 10 tests
```

## Notes

- `test.sh` requires `jq`, a command-line JSON parser used to read the `speedtest` results.
- `test.ps1` does not require `jq`.
- Multiple runs are better than a single run, especially for packet loss.
- A `0%` packet loss result can be valid, but it only reflects the test path and time window.
