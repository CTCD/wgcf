#!/bin/bash

upc_type() {
    case "$(uname -m)" in
    x86_64 | amd64) echo 'amd64' ;;
    armv8 | arm64 | aarch64) echo 'arm64' ;;
    *) red "CPU architecture not supported" && exit 0 ;;
    esac
}

generate_random_ipv4() {
    echo "162.159.192.$((RANDOM % 255))"
    echo "162.159.193.$((RANDOM % 255))"
    echo "162.159.195.$((RANDOM % 255))"
    echo "162.159.204.$((RANDOM % 255))"
    echo "188.114.96.$((RANDOM % 255))"
    echo "188.114.97.$((RANDOM % 255))"
    echo "188.114.98.$((RANDOM % 255))"
    echo "188.114.99.$((RANDOM % 255))"
}

generate_random_ipv6() {
    printf '2606:4700:d%d::%x:%x:%x:%x' $((RANDOM % 2)) $((RANDOM * 2 + RANDOM % 2)) $((RANDOM * 2 + RANDOM % 2)) $((RANDOM * 2 + RANDOM % 2)) $((RANDOM * 2 + RANDOM % 2))
}

echo "162.159.192.1" >ip.txt
while [ $(wc -l <ip.txt) -lt 100 ]; do
    address=$(generate_random_ipv4)
    if ! grep -q "$address" ip.txt; then
        echo "$address" >>ip.txt
    fi
done

while [ $(wc -l <ip.txt) -lt 200 ]; do
    address=$(generate_random_ipv6)
    if ! grep -q "$address" ip.txt; then
        echo "[$address]" >>ip.txt
    fi
done

wget https://raw.githubusercontent.com/CTCD/wgcf/main/warp-yxip-linux-$(upc_type) -O yxip
chmod +x yxip && ./yxip
cat result.csv | head -31
rm -f ip.txt result.csv yxip.sh
