# character_body

本游戏的角色设计采用了 分层模块化 (Layered Modularity) 和 锚点联接 (Anchor Alignment) 的机制。这种设计允许角色在动画过程中保持灵活的部位替换（装备、发型等），同时确保所有部件能够同步移动。

1. 身体部位划分与图层 (Layers)

游戏将角色拆分为数十个独立的图层，每个图层都有唯一的 z 属性（如 body, arm, head, mail, pants, weapon 等）。

- 基础部位：body (躯干), head (头部), face (面部/表情), hair (头发)。
- 装备部件：mail (上衣), pants (裤子), shoes (鞋子), weapon (武器) 等。
- 动态图层：同一部件在不同动画中可能处于不同图层。例如，手臂在某些攻击动作中会在身体前面 (arm)，在其他动作中可能在后面 (backArm)。

2. 锚点系统 (The "Map" System)

这是游戏动画设计的核心。每个部件的每一帧图片都带有一组命名的 锚点 (Map Nodes)，用于决定各个部件之间的连接位置。

- navel (肚脐)：身体和衣服的核心对齐点。
- neck (颈部)：身体与头部的连接点。
- brow (眉头)：头部与头发、面部表情的连接点。
- hand (手部)：手臂与武器或手掌的连接点。

对齐逻辑示例：
若要将头部 (head) 放置在身体 (body) 上： `Head_Position = Body_Position + Body.neck - Head.neck`.
这意味着系统会将头部的 neck 点精确重合到身体的 neck 点上。即使身体在呼吸动画中 neck 点上下移动，头部也会自动跟随。

3. 动画位置与时机 (Stance & Frames)

- Stance (姿态)：动画按姿态分类，如 stand1 (站立), walk1 (走路), swingO1 (单手挥动)。
- Frame (帧)：每个姿态由多帧组成。
- Delay (延迟)：每一帧都有一个 delay 属性（单位毫秒），决定了该帧的展示时长。

4. 装备/服装的设计

装备完全遵循身体的锚点规则。

- 上衣 (Coat)：通常包含 body 和 arm 两个部分。上衣的 body 部分会根据 navel 锚点对齐到身体，而上衣的 arm 部分则会根据手臂的锚点对齐。
- 武器 (Weapon)：通常使用 hand 或 handMove 锚点。当手臂挥动时，武器会根据手臂上的 hand 锚点实时更新位置。
