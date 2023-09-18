[ $EUID -ne 0 ] && echo "Please run as root" && exit 0
type wg || { echo "Please install wireguard-tools" && exit 0; }

upc_type() {
    case "$(uname -m)" in
    x86_64 | amd64) echo 'amd64' ;;
    armv8 | arm64 | aarch64) echo 'arm64' ;;
    *) red "CPU architecture not supported" && exit 0 ;;
    esac
}

private_key=$(wg genkey)
public_key=$(wg pubkey <<<"$private_key")

curl --request POST 'https://api.cloudflareclient.com/v0a2158/reg' \
    --header 'Content-Type: application/json' \
    --header 'User-Agent: okhttp/3.21' \
    --header 'CF-Client-Version: 6.21' \
    --header "Cf-Access-Jwt-Assertion: $1" \
    --data '{"key": "'$public_key'"}' |
    python3 -m json.tool >/etc/wireguard/wgcfreg.json

[[ ! -s /etc/wireguard/wgcfreg.json || ! $(grep 'public_key' /etc/wireguard/wgcfreg.json) ]] && {
    cd /etc/wireguard/
    curl -s https://api.github.com/repos/ViRb3/wgcf/releases/latest | grep "browser_download_url" | awk -F'"' '/'linux_$(upc_type)'/{print $4}' | xargs wget -O wgcf
    chmod +x wgcf
    rm -f wgcfreg.json wgcf-account.toml
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
    Address = $(awk -F'"' '/"addresses"/{endpoint_found=1; next} endpoint_found && /"v4"/{print $4; exit}' /etc/wireguard/wgcfreg.json)/32, $(awk -F'"' '/"addresses"/{endpoint_found=1; next} endpoint_found && /"v6"/{print $4; exit}' /etc/wireguard/wgcfreg.json)/128
    MTU = 1500
    Table = 1234

    [Peer]
    PublicKey = $(awk -F'"' '/"peers"/{endpoint_found=1; next} endpoint_found && /"public_key"/{print $4; exit}' /etc/wireguard/wgcfreg.json)
    AllowedIPs = 0.0.0.0/0, ::/0
    Endpoint = $(awk -F'"' '/"endpoint"/{endpoint_found=1; next} endpoint_found && /"host"/{print $4; exit}' /etc/wireguard/wgcfreg.json)" >/etc/wireguard/wgcf0.conf
    wg-quick up wgcf0
}
