#!/bin/bash

set -euo pipefail

RUN_COUNT="${1:-3}"

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: '$1' is not installed."
        exit 1
    fi
}

require_official_speedtest() {
    local version_output
    version_output=$(speedtest --version 2>&1 || true)

    if printf '%s' "$version_output" | grep -qi 'speedtest-cli'; then
        echo "Error: detected the unofficial Python 'speedtest-cli' package."
        echo "This script requires the official Ookla Speedtest CLI for valid, cross-platform results."
        echo ""
        echo "On macOS, replace it with:"
        echo "  brew uninstall speedtest-cli --force"
        echo "  brew tap teamookla/speedtest"
        echo "  brew install speedtest"
        exit 1
    fi
}

require_cmd speedtest
require_cmd jq
require_official_speedtest

if ! [[ "$RUN_COUNT" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: run count must be a positive integer."
    echo "Usage: ./test.sh [run_count]"
    exit 1
fi

sum_download=0
sum_upload=0
sum_latency=0
sum_jitter=0
sum_packet_loss=0
packet_loss_samples=0

min_download=""
max_download=""
min_upload=""
max_upload=""
min_latency=""
max_latency=""
min_jitter=""
max_jitter=""
min_packet_loss=""
max_packet_loss=""

update_min_max() {
    local value="$1"
    local current_min="$2"
    local current_max="$3"

    local new_min="$current_min"
    local new_max="$current_max"

    if [[ -z "$current_min" ]] || awk "BEGIN { exit !($value < $current_min) }"; then
        new_min="$value"
    fi

    if [[ -z "$current_max" ]] || awk "BEGIN { exit !($value > $current_max) }"; then
        new_max="$value"
    fi

    printf '%s %s\n' "$new_min" "$new_max"
}

echo "=== HVC NETWORK TEST ==="
echo ""
echo "Running official Ookla Speedtest CLI ($RUN_COUNT run(s))..."
echo ""

for run in $(seq 1 "$RUN_COUNT"); do
    if ! JSON_OUTPUT=$(speedtest --accept-license --accept-gdpr --format=json 2>/tmp/hvc_speedtest_error.log); then
        echo "Error: official Ookla Speedtest CLI failed."
        cat /tmp/hvc_speedtest_error.log
        rm -f /tmp/hvc_speedtest_error.log
        exit 1
    fi

    DOWNLOAD_MBPS=$(jq -r '(.download.bandwidth * 8 / 1000000) | @text' <<< "$JSON_OUTPUT")
    UPLOAD_MBPS=$(jq -r '(.upload.bandwidth * 8 / 1000000) | @text' <<< "$JSON_OUTPUT")
    LATENCY_MS=$(jq -r '.ping.latency | @text' <<< "$JSON_OUTPUT")
    JITTER_MS=$(jq -r '.ping.jitter | @text' <<< "$JSON_OUTPUT")
    PACKET_LOSS_VALUE=$(jq -r 'if .packetLoss == null then "" else (.packetLoss | tostring) end' <<< "$JSON_OUTPUT")
    SERVER_NAME=$(jq -r '.server.name // "Unknown"' <<< "$JSON_OUTPUT")
    SERVER_LOCATION=$(jq -r '.server.location // "Unknown"' <<< "$JSON_OUTPUT")
    SERVER_COUNTRY=$(jq -r '.server.country // "Unknown"' <<< "$JSON_OUTPUT")
    RESULT_URL=$(jq -r '.result.url // "N/A"' <<< "$JSON_OUTPUT")
    TIMESTAMP=$(jq -r '.timestamp // "N/A"' <<< "$JSON_OUTPUT")

    sum_download=$(awk "BEGIN { printf \"%.6f\", $sum_download + $DOWNLOAD_MBPS }")
    sum_upload=$(awk "BEGIN { printf \"%.6f\", $sum_upload + $UPLOAD_MBPS }")
    sum_latency=$(awk "BEGIN { printf \"%.6f\", $sum_latency + $LATENCY_MS }")
    sum_jitter=$(awk "BEGIN { printf \"%.6f\", $sum_jitter + $JITTER_MS }")

    read -r min_download max_download <<< "$(update_min_max "$DOWNLOAD_MBPS" "$min_download" "$max_download")"
    read -r min_upload max_upload <<< "$(update_min_max "$UPLOAD_MBPS" "$min_upload" "$max_upload")"
    read -r min_latency max_latency <<< "$(update_min_max "$LATENCY_MS" "$min_latency" "$max_latency")"
    read -r min_jitter max_jitter <<< "$(update_min_max "$JITTER_MS" "$min_jitter" "$max_jitter")"

    if [[ -n "$PACKET_LOSS_VALUE" ]]; then
        sum_packet_loss=$(awk "BEGIN { printf \"%.6f\", $sum_packet_loss + $PACKET_LOSS_VALUE }")
        packet_loss_samples=$((packet_loss_samples + 1))
        read -r min_packet_loss max_packet_loss <<< "$(update_min_max "$PACKET_LOSS_VALUE" "$min_packet_loss" "$max_packet_loss")"
        PACKET_LOSS_DISPLAY="${PACKET_LOSS_VALUE}%"
    else
        PACKET_LOSS_DISPLAY="N/A"
    fi

    echo "[Run $run/$RUN_COUNT]"
    printf "Timestamp: %s\n" "$TIMESTAMP"
    printf "Server: %s (%s, %s)\n" "$SERVER_NAME" "$SERVER_LOCATION" "$SERVER_COUNTRY"
    printf "Latency: %.2f ms\n" "$LATENCY_MS"
    printf "Jitter: %.2f ms\n" "$JITTER_MS"
    printf "Packet Loss: %s\n" "$PACKET_LOSS_DISPLAY"
    printf "Download: %.2f Mbit/s\n" "$DOWNLOAD_MBPS"
    printf "Upload: %.2f Mbit/s\n" "$UPLOAD_MBPS"
    printf "Result URL: %s\n" "$RESULT_URL"
    echo ""
done

rm -f /tmp/hvc_speedtest_error.log

avg_download=$(awk "BEGIN { printf \"%.2f\", $sum_download / $RUN_COUNT }")
avg_upload=$(awk "BEGIN { printf \"%.2f\", $sum_upload / $RUN_COUNT }")
avg_latency=$(awk "BEGIN { printf \"%.2f\", $sum_latency / $RUN_COUNT }")
avg_jitter=$(awk "BEGIN { printf \"%.2f\", $sum_jitter / $RUN_COUNT }")

echo "=== SUMMARY ==="
printf "Download avg/min/max: %s / %.2f / %.2f Mbit/s\n" "$avg_download" "$min_download" "$max_download"
printf "Upload avg/min/max: %s / %.2f / %.2f Mbit/s\n" "$avg_upload" "$min_upload" "$max_upload"
printf "Latency avg/min/max: %s / %.2f / %.2f ms\n" "$avg_latency" "$min_latency" "$max_latency"
printf "Jitter avg/min/max: %s / %.2f / %.2f ms\n" "$avg_jitter" "$min_jitter" "$max_jitter"

if (( packet_loss_samples > 0 )); then
    avg_packet_loss=$(awk "BEGIN { printf \"%.2f\", $sum_packet_loss / $packet_loss_samples }")
    printf "Packet loss avg/min/max: %s%% / %.2f%% / %.2f%%\n" "$avg_packet_loss" "$min_packet_loss" "$max_packet_loss"
else
    echo "Packet loss avg/min/max: N/A"
fi
