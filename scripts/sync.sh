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

mkdir -p "$REPO_DIR/workflows" "$REPO_DIR/custom_nodes/comfyui-minimax-h3-prompt-enhancer-T8"

cp "$COMFY_DIR/custom_nodes/comfyui-minimax-h3-prompt-enhancer-T8/nodes.py" \
   "$REPO_DIR/custom_nodes/comfyui-minimax-h3-prompt-enhancer-T8/"

cp "$COMFY_DIR/user/default/workflows/（主用）minimax_h3_ref5_5img_ui_enhancer.json" \
   "$REPO_DIR/workflows/"

cp "$COMFY_DIR/user/default/workflows/minimax_h3_turbo_4080_8step_enhancer.json" \
   "$REPO_DIR/workflows/" 2>/dev/null || true

cd "$REPO_DIR"
git add -A
git commit -m "$MSG" || echo "Nothing to commit"
git push
