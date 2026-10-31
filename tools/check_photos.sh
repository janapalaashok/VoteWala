#!/usr/bin/env bash
# Checks that candidate photo URLs load and send CORS headers (needed by Flutter web).
set -u
urls=$(grep -ohE 'https://[a-z]+\.wikimedia\.org/[^"'"'"']+' lib/data/results_2024.dart lib/data/featured_polls.dart | sort -u)
total=0; ok=0
for u in $urls; do
  total=$((total + 1))
  headers=$(curl -sSI -H 'Origin: https://example.com' -A 'VoteWalaCI/1.0' "$u" || true)
  status=$(echo "$headers" | head -1 | awk '{print $2}')
  cors=$(echo "$headers" | grep -i '^access-control-allow-origin' | tr -d '\r')
  if [ "$status" = "200" ] && [ -n "$cors" ]; then ok=$((ok + 1)); else echo "FAIL $status [$cors] $u"; fi
done
echo "photos ok: $ok / $total"
