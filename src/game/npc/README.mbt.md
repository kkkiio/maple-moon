# NPC

## MxNpc

`MxNpc` 用于解析 `Npc/<id>.img/mx.json` 资源（不含地图 `life` 刷新点）：

- `info.link`: NPC 模板链接（可选）。
- `info.scripted`: 归一化脚本标志（`script != null || shop == true`）。
- `info.speak_keys`: `info.speak` 的 key 列表。
- `animations_path`: Aseprite `animation.json` 引用路径（推荐写成相对 `mx.json` 的路径）。

示例：

```mbt nocheck
///|
test {
  let src : Json = {
    "info": { "speak": { "0": "n0" } },
    "animations_path": "animation.json",
  }
  let mx_npc : MxNpc = @json.from_json(src)
  inspect(mx_npc.animations_path, content="animation.json")
}
```

## 地图 NPC 动画

NPC 初始播放 `stand`。当前 clip 完整播放一轮后，客户端从资源的全部 animation
tag 中均匀随机选择下一状态，也允许再次选中当前状态。每个状态使用
`RepeatAnimation::Never`，由 AnimationPlayer 的完成状态触发下一轮选择，保证
状态机与实际画面进度一致。

这个规则与 OpenMapleClient 的 ambient NPC 行为一致。`say`、`blink`、`action`
等名称只是资源状态名，不在 controller 中形成硬编码白名单；不应进入候选集的
编辑态动画应在资源导出边界排除。

## NPC Talk

NPC 任务对话案例。

```mbt nocheck
///|
test {
  let text = "I must begin the traditional ceremony for our ancestors shortly, but I don't have enough #rLeaves#k for the ceremony. I don't have much time.\\n\\nOh, you look like an adventurer. Won't you help me?"
  let result = parse_talk_content(text)
  inspect(result.selections, content="[]")
  inspect(
    result.text_html,
    content=(
      #|<span style="color: black">I must begin the traditional ceremony for our ancestors shortly, but I don&#039;t have enough </span><span style="color: red">Leaves</span><span style="color: black"> for the ceremony. I don&#039;t have much time.</span><br/>
      #|<span style="color: black"></span><br/>
      #|<span style="color: black">Oh, you look like an adventurer. Won&#039;t you help me?</span>
    ),
  )
}
```

战士二转对话:

```mbt nocheck
///|
test {
  let text = "Alright, when you have made your decision, click on [I'll choose my occupation] at the bottom.#b\r\n#L0#Please explain to me what being the Fighter is all about.\r\n#L1#Please explain to me what being the Page is all about.\r\n#L2#Please explain to me what being the Spearman is all about.\r\n#L3#I'll choose my occupation!"
  let result = parse_talk_content(text)
  json_inspect(result.selections, content=[
    [
      "blue", 0, "<span style=\"color: blue\">Please explain to me what being the Fighter is all about.</span><br/>\n<span style=\"color: blue\"></span>",
    ],
    [
      "blue", 1, "<span style=\"color: blue\">Please explain to me what being the Page is all about.</span><br/>\n<span style=\"color: blue\"></span>",
    ],
    [
      "blue", 2, "<span style=\"color: blue\">Please explain to me what being the Spearman is all about.</span><br/>\n<span style=\"color: blue\"></span>",
    ],
    [
      "blue", 3, "<span style=\"color: blue\">I&#039;ll choose my occupation!</span>",
    ],
  ])
  inspect(
    result.text_html,
    content=(
      #|<span style="color: black">Alright, when you have made your decision, click on [I&#039;ll choose my occupation] at the bottom.</span><br/>
      #|
    ),
  )
}
```
