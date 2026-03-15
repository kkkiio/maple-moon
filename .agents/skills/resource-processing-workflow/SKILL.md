---
name: resource-processing-workflow
description: 处理 Maple Moon 资源下载、迁移、reanim 重打包与加载校验。用于新增或修复资源（尤其是 r2 到 assets 迁移）、排查 `failed to fetch`、贴图缺失，并统一资源格式到可运行状态时。
---

# Resource Processing Workflow

按以下流程处理资源，目标是让 `./assets` 可直接被当前 loader 正确加载。

职责边界：

- `nx_maple_res` 项目(路径从`NX_MAPLE_RES_PATH`环境变量或`.env.dev`文件获取) 负责原始 `.nx` 输入、`cache/` 中间产物、`reanim` 处理
- `./assets` 只负责最终运行时

## 1. 识别资源来源与目标格式

明确输出目标：

- 运行产物在 `./assets/`
- 需要统一帧偏移时，目标 JSON 应包含 `__off`

## 1.1 资源来源

有两大来源：

- 旧流程派生缓存：`$NX_MAPLE_RES_PATH/cache/r2/*`（常见 `__i: "...#frame"`）.
  - 部分资源还在远程存储 `r2:maple`, 需使用 `rclone` 从 `r2:maple` 下载到本地`$NX_MAPLE_RES_PATH/cache/r2`.
- 权威原始输入：`$NX_MAPLE_RES_PATH/assets/<Package>.nx`
  - `.nx` 导出中间产物：`$NX_MAPLE_RES_PATH/cache/nx_export/<Package>.nx/{nx.json,bitmaps/*}`（`__b`）

优先选择旧流程派生缓存. 因为 `.nx` 文件目前还不全.

## 1.2 根据来源处理

- 如果 `cache/r2` 已有同名资源, 直接进入 reanim 处理流程.
- 如果 `cache/r2` 没有, 先从 `r2:maple` 拉取到 `cache/r2`, 再进入 reanim 处理流程.
- 如果两者都没有, 再考虑从 `.nx` 导出.
- 如果发现 `cache/r2` 结构异常、或怀疑旧流程产物有误，优先回到 `.nx` 重新导出。
- 长期方向是逐步减少对 `cache/r2` 的依赖。

## 2. 从 r2 拉取最小必要资源

- 使用 `rclone` 从 `r2:maple` **只拉到 `$NX_MAPLE_RES_PATH/cache/r2`**，不要直接拉到 `./assets`，避免污染运行时资源目录。
- 优先精确同步缺失文件，不做全量拉取.

示例:

```bash
cd $NX_MAPLE_RES_PATH
rclone copy -v --no-update-modtime r2:maple cache/r2 --include 'Map/Obj/trap.img.json'
# rclone copy -v --no-update-modtime r2:maple cache/r2 --files-from /tmp/missing.txt
```

## 3. 使用 reanim 生成带 `__off` 的产物

```bash
moon run --target js cmd/reanim -- <input.json> <maple-moon-assets-output-dir> --spritesheet-dir <dir>
```

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

moon run --target js cmd/reanim -- cache/nx_export/Map.nx/WorldMap.json $MAPLE_MOON_PATH/assets/map/WorldMap --bitmaps-dir cache/nx_export/Map.nx/bitmaps
moon run --target js cmd/reanim -- cache/nx_export/Map.nx/maphelper_worldmap.json $MAPLE_MOON_PATH/assets/spritesheets/Map/MapHelper.img --bitmaps-dir cache/nx_export/Map.nx/bitmaps
```

- 当 `WorldMap` 是一个大节点集合时，先按顶层子节点拆分成多个 `WorldMapXXX.img.json` 再分别运行 `reanim`，避免把所有页面错误地合成到一个文件里。
- `MapHelper.img/worldMap` 这类单节点资源可直接整体跑一次 `reanim`。
- `nx_maple_res` 导出的 JSON 只用于中间产物，默认写到 `cache/nx_export`，不要直接提交。

## 4. 完整性校验

- 检查每个 JSON 的引用是否都存在于 `$MAPLE_MOON_PATH/assets/`。
- 检查期望 reanim 的 JSON 是否含 `__off`。
- 运行构建验证：

```bash
moon run --target js cmd/rescheck
```

## 5. loader 对齐

- 处理后资源需与 `src/lib/resource/builtin_resource_loaders.mbt` 的 `base_url` 与目录前缀一致。
- 遇到运行时报 `failed to fetch`，先验证 `./assets` 路径是否真实存在，再看 loader 映射。
