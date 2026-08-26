#!/bin/sh
set -e
# Populate the filter file from the allowlist mounted at runtime
cp /etc/tinyproxy/allowed-domains.txt /etc/tinyproxy/filter
exec tinyproxy -d -c /etc/tinyproxy/tinyproxy.conf
