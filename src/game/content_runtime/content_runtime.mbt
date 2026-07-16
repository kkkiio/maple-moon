///|
/// A player response delivered to the currently active NPC script turn.
pub(all) enum NpcScriptInput {
  /// Advance a Next or OK prompt.
  Continue
  /// Move backward from a Previous-capable prompt.
  Previous
  /// Accept a Yes/No prompt.
  Yes
  /// Decline a Yes/No prompt.
  No
  /// Select one numbered option from a simple menu.
  Select(Int)
  /// Close the dialogue without accepting its current action.
  Close
} derive(Debug, Eq)

///|
/// A dialogue view requested by an NPC script.
pub(all) enum NpcScriptPrompt {
  /// Show text with a Next button.
  Next(String)
  /// Show text with Yes and No buttons.
  YesNo(String)
  /// Show text with an OK button.
  Ok(String)
  /// Show markup text containing numbered selections.
  Simple(String)
}

///|
/// An authoritative command requested by a completed NPC script turn.
pub(all) enum NpcScriptCommand {
  /// Remove a positive amount of mesos from the current player.
  TakeMeso(Int)
  /// Transfer the current player to a map and numeric portal.
  Warp(map_id~ : Int, portal_id~ : Int)
}

///|
/// The read-only player and NPC state visible to one script evaluation.
pub(all) struct NpcScriptContext {
  /// Template ID of the NPC owning the conversation.
  npc_id : Int
  /// Current MapleStory job ID; zero identifies a beginner.
  job_id : Int
  /// Current authoritative meso balance.
  meso : Int
}

///|
/// Result of starting or advancing one NPC script.
pub(all) struct NpcScriptTurn {
  /// Opaque JSON state passed back to the same script on the next response.
  state : Json
  /// Dialogue to display, or `None` when the conversation completes immediately.
  prompt : NpcScriptPrompt?
  /// Commands validated and committed atomically by the authoritative host.
  commands : Array[NpcScriptCommand]
  /// Whether the host must discard the conversation after applying this turn.
  finished : Bool
}

///|
/// A statically compiled NPC script implementation.
pub(all) struct NpcScript {
  /// Start a new conversation from the current context.
  start : (NpcScriptContext) -> NpcScriptTurn raise
  /// Advance an existing conversation using its opaque state and player response.
  respond : (Json, NpcScriptInput, NpcScriptContext) -> NpcScriptTurn raise
}

///|
/// Errors produced while constructing or resolving an NPC script registry.
pub(all) suberror NpcScriptRegistryError {
  /// Two content packages attempted to claim the same script name.
  DuplicateScript(String)
  /// A loaded NPC resource referenced a script with no registered implementation.
  MissingScript(String)
}

///|
/// Registry of statically compiled NPC scripts keyed by NX `info.script` name.
pub struct NpcScriptRegistry {
  scripts : Map[String, NpcScript]
}

///|
/// Create an empty NPC script registry.
///
/// # Example
/// ```moonbit nocheck
/// let scripts = NpcScriptRegistry()
/// inspect(scripts.contains("mTaxi"), content="false")
/// ```
pub fn NpcScriptRegistry::NpcScriptRegistry() -> NpcScriptRegistry {
  { scripts: Map([]) }
}

///|
/// Register a unique NX script name.
///
/// # Example
/// ```moonbit nocheck
/// let scripts = NpcScriptRegistry()
/// scripts.register("example", script)
/// ```
///
/// # Errors
/// Raises `DuplicateScript` when the name was already registered.
pub fn NpcScriptRegistry::register(
  self : NpcScriptRegistry,
  name : String,
  script : NpcScript,
) -> Unit raise NpcScriptRegistryError {
  if self.scripts.contains(name) {
    raise DuplicateScript(name)
  }
  self.scripts.set(name, script)
}

///|
/// Return whether a script name has a registered implementation.
///
/// # Example
/// ```moonbit nocheck
/// let scripts = NpcScriptRegistry()
/// inspect(scripts.contains("missing"), content="false")
/// ```
pub fn NpcScriptRegistry::contains(
  self : NpcScriptRegistry,
  name : String,
) -> Bool {
  self.scripts.contains(name)
}

///|
/// Resolve one registered script by its exact NX name.
///
/// # Example
/// ```moonbit nocheck
/// let script = scripts.require("mTaxi")
/// ```
///
/// # Errors
/// Raises `MissingScript` when no implementation owns the name.
pub fn NpcScriptRegistry::require(
  self : NpcScriptRegistry,
  name : String,
) -> NpcScript raise NpcScriptRegistryError {
  match self.scripts.get(name) {
    Some(script) => script
    None => raise MissingScript(name)
  }
}
