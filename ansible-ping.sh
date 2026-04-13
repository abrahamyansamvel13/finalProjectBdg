#!/bin/bash
set -e

INVENTORY="inventory.yml"

echo "============================================"
echo " Gaming Stats API — Ansible Infrastructure"
echo "============================================"
echo ""

echo ">>> [1/5] Pinging backend (FastAPI)..."
ansible backend -i $INVENTORY -m ping
echo ""

echo ">>> [2/5] Pinging database (MySQL) via raw..."
ansible database -i $INVENTORY -m raw -a "mysqladmin ping -u user -ppassword 2>/dev/null && echo pong"
echo ""

echo ">>> [3/5] Pinging proxy (Nginx) via raw..."
ansible proxy -i $INVENTORY -m raw -a "nginx -t 2>&1 && echo pong"
echo ""

echo ">>> [4/5] Checking backend process..."
ansible backend -i $INVENTORY -m shell -a "ps aux | grep uvicorn | grep -v grep"
echo ""

echo ">>> [5/5] Disk usage on backend..."
ansible backend -i $INVENTORY -m shell -a "df -h /"
echo ""

echo "============================================"
echo " All checks complete."
echo "============================================"