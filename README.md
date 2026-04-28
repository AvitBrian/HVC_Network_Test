# HVC Network Test

Cross-platform wrappers for the official Ookla `speedtest` CLI.

## Overview

This repository provides simple wrappers around the official Ookla `speedtest` CLI so you can run repeated network tests on macOS, Linux, and Windows with consistent output.

## Files

- `test.sh` for macOS and Linux
- `test.ps1` for Windows PowerShell

## What It Reports

- Download speed
- Upload speed
- Latency
- Jitter
- Packet loss
- Server details
- Result URL
- Summary across multiple runs

---

## macOS Setup

Install the official Ookla CLI and `jq`:

```bash
brew tap teamookla/speedtest
brew install speedtest
brew install jq
```

Verify installation:

```bash
speedtest --version
```

---

## Windows 11 Setup

1. Install the official Ookla CLI:

   ```powershell
   winget install Ookla.Speedtest.CLI
   ```

2. Verify installation:

   ```powershell
   speedtest --version
   ```

3. Navigate to the project folder:

   ```powershell
   cd path\to\HVC_Network_Test
   ```

---

## Usage

### macOS / Linux

```bash
chmod +x ./test.sh
./test.sh
./test.sh 5
./test.sh 10
```

### Windows 11

Run in PowerShell:

```powershell
.\test.ps1
.\test.ps1 -RunCount 5
.\test.ps1 -RunCount 10
```

---

## If Scripts Are Blocked on Windows

Run this once in your PowerShell session:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Then run:

```powershell
.\test.ps1
```

---

## Alternative One-Line Execution

```powershell
powershell -ExecutionPolicy Bypass -File .\test.ps1
```

---

## Notes

- `test.sh` requires `jq` to parse JSON output from `speedtest`.
- `test.ps1` does not require `jq`.
- The default run count is `3` on all platforms.
- Multiple runs are more reliable than a single run, especially for packet loss.
- A `0%` packet loss result can still be valid because it only reflects the test path and time window sampled.
