typealias MapObjectBase = @map_object.MapObjectBase

typealias PhysicsObject = @physics.PhysicsObject

// Player states which determine animation and state
// Values are used in movement packets (Add one if facing left)
enum CharState {
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

pub fn int_value(self : CharState) -> Int {
  match self {
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
  }
}

pub fn hash(self : CharState) -> Hash {
  self.int_value()
}

// Base for characters, e.g. the player and other clients on the same map.
struct CharBase {
  sub : CharSubClass
  base : MapObjectBase
  look : CharLook
  // look_preview: CharLook
  // pets: Array[PetLook, 3]
  mut state : CharState
  mut attacking : Bool
  mut facing_right : Bool
  // name_label: Text
  // chat_balloon: ChatBalloon
  // effects: EffectLayer
  // recurring_effects: RecurringEffect
  // after_image: Afterimage
  // invincible: TimedBool
  // iron_body: TimedBool
  // mut damage_numbers: @immut/list.List[DamageNumber]
}

pub fn get_position(self : CharBase) -> Point[Int] {
  self.base.get_position()
}

pub fn set_position(self : CharBase, pos : Point[Int]) -> Unit {
  self.base.set_position(pos)
}

trait Character {
  // draw(Self, Double, Double, Double) -> Unit
  // draw_preview(Self, Point[Int], Double) -> Unit
  // update(Self, Physics) -> Int
  // get_layer(Self) -> Int
  // is_invincible(Self) -> Bool
  // get_level(Self) -> Int
  // get_skilllevel(Self, Int) -> Int
  // get_real_attackspeed(Self) -> Double
  // get_attackdelay(Self, Int) -> Int
  // set_direction(Self, Bool) -> Unit
  set_state(Self, CharState) -> Unit
  // attack_by_action(Self, String) -> Unit
  // attack_by_stance(Self, StanceId) -> Unit
  // attack_by_bool(Self, Bool) -> Unit
  // set_afterimage(Self, Int) -> Unit
  // get_afterimage(Self) -> Afterimage
  // show_attack_effect(Self, Animation, Int) -> Unit
  // show_effect_id(Self, CharEffectId) -> Unit
  // add_recurring_effect(Self, Int, Animation, Int) -> Unit
  // remove_recurring_effect(Self) -> Unit
  // show_iron_body(Self) -> Unit
  // show_damage(Self, Int) -> Unit
  // speak(Self, String) -> Unit
  change_look(Self, @MapleStat.Id, Int) -> Unit
  // set_state_by_byte(Self, Int) -> Unit
  // set_expression(Self, Int) -> Unit
  // add_pet(Self, Int, Int, String, Int, Point[Int], Int, Int) -> Unit
  // remove_pet(Self, Int, Bool) -> Unit
  getflip(Self) -> Bool
  // get_name(Self) -> String
  // is_sitting(Self) -> Bool
  // is_climbing(Self) -> Bool
  // is_twohanded(Self) -> Bool
  // get_weapontype(Self) -> WeaponType
  // get_look(Self) -> CharLook
  // get_look_const(Self) -> CharLook
  // init() -> Unit
  // new_char(Int, CharLook, String) -> Char
  // update_with_speed(Self, Physics, Double) -> Bool
  // get_stancespeed(Self) -> Double
}

pub trait CharSubClass {
  // Return the character's base attacking speed.
  get_integer_attackspeed(Self) -> Int
}

pub fn CharBase::new(
  sub : CharSubClass,
  oid : Int,
  look : CharLook,
  _name : String
) -> CharBase {
  {
    sub,
    base: MapObjectBase::new(oid),
    look,
    attacking: false,
    facing_right: false,
    state: CharState::STAND,
  }
}

pub fn is_climbing(self : CharBase) -> Bool {
  match self.state {
    CharState::LADDER | CharState::ROPE => true
    _ => false
  }
}

pub fn get_layer(self : CharBase) -> Int {
  if self.is_climbing() {
    7
  } else {
    self.base.phobj.fhlayer
  }
}

pub fn draw(
  self : CharBase,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  let absp = self.base.phobj.get_absolute(viewx, viewy, alpha)

  //     effects_.drawbelow(absp, alpha);

  //     recurring_effects_.drawbelow(absp, alpha);

  //     Color color;

  //     if (invincible_) {
  //         float phi = invincible_.alpha() * 30;
  //         float rgb = 0.9f - 0.5f * std::abs(std::sin(phi));

  //         color = Color(rgb, rgb, rgb, 1.0f);
  //     } else {
  //         color = Color::Code::CWHITE;
  //     }
  let color = @struct.Code::CWHITE
  self.look.draw(
    DrawArgument::new8(absp, color |> @struct.Color::from_code),
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

  //     // If ever changing code for namelabel confirm placements with map 10000
  //     name_label_.draw(absp + Point<int16_t>(0, -4));
  //     chat_balloon_.draw(absp - Point<int16_t>(0, 85));

  //     effects_.drawabove(absp, alpha);
  //     recurring_effects_.drawabove(absp, alpha);

  //     for (const auto &number : damage_numbers_) {
  //         number.draw(viewx, viewy, alpha);
  //     }
}

pub fn update(self : CharBase, physics : Physics, speed : Double) -> Bool {
  //     damage_numbers_.remove_if(
  //         [](DamageNumber &number) { return number.update(); });

  //     effects_.update();
  //     recurring_effects_.update();
  //     chat_balloon_.update();
  //     invincible_.update();
  //     iron_body_.update();

  //     for (auto &pet : pets_) {
  //         if (pet.get_itemid()) {
  //             switch (state_) {
  //                 case State::LADDER:
  //                 case State::ROPE: pet.set_stance(PetLook::Stance::HANG); break;
  //                 case State::SWIM: pet.set_stance(PetLook::Stance::FLY); break;
  //                 default:
  //                     if (pet.get_stance() == PetLook::Stance::HANG
  //                         || pet.get_stance() == PetLook::Stance::FLY) {
  //                         pet.set_stance(PetLook::Stance::STAND);
  //                     }

  //                     break;
  //             }

  //             pet.update(physics, get_position());
  //         }
  //     }

  let stancespeed = if speed >= 1.0 / @constants.timestep.to_double() {
    (@constants.timestep.to_double() * speed).to_int()
  } else {
    0
  }

  //     after_image_.update(look_.get_frame(), stancespeed);

  self.look.update(stancespeed)
}

pub fn get_phobj(self : CharBase) -> PhysicsObject {
  self.base.phobj
}

pub fn set_direction(self : CharBase, f : Bool) -> Unit {
  self.facing_right = f
  self.look.set_direction(f)
}

pub fn set_state(self : CharBase, st : CharState) -> Unit {
  self.state = st
  self.look.set_stance(@char_look.StanceId::by_state(st.int_value()))
}

pub fn getflip(self : CharBase) -> Bool {
  self.facing_right
}

// Get a speed modifier for the current stance.
pub fn get_stancespeed(self : CharBase) -> Double {
  if self.attacking {
    return self.get_real_attackspeed()
  }
  match self.state {
    CharState::WALK => self.base.phobj.moving_object.hspeed.abs()
    CharState::LADDER => self.base.phobj.moving_object.vspeed.abs()
    CharState::ROPE => self.base.phobj.moving_object.vspeed.abs()
    _ => 1.0
  }
}

// Return the attack speed as a multiplier
pub fn get_real_attackspeed(self : CharBase) -> Double {
  return 1.7 - self.sub.get_integer_attackspeed().to_double() / 10.0
}

fn change_look(self : CharBase, stat : @MapleStat.Id, id : Int) -> Unit {
  match stat {
    @MapleStat.Id::SKIN => self.look.set_body(id)
    @MapleStat.Id::FACE => self.look.set_face(id)
    @MapleStat.Id::HAIR => self.look.set_hair(id)
    @MapleStat.Id::LEVEL => ()
    @MapleStat.Id::JOB => ()
    @MapleStat.Id::STR => ()
    @MapleStat.Id::DEX => ()
    @MapleStat.Id::INT => ()
    @MapleStat.Id::LUK => ()
    @MapleStat.Id::HP => ()
    @MapleStat.Id::MAXHP => ()
    @MapleStat.Id::MP => ()
    @MapleStat.Id::MAXMP => ()
    @MapleStat.Id::AP => ()
    @MapleStat.Id::SP => ()
    @MapleStat.Id::EXP => ()
    @MapleStat.Id::FAME => ()
    @MapleStat.Id::MESO => ()
    @MapleStat.Id::PET => ()
    @MapleStat.Id::GACHAEXP => ()
  }
}

pub fn get_name(self : CharBase) -> String {
  // TODO
  "kkkiio"
}

pub fn get_weapontype(self : CharBase) -> @Weapon.Type! {
  let weapon_id = self.look.get_equips().get_weapon()
  if weapon_id <= 0 {
    return @Weapon.Type::NONE
  }
  return @Weapon.WeaponData::get!(weapon_id).get_type()
}
