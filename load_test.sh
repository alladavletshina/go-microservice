#!/bin/bash

echo "=== EXTENDED LOAD TESTING ==="
echo ""

echo "1. Quick test (10 seconds):"
wrk -t4 -c100 -d10s http://localhost:8080/api/users

echo ""
echo "2. Standard test (30 seconds):" 
wrk -t4 -c100 -d30s http://localhost:8080/api/users

echo ""
echo "3. High concurrency test (10 seconds):"
wrk -t8 -c500 -d10s http://localhost:8080/api/users
