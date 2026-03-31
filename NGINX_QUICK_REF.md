# Nginx Setup - Quick Reference

## Files Changed/Created

1. **nginx.conf** - Main nginx configuration (production-grade)
2. **docker-compose.yml** - Updated with nginx service
3. **test_nginx_setup.sh** - Bash test script
4. **test_nginx_setup.py** - Comprehensive Python test suite
5. **NGINX_SETUP.md** - Detailed documentation
6. **NGINX_QUICK_REF.md** - This quick reference

## Quick Start

```bash
# Start all services (MySQL, FastAPI, Nginx)
docker-compose up -d

# Check status
docker-compose ps

# Run tests
python3 test_nginx_setup.py          # Comprehensive test
bash test_nginx_setup.sh              # Bash test

# Access API
curl http://localhost/health         # Port 80
curl http://localhost:8080/health    # Port 8080 (alternate)
curl http://localhost/stats          # Get all stats
curl http://localhost/                # Root endpoint
```

## Architecture

```
Port 80 & 8080 (Host)
        ↓
   nginx:1.25-alpine (Reverse Proxy)
        ↓
   FastAPI:8000 (gaming_stats_api)
        ↓
   MySQL:3306 (gaming_stats_db)
```

## Key Features

### Security
- ✓ XSS protection header
- ✓ MIME type sniffing prevention
- ✓ Clickjacking prevention
- ✓ Read-only configuration

### Performance
- ✓ Gzip compression
- ✓ Connection pooling (32 keepalive)
- ✓ Optimized buffering
- ✓ Average latency: ~21ms

### Reliability
- ✓ Rate limiting (DDoS protection)
- ✓ Health checks
- ✓ Error handling
- ✓ Comprehensive logging

### Management
- ✓ Graceful reload (zero downtime)
- ✓ Easy configuration updates
- ✓ Persistent log volume
- ✓ Docker service discovery

## Configuration Locations

| Component | Location |
|-----------|----------|
| Nginx Config | `/home/samvel/Документы/finalProjectBdg/nginx.conf` |
| Compose File | `/home/samvel/Документы/finalProjectBdg/docker-compose.yml` |
| Logs | Docker volume `nginx_logs` |
| Docs | `NGINX_SETUP.md` |

## Rate Limiting

- **General Endpoints**: 10 req/sec + 20 req burst
- **Health Check**: 2 req/sec + 5 req burst

## Endpoints Accessible Through Nginx

| Endpoint | Method | Response |
|----------|--------|----------|
| `/health` | GET | `{"status": "healthy"}` |
| `/` | GET | `{"message": "Welcome to Gaming Stats API"}` |
| `/stats` | GET | List of all game statistics |
| `/stats/{id}` | GET | Single stat entry |
| `/stats` | POST | Create new stat entry |
| `/stats/player/{id}` | GET | Stats by player |
| `/stats/game/{name}` | GET | Stats by game |

## Logs

```bash
# View access logs
docker-compose exec nginx tail -f /var/log/nginx/access.log

# View error logs
docker-compose exec nginx tail -f /var/log/nginx/error.log

# View specific status codes
docker-compose exec -T nginx awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c
```

## Common Operations

### Reload Configuration (Zero Downtime)
```bash
docker-compose exec nginx nginx -t    # Validate
docker-compose exec nginx nginx -s reload  # Reload
```

### Restart Nginx
```bash
docker-compose restart nginx
```

### Check Container Status
```bash
docker-compose ps
sudo docker-compose ps (if permission denied)
```

### View Nginx Configuration
```bash
docker-compose exec nginx cat /etc/nginx/nginx.conf
```

### Validate Configuration
```bash
docker-compose exec nginx nginx -t
```

## Test Results

✓ **Connectivity**: Successfully connects to nginx on port 80
✓ **API Endpoints**: All endpoints accessible (/health, /, /stats)
✓ **Headers**: Security headers properly set
✓ **Performance**: Average 21.71ms response time
✓ **Alternate Port**: Port 8080 working correctly
✓ **Security**: X-Frame-Options, X-Content-Type-Options set
✓ **Error Handling**: 404 errors return proper JSON

## Troubleshooting

### Port Already in Use
```bash
sudo lsof -i :80      # Find process on port 80
sudo lsof -i :8080    # Find process on port 8080
sudo kill -9 <PID>    # Kill if needed
```

### Nginx Not Starting
```bash
docker-compose logs nginx        # Check error messages
docker-compose exec nginx nginx -t  # Validate config
```

### Backend Service Unavailable (502/503)
```bash
docker-compose logs app                    # Check app logs
docker-compose exec nginx curl app:8000/health  # Test backend
```

### Permission Denied with Docker
```bash
# Use sudo
sudo docker-compose ps
sudo docker-compose logs nginx
```

## Production Checklist

- [ ] Enable HTTPS/TLS certificates
- [ ] Add HSTS header
- [ ] Configure firewall rules
- [ ] Set up log rotation
- [ ] Monitor response times
- [ ] Review security headers
- [ ] Enable caching for static content
- [ ] Configure DDoS protection
- [ ] Set up alerting for errors
- [ ] Regular security updates

## Docker Volumes

```bash
# List volumes
docker volume ls | grep finalproject

# Inspect volume
docker volume inspect finalprojectbdg_nginx_logs

# View volume content
docker run --rm -v finalprojectbdg_nginx_logs:/logs alpine ls -la /logs
```

## Performance Optimization Tips

1. **Enable Caching**
   ```nginx
   proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=api_cache:10m;
   proxy_cache api_cache;
   ```

2. **Add Connection Pooling** (already enabled)
   ```nginx
   keepalive 32;  # ✓ Configured
   ```

3. **Enable Compression** (already enabled)
   ```nginx
   gzip on;  # ✓ Configured for text/json/js
   ```

## Notes

- Nginx config is read-only in container (`:ro` flag)
- Configuration changes require reload/restart
- Service discovery uses Docker DNS (`app:8000`)
- All services on same Docker network (`app-network`)
- Database port 3306 NOT exposed to host (only through app)

## References

- Nginx Documentation: https://nginx.org/en/docs/
- Docker Compose Docs: https://docs.docker.com/compose/
- FastAPI+ Proxy: https://fastapi.tiangolo.com/advanced/behind-a-proxy/
