# unraidIT_agent

A persistent AI agent for managing a home Unraid server ecosystem, with focus on Docker orchestration, disk/resource monitoring, media management (Plex, Radarr, Sonarr), and automation via n8n.

## System Overview

**Host:** superserver.local (10.1.10.10)  
**OS:** Unraid 7.2.2  
**SSH User:** root  
**SSH Key:** ~/.secret/claude_key (ed25519)

### Storage Configuration

**Disk Array:**
- /mnt/disk1 - 15T (98% full)
- /mnt/disk2 - 15T (96% full)
- /mnt/disk3 - 15T (99% full)
- /mnt/disk4 - 13T (99% full)
- /mnt/disk5 - 9.1T (98% full)
- /mnt/disk6 - 9.1T (97% full)
- /mnt/disk7 - 15T (64% full) — Most available space

**Cache:**
- /mnt/cache - 932G SSD (29% full)
- /mnt/cache_temp - 1.9T NVME (79% full)

**Pool:**
- /mnt/user - 90T total (82T used, 7.3T available) — 92% full

**Docker Storage:**
- /var/lib/docker - 50G (83% full)

### Critical Services

**Media Management:**
- Plex (media server) — port 32400 (via UPnP)
- Radarr (movies) — port 7878
- Sonarr (tv shows) — port 8989
- Prowlarr (indexer) — port 9696
- Bazarr (subtitles) — port 6767
- Lidarr (music) — port 8686
- Seerr (request management) — port 5055

**Download/Processing:**
- qBittorrent (VPN) — ports 8080, 8118
- SABnzbd (usenet) — port 8090
- n8n (automation) — port 5678

**Monitoring & Infrastructure:**
- Grafana — port 3002
- InfluxDB — port 8087
- Notifiarr — port 5454
- Tautulli (Plex monitoring) — no web port
- Nginx Proxy Manager — ports 180, 1443, 7818

**Data & Backup:**
- Immich (photo library) — port 8086
- PostgreSQL (Immich DB) — port 5433
- UrBackup (backups) — no web port
- Syncthing (sync) — port 8384

**Utilities:**
- Firefox (browser) — ports 3000-3001
- Krusader (file manager) — port 60801
- Wyze Bridge (RTMP) — ports 1935, 5000, 8554
- OpenClaw — port 18789
- RustDesk Server — no web port
- Apache Guacamole — port 6060
- CodeProject.AI — port 32168
- Cloudflare Tunnel — no web port
- Cloudflare DDNS — no web port
- Flatnotes — port 2345

## Operating Rules

### Always Do
- Monitor disk space on /mnt/user0 (currently 92% full) — warn at 85%+
- Check Docker container health status before any restart
- Log all actions (restarts, config changes) with timestamps
- Verify external connections (API calls, webhooks) succeed before considering task complete

### Ask First
- Any restart of media services (Plex, Radarr, Sonarr)
- Stopping/removing containers
- Modifications to n8n workflows
- Changes to Prowlarr indexer configuration
- Scaling down Docker resources

### Never Do
- Delete media files (audio, video, images) from /mnt/user* or /mnt/disk*
- Modify Plex library paths without confirmation
- Touch critical infrastructure: PostgreSQL_Immich, UrBackup containers
- Force kill Docker containers without graceful shutdown attempt
- Edit Radarr/Sonarr database directly

## Access Methods

### SSH
```bash
ssh -i ~/.secret/claude_key root@10.1.10.10
```

### Docker
All containers managed via Docker daemon (socket access via SSH).

### APIs
- **Radarr:** http://10.1.10.10:7878 (requires API key)
- **Sonarr:** http://10.1.10.10:8989 (requires API key)
- **Prowlarr:** http://10.1.10.10:9696 (requires API key)
- **Plex:** http://10.1.10.10:32400 (requires auth token)
- **n8n:** http://10.1.10.10:5678

### Webhooks
n8n can send webhooks to trigger Agent actions. Webhook endpoint format: (TBD)

## Common Operations

### Docker Management
```bash
# List containers
docker ps -a

# Check container logs
docker logs <container-name>

# Restart container
docker restart <container-name>

# Get container stats
docker stats --no-stream
```

### Disk Monitoring
```bash
# Check disk usage
df -h

# Check Plex library size
du -sh /mnt/user*

# Check specific container storage
docker inspect <container> | grep -A 2 MergedDir
```

### Service Health
```bash
# Check if service responds
curl -s http://10.1.10.10:7878/api/v3/system/status

# Restart service
docker restart binhex-radarr

# View service logs
docker logs binhex-radarr --tail 50
```

## Knowledge Base Structure
- `/kb/apis/` — API documentation (Radarr, Sonarr, Prowlarr, Plex)
- `/kb/docker/` — Container specs and startup configs
- `/kb/unraid/` — Unraid-specific docs and error codes
- `/kb/errors/` — Common issues and solutions
- `/kb/n8n/` — n8n workflow templates

## Priority Use Cases
1. **Restart failing containers** — Monitor health, auto-restart unhealthy services
2. **Monitor disk space** — Alert when /mnt/user exceeds 85%, suggest cleanup
3. **Troubleshoot errors** — Parse logs, identify root cause, suggest remediation
4. **Preventative maintenance** — Weekly health checks, database integrity, backup verification
5. **n8n automation** — Support workflow creation/modification for Plex/media tasks

## Notes
- Storage is nearly full (92%) — prioritize monitoring and cleanup
- Docker volume is 83% full — may need pruning
- Most disks are 96%+ full — limited room for new content
- /mnt/disk7 is the most available at 64% full
- Multiple services depend on database containers — coordinate restarts carefully
