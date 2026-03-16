# GitHub Hosts Speedup

通过修改系统 hosts 文件来加速 GitHub 访问。

## 工作原理

脚本通过 `ping` 命令获取常用 GitHub 域名的 IP，然后将这些 IP 写入系统的 `/etc/hosts` 文件。这样可以将域名解析到特定 IP，绕过 DNS 污染或选择更优路由，从而加快 GitHub 访问速度。

## 支持的域名

- `github.com` - 代码仓库
- `assets-cdn.github.com` - 静态资源
- `avatars.githubusercontent.com` - 头像
- `codeload.github.com` - 代码下载
- `github.io` - GitHub Pages
- `githubusercontent.com` - 用户内容
- `raw.githubusercontent.com` - 原始文件
- `user-images.githubusercontent.com` - 用户图片

## 使用方法

```bash
# 添加执行权限
chmod +x github_hosts_speedup.sh

# 运行脚本（需要管理员权限）
sudo ./github_hosts_speedup.sh
```

运行后需要刷新 DNS 缓存：

```bash
# macOS
sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder

# Linux (systemd)
sudo systemd-resolve --flush-caches
# 或
sudo resolvectl flush-caches

# Linux (nscd)
sudo /etc/init.d/nscd restart
```

## 注意事项

- 需要管理员权限来修改 `/etc/hosts`
- 脚本会备份原 hosts 文件到 `/etc/hosts.backup.时间戳`
- IP 地址可能变化，建议定期重新运行
- 如需恢复，删除 hosts 中以 `github` 开头的行即可

## License

MIT License