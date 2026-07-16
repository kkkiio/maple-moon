///|
using @content_runtime {type NpcScriptInput, type NpcScriptPrompt}

///|
fn load_npc_script_name(npc_id : Int) -> String? raise {
  let resource = "res://Npc/\{npc_id}.img/mx.json"
  let json = @res.require_json(resource)
  match json {
    { "info": { "script": Null, .. }, .. } => None
    { "info": { "script": Object(script_entries), .. }, .. } => {
      let mut index = 0
      while script_entries.get(index.to_string()) is Some(entry) {
        match entry {
          { "script": String(name), .. } if name != "" => return Some(name)
          _ =>
            fail(
              "NPC script entry must contain a non-empty script name: \{resource}",
            )
        }
        index += 1
      }
      fail("NPC script list must contain at least one entry: \{resource}")
    }
    { "info": { "script": _, .. }, .. } =>
      fail("NPC script list must be an object: \{resource}")
    _ => None
  }
}

///|
fn LocalServer::send_npc_script_prompt(
  self : LocalServer,
  npc_id : Int,
  prompt : NpcScriptPrompt,
) -> Unit {
  let (talk_type, text) = match prompt {
    Next(text) => (14, text)
    YesNo(text) => (1, text)
    Ok(text) => (13, text)
    Simple(text) => (4, text)
  }
  self.send_server_message(@server_proto.NpcDialogueMessage::{
    npcid: npc_id,
    talk_type,
    speaker: 0,
    text,
  })
}

///|
fn LocalServer::apply_npc_script_turn(
  self : LocalServer,
  npc_id : Int,
  script_name : String,
  turn : @content_runtime.NpcScriptTurn,
) -> Unit raise {
  let mut total_meso = 0
  let mut warp : (Int, Int)? = None
  for command in turn.commands {
    match command {
      TakeMeso(amount) => {
        guard amount > 0 else {
          fail("NPC script TakeMeso amount must be positive: \{script_name}")
        }
        total_meso += amount
      }
      Warp(map_id~, portal_id~) => {
        guard warp is None else {
          fail(
            "NPC script turn may contain only one Warp command: \{script_name}",
          )
        }
        guard map_id > 0 && portal_id >= 0 else {
          fail("NPC script Warp target must be positive: \{script_name}")
        }
        guard load_tiled_map_by_map_id(map_id) is Some(_) else {
          fail("NPC script Warp target map is unavailable: \{map_id}")
        }
        warp = Some((map_id, portal_id))
      }
    }
  }
  guard total_meso <= self.player_meso else {
    fail("NPC script attempted to take unavailable mesos: \{script_name}")
  }
  match (turn.finished, turn.prompt) {
    (true, Some(_)) => fail("finished NPC script turn cannot display a prompt")
    (false, None) => fail("unfinished NPC script turn must display a prompt")
    _ => ()
  }
  if total_meso > 0 {
    self.player_meso -= total_meso
    self.send_server_message(@server_proto.ChangeStatsMesoMessage::{
      meso: self.player_meso,
    })
  }
  match warp {
    Some((map_id, portal_id)) => {
      self.last_map_id = map_id
      self.last_portal_id = portal_id
      self.send_server_message(
        @server_proto.SetFieldMessage::ChangeMap(map_id~, portal_id~),
      )
      self.spawn_mobs_for_map(map_id)
    }
    None => ()
  }
  if total_meso > 0 || warp is Some(_) {
    self.save_character_core_snapshot()
  }
  if turn.finished {
    self.active_npc_script = None
  } else {
    self.active_npc_script = Some({ npc_id, script_name, state: turn.state })
  }
  match turn.prompt {
    Some(prompt) => self.send_npc_script_prompt(npc_id, prompt)
    None => ()
  }
}

///|
fn LocalServer::start_npc_script(
  self : LocalServer,
  npc_id : Int,
  script_name : String,
) -> Unit raise {
  let script = self.npc_scripts.require(script_name)
  let context : @content_runtime.NpcScriptContext = {
    npc_id,
    job_id: 0,
    meso: self.player_meso,
  }
  self.active_shop = None
  self.active_npc_script = Some({
    npc_id,
    script_name,
    state: { "stage": "starting" },
  })
  let turn = (script.start)(context)
  self.apply_npc_script_turn(npc_id, script_name, turn)
}

///|
fn LocalServer::on_npc_talk_more(self : LocalServer, json : Json) -> Unit raise {
  let message : @server_proto.NpcTalkMoreMessage = @json.from_json(json)
  guard self.active_npc_script is Some(session) else {
    fail("NPC_TALK_MORE requires an active NPC script session")
  }
  let input : NpcScriptInput = match (message.lastmsg, message.response) {
    (_, -1) => Close
    (1, 1) => Yes
    (1, 0) => No
    (4, 1) =>
      match message.selection {
        Some(selection) => Select(selection)
        None => fail("SEND_SIMPLE response requires a selection")
      }
    (13, 1) | (14, 1) => Continue
    (15, 1) => Continue
    (15, 0) | (16, 1) => Previous
    _ =>
      fail(
        "unsupported NPC script response: lastmsg=\{message.lastmsg}, response=\{message.response}",
      )
  }
  let script = self.npc_scripts.require(session.script_name)
  let context : @content_runtime.NpcScriptContext = {
    npc_id: session.npc_id,
    job_id: 0,
    meso: self.player_meso,
  }
  let turn = (script.respond)(session.state, input, context)
  self.apply_npc_script_turn(session.npc_id, session.script_name, turn)
}
