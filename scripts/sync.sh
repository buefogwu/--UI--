#!/bin/bash
# 同步 ComfyUI 最新改动到 GitHub 项目
set -e

REPO_DIR="/home/fogai/ComfyUI-Recovery-Project"
COMFY_DIR="/home/fogai/ComfyUI"

if [ -z "$1" ]; then
    MSG="sync: $(date +"%Y-%m-%d %H:%M:%S")"
else
    MSG="$1"
fi

mkdir -p "$REPO_DIR/workflows" "$REPO_DIR/custom_nodes/comfyui-minimax-h3-prompt-enhancer-T8" "$REPO_DIR/custom_nodes/comfyui-minimax-h3-audio-T8" "$REPO_DIR/workflows/rhtv"

# --- 节点源码 ---
cp "$COMFY_DIR/custom_nodes/comfyui-minimax-h3-prompt-enhancer-T8/nodes.py" "$REPO_DIR/custom_nodes/comfyui-minimax-h3-prompt-enhancer-T8/"
cp "$COMFY_DIR/custom_nodes/comfyui-minimax-h3-audio-T8/nodes.py" "$REPO_DIR/custom_nodes/comfyui-minimax-h3-audio-T8/"

# --- 康复 UI 主用工作流（ref5 / Turbo / 测试）---
cp "$COMFY_DIR/user/default/workflows/（主用）minimax_h3_ref5_5img_ui_enhancer.json" "$REPO_DIR/workflows/" 2>/dev/null || true
cp "$COMFY_DIR/user/default/workflows/minimax_h3_turbo_4080_8step_enhancer.json" "$REPO_DIR/workflows/" 2>/dev/null || true
cp "$COMFY_DIR/user/default/workflows/（测试）minimax_h3_ref5_5img_novram_safe.json" "$REPO_DIR/workflows/" 2>/dev/null || true

# --- RHTV Lite 视频管线工作流（Ref2VA 六段式 schema 链路）---
for f in image2video prompt_optimize_video text2image text2image_with_character; do
    cp "$COMFY_DIR/user/default/workflows/$f.json" "$REPO_DIR/workflows/rhtv/" 2>/dev/null || echo "skip $f (not found)"
done

cd "$REPO_DIR"
git add -A
git commit -m "$MSG" || echo "Nothing to commit"
git push
