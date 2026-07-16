///|
fn start_m_taxi(
  context : @content_runtime.NpcScriptContext,
) -> @content_runtime.NpcScriptTurn raise {
  guard context.npc_id > 0 else {
    fail("mTaxi requires a positive NPC template ID")
  }
  {
    state: { "stage": "introduction" },
    prompt: Some(
      Next(
        "Hi there! This cab is for VIP customers only. Instead of just taking you to different towns like the regular cabs, we offer a much better service worthy of VIP class. It's a bit pricey, but... for only 10,000 mesos, we'll take you safely to the\r\n#bAnt Tunnel#k.",
      ),
    ),
    commands: [],
    finished: false,
  }
}

///|
fn respond_m_taxi(
  state : Json,
  input : @content_runtime.NpcScriptInput,
  context : @content_runtime.NpcScriptContext,
) -> @content_runtime.NpcScriptTurn raise {
  guard state is { "stage": String(stage), .. } else {
    fail("mTaxi state must contain a string stage")
  }
  let cost = if context.job_id == 0 { 1000 } else { 10000 }
  match (stage, input) {
    ("introduction", Continue) => {
      let prompt = if context.job_id == 0 {
        "We have a special 90% discount for beginners. The Ant Tunnel is located deep inside the dungeon at the center of Victoria Island, where the 24 Hr Mobile Store is. Would you like to go there for #b1,000 mesos#k?"
      } else {
        "The regular fee applies for all non-beginners. The Ant Tunnel is located deep inside the dungeon at the center of Victoria Island, where the 24 Hr Mobile Store is. Would you like to go there for #b10,000 mesos#k?"
      }
      {
        state: { "stage": "confirmation" },
        prompt: Some(YesNo(prompt)),
        commands: [],
        finished: false,
      }
    }
    ("introduction", Close)
    | ("confirmation", No)
    | ("confirmation", Close)
    | ("insufficient_funds", Continue)
    | ("insufficient_funds", Close) =>
      {
        state: { "stage": "finished" },
        prompt: None,
        commands: [],
        finished: true,
      }
    ("confirmation", Yes) if context.meso < cost =>
      {
        state: { "stage": "insufficient_funds" },
        prompt: Some(
          Ok(
            "It looks like you don't have enough mesos. Sorry, but you won't be able to use this service without them.",
          ),
        ),
        commands: [],
        finished: false,
      }
    ("confirmation", Yes) =>
      {
        state: { "stage": "finished" },
        prompt: None,
        commands: [TakeMeso(cost), Warp(map_id=105070001, portal_id=0)],
        finished: true,
      }
    _ => fail("mTaxi received invalid input at stage \{stage}")
  }
}

///|
/// Build the statically compiled NPC script registry for the base game.
///
/// The registry preserves NX `info.script` names as exact content identifiers.
///
/// # Example
/// ```moonbit nocheck
/// let scripts = npc_scripts()
/// inspect(scripts.contains("mTaxi"), content="true")
/// ```
pub fn npc_scripts() -> @content_runtime.NpcScriptRegistry {
  let scripts = @content_runtime.NpcScriptRegistry()
  scripts.register("mTaxi", { start: start_m_taxi, respond: respond_m_taxi }) catch {
    @content_runtime.NpcScriptRegistryError::DuplicateScript(name) =>
      abort("duplicate base NPC script registration: \{name}")
    @content_runtime.NpcScriptRegistryError::MissingScript(name) =>
      abort("unexpected missing base NPC script during registration: \{name}")
  }
  scripts
}
