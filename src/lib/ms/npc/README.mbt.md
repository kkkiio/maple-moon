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

战士二转对话:

```mbt
test {
  let text = "Alright, when you have made your decision, click on [I'll choose my occupation] at the bottom.#b\r\n#L0#Please explain to me what being the Fighter is all about.\r\n#L1#Please explain to me what being the Page is all about.\r\n#L2#Please explain to me what being the Spearman is all about.\r\n#L3#I'll choose my occupation!"
  let result = parse_talk_content!(text)
  @json.inspect!(result.selections, content=[
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
  inspect!(
    result.text_html,
    content=
      #|<span style="color: black">Alright, when you have made your decision, click on [I&#039;ll choose my occupation] at the bottom.</span><br/>
      #|
    ,
  )
}
```
