#!/bin/sh

# 进入工作目录
cd /root/cfnb

# 💡 注入系统路径，防止后台 Crontab 定时任务运行时找不到 git 或 curl 命令
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# ==================== 配置区域 ====================
TG_BOT_TOKEN="8501584137:AAHbM9yR536RsPOeVVxp_M_MZc9WgHlooCE"
TG_CHAT_ID="-1003960585459"
TG_PROXY_DOMAIN="tg1.frenda.de5.net" 
# ==================================================


# ==================== 1. 核心修正：捕获内层新数据 ====================
if [ -f "ip.txt" ]; then
    echo "1. 🎯 破案了！发现内层刚生成的测速结果，正在转换为新数据缓存..."
    # 💡 把刚生成的测速结果改名，腾出 ip.txt 这个文件名给后面合并用
    mv ip.txt ip_new.txt
else
    echo "1. ❌ 警告：未在当前目录找到优选结果 ip.txt，请检查主程序是否正常运行！"
fi


# ==================== 2. 安全同步云端（绝对保护本地配置） ====================
echo "2. 📦 正在安全同步云端最新状态（保护本地 config.json 等修改）..."

# 妥善隔离本地修改过的文件（如 config.json）
git stash save "Auto-backup local configs" > /dev/null 2>&1

# 丝滑拉取云端最新的 keep.txt，并让本地 Git 指针推进，防止后续 push 冲突
git pull origin main

# 原封不动释放本地修改
git stash pop > /dev/null 2>&1


# ==================== 3. 传家宝置顶·智能合并区域 ====================
if [ -f "ip_new.txt" ]; then
    echo "3. 🧠 开始进行智能合并与去重..."
    
    if [ -f "keep.txt" ]; then
        echo "   -> ✅ 传家宝占领头部！优先保留 keep.txt，随后追加新测速 IP..."
        # 💡 调整顺序：keep.txt 在前，ip_new.txt 在后。传家宝绝对置顶！
        awk -F'[:#]' '!seen[$1]++' keep.txt ip_new.txt > ip.txt
    else
        echo "   -> ⚠️ 未检测到 keep.txt，直接沿用新测速结果。"
        mv ip_new.txt ip.txt
    fi
    
    # 清理临时缓存
    rm -f ip_new.txt
else
    echo "3. ℹ️ 没有找到新测速数据，跳过智能合并。"
fi
# ==========================================================


# ==================== 4. GitHub 推送区域 ====================
echo "4. 🚀 开始通过 CF 反代推送到 GitHub..."

if [ -f "ip.txt" ]; then
    git add ip.txt
    
    # 精准检查 ip.txt 是否真的有数据变化
    if [ -n "$(git status --porcelain ip.txt)" ]; then
        git commit -m "Automated IP update with latest benchmark: $(date '+%Y-%m-%d %H:%M:%S')"
        
        if git push origin main; then
            echo "   -> 🎉 融合了传家宝的 ip.txt 已成功同步至 GitHub 仓库！"
        else
            echo "   -> ❌ GitHub 推送失败，请检查网络或 Token。"
        fi
    else
        echo "   -> 😴 数据无任何变化，跳过 GitHub 推送。"
    fi

    # ==================== 5. Telegram 推送区域 ====================
    echo "5. 📤 正在通过 CF 代理将最终的优选 IP 推送到 Telegram..."
    IP_LIST=$(head -n 20 ip.txt)
    
    MESSAGE="✨ <b>Cloudflare 优选 IP 刷新成功</b> ✨

<code>${IP_LIST}</code>"
    
    curl -s -X POST "https://${TG_PROXY_DOMAIN}/bot${TG_BOT_TOKEN}/sendMessage" \
        -H "x-tg-verify: MyPrivateSecret2026" \
        -d "chat_id=${TG_CHAT_ID}" \
        --data-urlencode "text=${MESSAGE}" \
        -d "parse_mode=HTML" > /dev/null

    echo "============================================="
    echo "🎉【大功告成】传家宝已置顶合并，本地配置完好无损！"
    echo "============================================="
else
    echo "❌ 错误：未生成最终的 ip.txt。"
fi
