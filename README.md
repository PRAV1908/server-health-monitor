# Server Health Monitor

A lightweight bash-based monitoring and alerting tool for Linux servers. It
tracks CPU, memory, and disk usage, verifies critical services are running,
logs everything, and sends real-time Slack alerts when something crosses a
threshold — no agents, no external dependencies beyond `curl` and standard
GNU coreutils.

## Why this exists

Most monitoring stacks (Prometheus, Datadog, Nagios) are overkill for a
single box or a small homelab, and heavyweight to set up just to answer:
*"is this server okay right now, and will someone get pinged if it's not?"*
This project answers that in ~150 lines of bash.

## Features

- **Zero dependencies** beyond bash, coreutils, and `curl` — runs on any
  standard Linux distro out of the box
- **CPU, memory, and disk usage monitoring** with configurable thresholds
- **Systemd service health checks** (e.g. is `nginx`, `sshd`, `docker` alive)
- **Slack/Discord webhook alerts** the moment a threshold is breached
- **Persistent logging** of every run and every alert, for later review
- **Two install paths**: systemd timer (recommended) or plain cron

## How it works

Every N minutes, a scheduler (`systemd` timer or `cron`) runs `monitor.sh`,
which:

1. Samples CPU usage from `/proc/stat` over a 1-second window
2. Reads memory usage from `free`
3. Reads disk usage from `df` for a configured mount point
4. Checks that configured `systemd` services are active
5. Logs everything to `logs/monitor.log`
6. If any metric breaches its threshold, logs to `logs/alerts.log` **and**
   posts a formatted message to Slack via webhook

## Quick start

```bash
git clone https://github.com/<your-username>/server-health-monitor.git
cd server-health-monitor

# 1. Edit thresholds, services to check, and your Slack webhook URL
nano config.sh

# 2. Try it once
./monitor.sh --verbose

# 3. Install it to run on a schedule
./install.sh
```

## Sample output

```text
[2026-09-15 07:23:28] CPU: 0% | MEM: 5% | DISK(/): 47%
[2026-09-15 07:23:28] ALERT: The following services are not running: ssh cron
```

And the corresponding Slack message:

> 🚨 **Server Alert** on `my-server`
> The following services are not running: ssh cron

## Configuration

All settings live in `config.sh`:

| Variable | Description | Default |
|---|---|---|
| `CPU_THRESHOLD` | Alert if CPU usage % exceeds this | `85` |
| `MEM_THRESHOLD` | Alert if memory usage % exceeds this | `85` |
| `DISK_THRESHOLD` | Alert if disk usage % exceeds this | `90` |
| `DISK_MOUNT` | Which mount point to check | `/` |
| `SERVICES_TO_CHECK` | Array of systemd units to verify are active | `("ssh" "cron")` |
| `SLACK_WEBHOOK_URL` | Incoming webhook URL for alerts (blank disables Slack) | `""` |

## Project structure

```
server-health-monitor/
├── monitor.sh              # main script: collects metrics, checks thresholds, alerts
├── config.sh               # thresholds, services, webhook URL
├── install.sh               # sets up systemd timer or cron job
├── systemd/
│   ├── server-monitor.service
│   └── server-monitor.timer
└── logs/                    # generated at runtime (gitignored)
```

## Roadmap

- [ ] Email alerting as an alternative to Slack
- [ ] Historical metrics export (CSV) for basic trend charts
- [ ] Docker container health checks alongside systemd services
- [ ] Optional web dashboard (simple Flask/FastAPI status page)

## License

MIT — see [LICENSE](LICENSE).
