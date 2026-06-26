#!/bin/bash

# Disk Space Monitoring Script
# UC1 + UC2: Regular monitoring + Alert thresholds
# Returns JSON with disk status and alerts

set -o pipefail

# Configuration
WARN_THRESHOLD=85
ALERT_THRESHOLD=90
CRITICAL_THRESHOLD=95

# Paths to monitor
PATHS=(
  "/mnt/user"
  "/mnt/cache"
  "/mnt/disk7"
  "/var/lib/docker"
)

# Function to get disk usage
get_disk_usage() {
  local path=$1
  df -h "$path" 2>/dev/null | tail -1 | awk '{
    gsub(/%/, "", $5)
    print $2 "|" $3 "|" $4 "|" $5 "|" $6
  }'
}

# Function to parse usage and determine alert level
check_threshold() {
  local usage=$1
  if [[ $usage -ge $CRITICAL_THRESHOLD ]]; then
    echo "CRITICAL"
  elif [[ $usage -ge $ALERT_THRESHOLD ]]; then
    echo "ALERT"
  elif [[ $usage -ge $WARN_THRESHOLD ]]; then
    echo "WARNING"
  else
    echo "OK"
  fi
}

# Main monitoring logic
echo "{"
echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
echo "  \"thresholds\": {"
echo "    \"warning\": $WARN_THRESHOLD,"
echo "    \"alert\": $ALERT_THRESHOLD,"
echo "    \"critical\": $CRITICAL_THRESHOLD"
echo "  },"
echo "  \"disks\": ["

first=true
has_alert=false
alert_details=()

for path in "${PATHS[@]}"; do
  if [[ ! -d "$path" ]]; then
    continue
  fi

  usage_data=$(get_disk_usage "$path")
  if [[ -z "$usage_data" ]]; then
    continue
  fi

  IFS='|' read -r total used available percent mount <<<"$usage_data"
  status=$(check_threshold "${percent%.*}")

  if [[ "$status" != "OK" ]]; then
    has_alert=true
    alert_details+=("$path:$percent:$status")
  fi

  if [[ "$first" == false ]]; then
    echo ","
  fi
  first=false

  echo -n "    {
      \"path\": \"$path\",
      \"total\": \"$total\",
      \"used\": \"$used\",
      \"available\": \"$available\",
      \"percent_used\": $percent,
      \"status\": \"$status\"
    }"
done

echo ""
echo "  ],"
echo "  \"alerts\": ["

if [[ $has_alert == true ]]; then
  first=true
  for alert in "${alert_details[@]}"; do
    IFS=':' read -r path percent status <<<"$alert"
    if [[ "$first" == false ]]; then
      echo ","
    fi
    first=false
    echo -n "    {
      \"path\": \"$path\",
      \"percent_used\": $percent,
      \"level\": \"$status\",
      \"threshold\": \"$(check_threshold $percent)\"
    }"
  done
fi

echo ""
echo "  ],"
echo "  \"summary\": {"
if [[ $has_alert == true ]]; then
  echo "    \"status\": \"ACTION_REQUIRED\","
  echo "    \"message\": \"$(echo ${#alert_details[@]}) disk(s) exceed threshold(s)\","
  echo "    \"recommendation\": \"Check individual alerts for details\""
else
  echo "    \"status\": \"OK\","
  echo "    \"message\": \"All monitored disks within acceptable range\","
  echo "    \"recommendation\": \"No action needed\""
fi
echo "  }"
echo "}"
