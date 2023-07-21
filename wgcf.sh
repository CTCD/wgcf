type wg || { echo "Please install: sudo apt install wireguard-tools" && exit 0; }
private_key=$(wg genkey)
public_key=$(wg pubkey <<<"$private_key")

curl --request POST 'https://api.cloudflareclient.com/v0a2158/reg' \
    --header 'Content-Type: application/json' \
    --header 'User-Agent: okhttp/3.21' \
    --header 'CF-Client-Version: 6.21' \
    --header "Cf-Access-Jwt-Assertion: $1" \
    --data '{"key": "'$public_key'"}' |
    python3 -m json.tool >/etc/wireguard/wgcfreg.json

[[ ! -s /etc/wireguard/wgcfreg.json || $(grep 'error' /etc/wireguard/wgcfreg.json) ]] && {
    rm /etc/wireguard/wgcfreg.json
    curl -s https://api.github.com/repos/ViRb3/wgcf/releases/latest | grep "browser_download_url" | awk -F'"' '/linux_arm64/{print $4}' | xargs wget -O /etc/wireguard/wgcf
    chmod +x /etc/wireguard/wgcf
    cd /etc/wireguard/
    rm wgcf-account.toml
    echo | ./wgcf register
    ./wgcf generate
    wg-quick down wgcf0
    grep -v "DNS =" /etc/wireguard/wgcf-profile.conf >/etc/wireguard/wgcf0.conf
    sed -i '3i Table = 1234' /etc/wireguard/wgcf0.conf
    wg-quick up wgcf0
} || {
    wg-quick down wgcf0
    echo "[Interface]
    PrivateKey = $private_key
    Address = $(awk -F'"' '/"addresses"/{getline; print $4}' /etc/wireguard/wgcfreg.json)/32, $(awk -F'"' '/"addresses"/{getline; getline; print $4}' /etc/wireguard/wgcfreg.json)/128
    MTU = 1280
    Table = 1234

    [Peer]
    PublicKey = $(awk -F'"' '/"public_key"/{print $4}' /etc/wireguard/wgcfreg.json)
    AllowedIPs = 0.0.0.0/0, ::/0
    Endpoint = $(awk -F'"' '/"host"/{print $4}' /etc/wireguard/wgcfreg.json)" >/etc/wireguard/wgcf0.conf
    wg-quick up wgcf0
}
