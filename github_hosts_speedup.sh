#!/bin/bash
set -e

# 需要加速的 GitHub 相关域名
DOMAINS=(
    "github.com"
    "assets-cdn.github.com"
    "avatars.githubusercontent.com"
    "codeload.github.com"
    "github.io"
    "githubusercontent.com"
    "raw.githubusercontent.com"
    "user-images.githubusercontent.com"
    "gist.github.com"
)

# 解析单个域名的 IP（先 ping，失败则 dig）
get_ip() {
    local host=$1
    local ip
    ip=$(ping -c 1 -W 2 "$host" 2>/dev/null | head -1 | awk -F'[()]' '{print $2}')
    if [[ -z "$ip" ]]; then
        ip=$(dig +short "$host" | head -1)
    fi
    # 过滤无效响应（确保是有效的 IPv4 地址）
    if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$ip"
    fi
}

# 备份 hosts 文件
BACKUP="/etc/hosts.backup.$(date +%Y%m%d%H%M%S)"
echo "Backing up /etc/hosts to $BACKUP"
sudo cp /etc/hosts "$BACKUP"

# 创建临时文件
TEMP_FILE=$(mktemp)

# 添加标准的 hosts 文件头部
cat >> "$TEMP_FILE" << 'EOF'
##
# Host Database
#
# localhost is used to configure the loopback interface
# when the system is booting.  Do not change this entry.
##
127.0.0.1       localhost
255.255.255.255 broadcasthost
::1             localhost

EOF

# 复制原 hosts 并去除已有的目标域名条目
while IFS= read -r line; do
    skip=0
    for domain in "${DOMAINS[@]}"; do
        if [[ "$line" == *"$domain"* ]]; then
            skip=1
            break
        fi
    done
    if [[ $skip -eq 0 ]]; then
        echo "$line"
    fi
done < /etc/hosts >> "$TEMP_FILE"

# 为每个域名解析 IP 并追加到临时文件
for domain in "${DOMAINS[@]}"; do
    ip=$(get_ip "$domain")
    if [[ -n "$ip" ]]; then
        echo "$ip    $domain" | sudo tee -a "$TEMP_FILE" > /dev/null
        echo "Resolved $domain -> $ip"
    else
        echo "Failed to resolve $domain"
    fi
done

# 替换原 hosts 文件
sudo mv "$TEMP_FILE" /etc/hosts
echo "Updated /etc/hosts"
echo "You may need to flush DNS cache:"
echo "  sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder  # macOS"
echo "  sudo systemd-resolve --flush-caches                           # systemd"
echo "  sudo resolvectl flush-caches                                  # newer systemd"
echo "  sudo /etc/init.d/nscd restart                                 # nscd"
