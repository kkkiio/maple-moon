///|
typealias MapObjectBase = @map_object.MapObjectBase

///|
typealias PhysicsObject = @physics.PhysicsObject

///| Player states which determine animation and state
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
} derive(Eq, Compare)

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

///| Values are used in movement packets (Add one if facing left)
pub fn stance_value(self : CharState, facing_right~ : Bool) -> Int {
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

// Base for characters, e.g. the player and other clients on the same map.
///|
pub(all) struct CharBase {
  base : MapObjectBase
  mut look : @char_look.CharLook
  stats : @char_stats.CharStats
  // look_preview: CharLook
  // pets: Array[PetLook, 3]
  mut state : CharState
  mut attacking : Bool
  mut facing_right : Bool
  name : String
  name_label : @graphics.Text
  // chat_balloon: ChatBalloon
  effects : @graphics.EffectLayer
  // recurring_effects: RecurringEffect
  mut after_image : @utils.Future[@char_look.AfterImage] // TODO: load more early?
  invincible : @utils.TimedBool
  // iron_body: TimedBool
  damage_number_set : @ui.NumberSet
  damage_numbers : Array[@ui.Number]
  // Character trait methods converted to function fields
  get_skilllevel : (Int) -> Int
  get_integer_attackspeed : () -> Int // Return the character's base attacking speed.
}

///| Type alias for backward compatibility
pub(all) typealias Character = CharBase

///|
pub fn get_position(self : CharBase) -> @struct.Point[Int] {
  self.base.get_position()
}

///|
pub fn set_position(self : CharBase, pos : @struct.Point[Int]) -> Unit {
  self.base.set_position(pos)
}

///|
pub fn CharBase::new(
  oid : Int,
  look : @char_look.CharLook,
  name : String,
  damage_number_set : @ui.NumberSet,
  get_skilllevel~ : (Int) -> Int,
  stats : @char_stats.CharStats,
  get_integer_attackspeed~ : () -> Int
) -> CharBase {
  let char_base = {
    base: MapObjectBase::new(oid),
    look,
    stats,
    attacking: false,
    facing_right: false,
    name,
    name_label: @graphics.Text::new(
      text=name,
      @graphics.FontId::A13M,
      @graphics.TextAlignment::CENTER,
      @struct.ColorName::WHITE,
      nametag=true,
    ),
    effects: @graphics.EffectLayer::default(),
    state: CharState::STAND,
    after_image: @utils.Future::never(),
    invincible: @utils.TimedBool::default(),
    damage_number_set,
    damage_numbers: Array::new(),
    get_skilllevel,
    get_integer_attackspeed,
  }
  stats.watch_stat_changes(@maple_stat.Id::LEVEL, fn(old, new) {
    if new > old {
      char_base.show_effect_id(CharEffectId::LEVEL_UP)
    }
    IterContinue
  })
  char_base
}

///|
pub fn is_climbing(self : CharBase) -> Bool {
  match self.state {
    CharState::LADDER | CharState::ROPE => true
    _ => false
  }
}

///|
pub fn get_layer(self : CharBase) -> Int {
  if self.is_climbing() {
    7
  } else {
    self.base.phobj.fhlayer
  }
}

///|
pub fn draw(
  self : CharBase,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  let absp = self.base.phobj.get_absolute(viewx, viewy, alpha)
  self.effects.drawbelow(absp, alpha)

  //     recurring_effects_.drawbelow(absp, alpha);

  let color = if self.invincible.get() {
    let phi = self.invincible.alpha() * 30
    let rgb = 0.9 - 0.5 * @math.sin(phi).abs()
    @struct.Color::new_rgba(rgb, rgb, rgb, 1.0)
  } else {
    @struct.Code::CWHITE.color()
  }
  self.look.draw(
    @graphics.DrawArgument::from_point_and_color(absp, color),
    alpha,
  )

  //     after_image_.draw(self.look.get_frame(),
  //                       DrawArgument(absp, facing_right_),
  //                       alpha);

  //     if (iron_body_) {
  //         float ibalpha = iron_body_.alpha();
  //         float scale = 1.0f + ibalpha;
  //         float opacity = 1.0f - ibalpha;

  //         self.look.draw(DrawArgument(absp, scale, scale, opacity), alpha);
  //     }

  //     for (const auto &pet : pets_) {
  //         if (pet.get_itemid()) {
  //             pet.draw(viewx, viewy, alpha);
  //         }
  //     }

  // If ever changing code for namelabel confirm placements with map 10000
  self.name_label.draw(absp + @struct.Point::new(0, -4))
  // chat_balloon_.draw(absp - Point<int16_t>(0, 85));

  self.effects.drawabove(absp, alpha)
  //     recurring_effects_.drawabove(absp, alpha);

  for number in self.damage_numbers {
    number.draw(viewx, viewy, alpha)
  }
}

///|
pub fn update(self : CharBase, speed : Double) -> Bool {
  @utils.remove_if(self.damage_numbers, fn(number : @ui.Number) {
    number.update()
  })
  self.effects.update()
  //     recurring_effects_.update();
  //     chat_balloon_.update();
  self.invincible.update()
  //     iron_body_.update();

  let stancespeed = if speed >= 1.0 / @constants.step_time_ms.to_double() {
    (@constants.step_time_ms.to_double() * speed).to_int()
  } else {
    0
  }
  match self.after_image.poll() {
    None => ()
    Some(image) => image.update(self.look.get_frame(), stancespeed)
  }
  self.look.update(stancespeed)
}

///|
pub fn get_phobj(self : CharBase) -> PhysicsObject {
  self.base.phobj
}

///|
pub fn set_direction(self : CharBase, f : Bool) -> Unit {
  self.facing_right = f
  self.look.set_direction(f)
}

///|
pub fn set_state(self : CharBase, st : CharState) -> Unit {
  self.state = st
  self.look.set_stance(
    @types.StanceId::by_state(st.stance_value(facing_right=self.facing_right)),
  )
}

///|
pub fn is_facing_right(self : CharBase) -> Bool {
  self.facing_right
}

///| Get a speed modifier for the current stance.
pub fn get_stancespeed(self : CharBase, base_attack_speed : Int) -> Double {
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

///| Return the attack speed as a multiplier
pub fn get_real_attackspeed(base_attack_speed : Int) -> Double {
  return 1.7 - base_attack_speed.to_double() / 10.0
}

///|
pub fn get_name(self : CharBase) -> String {
  self.name
}

///|
pub fn get_weapontype(self : CharBase) -> @weapon.Type {
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
pub fn is_invincible(self : CharBase) -> Bool {
  self.invincible.get()
}

///|
pub fn set_afterimage(self : CharBase, skill_id : Int) -> Unit {
  guard self.look.get_equips().get_weapon() is Some(weapon) else { return }
  let stance_name = self.look.get_stance().name()
  let weapon_level = weapon.get_equipdata().get_reqstat(@maple_stat.Id::LEVEL)
  let ai_name = weapon.get_afterimage()
  self.after_image = @char_look.AfterImage::load(
    skill_id, ai_name, stance_name, weapon_level,
  )
}

///|
pub fn is_sitting(self : CharBase) -> Bool {
  self.state == CharState::SIT
}

///|
pub fn get_oid(self : CharBase) -> Int {
  self.base.get_oid()
}

///|
pub fn get_attackdelay(self : CharBase, no : Int) -> Int {
  let first_frame = self.after_image
    .poll()
    .map_or(0, fn(image) { image.get_first_frame() }) // WARN: may produce incorrect delay
  let delay = self.look.get_attackdelay(no, first_frame)
  let fspeed = get_real_attackspeed((self.get_integer_attackspeed)())
  (delay.to_double() / fspeed).to_int()
}

///|
pub fn is_twohanded(self : CharBase) -> Bool {
  self.look.get_equips().is_twohanded()
}

///|
pub fn regular_attack(self : CharBase, degenerate : Bool) -> Unit {
  self.look.attack(degenerate)
  self.attacking = true
  self.look.set_alerted(5000)
}

///|
pub fn show_effect_id(self : CharBase, toshow : CharEffectId) -> Unit {
  // TODO: Implement
}

///|
pub fn show_damage(self : CharBase, damage : Int) -> Unit {
  let start_y = self.base.phobj.get_y() - 60
  let x = self.base.phobj.get_x() - 10
  self.damage_numbers.push(
    self.damage_number_set.new_number(@ui.NumberType::HURT, damage, start_y, x~),
  )
  self.look.set_alerted(5000)
  self.invincible.set_for(2000)
}

///|
pub fn show_heal_number(self : CharBase, n : Int) -> Unit {
  let start_y = self.base.phobj.get_y() - 60
  let x = self.base.phobj.get_x() - 10
  self.damage_numbers.push(
    self.damage_number_set.new_number(@ui.NumberType::HEAL_HP, n, start_y, x~),
  )
}

///|
pub fn show_attack_effect(
  self : CharBase,
  toshow : @graphics.Animation,
  z : Int
) -> Unit {
  let attackspeed = get_real_attackspeed((self.get_integer_attackspeed)())
  self.effects.add(
    toshow,
    args=@graphics.DrawArgument::new(flip=self.facing_right),
    z~,
    speed=attackspeed,
  )
}

///|
pub fn show_iron_body(self : CharBase) -> Unit {
  // self.iron_body.set_for(500) // TODO: Implement
}

///|
pub fn attack_by_action(self : CharBase, action : String) -> Unit {
  self.look.set_action(action)
  self.attacking = true
  self.look.set_alerted(5000)
}

///|
pub fn attack_by_stance(self : CharBase, stance : @types.StanceId) -> Unit {
  self.look.attack_by_stance(stance)
  self.attacking = true
  self.look.set_alerted(5000)
}

///|
pub fn get_look(self : CharBase) -> @char_look.CharLook {
  self.look
}

///|
pub fn get_afterimage(self : CharBase) -> @char_look.AfterImage {
  self.after_image.poll().or_default()
}

///|
pub fn get_stats(self : CharBase) -> @char_stats.CharStats {
  self.stats
}

///|
pub(all) struct CharEntry {
  stats : @char_stats.StatsEntry
  look : @char_look.LookEntry
  id : Int
} derive(Show, ToJson)
