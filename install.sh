#!/usr/bin/env bash
#
# install.sh - installs server-health-monitor to run on a schedule.
# Supports systemd (preferred) or a plain cron fallback.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
chmod +x "${SCRIPT_DIR}/monitor.sh"

echo "Server Health Monitor installer"
echo "1) systemd timer (recommended, requires sudo)"
echo "2) cron job (no sudo needed)"
read -rp "Choose [1/2]: " choice

case "$choice" in
  1)
    echo "This will copy unit files to /etc/systemd/system/ and enable the timer."
    read -rp "Install path for this repo (default: ${SCRIPT_DIR}): " install_path
    install_path="${install_path:-$SCRIPT_DIR}"

    sed "s#/opt/server-health-monitor/monitor.sh#${install_path}/monitor.sh#" \
      "${SCRIPT_DIR}/systemd/server-monitor.service" | sudo tee /etc/systemd/system/server-monitor.service > /dev/null
    sudo cp "${SCRIPT_DIR}/systemd/server-monitor.timer" /etc/systemd/system/server-monitor.timer

    sudo systemctl daemon-reload
    sudo systemctl enable --now server-monitor.timer
    echo "Installed. Check status with: systemctl status server-monitor.timer"
    ;;
  2)
    CRON_LINE="*/5 * * * * ${SCRIPT_DIR}/monitor.sh"
    ( crontab -l 2>/dev/null | grep -v "monitor.sh" ; echo "$CRON_LINE" ) | crontab -
    echo "Installed cron job: $CRON_LINE"
    echo "View with: crontab -l"
    ;;
  *)
    echo "Invalid choice, exiting."
    exit 1
    ;;
esac
