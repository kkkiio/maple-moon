# Quest Module

## 任务要素

- 任务描述 QuestInfo.img
- NPC 对话 Say.img
- 阶段要求 Check.img
- 阶段奖励 Act.img

例子 1: Ayan 任务 2082 的对话

```mbt
test {
  let say_2082 =
    #| {
    #|  "0": {
    #|    "0": "Excuse me~ I know it's rude to ask a stranger, but can you please help me out? I am terrified of the Stumps that are wandering around outside this town. I can't even think of leaving here. I don't even want to see them, because they scare me to death. Please, if you have some time on your hands, can you help me out?",
    #|    "no": {
    #|      "0": "You must be busy. If you find some spare time later on, please come by and talk to me."
    #|    },
    #|    "yes": {
    #|      "0": "Thank you so much~ I knew you would say yes. As you can see, I am not from the tribes here. According to the elders here, years ago they found me lost in the streets, all bruised up and messy.",
    #|      "1": "The elders saved me, and I have been living here ever since. Unfortunately, I don't remember anything from the past. Something may have happened back then.",
    #|      "2": "Maybe that's because I went through something so horrible that my head chose to block it all out. I guess that's the reason why I am so scared of the Stumps. Can you do me a favor and take out #b50 Stumps#k please?"
    #|    }
    #|  },
    #|  "1": {
    #|    "0": "Wow, thank you so much! I see a lot less number of Stumps near Perion now! I feel like I can finally take a step outside. Thank you so much for your hard work!",
    #|    "stop": {
    #|      "mob": {
    #|        "0": "I don't think you have gotten all the Stumps yet. Please help me, for I am terrified of the Stumps."
    #|      }
    #|    }
    #|  }
    #|}
  let json = @json.parse!(say_2082)
  let quest_say : @resource.MapBasedArray[QuestPhaseSays] = @json.from_json!(
    json,
  )
  inspect!(
    quest_say._,
    content=
      #|[{says: ["Excuse me~ I know it's rude to ask a stranger, but can you please help me out? I am terrified of the Stumps that are wandering around outside this town. I can't even think of leaving here. I don't even want to see them, because they scare me to death. Please, if you have some time on your hands, can you help me out?"], ask: false, yes_reply: ["Thank you so much~ I knew you would say yes. As you can see, I am not from the tribes here. According to the elders here, years ago they found me lost in the streets, all bruised up and messy.", "The elders saved me, and I have been living here ever since. Unfortunately, I don't remember anything from the past. Something may have happened back then.", "Maybe that's because I went through something so horrible that my head chose to block it all out. I guess that's the reason why I am so scared of the Stumps. Can you do me a favor and take out #b50 Stumps#k please?"], no_reply: ["You must be busy. If you find some spare time later on, please come by and talk to me."], stop_hint: None, restore_lost: None}, {says: ["Wow, thank you so much! I see a lot less number of Stumps near Perion now! I feel like I can finally take a step outside. Thank you so much for your hard work!"], ask: false, yes_reply: [], no_reply: [], stop_hint: Some({base: [], item: [], npc: []}), restore_lost: None}]

    ,
  )
}
```

奖励

```mbt
test {
  let act_2082 =
    #| { "0": null, "1": { "exp": 300 } }
  let json = @json.parse!(act_2082)
  let quest_act : @resource.MapBasedArray[QuestPhaseAct] = @json.from_json!(json)
  inspect!(
    quest_act._,
  content="[{exp: None, mesos: None, items: [], unknown_acts: []}, {exp: Some(300), mesos: None, items: [], unknown_acts: []}]")
}
```

描述

```mbt
test {
  let desc = parse_quest_desc!(
    "He says he needs #rLeaves#k to use in a traditional ceremony for his ancestors.\\nEliminate #rDark Stumps#k and collect 20 #rLeaves#k.\\n#rDark Stumps#k can be found all throughout #b#m101030300##k and #b#m101030000##k.\\n\\nReport back to #b#@1020000:##k in #b#m102000000##k upon completion.",
  )
  inspect!(
    desc,

  content=
    #|<span style="color: black">He says he needs </span><span style="color: red">Leaves</span><span style="color: black"> to use in a traditional ceremony for his ancestors.<br/>
  #|Eliminate </span><span style="color: red">Dark Stumps</span><span style="color: black"> and collect 20 </span><span style="color: red">Leaves</span><span style="color: black">.<br/>
  #|</span><span style="color: red">Dark Stumps</span><span style="color: black"> can be found all throughout </span><map>101030300</map><span style="color: black"> and </span><map>101030000</map><span style="color: black">.<br/>
  #|<br/>
  #|Report back to </span><npc>1020000</npc><span style="color: black"> in </span><map>102000000</map><span style="color: black"> upon completion.</span>
  )
}

```

```mbt
///|
test "parse null phase says" {
  let q1021 = @json.parse!(
    #| {
    #|  "0": null,
    #|  "1": {
    #|    "stop": {
    #|      "item": {
    #|        "0": "I told you to have all #r7 #t2010007##k that I gave you. Open the item window and click#bconsumption tab#k. You can find #t2010007# and consume them by double click."
    #|      }
    #|    }
    #|  }
    #|}
    ,
  )
  let quest_say : @resource.MapBasedArray[QuestPhaseSays] = @json.from_json!(
    q1021,
  )
  inspect!(
    quest_say._,
    content=
      #|[{says: [], ask: false, yes_reply: [], no_reply: [], stop_hint: None, restore_lost: None}, {says: [], ask: false, yes_reply: [], no_reply: [], stop_hint: Some({base: [], item: ["I told you to have all #r7 #t2010007##k that I gave you. Open the item window and click#bconsumption tab#k. You can find #t2010007# and consume them by double click."], npc: []}), restore_lost: None}]

    ,
  )
}

///|
test "parse null hint" {
  let q2300 = @json.parse!(
    #| {
    #|   "0": {
    #|     "0": "Hey, I have a request for you.#b#L0#How can I help you?#l\\n#k",
    #|     "ask": 1,
    #|     "stop": { "0": null }
    #|   },
    #|   "1": {
    #|     "stop": {
    #|       "item": {
    #|         "0": "Who are you? You look like someone who's exploring Maple World. Our kingdom is in serious danger, and we need someone dependable that can save us. If you can't help us, then I suggest you move on."
    #|       }
    #|     }
    #|   }
    #| }
    ,
  )
  let quest_say : @resource.MapBasedArray[QuestPhaseSays] = @json.from_json!(
    q2300,
  )
  inspect!(
    quest_say._,
    content=
      #|[{says: ["Hey, I have a request for you.#b#L0#How can I help you?#l\\n#k"], ask: true, yes_reply: [], no_reply: [], stop_hint: Some({base: [{says: [], answer: 0}], item: [], npc: []}), restore_lost: None}, {says: [], ask: false, yes_reply: [], no_reply: [], stop_hint: Some({base: [], item: ["Who are you? You look like someone who's exploring Maple World. Our kingdom is in serious danger, and we need someone dependable that can save us. If you can't help us, then I suggest you move on."], npc: []}), restore_lost: None}]

    ,
  )
}

```
