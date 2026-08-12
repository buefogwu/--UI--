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

### 8. Schema 与 execute 参数顺序对齐

2026-08-12 修复 `define_schema()` 中输入定义顺序与 `execute()` 参数顺序不一致的问题，避免 `widgets_values` 清空后默认值错位（表现为 API Key 为空、模型 ID 变成随机数）。

最终一致的参数顺序：

1. prompt
2. task_type
3. duration_seconds
4. rewrite_mode
5. description_word_target
6. first_frame
7. last_frame
8. reference_images
9. reference_videos
10. reference_context
11. constraints
12. api_key
13. output_language
14. prompt_mode
15. official_skill_profile
16. creative_preset
17. reference_template
18. api_mode
19. openai_base_url
20. openai_video_urls
21. seed
22. shot_count
23. ai_workshop_model
24. custom_model
25. case_template
26. enabled
27. use_background_music
28. use_ambient_noise

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
