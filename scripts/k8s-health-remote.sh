#!/usr/bin/env bash
set -Eeuo pipefail

HOST="${HOST:-10.101.21.31}"
USER="${USER:-aspiredev}"
KEY="${KEY:-$HOME/.ssh/lab_rsa}"
OUTDIR="${OUTDIR:-$PWD/reports}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="$2"; shift 2 ;;
    --user) USER="$2"; shift 2 ;;
    --key)  KEY="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

mkdir -p "$OUTDIR"
TS="$(date +%F_%H%M%S)"
LOG="$OUTDIR/health-$HOST-$TS.log"
TMP="$(mktemp)"

cat >"$TMP" <<'REMOTE'
#!/usr/bin/env bash
set -Eeuo pipefail
kc(){ kubectl "$@"; }

echo "=== Host & Time ==="; hostname; date; echo

echo "=== Kubernetes version (client) ==="
kc version --client 2>/dev/null || kc version 2>/dev/null | head -n 10
echo

echo "=== Nodes (wide) ==="
kc get nodes -o wide || true
echo

echo "=== Nodes NotReady ==="
kc get nodes --no-headers 2>/dev/null | awk '$2!="Ready"{print}' || true
echo

echo "=== Pods not Running/Succeeded ==="
kc get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded || true
echo

echo "=== CrashLoopBackOff / OOMKilled ==="
kc get pods -A 2>/dev/null | egrep -E 'CrashLoopBackOff|OOMKilled' || true
echo

echo "=== Recent warnings (last 100 lines) ==="
kc get events -A --field-selector=type=Warning --sort-by=.lastTimestamp 2>/dev/null | tail -n 100 || true
echo

echo "=== Storage (PVC/PV) ==="
kc get pvc -A || true
kc get pv || true
echo

echo "=== Summary ==="
NOTREADY="$( kc get nodes --no-headers 2>/dev/null | awk '$2!="Ready"{c++} END{print c+0}' )"
CRASH="$( kc get pods -A 2>/dev/null | egrep -Ec 'CrashLoopBackOff|OOMKilled' || true )"
[ -z "$CRASH" ] && CRASH=0
echo "Nodes NotReady: $NOTREADY"
echo "CrashLoop/OOMKilled pods: $CRASH"

if [ "$NOTREADY" -gt 0 ] || [ "$CRASH" -gt 0 ]; then
  exit 1
fi
exit 0
REMOTE

SSH=(-i "$KEY" -o BatchMode=yes -o StrictHostKeyChecking=no)
scp -q "${SSH[@]}" "$TMP" "$USER@$HOST:/tmp/k8s-health.$$"
ssh "${SSH[@]}" "$USER@$HOST" "bash /tmp/k8s-health.$$" | tee "$LOG"
RC=${PIPESTATUS[0]}
ssh "${SSH[@]}" "$USER@$HOST" "rm -f /tmp/k8s-health.$$" || true
rm -f "$TMP"

echo
echo "Log saved to: $LOG"
exit $RC
