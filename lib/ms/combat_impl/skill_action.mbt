///|
trait SkillAction {
  apply(Self, @character.Character, @combat.AttackType) -> Unit
}

///|
struct NoAction {} derive(Default)

///|
fn NoAction::new() -> NoAction {
  NoAction::default()
}

///|
fn NoAction::apply(
  self : NoAction,
  target : @character.Character,
  atype : @combat.AttackType
) -> Unit {
  // Do nothing
}

///|
struct SingleAction {
  action : String
}

///|
fn SingleAction::new(src : @resource.NxNode) -> SingleAction {
  { action: src["action"]["0"].get_string() }
}

///|
fn SingleAction::apply(
  self : SingleAction,
  target : @character.Character,
  atype : @combat.AttackType
) -> Unit {
  target.attack_by_action(self.action)
}

///|
struct TwoHandedAction {
  actions : @utils.BoolPair[String]
}

///|
fn TwoHandedAction::new(src : @resource.NxNode) -> TwoHandedAction {
  {
    actions: @utils.BoolPair::new(
      src["action"]["0"].get_string(),
      src["action"]["1"].get_string(),
    ),
  }
}

///|
pub impl SkillAction for TwoHandedAction with apply(self, target, _) {
  let twohanded = target.is_twohanded()
  let action = self.actions[twohanded]
  target.attack_by_action(action)
}

///|
struct ByLevelAction {
  actions : Map[Int, String]
  skill_id : Int
}

///|
fn ByLevelAction::new(src : @resource.NxNode, id : Int) -> ByLevelAction! {
  let actions = Map::new()
  for sub in src["level"] {
    let level = @strconv.parse_int!(sub.name())
    let action = sub["action"].get_string()
    actions.set(level, action)
  }
  { actions, skill_id: id }
}

///|
fn ByLevelAction::apply(
  self : ByLevelAction,
  target : @character.Character,
  atype : @combat.AttackType
) -> Unit {
  let level = (target.get_skilllevel)(self.skill_id)
  match self.actions.get(level) {
    Some(action) => target.attack_by_action(action)
    None => ()
  }
}
