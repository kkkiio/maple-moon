///|
test "parse null phase says" {
  let q1021 = @json.parse(
    (
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
    ),
  )
  let quest_say : @resource.MapBasedArray[@quest.NxQuestPhaseSays] = @json.from_json(
    q1021,
  )
  let phases = quest_say.0
  assert_true(phases.length() == 2)
  assert_true(phases[0].says.is_empty())
  assert_true(phases[0].stop is None)
  guard phases[1].stop is Some(hints) else { fail("expect stop hints") }
  assert_true(hints.item.length() == 1)
  inspect(
    hints.item[0],
    content="I told you to have all #r7 #t2010007##k that I gave you. Open the item window and click#bconsumption tab#k. You can find #t2010007# and consume them by double click.",
  )
}

///|
test "parse null hint" {
  let q2300 = @json.parse(
    (
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
    ),
  )
  let quest_say : @resource.MapBasedArray[@quest.NxQuestPhaseSays] = @json.from_json(
    q2300,
  )
  let phases = quest_say.0
  assert_true(phases.length() == 2)
  assert_true(phases[0].ask)
  guard phases[0].stop is Some(stop0) else { fail("expect phase0 stop") }
  assert_true(stop0.base.length() == 1)
  assert_true(stop0.base[0].says.is_empty())
  guard phases[1].stop is Some(stop1) else { fail("expect phase1 stop") }
  assert_true(stop1.item.length() == 1)
  inspect(
    stop1.item[0],
    content="Who are you? You look like someone who's exploring Maple World. Our kingdom is in serious danger, and we need someone dependable that can save us. If you can't help us, then I suggest you move on.",
  )
}

///|
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
  let says : @quest.NxQuestPhaseSays = @json.from_json(say_2090_1)
  let talk0 = next_talk(
    says,
    Ask(next=0, expect_answer=0, error_replys=[], answer=0),
    Some(true),
  )
  guard talk0 is Some(talk0) else { fail("talk0 is None") }
  guard talk0.expect_response is SELECT(fun) else {
    fail("talk0.expect_response is not SELECT")
  }
  let talk1 = fun(4)
  guard talk1 is Some(talk1) else { fail("talk1 is None") }
  guard talk1.expect_response is SELECT(fun) else {
    fail("talk1.expect_response is not SELECT")
  }
  let talk2 = fun(3)
  guard talk2 is Some(talk2) else { fail("talk2 is None") }
  guard talk2.expect_response is SELECT(fun) else {
    fail("talk2.expect_response is not SELECT")
  }
  let talk3 = fun(0)
  guard talk3 is Some(talk3) else { fail("talk3 is None") }
  guard talk3.expect_response is OK(fun) else {
    fail("talk3.expect_response is not OK")
  }
  let action = fun()
  guard action is Some(CompleteQuest) else {
    fail("expect complete quest action")
  }
}

///|
test "Icarus's Hang Glider" {
  let say_2083_1 : Json = {
    "0": "Wouldn't it be incredible to swim in those clouds and fly your way through freedom? I wonder what it's like to fly, free as a bird. Even if it's only for a few minutes, I'd be more than happy to just be up there! \\r\\n#L0##bCan humans really fly?#k#l\\r\\n#L1##bGrow up, you know we can't fly..#k",
    "1": "Oh yeah, I truly believe we're meant to fly, and I will try my hardest to make that wish come true! That got me thinking, in order to fulfill my dream, I should make a huge hang glider! I read it in a book, and it says we can fly like a bird with the hang glider in place. All I need now is a set of materials needed to build it, and ... do you want to help me out here? If you get me the materials, I'll definitely let you ride on it. What do you think?",
    "ask": 1,
    "no": {
      "0": "I can't believe you're giving up on a golden opportunity to fly. If that's the case, then I'm going to try to make it myself! You'll see!!!",
    },
    "stop": {
      "0": {
        "1": "You are just like everyone else living in a box. Wake up, think outside the box! You'll see ... someday you'll see me flying around here.",
        "answer": 1,
      },
    },
    "yes": {
      "0": "I knew you'd help me out! Together we can make the most awesome hang glider ever! I was thinking, in order to make it happen, I'll need #b50 #t4000042#s#k for the wings, #b10 #t4003001#s#k for the framework, and #b50 #t4003004#s#k to make the flight as smooth as possible. You'll see a lot of Stirge's at the subway station nearby, so you should check it out!",
    },
  }
  let says : @quest.NxQuestPhaseSays = @json.from_json(say_2083_1)
  let talk0 = next_talk(
    says,
    Ask(next=0, expect_answer=0, error_replys=[], answer=0),
    None,
  )
  guard talk0 is Some(talk0) else { fail("expect talk0") }
  guard talk0.expect_response is SELECT(fun) else {
    fail("expect talk0 SELECT")
  }
  let talk1 = fun(0)
  guard talk1 is Some(talk1) else { fail("expect talk1") }
  guard talk1.expect_response is YES_NO(fun) else {
    fail("expect talk1 YES_NO")
  }
  let (talk2, action) = fun(true)
  guard action is Some(StartQuest) else { fail("expect start quest action") }
  guard talk2 is Some(talk2) else { fail("expect talk2") }
  guard talk2.expect_response is OK(fun) else { fail("expect talk2 OK") }
  let action2 = fun()
  assert_true(action2 is None)
}

///|
test "quest 2091 should use stop item text when quest is unmet" {
  let say_2091_phase1 : @quest.NxQuestPhaseSays = @json.from_json({
    "0": "Wow, you brought all of them!! Thank you so much! Thanks to you, I won't be so bored up in here afterwards. How should I thank you for your hard work? Hmmm ... here, take this!",
    "stop": {
      "item": {
        "0": "You don't have all of them? Please help me ... I am bored out of my mind here.",
      },
    },
    "yes": { "0": "Again, thanks a lot! Later!!" },
  })
  let talk = next_talk(say_2091_phase1, Narrative(next=0), Some(false))
  guard talk is Some(talk) else { fail("expect talk") }
  inspect(
    talk.content,
    content="You don't have all of them? Please help me ... I am bored out of my mind here.",
  )
  guard talk.expect_response is OK(fun) else { fail("expect OK") }
  assert_true(fun() is None)
}

///|
test "quest 2091 should keep complete flow when quest is met" {
  let say_2091_phase1 : @quest.NxQuestPhaseSays = @json.from_json({
    "0": "Wow, you brought all of them!! Thank you so much! Thanks to you, I won't be so bored up in here afterwards. How should I thank you for your hard work? Hmmm ... here, take this!",
    "stop": {
      "item": {
        "0": "You don't have all of them? Please help me ... I am bored out of my mind here.",
      },
    },
    "yes": { "0": "Again, thanks a lot! Later!!" },
  })
  let talk = next_talk(say_2091_phase1, Narrative(next=0), Some(true))
  guard talk is Some(talk) else { fail("expect talk") }
  inspect(
    talk.content,
    content="Wow, you brought all of them!! Thank you so much! Thanks to you, I won't be so bored up in here afterwards. How should I thank you for your hard work? Hmmm ... here, take this!",
  )
  guard talk.expect_response is YES_NO(fun) else { fail("expect YES_NO") }
  let (next_talk, action) = fun(true)
  guard action is Some(CompleteQuest) else {
    fail("expect complete quest action")
  }
  guard next_talk is Some(next_talk) else { fail("expect follow-up talk") }
  inspect(next_talk.content, content="Again, thanks a lot! Later!!")
}
