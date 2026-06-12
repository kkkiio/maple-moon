///|
using @quest {type NxQuestPhaseSays}

///|
fn talk_about_quest(
  npc_quest : NpcQuest,
  quest_says : Array[NxQuestPhaseSays],
  open_npc_talk_ui : (@npc.TalkArgs) -> Unit,
) -> Unit {
  if build_talk_args_for_quest(npc_quest, quest_says, open_npc_talk_ui)
    is Some(talk_args) {
    open_npc_talk_ui(talk_args)
  }
}

///|
pub fn build_talk_args_for_quest(
  npc_quest : NpcQuest,
  quest_says : Array[NxQuestPhaseSays],
  open_npc_talk_ui : (@npc.TalkArgs) -> Unit,
) -> @npc.TalkArgs? {
  let phase = npc_quest.in_progress_quest.map_or(0, fn(it) { it.0 })
  guard quest_says.get(phase) is Some(says) else { return None }
  let quest_met = npc_quest.in_progress_quest.map_or(None, fn(it) { Some(it.1) })
  guard next_talk(
      says,
      if says.ask {
        Ask(next=0, expect_answer=0, error_replys=[], answer=0)
      } else {
        Narrative(next=0)
      },
      quest_met,
    )
    is Some(args) else {
    return None
  }
  Some(bind_io(args, npc_quest, open_npc_talk_ui))
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
} derive(Debug)

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
} derive(Debug)

///|
pub fn next_talk(
  says : NxQuestPhaseSays,
  state : TalkState,
  quest_met : Bool?,
) -> QuestTalk? {
  // @log.info({ "state": state }, "next_talk")
  match state {
    Narrative(next=i) => {
      if i == 0 && quest_met == Some(false) {
        if says.stop is Some(hints) {
          let unmet_text = if hints.item.get(0) is Some(text) {
            Some(text)
          } else if hints.npc.get(0) is Some(text) {
            Some(text)
          } else {
            None
          }
          if unmet_text is Some(text) {
            return Some({ content: text, expect_response: OK(fn() { None }) })
          }
        }
      }
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
        @log.error("says.get(i) is None", data={ "says": says.says, "i": i })
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
            @log.error("says.stop is None", data={ "says": says.stop })
            return None
          }
          guard hints.base.get(i) is Some(quiz) else {
            @log.error("hints.base.get(i) is None", data={
              "hints": hints.base,
              "i": i,
            })
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
  open_npc_talk_ui : (@npc.TalkArgs) -> Unit,
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
          open_npc_talk_ui(bind_io(next_args, npc_quest, open_npc_talk_ui))
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
            execute_action(action, npc_quest)
          }
          guard next_args is Some(next_args) else { return }
          open_npc_talk_ui(bind_io(next_args, npc_quest, open_npc_talk_ui))
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
          execute_action(action, npc_quest)
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
          open_npc_talk_ui(bind_io(next_args, npc_quest, open_npc_talk_ui))
        }),
        speaker: @npc.Speaker::NPC_LEFT,
      }
  }
}

///|
fn execute_action(action : Action, npc_quest : NpcQuest) -> Unit {
  match action {
    StartQuest =>
      @game_server.send(
        @server_proto.QuestActionMessage::StartQuest(
          quest_id=npc_quest.quest_id,
          npc_id=npc_quest.npc_id,
        ),
      )
    CompleteQuest =>
      @game_server.send(
        @server_proto.QuestActionMessage::CompleteQuest(
          quest_id=npc_quest.quest_id,
          npc_id=npc_quest.npc_id,
          selection=None,
        ),
      )
  }
}
