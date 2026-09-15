#!/usr/bin/env bash
# config.sh - central configuration for the server health monitor
# Copy this file, fill in your own values, and keep secrets out of git.
# (Add your real config.sh to .gitignore if it contains a real webhook URL.)

# --- Thresholds (percentage) ---
CPU_THRESHOLD=85
MEM_THRESHOLD=85
DISK_THRESHOLD=90

# --- Which disk mount to check ---
DISK_MOUNT="/"

# --- Services to verify are running (systemd unit names) ---
# Leave empty to skip service checks: SERVICES_TO_CHECK=()
SERVICES_TO_CHECK=("ssh" "cron")

# --- Alerting ---
# Slack (or Discord) incoming webhook URL. Leave blank to disable Slack alerts.
SLACK_WEBHOOK_URL=""

# --- Paths ---
LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/logs"
LOG_FILE="${LOG_DIR}/monitor.log"
ALERT_LOG_FILE="${LOG_DIR}/alerts.log"
