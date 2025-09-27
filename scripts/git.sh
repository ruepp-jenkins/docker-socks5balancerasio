#!/bin/bash
set -e
echo "Fetch remote repository"

git clone https://github.com/Socks5Balancer/Socks5BalancerAsio.git repo
git clone https://github.com/Socks5Balancer/html.git repo_html

# replace original Dockerfile
rm repo/Dockerfile
cp Dockerfile repo/Dockerfile
