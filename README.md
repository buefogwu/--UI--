# 康复 UI 项目探索

ComfyUI + MiniMax H3 在 RTX 4080 SUPER 16GB 上的部署与工作流探索。

## 硬件/环境

- GPU: NVIDIA GeForce RTX 4080 SUPER 16GB
- ComfyUI 启动参数: `--novram --use-sage-attention`
- 主用模型: `minimax_h3_fl2va_pruned_int8_convrot.safetensors`（pruned，省显存）

## 仓库内容

- `workflows/（主用）minimax_h3_ref5_5img_ui_enhancer.json`
  - 主用 ref5 工作流（首帧图生音视频 + 参考图 + 提示词优化）
  - 含简化版分辨率参考面板（手动填写 width/height）
- `workflows/minimax_h3_turbo_4080_8step_enhancer.json`
  - T8 Turbo 8 步快速工作流
- `custom_nodes/comfyui-minimax-h3-prompt-enhancer-T8/nodes.py`
  - 修改后的 MiniMax H3 Prompt Enhancer 节点源码

## 主要改动

### Prompt Enhancer 节点

- 强制走 OpenAI 兼容模式（`api_mode` 在 `execute()` 内固定为 `OPENAI_API_MODE`）。
- 保留旧 API 模式选项以避免浏览器缓存导致"无效输入"。
- `api_key`、`custom_model`、`openai_base_url` 等字段支持环境变量兜底：
  - `OPENAI_API_KEY`
  - `OPENAI_BASE_URL=https://api.minimaxi.com/v1`
  - `OPENAI_MODEL=MiniMax-M3`
- 增加背景音乐/环境底噪开关，关闭时分别强制输出 `non_diegetic_music: N/A` / `overall_soundscape: N/A`。
- T2VA 模式下自动忽略参考媒体，不再报错。
- 增加 Base URL 无效时 fallback 到 `OPENAI_BASE_URL` 环境变量。
- 剥离 `<think>` 推理内容污染。
- 对齐 `define_schema()` 与 `execute()` 参数顺序，避免 `widgets_values` 清空后错位。

### 工作流

- ref5 主用工作流已回滚到自动分辨率面板之前的简洁状态。
- 新增 `Note` 参考面板，列出 4080 SUPER 16GB + pruned 模型可安全运行的 16:9 分辨率：

| MP | 分辨率 | 建议 |
|---|---|---|
| 0.30 | 736×416 | 最安全，长时首选 |
| 0.325 | 768×448 | 安全，Turbo/长时稳 |
| 0.50 | 960×544 | 主用推荐，5-8s 稳 |
| 0.75 | 1152×640 | 8s 内可试 |
| 0.90 | 1280×704 | 上限，建议 5s |

## 注意事项

- 节点 schema 改动后，必须重启 ComfyUI 并强制刷新浏览器（`Ctrl/Cmd + Shift + R`）。
- 工作流中 Prompt Enhancer 的 `widgets_values` 已清空，加载后会自动填入默认值；API Key 留空即可走环境变量。
-  Workflow JSON 中不含 API Key，但部署时仍需在 systemd/环境变量中配置。
