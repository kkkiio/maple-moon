# BGM

地图背景音乐管理模块。

职责：

- 把地图 `info.bgm` 提供的逻辑 key 映射成当前项目的音频资源路径
- 维护单个当前播放中的 BGM entity
- 在地图切换时切歌，并避免同曲重复播放

当前仅支持地图 BGM 路径：

- `BgmXX.img/Name`

并按固定规则映射到：

- `/assets/sound/BgmXX.img/Name.mp3`

不处理技能音效、UI 音效或其他 `Sound.nx` 路径。
