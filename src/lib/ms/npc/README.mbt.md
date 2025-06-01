# NPC

## NPC Talk

NPC 任务对话案例。

```mbt
test {
    let text = "I must begin the traditional ceremony for our ancestors shortly, but I don't have enough #rLeaves#k for the ceremony. I don't have much time.\\n\\nOh, you look like an adventurer. Won't you help me?"
  let result = parse_talk_content!(text)
  inspect!(result.selections, content="[]")
  inspect!(
    result.text_html,
  content=
    #|<span style="color: black">I must begin the traditional ceremony for our ancestors shortly, but I don't have enough </span><span style="color: red">Leaves</span><span style="color: black"> for the ceremony. I don't have much time.<br>
  #|<br>
  #|Oh, you look like an adventurer. Won't you help me?</span>
  )
}
```
