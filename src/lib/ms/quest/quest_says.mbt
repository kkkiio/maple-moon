///|
fn talk_about_quest(
  npc_quest : NpcQuest,
  quest_says : Array[QuestPhaseSays],
  network : @net.Network,
  open_npc_talk_ui : (@npc.TalkArgs) -> Unit
) -> Unit {
  let phase = npc_quest.in_progress_quest.map_or(0, fn(it) { it.0.phase })
  let says = quest_says[phase]
  let quest_met = npc_quest.in_progress_quest.map_or(None, fn(it) { Some(it.1) })
  let args = next_talk(
    says,
    if says.ask {
      Ask(next=0, expect_answer=0, error_replys=[], answer=0)
    } else {
      Narrative(next=0)
    },
    quest_met,
  )
  guard args is Some(args)  // should always have some words to say
  open_npc_talk_ui(bind_io(args, npc_quest, network, open_npc_talk_ui))
}

///|
pub struct QuestTalk {
  content : String
  expect_response : ExpectResponse
}

///|
pub enum ExpectResponse {
  NEXT(() -> QuestTalk?)
  YES_NO((Bool) -> (QuestTalk?, Action?))
  OK(() -> Action?)
  SELECT((Int) -> QuestTalk?)
}

///|
pub enum Action {
  StartQuest
  CompleteQuest
} derive(Show)

///|
pub(all) enum TalkState {
  Narrative(next~ : Int)
  YesReply(next~ : Int)
  NoReply(next~ : Int)
  Ask(
    next~ : Int,
    expect_answer~ : Int,
    error_replys~ : Array[String],
    answer~ : Int
  )
} derive(Show)

///|
pub fn next_talk(
  says : QuestPhaseSays,
  state : TalkState,
  quest_met : Bool?
) -> QuestTalk? {
  // @log.info({ "state": state }, "next_talk")
  match state {
    Narrative(next=i) => {
      // TODO: show hint according to the un met requirements (item, npc, etc.)
      guard says.says.get(i) is Some(str) else { return None }
      let last = says.says.get(i + 1) is None
      let yesno = says.yes_reply.length() > 0
      let expect_response = match (last, yesno) {
        (true, true) => // yesno
          YES_NO(fn(c) {
            (
              next_talk(
                says,
                if c {
                  YesReply(next=0)
                } else {
                  NoReply(next=0)
                },
                quest_met,
              ),
              match (c, quest_met) {
                (true, None) => Some(StartQuest)
                (true, Some(true)) => Some(CompleteQuest)
                _ => None
              },
            )
          })
        (true, false) => // end
          OK(fn() { None })
        (false, _) => // continue
          NEXT(fn() { next_talk(says, Narrative(next=i + 1), quest_met) })
      }
      Some({ content: str, expect_response })
    }
    YesReply(next=i) => {
      guard says.yes_reply.get(i) is Some(str) else { return None }
      let last = says.yes_reply.get(i + 1) is None
      let expect_response = if last {
        OK(fn() { None })
      } else {
        NEXT(fn() { next_talk(says, YesReply(next=i + 1), quest_met) })
      }
      Some({ content: str, expect_response })
    }
    NoReply(next=i) => {
      guard says.no_reply.get(i) is Some(str) else { return None }
      let last = says.no_reply.get(i + 1) is None
      let expect_response = if last {
        OK(fn() { None })
      } else {
        NEXT(fn() { next_talk(says, NoReply(next=i + 1), quest_met) })
      }
      Some({ content: str, expect_response })
    }
    Ask(next=i, expect_answer~, error_replys~, answer~) => {
      if expect_answer != answer { // check quiz answer
        // wrong, hint, end
        let str = error_replys[answer]
        return Some({ content: str, expect_response: OK(fn() { None }) })
      }
      // correct answer
      guard says.says.get(i) is Some(str) else {
        @log.error({ "says": says.says, "i": i }, "says.get(i) is None")
        return None
      }
      let last = says.says.get(i + 1) is None
      let yesno = says.yes_reply.length() > 0
      let expect_response = match (last, yesno) {
        (true, true) => // yesno
          YES_NO(fn(c) {
            (
              next_talk(
                says,
                if c {
                  YesReply(next=0)
                } else {
                  NoReply(next=0)
                },
                quest_met,
              ),
              match (c, quest_met) {
                (true, None) => Some(StartQuest)
                (true, Some(true)) => Some(CompleteQuest)
                _ => None
              },
            )
          })
        (true, false) => // end
          OK(fn() {
            match quest_met {
              Some(true) => Some(CompleteQuest)
              _ => None
            }
          })
        (
          false, // continue
          _,
        ) => {
          guard says.stop is Some(hints) else {
            @log.error({ "says": says.stop }, "says.stop is None")
            return None
          }
          guard hints.base.get(i) is Some(quiz) else {
            @log.error(
              { "hints": hints.base, "i": i },
              "hints.base.get(i) is None",
            )
            return None
          }
          let expect_answer = quiz.answer - 1 // CONFUSING: option missmatch with the answer
          let error_replys = quiz.says
          SELECT(fn(c) {
            next_talk(
              says,
              Ask(next=i + 1, expect_answer~, error_replys~, answer=c),
              quest_met,
            )
          })
        }
      }
      Some({ content: str, expect_response })
    }
  }
}

///|
fn bind_io(
  args : QuestTalk,
  npc_quest : NpcQuest,
  network : @net.Network,
  open_npc_talk_ui : (@npc.TalkArgs) -> Unit
) -> @npc.TalkArgs {
  match args.expect_response {
    NEXT(fun) =>
      {
        npc_id: npc_quest.npc_id,
        str: args.content,
        talk_action: @npc.TalkAction::SEND_NEXT(fn(c) {
          guard c is Some(_) else { return }
          let next_args = fun()
          guard next_args is Some(next_args) else { return }
          open_npc_talk_ui(
            bind_io(next_args, npc_quest, network, open_npc_talk_ui),
          )
        }),
        speaker: @npc.Speaker::NPC_LEFT,
      }
    YES_NO(fun) =>
      {
        npc_id: npc_quest.npc_id,
        str: args.content,
        talk_action: @npc.TalkAction::SEND_YESNO(fn(c) {
          guard c is Some(c) else { return }
          let (next_args, action) = fun(c)
          if action is Some(action) {
            execute_action(action, npc_quest, network)
          }
          guard next_args is Some(next_args) else { return }
          open_npc_talk_ui(
            bind_io(next_args, npc_quest, network, open_npc_talk_ui),
          )
        }),
        speaker: @npc.Speaker::NPC_LEFT,
      }
    OK(fun) =>
      {
        npc_id: npc_quest.npc_id,
        str: args.content,
        talk_action: @npc.TalkAction::SEND_OK(fn(c) {
          guard c is Some(_) else { return }
          let action = fun()
          guard action is Some(action) else { return }
          execute_action(action, npc_quest, network)
        }),
        speaker: @npc.Speaker::NPC_LEFT,
      }
    SELECT(fun) =>
      {
        npc_id: npc_quest.npc_id,
        str: args.content,
        talk_action: @npc.TalkAction::SEND_SIMPLE(fn(c) {
          guard c is Some(c) else { return }
          let next_args = fun(c)
          guard next_args is Some(next_args) else { return }
          open_npc_talk_ui(
            bind_io(next_args, npc_quest, network, open_npc_talk_ui),
          )
        }),
        speaker: @npc.Speaker::NPC_LEFT,
      }
  }
}

///|
fn execute_action(
  action : Action,
  npc_quest : NpcQuest,
  network : @net.Network
) -> Unit {
  match action {
    StartQuest =>
      network.send_message(
        QuestActionMessage::StartQuest(
          quest_id=npc_quest.quest_id,
          npc_id=npc_quest.npc_id,
        ),
      )
    CompleteQuest =>
      network.send_message(
        QuestActionMessage::CompleteQuest(
          quest_id=npc_quest.quest_id,
          npc_id=npc_quest.npc_id,
          selection=None, // TODO: what selection should be sent?
        ),
      )
  }
}
