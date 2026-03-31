///|
trait SkillAction {
  apply(Self, @character.Character, @combat_proto.AttackType) -> Unit
}

///|
struct NoAction {} derive(Default)

///|
fn NoAction::new() -> NoAction {
  NoAction::default()
}

///|
pub impl SkillAction for NoAction with apply(
  _ : NoAction,
  _ : @character.Character,
  _ : @combat_proto.AttackType,
) -> Unit {
  // Do nothing
}

///|
struct SingleAction {
  action : String
}

///|
fn SingleAction::new(src : Json) -> SingleAction {
  let action = match src {
    { "action": { "0": String(action), .. }, .. } => action
    _ => ""
  }
  { action, }
}

///|
pub impl SkillAction for SingleAction with apply(
  self : SingleAction,
  target : @character.Character,
  _ : @combat_proto.AttackType,
) -> Unit {
  target.attack_by_action(self.action)
}

///|
struct TwoHandedAction {
  actions : @utils.BoolPair[String]
}

///|
fn TwoHandedAction::new(src : Json) -> TwoHandedAction {
  let (action0, action1) = match src {
    { "action": { "0": String(action0), "1": String(action1), .. }, .. } =>
      (action0, action1)
    _ => ("", "")
  }
  { actions: @utils.BoolPair::new(action0, action1) }
}

///|
pub impl SkillAction for TwoHandedAction with apply(self, target, _) {
  let twohanded = target.is_two_handed()
  let action = self.actions[twohanded]
  target.attack_by_action(action)
}

///|
struct ByLevelAction {
  actions : Map[Int, String]
  skill_id : Int
}

///|
fn ByLevelAction::new(src : Json, id : Int) -> ByLevelAction raise {
  let actions = Map::new()
  if src is { "level": Object(levels), .. } {
    for level, sub in levels {
      if sub is { "action": String(action), .. } {
        actions.set(@string.parse_int(level), action)
      }
    }
  }
  { actions, skill_id: id }
}

///|
pub impl SkillAction for ByLevelAction with apply(
  self : ByLevelAction,
  target : @character.Character,
  _ : @combat_proto.AttackType,
) -> Unit {
  let level = (target.get_skilllevel)(self.skill_id)
  match self.actions.get(level) {
    Some(action) => target.attack_by_action(action)
    None => ()
  }
}

///|
struct FuncSkillAction((@character.Character, @combat_proto.AttackType) -> Unit)

///|
pub impl SkillAction for FuncSkillAction with apply(self, c, t) {
  (self.0)(c, t)
}
