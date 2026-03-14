---
name: resource-processing-workflow
description: 处理 Maple Moon 资源下载、迁移、reanim 重打包与加载校验。用于新增或修复资源（尤其是 r2 到 assets 迁移）、排查 `failed to fetch`、`missing __off`、贴图缺失，并统一资源格式到可运行状态时。
---

# Resource Processing Workflow

按以下流程处理资源，目标是让 `./assets` 可直接被当前 loader 正确加载。

职责边界：

- `nx_maple_res` 项目(路径从`NX_MAPLE_RES_PATH`环境变量或`.env.dev`文件获取) 负责原始 `.nx` 输入、`cache/` 中间产物、`reanim` 处理
- `./assets` 只负责最终运行时

## 1. 识别资源来源与目标格式

- 优先识别输入来源：
  - 权威原始输入：`$NX_MAPLE_RES_PATH/assets/<Package>.nx`
  - `.nx` 导出中间产物：`$NX_MAPLE_RES_PATH/cache/nx_export/<Package>.nx/{nx.json,bitmaps/*}`（`__b`）
  - 旧流程派生缓存：`$NX_MAPLE_RES_PATH/cache/r2/*`（常见 `__i: "...#frame"`）
- 明确输出目标：
  - 运行产物在 `./assets/`
  - 需要统一帧偏移时，目标 JSON 应包含 `__off`

## 1.1 优先选择最小来源

- 默认把 `.nx` 视为权威来源，`cache/r2` 只是为了省去重复提取而保留的派生缓存。
- 如果 `cache/r2` 已有可直接复用的 JSON，可以先复用；但一旦发现缺资源、结构异常、或怀疑旧流程产物有误，优先回到 `.nx` 重新导出。
- 长期方向是逐步减少对 `cache/r2` 的依赖，而不是继续扩大它的覆盖面。
- 目标始终是：`./assets/` 里只保留 Maple Moon 当前 loader 可直接消费的运行产物，不让运行时承担 `__b` 解析职责。

## 2. 从 r2 拉取最小必要资源

- 使用 `rclone` 从 `r2:maple` **只拉到 `$NX_MAPLE_RES_PATH/cache/r2`**，不要直接拉到 `./assets`，避免污染运行时资源目录。
- 优先精确同步缺失文件，不做全量拉取：
  - 先扫描 JSON 里的 `__i` 引用并计算缺失
  - 用 `--files-from` 精确同步到 `$NX_MAPLE_RES_PATH/cache/r2`

示例：

```bash
cd $NX_MAPLE_RES_PATH
rclone copy -v --no-update-modtime r2:maple cache/r2 --files-from /tmp/missing.txt
```

- 若误下到 `./assets`（例如 `assets/Npc/images/*` 这类原始切图），应先迁回 `$NX_MAPLE_RES_PATH/cache/r2` 或删除后重拉，随后再通过 reanim/转换流程产出到最终 `./assets`。

## 3. 使用 reanim 生成带 `__off` 的产物

- 先构建：

```bash
cd $NX_MAPLE_RES_PATH
moon build --target js --release cmd/reanim
```

- 使用 reanim：

```bash
node _build/js/release/build/cmd/reanim/reanim.js <input.json> <maple-moon-assets-output-dir> --spritesheet-dir <dir>
```

- `Item/Special` 的关键路径规则：
  - 输入：`$NX_MAPLE_RES_PATH/cache/r2/Item/Special/0900.img.json`
  - `--spritesheet-dir` 必须是 `$NX_MAPLE_RES_PATH/cache/r2/spritesheets/Item`
  - 不能传 `$NX_MAPLE_RES_PATH/cache/r2/spritesheets/Item/Special`（会路径重复）

## 3.1 从 `.nx` 取资源时使用 `nx_maple_res`

- `nx_maple_res` 负责从 `.nx` 里按节点导出原始 JSON 与 bitmap，不直接产出 Maple Moon 运行资源。
- 推荐流程：

```bash
cd $NX_MAPLE_RES_PATH

moon run cmd/main -- to_json assets/Map.nx --nodepath WorldMap --output cache/nx_export/Map.nx/WorldMap.json
moon run cmd/main -- save_bitmap assets/Map.nx WorldMap --out-dir cache/nx_export

moon run cmd/main -- to_json assets/Map.nx --nodepath MapHelper.img/worldMap --output cache/nx_export/Map.nx/maphelper_worldmap.json
moon run cmd/main -- save_bitmap assets/Map.nx MapHelper.img/worldMap --out-dir cache/nx_export
```

- 上一步的导出结果仍是 `__b` 原始格式，必须再走 `reanim`：

```bash
cd $NX_MAPLE_RES_PATH

moon build --target js --release cmd/reanim

node _build/js/release/build/cmd/reanim/reanim.js cache/nx_export/Map.nx/WorldMap.json $MAPLE_MOON_PATH/assets/map/WorldMap --bitmaps-dir cache/nx_export/Map.nx/bitmaps
node _build/js/release/build/cmd/reanim/reanim.js cache/nx_export/Map.nx/maphelper_worldmap.json $MAPLE_MOON_PATH/assets/spritesheets/Map/MapHelper.img --bitmaps-dir cache/nx_export/Map.nx/bitmaps
```

- 当 `WorldMap` 是一个大节点集合时，先按顶层子节点拆分成多个 `WorldMapXXX.img.json` 再分别运行 `reanim`，避免把所有页面错误地合成到一个文件里。
- `MapHelper.img/worldMap` 这类单节点资源可直接整体跑一次 `reanim`。
- `nx_maple_res` 导出的 JSON 只用于中间产物，默认写到 `cache/nx_export`，不要直接提交。

## 4. Item/Special 实战规则

- `0900.img`：适合 reanim，输出单图集并写入 `__off`
- `MaplePoint.img`：适合 reanim，输出单图集并写入 `__off`
- `0910.img` / `0911.img`：引用 `images/Item/*.png`，通常不需要 reanim；要补齐 `assets/images/Item/*`

## 5. 完整性校验

- 检查每个 JSON 的引用是否都存在于 `$MAPLE_MOON_PATH/assets/`。
- 检查期望 reanim 的 JSON 是否含 `__off`。
- 如果 loader 只需要某个子节点，优先只加载该子节点，避免整份 JSON 牵连无关 spritesheet 依赖。
  - 例如 world map tooltip 只需要 `ToolTip/WorldMap`，不要整份加载 `ToolTip`。
- 运行构建验证：

```bash
moon build --release
```

## 6. loader 对齐

- 处理后资源需与 `src/lib/resource/builtin_resource_loaders.mbt` 的 `base_url` 与目录前缀一致。
- 遇到运行时报 `failed to fetch`，先验证 `./assets` 路径是否真实存在，再看 loader 映射。
