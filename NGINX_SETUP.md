# Nginx Reverse Proxy Setup Guide

## Overview

This document describes the nginx reverse proxy configuration for the Gaming Stats API. Nginx acts as a reverse proxy to forward all incoming traffic from the host machine (ports 80/8080) to the FastAPI backend running on port 8000 inside its container.

## Architecture

```
┌─────────────────────┐
│  Host Machine       │
│  Port 80 / 8080     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Nginx Container    │
│  (Reverse Proxy)    │
│  Port 80 internal   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│  Docker Bridge Network (app-network)    │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │ FastAPI App Container           │  │
│  │ Port 8000                        │  │
│  │ (gaming_stats_api)               │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │ MySQL Container                  │  │
│  │ Port 3306                        │  │
│  │ (gaming_stats_db)                │  │
│  └──────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
```

## Files

### 1. `docker-compose.yml` (Updated)
Contains the nginx service configuration with:
- **Image**: `nginx:1.25-alpine` (lightweight, optimized image)
- **Ports**: 
  - `80:80` - Standard HTTP port
  - `8080:80` - Alternate port (useful for development/testing)
- **Volume Mount**: `./nginx.conf:/etc/nginx/nginx.conf:ro` (read-only bind mount)
- **Health Check**: Uses `wget` to verify nginx is responding
- **Dependencies**: Depends on the `app` service
- **Network**: Connected to `app-network` for service discovery

### 2. `nginx.conf` (New)
Production-grade nginx configuration with:

#### Performance Optimizations
- **Worker Processes**: Auto-adjusted based on CPU cores
- **Worker Connections**: 1024 per worker
- **TCP Optimizations**: `tcp_nopush`, `tcp_nodelay` enabled
- **Gzip Compression**: Enabled for text/JSON/JS files (level 6)
- **Keepalive**: 65s keepalive timeout

#### Proxy Configuration
- **Upstream Server**: `gaming_stats_api:8000`
- **Connection Reuse**: 32 keepalive connections
- **Buffering**: 4KB buffers with 8 buffers per request
- **Timeouts**: 60s for connect, send, and read

#### Security Features
- **Security Headers**:
  - `X-Frame-Options: SAMEORIGIN` - Prevent clickjacking
  - `X-Content-Type-Options: nosniff` - Block MIME type sniffing
  - `X-XSS-Protection: 1; mode=block` - XSS protection
  - `Referrer-Policy: strict-origin-when-cross-origin`

#### Rate Limiting
- **General**: 10 requests/second with 20-request burst
- **Health Check**: 2 requests/second with 5-request burst (strict)

#### Request Forwarding
Proper proxy headers for backend awareness:
- `X-Real-IP` - Client's real IP address
- `X-Forwarded-For` - Client IP in proxy chain
- `X-Forwarded-Proto` - Original protocol (http/https)
- `X-Forwarded-Host` - Original hostname
- `Host` - Rewritten to nginx host

#### Error Handling
- **404**: Custom JSON error page
- **502/503/504**: Service unavailable error page

#### Special Endpoints
- `/health` - Health check with strict rate limiting (cached response)
- `/` - All other requests proxied with normal rate limits

## Usage

### Starting the Stack
```bash
docker-compose up -d
```

### Stopping the Stack
```bash
docker-compose down
```

### Viewing Logs
```bash
# Nginx access logs
docker-compose exec nginx tail -f /var/log/nginx/access.log

# Nginx error logs
docker-compose exec nginx tail -f /var/log/nginx/error.log
```

### Testing Endpoints

**Port 80 (Standard HTTP)**:
```bash
curl http://localhost/health
curl http://localhost/stats
curl http://localhost/
```

**Port 8080 (Alternate)**:
```bash
curl http://localhost:8080/health
curl http://localhost:8080/stats
```

**With Headers**:
```bash
curl -i http://localhost/health
```

##Testing

### Automated Tests

#### Python Test Suite (Comprehensive)
```bash
python3 test_nginx_setup.py
```

Tests:
- Connectivity to nginx
- All API endpoints (/health, /, /stats)
- Proxy headers are properly forwarded
- Performance metrics (latency, response times)
- Alternate port (8080) functionality
- Security headers presence
- Error handling (404 responses)

**Expected Output**: 7/7 tests pass with ~20ms average latency

#### Bash Test Script
```bash
bash test_nginx_setup.sh
```

Tests:
- Container status check
- Nginx configuration validity
- Health endpoint (HTTP 200)
- API availability
- Performance testing (5 requests)
- Log verification

### Manual Testing

**Health Check**:
```bash
curl http://localhost/health
# Expected: {"status": "healthy"}
```

**Performance Test**:
```bash
for i in {1..5}; do time curl -s http://localhost/health > /dev/null; done
```

**Response Headers**:
```bash
curl -i http://localhost/health
```

## Configuration Details

### Nginx Upstream
```nginx
upstream gaming_stats_api {
    server app:8000;
    keepalive 32;
}
```
- Uses Docker service discovery (`app` resolves to container IP)
- Maintains 32 persistent connections for efficiency

### Rate Limiting Zones
```nginx
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=strict:10m rate=2r/s;
```
- `general`: 10 req/sec, 20-request burst (normal endpoints)
- `strict`: 2 req/sec, 5-request burst (health checks)

### Logging Format
```
$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent
"$http_referer" "$http_user_agent" "$http_x_forwarded_for"
rt=$request_time uct="$upstream_connect_time" uht="$upstream_header_time"
urt="$upstream_response_time"
```

Metrics captured:
- `rt`: Total request time
- `uct`: Time to connect to upstream
- `uht`: Time to receive first byte from upstream
- `urt`: Total upstream response time

## Performance Metrics

### Observed Performance (Test Results)
- **Average Response Time**: ~21.71ms
- **Min Response Time**: ~5.97ms
- **Max Response Time**: ~43.03ms
- **Throughput**: Successfully handles queries per second
- **Error Rate**: 0%

### Optimization Tips

1. **Connection Pooling**: Nginx maintains 32 keepalive connections
2. **Buffering**: Enabled to prevent waiting on slow clients
3. **Gzip**: Enabled for text responses (reduces bandwidth by ~70%)
4. **Caching**: Can be added easily (not currently implemented)

## Docker Volume

### `nginx_logs` Volume
Stores nginx logs persistently:
```bash
# View logs
docker volume inspect finalprojectbdg_nginx_logs

# Access logs directly
docker run --rm -v finalprojectbdg_nginx_logs:/logs alpine tail -20 /logs/access.log
```

## Troubleshooting

### Nginx Not Starting
```bash
# Check logs
docker-compose logs nginx

# Validate configuration
docker-compose exec nginx nginx -t
```

### High Response Times
- Check upstream service health: `http://localhost/health`
- Review nginx error logs
- Check database connectivity

### Port Already in Use
```bash
# Find process using port 80
sudo lsof -i :80
sudo lsof -i :8080

# Kill process (if needed)
sudo kill -9 <PID>
```

### Backend Service Unavailable (502/503)
- Ensure FastAPI app is running: `docker-compose ps`
- Check app logs: `docker-compose logs app`
- Verify app connectivity: `docker-compose exec nginx curl app:8000/health`

## Security Considerations

### Headers Added
- **CORS-related**: Can be added if needed
- **HSTS**: Can be enabled for HTTPS (change `http` to `https` in production)
- **CSP**: Can be added for additional protection

### Current Security Measures
- ✓ XSS protection
- ✓ Clickjacking prevention
- ✓ MIME type sniffing prevention
- ✓ Referrer policy
- ✓ Read-only config file
- ✓ Deny access to dotfiles

### Production Recommendations
1. Enable HTTPS/TLS (SSL certificates)
2. Add HSTS header
3. Implement rate limiting stricter limits
4. Add WAF (Web Application Firewall) rules
5. Regular security updates to nginx
6. Monitor logs for suspicious activity
7. Implement DDoS protection

## Updating Nginx Configuration

### Without Restarting (Graceful Reload)
```bash
# Validate config
docker-compose exec nginx nginx -t

# Reload with zero downtime
docker-compose exec nginx nginx -s reload
```

### After Modifying nginx.conf
1. Edit `nginx.conf`
2. Test: `docker-compose exec nginx nginx -t`
3. Reload: `docker-compose exec nginx nginx -s reload`

### Full Restart
```bash
docker-compose restart nginx
```

## Scaling Considerations

### Multiple Backend Instances
```nginx
upstream gaming_stats_api {
    server app1:8000;
    server app2:8000;
    server app3:8000;
    keepalive 32;
}
```

### Load Balancing Algorithms
```nginx
upstream gaming_stats_api {
    least_conn;  # Least connections
    # or ip_hash;  # IP-based sticky sessions
    # or random;   # Random distribution
    server app:8000;
}
```

## Monitoring

### Logs Format Analysis
```bash
# Total requests
docker-compose exec -T nginx wc -l /var/log/nginx/access.log

# Requests by status code
docker-compose exec -T nginx awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c

# Top endpoints
docker-compose exec -T nginx awk '{print $7}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10

# Average response time
docker-compose exec -T nginx awk -F'rt=' '{print $2}' /var/log/nginx/access.log | awk -F' ' '{total+=$1; count++} END {print "Average:", total/count "s"}'
```

## Resources

- [Nginx Documentation](https://nginx.org/en/docs/)
- [Nginx as Reverse Proxy](https://nginx.org/en/docs/http/ngx_http_proxy_module.html)
- [Docker Compose Service Discovery](https://docs.docker.com/compose/networking/)
- [FastAPI Behind Proxies](https://fastapi.tiangolo.com/advanced/behind-a-proxy/)

## Maintenance

### Regular Checks
- Weekly: Review logs for errors
- Monthly: Check for nginx updates
- Quarterly: Review security headers and rate limits

### Log Rotation
To prevent logs from growing too large:
```bash
# Manual cleanup (keep last 7 days)
docker-compose exec -T nginx sh -c 'find /var/log/nginx -type f -mtime +7 -delete'
```

## Summary

This nginx setup provides:
- ✓ Efficient reverse proxy with connection pooling
- ✓ Rate limiting for DDoS protection
- ✓ Security headers for web protection
- ✓ Comprehensive logging for monitoring
- ✓ Performance optimization (gzip, buffering)
- ✓ Health checks for reliability
- ✓ Easy configuration management
- ✓ Graceful reloading without downtime
