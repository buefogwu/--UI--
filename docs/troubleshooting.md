# 常见问题排查

## 1. "api_mode 无效输入" 或下拉框显示乱码（如"贞贞平价小屋"）

**原因**：浏览器缓存了旧 schema。

**解决**：
1. 重启 ComfyUI
2. 浏览器强制刷新 `Ctrl/Cmd + Shift + R`
3. 如仍乱码，清浏览器缓存或换隐私窗口

## 2. "Base URL must begin with http:// or https://"

**原因**：`widgets_values` 错位，`openai_base_url` 拿到了无效值。

**解决**：
- 检查节点中 Base URL 是否以 `http://` 或 `https://` 开头
- 或留空，让节点 fallback 到 `OPENAI_BASE_URL` 环境变量

## 3. "unknown model 398246384122850"

**原因**：`widgets_values` 错位，`custom_model` 拿到了随机数字。

**解决**：
- 清空 enhancer 节点的 `widgets_values`
- 重启 ComfyUI 并强制刷新浏览器
- 已在 2026-08-12 修复 schema/execute 顺序不一致问题

## 4. HTTP 401 "Please carry the API secret key"

**原因**：`api_key` 为空，且环境变量未设置或未被读取。

**解决**：
- 检查 systemd 服务或 ComfyUI 启动环境中是否设置了 `OPENAI_API_KEY`
- 或在节点中手动填写 API Key

## 5. T2VA 报 "does not accept reference media"

**原因**：T2VA 不应连接参考图/视频。

**解决**：已在节点中自动忽略，无需手动断开。

## 6. I2VA 提示 "I2VA requires first_frame"

**原因**：`first_frame` 输入未连线。

**解决**：将 `first_frame` 连到与 `AudioConditioningT8.first_frame` 同一张首帧图。

## 7. 浏览器强刷后节点仍显示旧字段

**原因**：ComfyUI 前端对节点定义有缓存。

**解决**：
1. 关闭所有 ComfyUI 标签页
2. 清浏览器缓存
3. 重新打开

## 8. "ConnectionError: The write operation timed out" / "Fast retry was exhausted"

**原因**：OpenAI 兼容模式将首帧图/参考图以内联 base64 发送，Payload 大，连接写入超时。

**解决**：
- 已在 2026-08-12 将 OpenAI 兼容端点的连接超时从 60 秒提高到 180 秒
- 如仍超时，检查网络稳定性或进一步降低首帧图分辨率/文件大小
- 避免同时发送过多参考图

## 9. "贞贞平价小屋" 重新出现在 API 模式下拉框

**原因**：浏览器/ComfyUI 前端缓存了旧的节点定义，或工作流保存了旧 schema 的 `widgets_values`，导致 `api_mode` 显示成旧选项。

**解决**：
1. 已在 2026-08-12 将 `API_MODES` 顺序改为 `[OpenAI兼容接口, 贞贞平价小屋, AI工坊]`，让默认/首位显示 OpenAI 兼容。
2. 清空工作流中 enhancer 节点的 `widgets_values`。
3. 在 `minimax_h3_prompt_enhancer.js` 末尾追加时间戳注释，强制浏览器重新加载前端脚本。
4. 关闭所有 ComfyUI 标签页，清空浏览器缓存（尤其是 IndexedDB / Service Worker），再重新打开。
5. 重新加载主用 ref5 工作流，检查 API 模式是否显示为 "OpenAI兼容接口（备用）"。

**注意**：无论 UI 显示什么选项，`execute()` 内都会强制 `api_mode = OPENAI_API_MODE`，实际请求始终走 OpenAI 兼容接口。

## 10. Ref2VA 报 "Ref2VA uses reference_images/reference_videos, not first_frame/last_frame"

**原因**：切换到 Ref2VA 时，enhancer 节点仍连着 `first_frame`/`last_frame`（从 I2VA/FL2VA 模式带过来的）。

**解决**：
- 已在 2026-08-12 将校验改为自动忽略 `first_frame`/`last_frame` 并打印警告，不再报错。
- 如需真正使用参考图/视频，请将参考素材连到 `reference_images` / `reference_videos` 输入。

## 11. "检测到错误 / validation errors"（description_word_target / case_template / rewrite_mode 等）

**根因**：后端 schema 的 widget 顺序与前端的 `SERIALIZED_WIDGET_NAMES` 序列化数组不一致。前端保存的 `widgets_values` 是固定顺序，但 ComfyUI 加载时按后端 `input_order` 解析，顺序错位导致 widget 拿到错误类型的值。

**彻底解决**：
- 2026-08-12 已统一顺序：
  1. prompt, task_type, duration_seconds, shot_count, rewrite_mode, description_word_target
  2. output_language, prompt_mode, official_skill_profile, creative_preset, case_template
  3. api_mode, ai_workshop_model, custom_model
  4. reference_context, constraints, api_key, reference_template
  5. openai_base_url, openai_video_urls, seed, control_after_generate
  6. enabled, use_background_music, use_ambient_noise
- 若旧工作流仍报验证错误，请重新加载主用 ref5 工作流，或清空 enhancer 节点的 `widgets_values` 后保存。
- 同时清除浏览器缓存并强制刷新 `Ctrl/Cmd + Shift + R`。

## 12. Ref2VA 仍报 "requires at least one reference image or reference video"

**原因**：参考图实际连到了 `first_frame`，而没有连到 `reference_images`。

**解决**：
- 把参考图连到 `reference_images.reference_image_0`（以及后续自动展开的 reference_image_1/2/3/4）。
- 或者升级到 2026-08-12 后的节点版本：当 Ref2VA 未连接 `reference_images` 但连了 `first_frame` 时，节点会自动把 `first_frame` 提升为参考图，兼容旧连线。

## 13. 同一个工作流想同时支持 T2VA/I2VA/FL2VA/L2VA/Ref2VA

**原因**：不同模式对输入要求不同，旧版本会严格报错（如 I2VA 不能连 reference_images）。

**解决**：
- 2026-08-12 后节点改为「自动忽略当前模式不需要的媒体输入」并打印警告，不再强制断线。
- 推荐在主用 ref5 工作流里同时连好：
  - `first_frame`：I2VA / FL2VA 用
  - `last_frame`：FL2VA / L2VA 用
  - `reference_images`：Ref2VA 用
- 切换 `task_type` 时无需手动拔线，节点会按模式取所需输入。


## 14. 添加可选视频/音频输入后报错 "invalid connection" 或 "Is a directory"

**原因**：
- `MiniMaxH3AudioConditioningT8` 的 `ref_videos.ref_video_0` 输入类型是 `IMAGE`，不是 `VIDEO`，不能直接接 `LoadVideo`。
- 空的 `LoadVideo` 节点会返回 `/home/fogai/ComfyUI/input` 目录路径，PromptEnhancer 尝试作为视频打开时报 `av.error.IsADirectoryError`。
- 同理，空的 `LoadAudio` 也可能传入无效路径。

**解决**：
- 在测试工作流 `（测试）minimax_h3_ref5_5img_novram_safe.json` 中，已将 `LoadVideo`/`LoadAudio` 节点默认断开连接。
- 需要使用时，先上传文件，再手动连接到 PromptEnhancer 的对应输入。
- `AudioConditioning.ref_videos` 若需要视频参考，请先通过抽帧/图像节点提供 `IMAGE` 类型输入。


## 15. 五模式（T2VA/I2VA/FL2VA/L2VA/Ref2VA）自动化测试通过

**时间**：2026-08-13 05:01
**测试工作流**：`workflows/（测试）minimax_h3_ref5_5img_novram_safe.json`
**测试配置**：
- 模型：`minimax_h3_fl2va_pruned_int8_convrot.safetensors` + Turbo 4步 LoRA
- 分辨率：1152×640，长度 56 帧（约 2 秒 @ 24fps）
- 参数：`--novram --use-sage-attention`
- 测试图片：`111.jpg`

**结果**：
| 模式 | 状态 | 输出文件 |
|------|------|----------|
| T2VA | SUCCESS | REF5_00098-audio.mp4 |
| I2VA | SUCCESS | REF5_00099-audio.mp4 |
| FL2VA | SUCCESS | REF5_00100-audio.mp4 |
| L2VA | SUCCESS | REF5_00101-audio.mp4 |
| Ref2VA | SUCCESS | REF5_00102-audio.mp4 |

**说明**：
- AudioConditioning 节点已设置合理的默认 `widgets_values`，不再使用占位字符串。
- 切换 PromptEnhancer 的 `task_type` 时，AudioConditioning 的 `task_type` 保持 `auto` 即可自动跟随。
- 测试脚本位于 `/tmp/run_h3_modes.py`（服务器本地）。
