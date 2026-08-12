# MiniMax H3 Prompt Enhancer 节点改动记录

## 改动目标

让 `comfyui-minimax-h3-prompt-enhancer-T8` 节点稳定运行在 OpenAI 兼容模式下，适配 MiniMax-M3 / 其他 OpenAI 兼容接口，并解决 ComfyUI 浏览器缓存、widgets_values 错位、T2VA 参考媒体报错等问题。

## 关键改动清单

### 1. API 模式强制为 OpenAI 兼容

- `API_MODES` 恢复为包含旧选项 `[SEEDANCE_API_MODE, AI_WORKSHOP_API_MODE, OPENAI_API_MODE]`，避免旧工作流/缓存报"无效输入"。
- `execute()` 内强制 `api_mode = OPENAI_API_MODE`。
- 节点显示名改为 `MiniMax H3 Prompt Enhancer (OpenAI-compatible)`。

### 2. 环境变量兜底

| 字段 | 环境变量 |
|---|---|
| API Key | `OPENAI_API_KEY` |
| Base URL | `OPENAI_BASE_URL`（默认 `https://api.minimaxi.com/v1`） |
| 模型 ID | `OPENAI_MODEL`（默认 `MiniMax-M3`） |

`_provider_config()` 会过滤掉 `LEGACY_UI_VALUES` 等无效值，并在 URL 不合法时 fallback 到环境变量。

### 3. 字段可保存、可手动输入

- 去掉 `api_key` 的 `force_input=True`，恢复为普通文本框。
- 去掉 `custom_model`、`openai_base_url`、`openai_video_urls` 的 `socketless=True`，保存工作流时不再丢失。

### 4. 音频开关

增加两个布尔开关：
- **背景音乐**：关闭时强制 `non_diegetic_music: N/A`
- **环境底噪**：关闭时强制 `overall_soundscape: N/A`

开关状态通过 `execute → enhance_prompt → _build_messages → _build_user_instruction` 传递，并在 system prompt 中作为最高优先级规则。

### 5. T2VA 参考媒体处理

`_validate_inputs()` 中，T2VA 遇到 reference_images/reference_videos 时打印警告并自动忽略，不再报错。

### 6. `<think>` 推理内容剥离

`_request_completion()` 中用正则 `re.sub(r"<think>.*?</think>", "", content, flags=re.DOTALL)` 移除推理内容，避免污染最终提示词。

### 7. 超时与重试

OpenAI 兼容端点连接超时从 `(20, 300)` 改为 `(60, 300)`，并增加 3 次指数退避重试。

### 8. Schema 与前端序列化顺序对齐

2026-08-12 修复 `define_schema()` 中 widget 顺序与前端 `SERIALIZED_WIDGET_NAMES` 序列化数组不一致的问题，彻底解决 `widgets_values` 错位导致的验证错误（如 `description_word_target`、`case_template`、`rewrite_mode` 类型不匹配）。

**根因**：前端 `minimax_h3_prompt_enhancer.js` 的 `onSerialize` 强制按固定数组保存 `widgets_values`，但后端 schema 的 widget 顺序不同。ComfyUI 加载时按后端自然顺序（`input_order`）解析 `widgets_values`，顺序不一致就导致每个 widget 拿到错误类型的值。

**最终一致的 widget 顺序（与 `SERIALIZED_WIDGET_NAMES` 完全一致）**：

1. prompt
2. task_type
3. duration_seconds
4. shot_count
5. rewrite_mode
6. description_word_target
7. output_language
8. prompt_mode
9. official_skill_profile
10. creative_preset
11. case_template
12. api_mode
13. ai_workshop_model
14. custom_model
15. reference_context
16. constraints
17. api_key
18. reference_template
19. openai_base_url
20. openai_video_urls
21. seed
22. control_after_generate（seed 的联动控件）
23. enabled
24. use_background_music
25. use_ambient_noise

**实现细节**：
- 将 `enabled`、`use_background_music`、`use_ambient_noise` 改为 `optional=True`，使其进入 optional 分组并排在 `seed` 之后。
- 前端 `SERIALIZED_WIDGET_NAMES` 增加 `"enabled"`、`"use_background_music"`、`"use_ambient_noise"` 三项。
- 主用工作流 `widgets_values` 同步补齐为 25 项，最后三项为 `True, True, True`。

## 源码文件

- `custom_nodes/comfyui-minimax-h3-prompt-enhancer-T8/nodes.py`

## 回滚方法

如需回滚节点源码：

```bash
cd /home/fogai/ComfyUI-Recovery-Project
git log --oneline
git checkout <commit-hash> -- custom_nodes/comfyui-minimax-h3-prompt-enhancer-T8/nodes.py
cp custom_nodes/comfyui-minimax-h3-prompt-enhancer-T8/nodes.py /home/fogai/ComfyUI/custom_nodes/comfyui-minimax-h3-prompt-enhancer-T8/
systemctl --user restart comfyui
```

### 9. OpenAI 兼容模式写入超时修复

- 2026-08-12 新增 `OPENAI_COMPATIBLE_REQUEST_TIMEOUT = (180, 300)`。
- OpenAI 兼容端点（内联 base64 图片）使用 180 秒连接超时，替代默认 60 秒。
- Seedance 端点（单独上传媒体）保持 60 秒不变。

### 10. API 模式下拉框顺序调整

- 2026-08-12 将 `API_MODES` 顺序从 `[Seedance, AI工坊, OpenAI]` 改为 `[OpenAI, Seedance, AI工坊]`。
- 目的是：当浏览器缓存或旧 `widgets_values` 导致错位时，默认显示 OpenAI 兼容接口而非 "贞贞平价小屋"。
- `execute()` 内部仍强制使用 `OPENAI_API_MODE`，不受 UI 显示影响。

### 11. Ref2VA 自动忽略首帧/尾帧输入

- 2026-08-12 修改 `_validate_inputs`：Ref2VA 遇到 `first_frame`/`last_frame` 时打印警告并忽略，不再强制要求用户手动断线。
- 与 T2VA 自动忽略参考媒体的处理保持一致。

### 12. 全模式通用输入容错

- 2026-08-12 进一步放宽 `_validate_inputs`：
  - **I2VA**：仍需要 `first_frame`；若误连 `last_frame` / `reference_images` / `reference_videos`，自动忽略并打印警告，不再报错。
  - **FL2VA**：仍需要 `first_frame` + `last_frame`；误连参考图/视频时自动忽略。
  - **L2VA**：仍需要 `last_frame`；误连 `first_frame` / 参考图/视频时自动忽略。
  - **Ref2VA**：未连参考媒体但连了 `first_frame`/`last_frame` 时，自动把它们提升为参考图，避免 "requires reference image" 错误。
- 这样一份工作流可同时连好首帧、尾帧、参考图，切换 `task_type` 时无需反复拔线。

### 13. 主用 ref5 工作流连线更新

- 将 5 张参考图（LoadImage 节点 30-34）同时连到：
  - `MiniMaxH3AudioConditioningT8` 的 `ref_images.ref_image_0~3`（保持原有逻辑）
  - `MiniMaxH3PromptEnhancerT8` 的 `reference_images.reference_image_0~4`
- 将第 5 张参考图（节点 34）同时连到 `MiniMaxH3PromptEnhancerT8.last_frame`，使 FL2VA / L2VA 可用。
- `first_frame` 保持由节点 30 连接。


### 14. 可选参考视频/音频输入的连线规范

- `LoadVideo`（节点 38）不能直接连 `AudioConditioning.ref_videos`，因为后者槽类型为 `IMAGE`。
- 空的 `LoadVideo`/`LoadAudio` 会传入目录路径或空路径，导致运行时错误。
- 测试工作流中已将这两个节点默认悬空，用户上传文件后按需手动连接。
- 推荐做法：
  - 参考视频 → PromptEnhancer.reference_videos（仅当确实需要参考视频时）
  - 参考音频 → AudioConditioning.ref_audios（上传音频后连接）
  - 视频抽帧/关键帧 → AudioConditioning.ref_videos（类型为 IMAGE）


### 15. 五模式自动化测试与 AudioConditioning 默认值修复

- 2026-08-13 通过 `/tmp/run_h3_modes.py` 自动跑通 T2VA / I2VA / FL2VA / L2VA / Ref2VA。
- 修复 AudioConditioning `widgets_values` 中的占位值：
  - `width=1152`, `height=640`, `length=56`
  - `task_type='auto'`（跟随 PromptEnhancer）
  - `audio_mode='native'`
  - `audio_denoise_strength=0.35`
  - `add_source_as_reference=False`
  - `prompt_primary_audio_ordinal=0`
  - `strict_prompt_tags=False`
  - `ref_image_size='match'`
  - `reference_video_policy='official_2_to_15s'`
- 这些默认值让工作流加载后即可直接切换模式运行，无需每次手动修正 AudioConditioning。
