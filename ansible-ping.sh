#!/bin/bash
INVENTORY="inventory.yml"

echo "============================================"
echo " Gaming Stats API — Ansible Infrastructure"
echo "============================================"

echo ">>> [1/3] Pinging backend (FastAPI)..."
ansible backend -i $INVENTORY -m ping

echo ">>> [2/3] Pinging database (MySQL) via raw..."
ansible database -i $INVENTORY -m raw -a "mysqladmin ping -u user -ppassword 2>/dev/null && echo pong"

echo ">>> [3/3] Pinging proxy (Nginx) via raw..."
ansible proxy -i $INVENTORY -m raw -a "nginx -t 2>&1 && echo pong"

echo "============================================"
echo " All checks complete."
echo "============================================"
