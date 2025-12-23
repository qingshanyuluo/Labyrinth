#!/bin/bash

# ==============================================================================
# 🔒 PROJECT ETERNAL LOG (APPEND ONLY)
# ==============================================================================
#
# [未来解密说明书 / Decryption Manual for the Future]
# 如果脚本失效，请使用以下 OpenSSL 标准参数手动解密：
# If this script fails, use these standard parameters to decrypt manually:
#
# Algorithm: AES-256-CBC
# Key Derivation: PBKDF2
# Hash Digest: SHA256
# Iterations: 100000
# Salt: Enabled
# Encoding: Base64
#
# [解密命令示例 / Command to Decrypt]
# openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -md sha256 -a -in memory.dat
#
# ==============================================================================

# --- 配置区 (Configuration) ---
DATA_FILE="memory.dat"
TEMP_FILE="memory.dat.tmp"

# 锁死加密参数，确保未来几十年的兼容性
# -aes-256-cbc: 军用标准加密
# -pbkdf2: 现代密钥派生函数
# -iter 100000: 增加暴力破解难度
# -md sha256: 强制使用 SHA256 哈希，防止默认算法改变
# -a: Base64 编码，纯文本格式，Git友好
OPENSSL_ARGS="-aes-256-cbc -pbkdf2 -iter 100000 -md sha256 -a -salt"

# --- 1. 获取密码 (只在内存中存在) ---
echo -n "🔑 请输入密码 (Password): "
read -s PASSWORD
echo ""
export PASSWORD

# --- 2. 获取输入 (Ctrl+D 结束) ---
echo "-------------------------------------------------"
echo "📝 请输入新记忆 (完成后按 Ctrl+D 保存):"
echo "-------------------------------------------------"
NEW_CONTENT=$(cat)

# 防止空写入
if [ -z "$NEW_CONTENT" ]; then
    echo "❌ 内容为空，已取消。"
    unset PASSWORD
    exit 0
fi

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# --- 3. 核心逻辑：流式追加 (Stream Append) ---
echo "⚙️ 正在加密处理..."

if [ -f "$DATA_FILE" ]; then
    # 【验证密码】
    # 先尝试解密但不输出，只检查退出代码
    # 这一步至关重要！防止用错误密码覆盖掉原文件
    if ! openssl enc -d $OPENSSL_ARGS -pass env:PASSWORD -in "$DATA_FILE" > /dev/null 2>&1; then
        echo "⛔️ 密码错误！无法追加，原文件未修改。"
        unset PASSWORD
        exit 1
    fi

    # 【追加逻辑】
    # ( 解密旧数据流 + 打印新数据 ) | 重新加密 -> 临时文件
    (
        openssl enc -d $OPENSSL_ARGS -pass env:PASSWORD -in "$DATA_FILE" 2>/dev/null
        echo ""
        echo "--- [$TIMESTAMP] ---"
        echo "$NEW_CONTENT"
    ) | openssl enc $OPENSSL_ARGS -pass env:PASSWORD -out "$TEMP_FILE"

else
    # 【新建逻辑】
    # 直接加密新数据 -> 文件
    (
        echo "--- [$TIMESTAMP] ---"
        echo "$NEW_CONTENT"
    ) | openssl enc $OPENSSL_ARGS -pass env:PASSWORD -out "$TEMP_FILE"
fi

# --- 4. 安全替换 ---
if [ $? -eq 0 ]; then
    mv "$TEMP_FILE" "$DATA_FILE"
    echo "✅ 记录已追加。 (文件: $DATA_FILE)"
else
    echo "❌ 写入失败，原文件保持不变。"
    rm -f "$TEMP_FILE"
fi

# 清理内存密码
unset PASSWORD
