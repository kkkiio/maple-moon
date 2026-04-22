///|
using @char_stance {type StanceId}

///|
using @map_object {type MapObjectBase}

///|
using @server_proto {type StatsEntry}

///|
using @physics {type PhysicsObject}

///|
/// Player states which determine animation and state
pub(all) enum CharState {
  WALK
  STAND
  FALL
  ALERT
  PRONE
  SWIM
  LADDER
  ROPE
  DIED
  SIT
} derive(Eq, Compare, Debug)

///|
pub(all) enum Facing {
  LEFT
  RIGHT
}

///|
pub fn Facing::is_facing_right(self : Facing) -> Bool {
  match self {
    Facing::RIGHT => true
    _ => false
  }
}

///|
/// Values are used in movement packets (Add one if facing left)
pub fn CharState::stance_value(self : CharState, facing_right~ : Bool) -> Int {
  (match self {
    WALK => 2
    STAND => 4
    FALL => 6
    ALERT => 8
    PRONE => 10
    SWIM => 12
    LADDER => 14
    ROPE => 16
    DIED => 18
    SIT => 20
  }) +
  (if facing_right { 0 } else { 1 })
}

///|
/// Base for characters, e.g. the player and other clients on the same map.
pub(all) struct Character {
  entity : @entity.Entity
  base : MapObjectBase
  mut look : @char_look.CharLook
  stats : @char_stats.CharStats
  // look_preview: CharLook
  // pets: Array[PetLook, 3]
  mut state : CharState
  mut attacking : Bool
  mut facing_right : Bool
  name : String
  // name_label : @graphics.Text
  // chat_balloon: ChatBalloon
  // recurring_effects: RecurringEffect
  invincible : @utils.TimedBool
  // iron_body: TimedBool
  // damage_number_set : @ui.NumberSet
  // damage_numbers : Array[@ui.Number]
  // Character trait methods converted to function fields
  get_skilllevel : (Int) -> Int
  alerted : @utils.TimedBool
}

///|
/// Global character registry keyed by object id.
let character_registry : Map[Int, Character] = Map::new()

///|
/// Register a character into the global registry.
pub fn register_character(character : Character) -> Unit {
  character_registry.set(character.get_oid(), character)
}

///|
/// Remove a character from the global registry by object id.
pub fn unregister_character_by_oid(oid : Int) -> Unit {
  ignore(character_registry.remove(oid))
}

///|
/// Get a character from the global registry by object id.
pub fn get_character_by_oid(oid : Int) -> Character? {
  character_registry.get(oid)
}

///|
/// Clear all characters from the global registry.
pub fn clear_character_registry() -> Unit {
  character_registry.clear()
}

///|
pub fn Character::get_position(self : Character) -> @struct.Point[Int] {
  self.base.get_position()
}

///|
pub fn Character::set_position(
  self : Character,
  pos : @struct.Point[Int],
) -> Unit {
  self.base.set_position(pos)
}

///|
pub fn Character::new(
  entity : @entity.Entity,
  oid : Int,
  look : @char_look.CharLook,
  name : String,
  get_skilllevel~ : (Int) -> Int,
  stats : @char_stats.CharStats,
) -> Character {
  let char_base = {
    entity,
    base: MapObjectBase::new(oid, on_pos_change=fn(pos) {
      @transform2d.set_xy(entity, pos)
    }),
    look,
    stats,
    attacking: false,
    facing_right: false,
    name,
    // name_label: @graphics.Text::new(
    //   text=name,
    //   @graphics.FontId::A13M,
    //   @graphics.TextAlignment::CENTER,
    //   @struct.ColorName::WHITE,
    //   nametag=true,
    // ),
    state: CharState::STAND,
    invincible: @utils.TimedBool::default(),
    get_skilllevel,
    alerted: @utils.TimedBool::default(),
  }
  stats.watch_stat_changes(@maple_stat.Id::LEVEL, fn(old, new) {
    if new > old {
      char_base.show_effect_id(CharEffectId::LEVEL_UP)
    }
    true
  })
  char_base
}

///|
pub fn Character::is_climbing(self : Character) -> Bool {
  match self.state {
    CharState::LADDER | CharState::ROPE => true
    _ => false
  }
}

///|
/// Return the current high-level character state.
pub fn Character::get_state(self : Character) -> CharState {
  self.state
}

///|
pub fn Character::get_layer(self : Character) -> Int {
  if self.is_climbing() {
    7
  } else {
    self.base.phobj.fhlayer
  }
}

///|
/// speed is the multiplier of the timestep.
pub fn Character::update(self : Character, speed : Double) -> Unit {
  // TODO: implement recurring_effects
  //     recurring_effects_.update();
  // TODO: implement chat_balloon
  //     chat_balloon_.update();
  self.invincible.update(timestep=@logic_fps.STEP_TIME_MS)
  self.look.set_animation_speed(speed)
  // TODO: implement iron_body
  //     iron_body_.update();

  let stancespeed_ms = @cmp.maximum(
    (@logic_fps.STEP_TIME_MS.to_double() * speed).to_int(),
    0,
  )
  self.alerted.update(timestep=stancespeed_ms)
}

///|
pub fn Character::get_phobj(self : Character) -> PhysicsObject {
  self.base.phobj
}

///|
pub fn Character::set_facing_right(self : Character, f : Bool) -> Unit {
  self.facing_right = f
  self.look.set_facing_right(f)
}

///|
pub fn Character::set_state(self : Character, st : CharState) -> Unit {
  self.state = st
  self.look.set_stance(
    StanceId::by_state(st.stance_value(facing_right=self.facing_right)),
  )
}

///|
pub fn Character::is_facing_right(self : Character) -> Bool {
  self.facing_right
}

///|
/// Get a speed modifier for the current stance.
pub fn Character::get_stancespeed(
  self : Character,
  base_attack_speed : Int,
) -> Double {
  if self.attacking {
    return get_real_attackspeed(base_attack_speed)
  }
  match self.state {
    CharState::WALK => self.base.phobj.moving_object.hspeed.abs()
    CharState::LADDER => self.base.phobj.moving_object.vspeed.abs()
    CharState::ROPE => self.base.phobj.moving_object.vspeed.abs()
    _ => 1.0
  }
}

///|
/// Return the attack speed as a multiplier
pub fn get_real_attackspeed(base_attack_speed : Int) -> Double {
  return 1.7 - base_attack_speed.to_double() / 10.0
}

///|
pub fn Character::get_name(self : Character) -> String {
  self.name
}

///|
pub fn Character::get_weapontype(self : Character) -> @weapon.Type {
  self.look
  .get_equips()
  .get_weapon()
  .map_or(@weapon.Type::NONE, fn(data) { data.get_type() })
}

///|
pub fn get_weapon_type_in_look(look : @char_look.CharLook) -> @weapon.Type {
  look
  .get_equips()
  .get_weapon()
  .map_or(@weapon.Type::NONE, fn(data) { data.get_type() })
}

///|
/// Returns true if the character is invincible.
pub fn Character::is_invincible(self : Character) -> Bool {
  self.invincible.get()
}

///|
/// Get the entity associated with this character.
pub fn Character::get_entity(self : Character) -> @entity.Entity {
  self.entity
}

///|
pub fn Character::is_sitting(self : Character) -> Bool {
  self.state == CharState::SIT
}

///|
pub fn Character::get_oid(self : Character) -> Int {
  self.base.get_oid()
}

///|
pub fn Character::get_attackdelay(self : Character, no : Int) -> Int {
  let first_frame = @char_look.get_after_image(self.entity).map_or(0, fn(
    image,
  ) {
    image.get_first_frame()
  })
  let delay = self.look.get_attackdelay(no, first_frame)
  let fspeed = get_real_attackspeed(
    get_integer_attackspeed(self.look, self.stats),
  )
  (delay.to_double() / fspeed).to_int()
}

///|
pub fn Character::is_two_handed(self : Character) -> Bool {
  self.look.get_equips().is_two_handed()
}

///|
pub fn Character::regular_attack(self : Character, degenerate : Bool) -> Unit {
  self.look.attack(degenerate)
  self.attacking = true
  self.set_alerted(5000)
}

///|
pub fn Character::show_effect_id(
  _self : Character,
  _toshow : CharEffectId,
) -> Unit {
  // TODO: Implement
}

///|
pub fn Character::show_damage(self : Character, damage : Int) -> Unit {
  let start_y = self.base.phobj.get_y() - 60
  let x = self.base.phobj.get_x() - 10
  @ui.show_number(@ui.NumberType::HURT, damage, start_y, x~)
  self.set_alerted(5000)
  self.invincible.set_for(2000)
}

///|
pub fn Character::show_heal_number(self : Character, n : Int) -> Unit {
  let start_y = self.base.phobj.get_y() - 60
  let x = self.base.phobj.get_x() - 10
  @ui.show_number(@ui.NumberType::HEAL_HP, n, start_y, x~)
}

///|
pub fn Character::show_attack_effect(
  self : Character,
  toshow : @graphics.EffectAnimation,
  z : Int,
) -> Unit {
  let attackspeed = get_real_attackspeed(
    get_integer_attackspeed(self.look, self.stats),
  )
  @graphics.add_effect_animation(
    self.entity,
    toshow,
    z=@graphics.EFFECT_ZINDEX + z,
    speed=attackspeed,
    flip=self.facing_right,
  )
}

///|
pub fn Character::show_iron_body(_self : Character) -> Unit {
  // TODO: Implement
  // self.iron_body.set_for(500) 
}

///|
pub fn Character::attack_by_action(self : Character, action : String) -> Unit {
  self.look.set_action(action)
  self.attacking = true
  self.set_alerted(5000)
}

///|
pub fn Character::attack_by_stance(self : Character, stance : StanceId) -> Unit {
  self.look.attack_by_stance(stance)
  self.attacking = true
  self.set_alerted(5000)
}

///|
pub fn Character::get_look(self : Character) -> @char_look.CharLook {
  self.look
}

///|
pub fn Character::is_animation_finished(self : Character) -> Bool {
  self.look.is_animation_finished()
}

///|
pub fn Character::get_stats(self : Character) -> @char_stats.CharStats {
  self.stats
}

///|
pub(all) struct CharEntry {
  stats : StatsEntry
  look : @char_look.LookEntry
  id : Int
} derive(Debug, ToJson)

///|
/// Whether the character is alerted. When alerted, some operations are forbidden, like changing equips.
pub fn Character::is_alerted(self : Character) -> Bool {
  self.alerted.get()
}

///|
/// Set the character to be alerted for a certain amount of time.
pub fn Character::set_alerted(self : Character, millis : Int) -> Unit {
  self.alerted.set_for(millis)
}

///|
pub fn get_integer_attackspeed(
  look : @char_look.CharLook,
  stats : @char_stats.CharStats,
) -> Int {
  guard look.get_equips().get_weapon() is Some(weapon) else { return 0 }
  let base_speed = stats.get_attackspeed()
  let weapon_speed = weapon.get_speed()
  base_speed + weapon_speed
}
