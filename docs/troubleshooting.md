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
