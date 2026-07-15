///|
trait SkillAction {
  fn apply(Self, @character.Character, @combat_proto.AttackType) -> Unit
}

///|
struct NoAction {} derive(Default)

///|
fn NoAction::NoAction() -> NoAction {
  Default::default()
}

///|
pub impl SkillAction for NoAction with fn apply(
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
fn SingleAction::SingleAction(src : Json) -> SingleAction {
  let action = match src {
    { "action": { "0": String(action), .. }, .. } => action
    _ => ""
  }
  { action, }
}

///|
pub impl SkillAction for SingleAction with fn apply(
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
fn TwoHandedAction::TwoHandedAction(src : Json) -> TwoHandedAction {
  let (action0, action1) = match src {
    { "action": { "0": String(action0), "1": String(action1), .. }, .. } =>
      (action0, action1)
    _ => ("", "")
  }
  { actions: BoolPair(action0, action1) }
}

///|
pub impl SkillAction for TwoHandedAction with fn apply(self, target, _) {
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
fn ByLevelAction::ByLevelAction(src : Json, id : Int) -> ByLevelAction {
  let actions = Map([])
  if src is { "level": Object(levels), .. } {
    for level, sub in levels {
      if sub is { "action": String(action), .. } {
        let parsed_level = @string.parse_int(level) catch {
          _ => abort("invalid skill action level: \{level}")
        }
        actions.set(parsed_level, action)
      }
    }
  }
  { actions, skill_id: id }
}

///|
pub impl SkillAction for ByLevelAction with fn apply(
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
pub impl SkillAction for FuncSkillAction with fn apply(self, c, t) {
  (self.0)(c, t)
}
