# `ms/camera`

相机策略层（业务层），用于在 Selene 新 API 之上统一管理：

- 相机实体初始化：`setup_camera_entity` / `ensure_camera_entity`
- 跟随目标：`set_follow_target` / `clear_follow_target`
- 边界限制：`set_limits` / `clear_limits`
- 坐标换算：`viewport_to_world` / `world_to_viewport`
- 每帧更新：`camera_follow_system`

## 使用方式

1. 启动场景时创建或接管一个 camera entity。  
2. 设置跟随目标和地图边界。  
3. 在主循环每帧调度 `camera_follow_system`。

该包只封装策略，不修改 Selene 引擎实现。
