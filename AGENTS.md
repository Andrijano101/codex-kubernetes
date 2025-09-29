# Repository Guidelines

This repo contains automation for running remote Kubernetes health checks from the Rancher VM, pushing logs to GitHub, and maintaining scripts with OpenAI Codex.

## Project Structure
- `scripts/`: bash scripts (health checks, triage, utilities)
- `reports/`: run logs (git-ignored by default)
- `AGENTS.md`: instructions Codex follows

## Dev Commands
- Run remote healthcheck: `scripts/k8s-health-remote.sh --host 10.101.21.31 --user aspiredev --key /home/aspiredev/.ssh/lab_rsa`
- Harbor triage locally on master: `scripts/harbor-triage.sh` (runs `kubectl -n harbor describe` on the remote)
- Hourly cron is installed by this bootstrap; adjust with `crontab -e`.

## Style & Conventions
- Bash with `set -Eeuo pipefail`.
- Parametrized scripts (flags or env vars).
- No secrets in git. Keys/kubeconfigs remain local.

## Codex Instructions (Agent)
When asked to "update health checks" or "triage harbor":
- Edit scripts under `scripts/`, keep them idempotent and POSIX-friendly.
- Prefer resilient `kubectl` usage (no `--short` assumptions).
- After changes: run the script, save logs to `reports/`, then `git add/commit/push`.

