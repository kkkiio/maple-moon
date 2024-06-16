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
} derive(Debug, Eq, Compare)

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
  base : MapObjectBase
  look : CharLook
  // look_preview: CharLook
  // pets: Array[PetLook, 3]
  mut state : CharState
  // mut attacking: Bool
  // mut facing_right: Bool
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

trait Char {
  // draw(Self, Double, Double, Double) -> Unit
  // draw_preview(Self, Point[Int], Double) -> Unit
  // update(Self, Physics) -> Int
  // get_layer(Self) -> Int
  // is_invincible(Self) -> Bool
  // get_level(Self) -> Int
  // get_skilllevel(Self, Int) -> Int
  // get_integer_attackspeed(Self) -> Int
  // get_real_attackspeed(Self) -> Double
  // get_attackdelay(Self, Int) -> Int
  // set_direction(Self, Bool) -> Unit
  // set_state(Self, CharState) -> Unit
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
  // change_look(Self, MapleStatId, Int) -> Unit
  // set_state_by_byte(Self, Int) -> Unit
  // set_expression(Self, Int) -> Unit
  // add_pet(Self, Int, Int, String, Int, Point[Int], Int, Int) -> Unit
  // remove_pet(Self, Int, Bool) -> Unit
  // getflip(Self) -> Bool
  // get_name(Self) -> String
  // is_sitting(Self) -> Bool
  // is_climbing(Self) -> Bool
  // is_twohanded(Self) -> Bool
  // get_weapontype(Self) -> WeaponType
  // get_look(Self) -> CharLook
  // get_look_const(Self) -> CharLook
  // get_phobj(Self) -> PhysicsObject
  // init() -> Unit
  // new_char(Int, CharLook, String) -> Char
  // update_with_speed(Self, Physics, Double) -> Bool
  // get_stancespeed(Self) -> Double
}

pub fn CharBase::new(oid : Int, look : CharLook, _name : String) -> CharBase {
  { base: MapObjectBase::new(oid), look, state: CharState::STAND }
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

// void Char::draw(double viewx, double viewy, float alpha) const {
pub fn draw(
  self : CharBase,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  //     Point<int16_t> absp = phobj_.get_absolute(viewx, viewy, alpha);
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
  let color = Code::CWHITE
  self.look.draw(DrawArgument::new8(absp, color |> Color::from_code), alpha)

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
