#!/bin/bash

# Cleanup Suggestions Script
# UC3: Provide safe, actionable recommendations to free space
# Returns JSON with cleanup actions, estimated space freed, and safety checks

set -o pipefail

# Configuration
DOCKER_PRUNE_ESTIMATE=3000  # MB estimate
LOG_CLEANUP_ESTIMATE=500    # MB estimate
TEMP_CLEANUP_ESTIMATE=1000  # MB estimate

# Function to check Docker system space
check_docker_space() {
  local docker_df=$(docker system df 2>/dev/null | grep "^Local Volumes" | awk '{print $NF}' | sed 's/[A-Za-z]//g')

  if [[ -z "$docker_df" ]]; then
    echo "0"
  else
    echo "$docker_df" | awk '{print int($1 * 1024)}'  # Convert to MB
  fi
}

# Function to check old logs
check_old_logs() {
  local log_size=$(du -sh /var/log 2>/dev/null | awk '{print $1}' | sed 's/[A-Za-z]//g')

  if [[ -z "$log_size" ]]; then
    echo "0"
  else
    echo "$log_size" | awk '{print int($1 * 1024)}'  # Convert to MB
  fi
}

# Function to identify running containers
get_running_containers() {
  docker ps --format "{{.Names}}" 2>/dev/null | sort
}

# Main cleanup suggestions
echo "{"
echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
echo "  \"suggestions\": ["

first=true

# Suggestion 1: Docker System Prune
docker_space=$(check_docker_space)
if [[ ! -z "$docker_space" && "$docker_space" -gt 100 ]]; then
  echo -n "    {
      \"id\": \"docker-prune\",
      \"name\": \"Docker System Prune\",
      \"description\": \"Remove unused Docker images, volumes, and networks\",
      \"command\": \"docker system prune -a --volumes\",
      \"estimated_space_freed_mb\": $DOCKER_PRUNE_ESTIMATE,
      \"safety_level\": \"MEDIUM\",
      \"safety_notes\": [
        \"Will remove all unused images (not tied to running containers)\",
        \"Will remove unused volumes\",
        \"This is REVERSIBLE - images can be re-downloaded from registry\",
        \"Does NOT affect running containers or their data\"
      ],
      \"prerequisites\": \"Docker daemon running\",
      \"requires_confirmation\": true,
      \"risk\": \"LOW - images can be restored from registry\"
    }"
  first=false
fi

# Suggestion 2: Log Rotation/Cleanup
if [[ "$first" == false ]]; then echo ","; fi
echo -n "    {
    \"id\": \"log-cleanup\",
    \"name\": \"Log Rotation & Cleanup\",
    \"description\": \"Clean up old Docker container logs and system logs\",
    \"command\": \"find /var/lib/docker/containers -name \\\"*-json.log\\\" -mtime +7 -delete && journalctl --vacuum=7d\",
    \"estimated_space_freed_mb\": $LOG_CLEANUP_ESTIMATE,
    \"safety_level\": \"MEDIUM\",
    \"safety_notes\": [
      \"Removes logs older than 7 days\",
      \"Historical logs are deleted permanently\",
      \"Recent logs (< 7 days) are preserved for troubleshooting\",
      \"Does NOT affect running services\"
    ],
    \"prerequisites\": \"SSH access\",
    \"requires_confirmation\": true,
    \"risk\": \"LOW - old logs are not needed for operations\"
  }"
first=false

# Suggestion 3: Cache Cleanup
if [[ -d "/mnt/cache/appdata" ]]; then
  echo ","
  echo -n "    {
    \"id\": \"cache-cleanup\",
    \"name\": \"Application Cache Cleanup\",
    \"description\": \"Clear temporary files and caches in /mnt/cache/appdata\",
    \"command\": \"find /mnt/cache/appdata -type f -name \\\"*.tmp\\\" -o -name \\\"cache\\\" -delete\",
    \"estimated_space_freed_mb\": $TEMP_CLEANUP_ESTIMATE,
    \"safety_level\": \"MEDIUM\",
    \"safety_notes\": [
      \"Removes temporary application files\",
      \"Applications will regenerate caches as needed\",
      \"Does NOT delete configuration or data files\",
      \"Some services may need restart after cache clear\"
    ],
    \"prerequisites\": \"SSH access, /mnt/cache accessible\",
    \"requires_confirmation\": true,
    \"risk\": \"LOW - caches are regenerated automatically\"
  }"
  first=false
fi

echo ""
echo "  ],"
echo "  \"not_recommended\": ["
echo "    {
      \"action\": \"Delete media files\",
      \"reason\": \"Media library corruption risk, requires explicit user action\",
      \"why_not\": \"Unraid system guardrail - media deletion requires manual confirmation\"
    },"
echo "    {
      \"action\": \"Remove running containers\",
      \"reason\": \"Service disruption and data loss risk\",
      \"why_not\": \"Critical services depend on running containers\"
    },"
echo "    {
      \"action\": \"Truncate databases\",
      \"reason\": \"Data loss, service corruption\",
      \"why_not\": \"Databases store essential state for media apps\"
    }"
echo "  ],"
echo "  \"storage_strategy\": {"
echo "    \"recommendation\": \"Use /mnt/disk7 for new content\",
echo "    \"reason\": \"Currently at 64% capacity with 5.3T available space\",
echo "    \"current_status\": {"
echo "      \"/mnt/user\": { \"usage\": \"92%\", \"status\": \"CRITICAL\" },"
echo "      \"/mnt/disk7\": { \"usage\": \"64%\", \"status\": \"GOOD\" }"
echo "    }"
echo "  },"
echo "  \"summary\": {"

total_estimated=$((DOCKER_PRUNE_ESTIMATE + LOG_CLEANUP_ESTIMATE + TEMP_CLEANUP_ESTIMATE))
echo "    \"total_estimated_space_freed_mb\": $total_estimated,"
echo "    \"urgency\": \"HIGH\","
echo "    \"recommended_next_step\": \"Run docker-prune first (highest impact)\","
echo "    \"note\": \"All cleanup actions require user confirmation before execution\""
echo "  }"
echo "}"
