#!/usr/bin/env bash
set -Eeuo pipefail

HOST="${HOST:-10.101.21.31}"
USER="${USER:-aspiredev}"
KEY="${KEY:-$HOME/.ssh/lab_rsa}"
NS="${NS:-harbor}"

SSH=(-i "$KEY" -o BatchMode=yes -o StrictHostKeyChecking=no)
ssh "${SSH[@]}" "$USER@$HOST" 'bash -s' <<'REMOTE'
set -Eeuo pipefail
NS="${NS:-harbor}"
echo "Pods in $NS not Running/Completed:"
kubectl -n "$NS" get pods | awk 'NR==1 || ($3!="Running" && $3!="Completed"){print}'
echo
for p in $(kubectl -n "$NS" get pods --no-headers | awk '$3!="Running" && $3!="Completed"{print $1}'); do
  echo "---- $p ----"
  kubectl -n "$NS" describe pod "$p" | tail -n +1
  echo
done
REMOTE
