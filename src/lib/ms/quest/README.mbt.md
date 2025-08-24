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
      #|[{says: ["Excuse me~ I know it's rude to ask a stranger, but can you please help me out? I am terrified of the Stumps that are wandering around outside this town. I can't even think of leaving here. I don't even want to see them, because they scare me to death. Please, if you have some time on your hands, can you help me out?"], ask: false, yes_reply: ["Thank you so much~ I knew you would say yes. As you can see, I am not from the tribes here. According to the elders here, years ago they found me lost in the streets, all bruised up and messy.", "The elders saved me, and I have been living here ever since. Unfortunately, I don't remember anything from the past. Something may have happened back then.", "Maybe that's because I went through something so horrible that my head chose to block it all out. I guess that's the reason why I am so scared of the Stumps. Can you do me a favor and take out #b50 Stumps#k please?"], no_reply: ["You must be busy. If you find some spare time later on, please come by and talk to me."], stop: None, restore_lost: None}, {says: ["Wow, thank you so much! I see a lot less number of Stumps near Perion now! I feel like I can finally take a step outside. Thank you so much for your hard work!"], ask: false, yes_reply: [], no_reply: [], stop: Some({base: [], item: [], npc: []}), restore_lost: None}]


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
    #|<span style="color: black">He says he needs </span><span style="color: red">Leaves</span><span style="color: black"> to use in a traditional ceremony for his ancestors.</span><br/>
    #|<span style="color: black">Eliminate </span><span style="color: red">Dark Stumps</span><span style="color: black"> and collect 20 </span><span style="color: red">Leaves</span><span style="color: black">.</span><br/>
    #|<span style="color: black"></span><span style="color: red">Dark Stumps</span><span style="color: black"> can be found all throughout </span><map>101030300</map><span style="color: black"> and </span><map>101030000</map><span style="color: black">.</span><br/>
    #|<span style="color: black"></span><br/>
    #|<span style="color: black">Report back to </span><npc>1020000</npc><span style="color: black"> in </span><map>102000000</map><span style="color: black"> upon completion.</span>

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
      #|[{says: [], ask: false, yes_reply: [], no_reply: [], stop: None, restore_lost: None}, {says: [], ask: false, yes_reply: [], no_reply: [], stop: Some({base: [], item: ["I told you to have all #r7 #t2010007##k that I gave you. Open the item window and click#bconsumption tab#k. You can find #t2010007# and consume them by double click."], npc: []}), restore_lost: None}]


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
      #|[{says: ["Hey, I have a request for you.#b#L0#How can I help you?#l\\n#k"], ask: true, yes_reply: [], no_reply: [], stop: Some({base: [{says: [], answer: 0}], item: [], npc: []}), restore_lost: None}, {says: [], ask: false, yes_reply: [], no_reply: [], stop: Some({base: [], item: ["Who are you? You look like someone who's exploring Maple World. Our kingdom is in serious danger, and we need someone dependable that can save us. If you can't help us, then I suggest you move on."], npc: []}), restore_lost: None}]


    ,
  )
}

```

## 问答

这是一个问答型任务。玩家接受了任务后，回答问题，回答正确后，任务完成。

```mbt
test "I'm Bored 1" {
  let say_2090_1 : Json = {
      "0": "Which of these monsters will you NOT see near Kerning City? \\r\\n#L0##b1. Stump#k #l\\r\\r#L1##b2. Blue Mushroom#k #l\\r\\n#L2##b3. Slime#k #l\\r\\n#L3##b4. Ribbon Pig#k #l\\r\\n#L4##b5. Hector#k #l",
      "1": "Which of these NPC's will not NOT see at Kerning City?\\r\\n#L0##b1. Don Giovanni#k #l\\r\\n#L1##b2. Andre#k #l\\r\\n#L2##b3. Mong From the Kong#k #l\\r\\n#L3##b4. Valen#k \\r\\n#L4##b5. Don Hwang#k #l",
      "2": "To make your way to Orbis, which of these towns will you have to go to get on board for the trip?\\r\\n#L0##b1. Ellinia#k #l\\r\\n#L1##b2. El Nath#k #l\\r\\n#L3##b3. Perion#k #l\\r\\n#L4##b4. Henesys#k #l",
      "3": "Wow, you're pretty good! You should be starring on a quiz show, the way you're answering these questions!",
      "ask": 1,
      "stop": {
        "0": {
          "0": "No no no! Think carefully!",
          "1": "No no no! Think carefully!",
          "2": "No no no! Think carefully!",
          "3": "No no no! Think carefully!",
          "answer": 5,
        },
        "1": {
          "0": "You're wrong!! You can see that NPC at Kerning City!",
          "1": "You're wrong!! You can see that NPC at Kerning City!",
          "2": "You're wrong!! You can see that NPC at Kerning City!",
          "4": "You're wrong!! You can see that NPC at Kerning City!",
          "answer": 4,
        },
        "2": {
          "1": "Are you sure? Think again!",
          "2": "Are you sure? Think again!",
          "3": "Are you sure? Think again!",
          "4": "Are you sure? Think again!",
          "answer": 1,
        },
      },
    }
  let says : QuestPhaseSays = @json.from_json!(
    say_2090_1,
  )

  let talk0 = next_talk(says, Ask(next=0, expect_answer=0, error_replys=[], answer=0), Some(true))
  guard talk0 is Some(talk0) else {fail("talk0 is None")}
  inspect!(talk0.content, content="Which of these monsters will you NOT see near Kerning City? \\r\\n#L0##b1. Stump#k #l\\r\\r#L1##b2. Blue Mushroom#k #l\\r\\n#L2##b3. Slime#k #l\\r\\n#L3##b4. Ribbon Pig#k #l\\r\\n#L4##b5. Hector#k #l")
  guard talk0.expect_response is SELECT(fun) else {fail("talk0.expect_response is not SELECT")}
  let talk1 = fun(4)
  guard talk1 is Some(talk1) else {fail("talk1 is None")}
  inspect!(talk1.content, content="Which of these NPC's will not NOT see at Kerning City?\\r\\n#L0##b1. Don Giovanni#k #l\\r\\n#L1##b2. Andre#k #l\\r\\n#L2##b3. Mong From the Kong#k #l\\r\\n#L3##b4. Valen#k \\r\\n#L4##b5. Don Hwang#k #l")
  guard talk1.expect_response is SELECT(fun) else {fail("talk1.expect_response is not SELECT")}
  let talk2 = fun(3)
  guard talk2 is Some(talk2) else {fail("talk2 is None")}
  inspect!(talk2.content, content="To make your way to Orbis, which of these towns will you have to go to get on board for the trip?\\r\\n#L0##b1. Ellinia#k #l\\r\\n#L1##b2. El Nath#k #l\\r\\n#L3##b3. Perion#k #l\\r\\n#L4##b4. Henesys#k #l")
  guard talk2.expect_response is SELECT(fun) else {fail("talk2.expect_response is not SELECT")}
  let talk3 = fun(0)
  guard talk3 is Some(talk3) else {fail("talk3 is None")}
  inspect!(talk3.content, content="Wow, you're pretty good! You should be starring on a quiz show, the way you're answering these questions!")
  guard talk3.expect_response is OK(fun) else {fail("talk3.expect_response is not OK")}
  let action = fun()
  inspect!(action, content="Some(CompleteQuest)")
}
```

这是一个在对话中穿插问答的任务。玩家在对话中选择对的选项后，才继续对话接受任务。

```mbt
test "Icarus's Hang Glider" {
  let say_2083_1 : Json = {
        "0": "Wouldn't it be incredible to swim in those clouds and fly your way through freedom? I wonder what it's like to fly, free as a bird. Even if it's only for a few minutes, I'd be more than happy to just be up there! \\r\\n#L0##bCan humans really fly?#k#l\\r\\n#L1##bGrow up, you know we can't fly..#k",
        "1": "Oh yeah, I truly believe we're meant to fly, and I will try my hardest to make that wish come true! That got me thinking, in order to fulfill my dream, I should make a huge hang glider! I read it in a book, and it says we can fly like a bird with the hang glider in place. All I need now is a set of materials needed to build it, and ... do you want to help me out here? If you get me the materials, I'll definitely let you ride on it. What do you think?",
        "ask": 1,
        "no": {
          "0": "I can't believe you're giving up on a golden opportunity to fly. If that's the case, then I'm going to try to make it myself! You'll see!!!"
        },
        "stop": {
          "0": {
            "1": "You are just like everyone else living in a box. Wake up, think outside the box! You'll see ... someday you'll see me flying around here.",
            "answer": 1
          }
        },
        "yes": {
          "0": "I knew you'd help me out! Together we can make the most awesome hang glider ever! I was thinking, in order to make it happen, I'll need #b50 #t4000042#s#k for the wings, #b10 #t4003001#s#k for the framework, and #b50 #t4003004#s#k to make the flight as smooth as possible. You'll see a lot of Stirge's at the subway station nearby, so you should check it out!"
        }
      }
  let says : QuestPhaseSays = @json.from_json!(
    say_2083_1,
  )
  let talk0 = next_talk(says, Ask(next=0, expect_answer=0, error_replys=[], answer=0), None)
  guard talk0 is Some(talk0) else {fail("expect talk0")}
  inspect!(talk0.content, content="Wouldn't it be incredible to swim in those clouds and fly your way through freedom? I wonder what it's like to fly, free as a bird. Even if it's only for a few minutes, I'd be more than happy to just be up there! \\r\\n#L0##bCan humans really fly?#k#l\\r\\n#L1##bGrow up, you know we can't fly..#k")
  guard talk0.expect_response is SELECT(fun) else {fail("expect talk0 SELECT")}
  let talk1 = fun(0)
  guard talk1 is Some(talk1) else {fail("expect talk1")}
  inspect!(talk1.content, content="Oh yeah, I truly believe we're meant to fly, and I will try my hardest to make that wish come true! That got me thinking, in order to fulfill my dream, I should make a huge hang glider! I read it in a book, and it says we can fly like a bird with the hang glider in place. All I need now is a set of materials needed to build it, and ... do you want to help me out here? If you get me the materials, I'll definitely let you ride on it. What do you think?")
  guard talk1.expect_response is YES_NO(fun) else {fail("expect talk1 YES_NO")}
  let ( talk2, action ) = fun(true)
  assert_true(action is Some(StartQuest))
  guard talk2 is Some(talk2) else {fail("expect talk2")}
  inspect!(talk2.content, content="I knew you'd help me out! Together we can make the most awesome hang glider ever! I was thinking, in order to make it happen, I'll need #b50 #t4000042#s#k for the wings, #b10 #t4003001#s#k for the framework, and #b50 #t4003004#s#k to make the flight as smooth as possible. You'll see a lot of Stirge's at the subway station nearby, so you should check it out!")
  guard talk2.expect_response is OK(fun) else {fail("expect talk2 OK")}
  let action2 = fun()
  inspect!(action2, content="None")
}
```
