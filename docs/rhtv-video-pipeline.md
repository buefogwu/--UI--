# RHTV Lite × MiniMax H3 视频管线

> 2026-08-16/17 在 RTX 4080 SUPER 16GB 上为 RHTV Lite 本地端构建的 Ref2VA 视频生成管线。
> 工作流位于 `workflows/rhtv/`，模型 pruned `minimax_h3_fl2va_pruned_int8_convrot` + Turbo LoRA，1280×704 / length=73（17n+5）/ 24fps / 8 步 / audio_mode=native。

## 1. image2video.json — Ref2VA + 六段式 schema + 环境参考图

**核心教训**：Ref2VA **必须用六段式 schema prompt**（`subject_definitions`/`summary`/`retention_analysis`/`detailed_description`/`overall_soundscape`/`non_diegetic_music`），不能用裸英文。裸 prompt 下多张参考图里只有"人物+环境融合的完整静帧"被当权威，**纯环境图被完全忽略**（环境随机）。用 schema 把环境图声明为 `<Subject 1>` 环境 `fully_preserved`、静帧人物为 `<Subject 2>` 人物 `fully_preserved`，`detailed_description` 把人物放进环境 → **环境图+人物同时生效**（6 组对照实验实测）。

- `<Picture N>` 编号 = `ref_image` 连接序（`comfy/text_encoders/minimax.py` `tokenize_with_weights` 自动前置 `<Picture N>: <vision block>`）。
- 接法：环境图 → `ref_images.ref_image_0`（=`<Picture 1>`=`<Subject 1>` 环境）、分镜静帧 → `ref_images.ref_image_1`（=`<Picture 2>`=`<Subject 2>` 人物）。
- 占位符：`__POSITIVE_PROMPT__`（节点6 prompt=六段式schema）、`__SCENE_IMAGE__`（节点30 环境图）、`__REF_IMAGE__`（节点31 静帧）。seed 走 `_inject_seed` 注入节点8 `noise_seed`。
- **autogrow v3 API key 带点号**：`ref_images.ref_image_0`（不是 `ref_image_0`，后者报 `unexpected keyword argument`）。
- 视频 conditioning 节点无数值 `reference_strength`（仅 Still conditioning 有）；权重靠 schema `retention_analysis` 的 `fully_preserved` 声明。可选增强节点 `MiniMaxH3VisualReferenceStrengthEXPT8`（`reference_strength=0.99`，≤0.95 损伤 identity/端点）。
- 退化：无环境图时 `__SCENE_IMAGE__` 注入静帧同值（ref0=ref1=静帧），schema 仍写两 Subject，环境锁回静帧环境。
- 输出 `VHS_VideoCombine` 节点12，`RHTV_vid_XXXXX-audio.mp4`，`/history` 读 `gifs`。

## 2. prompt_optimize_video.json — Ref2VA 六段式 schema Enhancer

复用现有 `MiniMaxH3PromptEnhancerT8` 改传参，新建独立文件（与 Still 的 `prompt_optimize.json` 解耦）。

- `task_type=Ref2VA（参考图/视频生音视频）`（=full-reference，由 task_type 选定，非 prompt_mode）、`prompt_mode=官方增强`、`official_skill_profile=官方 Skill 严格（全英文协议）`、`shot_count="1"` 固定、`output_language=English`、`rewrite_mode=balanced`。
- 接图：`reference_images.reference_image_0`=环境图→`<Picture 1>`→`<Subject 1>`、`reference_images.reference_image_1`=静帧→`<Picture 2>`→`<Subject 2>`（dotted autogrow，编号=连接序，与 conditioning 前置序一致）。
- **去 `H3PromptToStillTags`**（视频要 raw schema 不过清洗），ShowText 直连 Enhancer。
- constraints 钉编号/角色/单 Shot/字段序——与 Ref2VA 任务规则（nodes.py line 314）同向 → **实测 100% 服从**（远优于 Still 案例的 ~1/3，无需 schema 规整节点）。
- Enhancer `use_ambient_noise`/`use_background_music` → schema `overall_soundscape`/`non_diegetic_music` 出 content 或 N/A。
- 占位符：`__ZH_PROMPT__`（文本）、`__SCENE_IMAGE__`、`__REF_IMAGE__`。v1 不接演员图。
- 端到端实测：Enhancer 产 schema(4528字符) → 喂 image2video.json → 环境(夜街)+人物(女子)同时生效。

## 3. 音频开关 A/B/C/D 实测（audio_mode=native）

`audio_mode=native` 忠实按 schema 的 `overall_soundscape`/`non_diegetic_music` 生成音轨；conditioning 节点**无节点级音轨开关字段**，**schema 文本即唯一控制机制**。同 seed 同图 4 路对照：

| 路 | overall_soundscape | non_diegetic_music | LUFS-I | 结论 |
|---|---|---|---|---|
| A | 内容 | N/A | -45.7 | 环境音已生成（低频床+瞬态），声音安静故低 |
| B | N/A | 内容 | -21.1 | **BGM 已生成，广播级响度，谐波音调=音乐性** |
| C | 内容 | 内容 | -23.3 | 两字段同时生效（谐波+环境纹理并存） |
| D | N/A | N/A | -47.5 | **近静音**（N/A→不生音） |

- native **能生 BGM**（不必后制；但器乐质量粗糙=持续音调带谐波，非清晰乐句，复杂 BGM 建议后制）。
- `N/A` → 真静音（native 不补底噪）。
- 环境音也生效但**响度跟随所描声音**：纯低频氛围词（hum/hiss）→ 近本底；要明显环境音需描述具体声学事件（脚步/水花/关门/风声）。
- AAC 32kHz 会压低极安静底噪。

## 4. Prompt 站位/构图技法（官方 h3-prompt-writing skill）

控制角色在环境中的站位**无专用标签/参数**，靠 `detailed_description` 里自然英文 + 4 手法：
1. **景别**（shot type）：远景/建立镜头=环境主导人物小；中景=平衡；特写=人物主导。
2. **帧内位置 + 环境锚**（ref-en.txt：人物首次出现要描述 "position in the frame"）：`centered / from the left / in the foreground` + `on the wet pavement / beside the counter / under the neon sign`。base-en.txt 保证 spatial relationships 全镜头保持一致。
3. **运镜**（motion type + amplitude + speed）：Push In 凸显人物、Pull Out 退环境全景、Truck/Pan 横向位移、Arc 绕人物换背景。amplitude 定义=构图变化范围。
4. **构图锚/分镜参考图**（精准控制位）：加第 3 张图做 `<Picture N>` storyboard，`"defining their viewpoint, subject placement, and shot order"`，retention 标 `keyframe completion`/`reference generation`。

## 参考

- 官方 skill：`MiniMax-AI/MiniMax-H3` 仓库 `skills/h3-prompt-writing/`（SKILL.md + references/base-en.txt + references/ref-en.txt）。
- 六段式 schema 官方文档：HuggingFace `MiniMaxAI/MiniMax-H3` 的 `docs/VIDEO_PROMPT_WRITING_GUIDE_ref_en.md`。
- 节点源码：`comfyui-minimax-h3-prompt-enhancer-T8/nodes.py`、`comfyui-minimax-h3-audio-T8/conditioning.py`。
