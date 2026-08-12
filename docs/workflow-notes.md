# 工作流使用说明

## 主用工作流

- `workflows/（主用）minimax_h3_ref5_5img_ui_enhancer.json`
- 用途：首帧图生音视频（I2VA）/ 文生音视频（T2VA）/ FL2VA / L2VA / Ref2VA
- 模型：`minimax_h3_fl2va_pruned_int8_convrot.safetensors`

## Turbo 工作流

- `workflows/minimax_h3_turbo_4080_8step_enhancer.json`
- 用途：8 步快速生成
- 模型：非 pruned 的 `minimax_h3_fl2va_int8_convrot.safetensors`
- 显存占用更高，16GB 上限约 **768×448**

## 分辨率设置

ref5 主用工作流使用手动填写分辨率，右侧 Note 面板提供参考：

| MP | 16:9 分辨率 | 建议 |
|---|---|---|
| 0.30 | 736×416 | 最安全，长时首选 |
| 0.325 | 768×448 | 安全，Turbo/长时稳 |
| 0.50 | 960×544 | 主用推荐，5-8s 稳 |
| 0.75 | 1152×640 | 8s 内可试 |
| 0.90 | 1280×704 | 上限，建议 5s |

在 `MiniMaxH3AudioConditioningT8` 节点中手动设置 `width` 和 `height`。

## 时长换算

按 24fps：
- 124 帧 ≈ 5 秒
- 248 帧 ≈ 10 秒
- 372 帧 ≈ 15 秒

1280×704 超过 5s 容易 OOM；960×544 可尝试 8-10s。

## 提示词优化节点配置

- API Key：留空读环境变量 `OPENAI_API_KEY`
- Base URL：留空读环境变量 `OPENAI_BASE_URL`
- 模型 ID：留空读环境变量 `OPENAI_MODEL`
- 启用提示词优化：开启
- 输出语言：按需选择
- 提示词模式：官方增强 / 兼容模式
