#!/usr/bin/env bash
#
# monitor.sh - Server Health Monitoring & Alert System
#
# Collects CPU, memory, disk, and service-status metrics, logs them,
# and sends a Slack alert when any metric crosses its configured threshold.
#
# Usage:
#   ./monitor.sh            # run once (intended to be called by cron/systemd)
#   ./monitor.sh --verbose  # also print output to stdout
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

VERBOSE=false
[[ "${1:-}" == "--verbose" ]] && VERBOSE=true

mkdir -p "$LOG_DIR"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

log() {
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
    $VERBOSE && echo "[$TIMESTAMP] $1"
}

alert() {
    local message="$1"
    echo "[$TIMESTAMP] ALERT: $message" >> "$ALERT_LOG_FILE"
    $VERBOSE && echo "[$TIMESTAMP] ALERT: $message"

    if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
        curl -s -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\":rotating_light: *Server Alert* on \`$(hostname)\`\n${message}\"}" \
            "$SLACK_WEBHOOK_URL" > /dev/null || log "WARNING: failed to send Slack alert"
    fi
}

# ---------- CPU usage ----------
# Average CPU utilization over a 1-second sample, derived from /proc/stat.
read_cpu_usage() {
    local cpu_line1 cpu_line2 idle1 idle2 total1 total2
    cpu_line1=($(grep '^cpu ' /proc/stat))
    sleep 1
    cpu_line2=($(grep '^cpu ' /proc/stat))

    idle1=${cpu_line1[4]}
    idle2=${cpu_line2[4]}

    total1=0; for v in "${cpu_line1[@]:1}"; do total1=$((total1 + v)); done
    total2=0; for v in "${cpu_line2[@]:1}"; do total2=$((total2 + v)); done

    local total_delta=$((total2 - total1))
    local idle_delta=$((idle2 - idle1))

    if [[ $total_delta -eq 0 ]]; then
        echo 0
    else
        echo $(( (100 * (total_delta - idle_delta)) / total_delta ))
    fi
}

# ---------- Memory usage ----------
read_mem_usage() {
    free | awk '/^Mem:/ {printf "%d", ($2-$7)/$2 * 100}'
}

# ---------- Disk usage ----------
read_disk_usage() {
    df -P "$DISK_MOUNT" | awk 'NR==2 {gsub("%","",$5); print $5}'
}

# ---------- Service checks ----------
check_services() {
    local failed=()
    for svc in "${SERVICES_TO_CHECK[@]}"; do
        if ! systemctl is-active --quiet "$svc" 2>/dev/null; then
            failed+=("$svc")
        fi
    done
    echo "${failed[@]:-}"
}

main() {
    local cpu mem disk failed_services

    cpu=$(read_cpu_usage)
    mem=$(read_mem_usage)
    disk=$(read_disk_usage)
    failed_services=$(check_services)

    log "CPU: ${cpu}% | MEM: ${mem}% | DISK(${DISK_MOUNT}): ${disk}%"

    if (( cpu >= CPU_THRESHOLD )); then
        alert "CPU usage is ${cpu}% (threshold ${CPU_THRESHOLD}%)"
    fi

    if (( mem >= MEM_THRESHOLD )); then
        alert "Memory usage is ${mem}% (threshold ${MEM_THRESHOLD}%)"
    fi

    if (( disk >= DISK_THRESHOLD )); then
        alert "Disk usage on ${DISK_MOUNT} is ${disk}% (threshold ${DISK_THRESHOLD}%)"
    fi

    if [[ -n "$failed_services" ]]; then
        alert "The following services are not running: ${failed_services}"
    fi
}

main
