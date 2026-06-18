#!/usr/bin/env bash
# Usage: ./push.sh "mô tả thay đổi"
# Commit toàn bộ thay đổi và push lên GitHub (Vercel sẽ tự deploy).
set -e
git add .
git commit -m "${1:-update}"
git push
