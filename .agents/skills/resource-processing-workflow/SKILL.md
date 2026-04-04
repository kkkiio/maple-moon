---
name: resource-processing-workflow
description: 处理 Maple Moon 资源迁移、导出与加载校验。用于新增或修复资源、排查 `failed to fetch`、贴图缺失，并将资源统一到 `tiled(.tmj/.tsj)` 与 `aseprite(json+png)` 运行格式。
---

# Resource Processing Workflow

按以下流程处理资源，目标是让 `./assets` 可直接被当前 loader 正确加载。

职责边界：

- `nx_maple_res` 项目（路径从 `NX_MAPLE_RES_PATH` 环境变量或 `.env.dev` 获取）负责原始 `.nx` 输入和导出工具链。
- `./assets` 只存放最终运行时资源（含 `map.tmj`、外部 `tilesets/*.tsj`、spritesheet 的 `json+png` 等）。

## 1. 识别资源来源与目标格式

明确输出目标：

- 运行产物在 `./assets/`
- 地图资源优先使用 Tiled 格式：`.tmj` + `.tsj`
- 动画/图集资源优先使用 Aseprite 格式：`json+png`

## 1.1 资源来源

当前权威来源是：

- 原始输入：`$NX_MAPLE_RES_PATH/assets/<Package>.nx`
- 导出工具：`nx_maple_res/cmd/main`

中间产物目录是 `nx_maple_res` 项目内的
`$NX_MAPLE_RES_PATH/cache/nx_export`，不作为长期依赖。

## 1.2 根据来源处理

- 缺资源时，优先确认对应 `.nx` 节点是否存在。
- 存在则直接走 `nx_maple_res` 导出流程生成目标资源。
- 如果导出结果异常，先定位节点路径和导出参数，再修复导出工具或资源映射，不回退到旧缓存体系。

## 2. 迁移导出流程（以 `nx_maple_res export` 为主）

优先用 `nx_maple_res` 一次导出可运行资源：

```bash
cd $NX_MAPLE_RES_PATH

moon run --target native cmd/main -- export \
  --include 'Map/Map1/102000001.img' \
  --out-dir $MAPLE_MOON_PATH/assets/map \
  assets/Map.nx
```

说明：

- `Map.nx` 导出后应在目标目录生成 `Map/.../mx.json` + `map.tmj` + `tilesets/*.tsj` + 贴图文件。
- 推荐始终使用 `--include` 精确导出，避免无关资源大面积改动。

## 3. 关于 `NxAnimation` / `NxTexture`

迁移到 Tiled + Aseprite 不代表废弃 `NxAnimation` / `NxTexture`：

- 这套格式仍然用于部分运行时模块（例如角色、特效、UI 等）。
- 当目标模块仍消费 `NxAnimation` / `NxTexture` 时，继续保留该格式资源，不强行转换成 `tmj/tsj`。
- `$NX_MAPLE_RES_PATH/cache/nx_export` 仍可作为排查导出问题的中间层，但默认不提交。

## 4. 完整性校验

- 检查 `mx.json` 指向的 `map.tmj` 是否存在，`tmj` 引用的 `tsj/png` 是否存在。
- 检查资源路径是否与 loader 前缀一致。
- 运行构建验证：

```bash
moon run --target js cmd/rescheck
```

## 5. loader 对齐

- 处理后资源需与 `src/lib/resource/builtin_resource_loaders.mbt` 的 `base_url` 与目录前缀一致。
- 遇到运行时报 `failed to fetch`，先验证 `./assets` 路径是否真实存在，再看 loader 映射与 `mx.json` 路径。
