///|
pub(all) enum StanceType {
  MOVE
  STAND
  JUMP
  HIT
  DIE
  SKILL
} derive(Eq, Hash)

///|
pub(all) struct Stance {
  t : StanceType
  face_right : Bool
} derive(Eq)

///|
pub fn Stance::from_byte(b : Int) -> Stance {
  let face_right = b % 2 == 0
  let t = match b / 2 {
    1 => StanceType::MOVE
    2 => StanceType::JUMP
    3 => StanceType::HIT
    4 => StanceType::DIE
    _ => StanceType::MOVE
  }
  { t, face_right }
}

///|
pub fn int_value(self : Stance) -> Int {
  (match self.t {
    StanceType::MOVE => 1
    StanceType::STAND => 2
    StanceType::JUMP => 3
    StanceType::HIT => 4
    StanceType::DIE => 5
    StanceType::SKILL => 6
  }) *
  2 +
  (if self.face_right { 0 } else { 1 })
}

///|
pub fn Stance::from_type(t : StanceType) -> Stance {
  { t, face_right: true }
}

///|
pub fn flip(self : Stance) -> Stance {
  { t: self.t, face_right: not(self.face_right) }
}

///|
struct Mob {
  base : @map_object.MapObjectBase
  animations : Map[StanceType, @graphics.Animation]
  skill_cache : Map[Int, @utils.Future[Result[MobSkill, Error]]]
  attacks : Map[Int, MobSpecialAttack]
  skill_stands : Map[Int, @graphics.Animation]
  attack_stands : Map[Int, @graphics.Animation]
  buffs : Array[MobBuff]
  level : Int
  speed : Double
  fly_speed : Double
  watk : Int
  wdef : Int
  mdef : Int
  avoid : Int
  knockback : Int
  touch_damage : Bool
  no_flip : Bool
  can_move : Bool
  can_jump : Bool
  can_fly : Bool
  is_boss : Bool
  effects : @graphics.EffectLayer
  name_label : @graphics.Text
  hp_bar : @ui.MobHpBar
  randomizer : @utils.Randomizer
  show_hp : @utils.TimedBool
  mut movements : Array[@physics.Movement]
  mut counter : Int
  id : Int
  mut dying : Bool
  mut dead : Bool
  mut control : Bool
  mut aggro : Bool
  mut stance : Stance
  mut fly_direction : FlyDirection
  mut hp_percent : Int
  mut fading : Bool
  mut fade_in : Bool
  opacity : @utils.Linear
  src : @resource.NxNode
}

///|
enum FlyDirection {
  STRAIGHT
  UPWARDS
  DOWNWARDS
}

///|
pub fn Mob::load(
  oi : Int,
  mid : Int,
  mode : Int,
  st : Int,
  fh : Int,
  newspawn : Bool,
  _team : Int,
  position : @struct.Point[Int],
  randomizer : @utils.Randomizer
) -> @utils.Future[Result[Mob, Error]] {
  let strid = @string_format.extend_id(mid, 7)
  mob_loader
  .load_res([strid + ".img"])
  .map_exn(fn(src) {
    Mob::new!(oi, mid, mode, st, fh, newspawn, _team, position, randomizer, src)
  })
}

///|
fn Mob::new(
  oi : Int,
  mid : Int,
  mode : Int,
  st : Int,
  fh : Int,
  newspawn : Bool,
  _team : Int,
  position : @struct.Point[Int],
  randomizer : @utils.Randomizer,
  src : @resource.NxNode
) -> Mob! {
  let base = @map_object.MapObjectBase::new(oi)
  let info = src["info"]
  let level = info["level"].get_int!()
  let watk = info["PADamage"].get_int!()
  // let matk = info["MADamage"].get_int!()
  let wdef = info["PDDamage"].get_int!()
  let mdef = info["MDDamage"].get_int!()
  // let accuracy = info["acc"].get_int!()
  let avoid = info["eva"].get_int!()
  let knockback = info["pushed"].get_int!()
  let mut speed = info["speed"].get_float!()
  let mut fly_speed = info["flySpeed"].get_float!()
  let touch_damage = info["bodyAttack"].get_bool!()
  // let undead = info["undead"].get_bool!()
  let is_boss = info["boss"].get_bool!()
  let no_flip = info["noFlip"].get_bool!()
  // let not_attack = info["notAttack"].get_bool!()
  let can_jump = src["jump"].get_children_count() > 0
  let can_fly = src["fly"].get_children_count() > 0
  let can_move = src["move"].get_children_count() > 0 || can_fly
  let animations : Map[StanceType, @graphics.Animation] = Map::new()
  if can_fly {
    animations[StanceType::STAND] = src["fly"]
      |> @graphics.Animation::from_resource
    animations[StanceType::MOVE] = src["fly"]
      |> @graphics.Animation::from_resource
  } else {
    animations[StanceType::STAND] = src["stand"]
      |> @graphics.Animation::from_resource
    animations[StanceType::MOVE] = src["move"]
      |> @graphics.Animation::from_resource
  }
  animations[StanceType::JUMP] = src["jump"]
    |> @graphics.Animation::from_resource
  animations[StanceType::HIT] = src["hit1"]
    |> @graphics.Animation::from_resource
  animations[StanceType::DIE] = src["die1"]
    |> @graphics.Animation::from_resource
  let name = @resource.string_loader()
    .load_res(["Mob.img", mid.to_string(), "name"])
    .get_string()

  //TODO: sound

  let skillnode = info["skill"]
  let skill_stands = {}
  for i in 0..<skillnode.get_children_count() {
    let skill_id = skillnode[i.to_string()]["skill"].get_int!()
    let action = skillnode[i.to_string()]["action"].get_int!()
    skill_stands.set(
      skill_id,
      src["skill" + action.to_string()] |> @graphics.Animation::from_resource,
    )
  }
  let attack_stands = (1)
    .until(@int.max_value)
    .map_while(fn(i) {
      let attack_node = src["attack" + i.to_string()]
      if attack_node.get_children_count() > 0 {
        Some((i, attack_node |> @graphics.Animation::from_resource))
      } else {
        None
      }
    })
    |> Map::from_iter

  // init or risk crash
  match animations[StanceType::STAND] {
    Some(stand) => animations[StanceType::SKILL] = stand
    None => ()
  }
  speed += 100
  speed *= 0.001
  fly_speed += 100
  fly_speed *= 0.0005
  if can_fly {
    base.phobj.t = @physics.PhysicsObjectType::FLYING
  }
  let id = mid
  base.set_position(position)
  let control = mode > 0
  let aggro = mode == 2
  base.phobj.fhid = fh
  base.phobj.set_flag(@physics.PhysicsObjectFlag::TURN_AT_EDGES)
  let hp_percent = 0
  let dying = false
  let dead = false
  let stance = Stance::from_byte(st)
  match animations[stance.t] {
    Some(anim) => anim.reset()
    None => ()
  }
  let fly_direction = STRAIGHT
  let counter = 0
  let name_label = @graphics.Text::new(
    text=name,
    @graphics.FontId::A13M,
    @graphics.TextAlignment::CENTER,
    @struct.ColorName::WHITE,
    nametag=true,
  )
  {
    base,
    animations,
    skill_cache: Map::new(),
    attacks: Map::new(),
    skill_stands,
    attack_stands,
    buffs: [],
    level,
    speed,
    fly_speed,
    watk,
    wdef,
    mdef,
    avoid,
    knockback,
    touch_damage,
    no_flip,
    can_move,
    can_jump,
    can_fly,
    is_boss,
    effects: @graphics.EffectLayer::default(),
    name_label,
    hp_bar: @ui.MobHpBar::default(),
    randomizer,
    show_hp: @utils.TimedBool::default(),
    movements: [],
    counter,
    id,
    dying,
    dead,
    control,
    aggro,
    stance,
    fly_direction,
    hp_percent,
    fading: false,
    fade_in: newspawn,
    opacity: @utils.Linear::new(if newspawn { 0.0 } else { 1.0 }),
    src,
  }
}

///|
pub fn get_oid(self : Mob) -> Int {
  self.base.get_oid()
}

///|
pub fn Mob::draw(
  self : Mob,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  let absp = self.base.phobj.get_absolute(viewx, viewy, alpha)
  let headpos = self.get_head_position(position=absp)
  self.effects.drawbelow(absp, alpha)
  if not(self.dead) {
    match self.animations[self.stance.t] {
      Some(anim) =>
        anim.draw(
          @graphics.DrawArgument::new14(
            absp,
            self.stance.face_right && not(self.no_flip),
            opacity=self.opacity.get(alpha~),
          ),
          alpha,
        )
      None => ()
    }
    if self.show_hp.get() {
      self.name_label.draw(absp)
      if not(self.dying) && self.hp_percent > 0 {
        self.hp_bar.draw(headpos, self.hp_percent)
      }
    }
  }
  self.effects.drawabove(absp, alpha)
}

///|
pub fn Mob::update(self : Mob, physics : @physics.Physics) -> Int {
  if not(self.base.is_active()) {
    return self.base.phobj.fhlayer
  }
  let aniend = match self.animations[self.stance.t] {
    Some(anim) => anim.update()
    None => false
  }
  if aniend && self.stance.t == StanceType::SKILL {
    self.set_stance(Stance::from_type(StanceType::STAND))
  }
  if aniend && self.stance.t == StanceType::DIE {
    self.dead = true
  }
  if self.fading {
    self.opacity.add(-0.025)
    if self.opacity.last() < 0.025 {
      self.opacity.set(0.0)
      self.fading = false
      self.dead = true
    }
  } else if self.fade_in {
    self.opacity.add(0.025)
    if self.opacity.last() > 0.975 {
      self.opacity.set(1.0)
      self.fade_in = false
    }
  }
  if self.dead {
    self.base.deactivate()
    return -1
  }
  self.effects.update()
  self.show_hp.update()

  // TODO: add buffs animation?
  if not(self.dying) {
    if not(self.can_fly) {
      if self.base.phobj.is_flag_not_set(
          @physics.PhysicsObjectFlag::TURN_AT_EDGES,
        ) {
        self.stance = self.stance.flip()
        self.base.phobj.set_flag(@physics.PhysicsObjectFlag::TURN_AT_EDGES)
        if self.stance.t == StanceType::HIT {
          self.set_stance(Stance::from_type(StanceType::STAND))
        }
      }
    }
    match self.stance.t {
      StanceType::MOVE =>
        if self.can_fly {
          self.base.phobj.hforce = if self.stance.face_right {
            self.fly_speed
          } else {
            -self.fly_speed
          }
          match self.fly_direction {
            FlyDirection::UPWARDS => self.base.phobj.vforce = -self.fly_speed
            FlyDirection::DOWNWARDS => self.base.phobj.vforce = self.fly_speed
            _ => ()
          }
        } else {
          self.base.phobj.hforce = if self.stance.face_right {
            self.speed
          } else {
            -self.speed
          }
        }
      StanceType::HIT =>
        if self.can_move {
          let kbforce = if self.base.phobj.onground { 0.2 } else { 0.1 }
          self.base.phobj.hforce = if self.stance.face_right { // backwards
            -kbforce
          } else {
            kbforce
          }
        }
      StanceType::JUMP => self.base.phobj.vforce = -5.0
      _ => ()
    }
    physics.move_object(self.base.phobj)
    if self.control {
      self.counter += 1
      let next = match self.stance.t {
        StanceType::HIT => self.counter > 200
        StanceType::JUMP => self.base.phobj.onground
        _ => aniend && self.counter > 200
      }
      if next {
        self.next_move()
        self.update_movement()
        self.counter = 0
      }
    }
  } else {
    self.base.phobj.moving_object.normalize()
    physics.get_fht().update_fh(self.base.phobj)
  }
  return self.base.phobj.fhlayer
}

///|
fn next_move(self : Mob) -> Unit {
  if self.can_move {
    match self.stance.t {
      StanceType::HIT | StanceType::STAND =>
        self.set_stance({
          t: StanceType::MOVE,
          face_right: self.randomizer.next_bool(),
        })
      StanceType::MOVE | StanceType::JUMP =>
        if self.can_jump &&
          self.base.phobj.onground &&
          self.randomizer.below(0.25) {
          self.set_stance(Stance::from_type(StanceType::JUMP))
        } else {
          match self.randomizer.next_int(3) {
            0 => self.set_stance(Stance::from_type(StanceType::STAND))
            1 => self.set_stance({ t: StanceType::MOVE, face_right: false })
            _ => self.set_stance({ t: StanceType::MOVE, face_right: true })
          }
        }
      _ => ()
    }
    if self.stance.t == StanceType::MOVE && self.can_fly {
      self.fly_direction = self.randomizer.choose([
        FlyDirection::STRAIGHT,
        FlyDirection::UPWARDS,
        FlyDirection::DOWNWARDS,
      ])
    }
  } else {
    self.set_stance(Stance::from_type(StanceType::STAND))
  }
}

///|
pub fn set_stance(self : Mob, newstance : Stance) -> Unit {
  if self.stance != newstance {
    self.stance = newstance
    match self.animations[self.stance.t] {
      Some(anim) => anim.reset()
      None => ()
    }
  }
}

///|
pub fn makeactive(self : Mob) -> Unit {
  self.base.makeactive()
}

///|
pub fn is_active(self : Mob) -> Bool {
  self.base.is_active()
}

///|
pub fn get_layer(self : Mob) -> Int {
  self.base.get_layer()
}

///| Change this mob's control mode:
/// 0 - no control, 1 - control, 2 - aggro
pub fn Mob::set_control(self : Mob, mode : Int) -> Unit {
  self.control = mode > 0
  self.aggro = mode == 2
}

///|
pub fn is_alive(self : Mob) -> Bool {
  self.base.is_active() && not(self.dying)
}

///|
pub fn is_in_range(self : Mob, range : @struct.Rectangle[Int]) -> Bool {
  if range.get_horizontal().delta().is_neg() ||
    range.get_vertical().delta().is_neg() {
    @log.error({ "range": range }, "invalid range")
    panic()
  }
  if not(self.base.is_active()) {
    return false
  }
  match self.animations[self.stance.t] {
    Some(anim) => {
      let bounds = anim.get_bounds()
      range.overlaps(bounds.shift(self.base.get_position()))
    }
    None => false
  }
}

///|
pub fn Mob::get_live_range(self : Mob) -> @struct.Rectangle[Int]? {
  if not(self.base.is_active()) {
    return None
  }
  match self.animations[self.stance.t] {
    Some(anim) => {
      let bounds = anim.get_bounds()
      Some(bounds.shift(self.base.get_position()))
    }
    None => None
  }
}

///|
pub fn create_touch_attack(self : Mob) -> @combat.MobAttack {
  if not(self.touch_damage) {
    return @combat.MobAttack::default()
  }
  let minattack = (self.watk.to_double() * 0.8).to_int()
  let maxattack = self.watk
  let attack = self.randomizer.next_int(from=minattack, maxattack)
  return @combat.MobAttack::new(
    attack,
    self.base.get_position(),
    self.id,
    self.base.get_oid(),
  )
}

///|
pub fn update_movement(self : Mob) -> Unit {
  new_move_mob_packet(
    self.base.get_oid(),
    1,
    0,
    0,
    0,
    0,
    0,
    self.base.get_position(),
    @physics.Movement::from_physics_object(
      self.base.phobj,
      self.stance.int_value(),
    ),
  ).dispatch()
}

///|
pub fn update_movement_ex(
  self : Mob,
  t : Int,
  nibbles : Int,
  action : Int,
  skill : Int,
  skill_level : Int,
  option : Int
) -> Unit {
  new_move_mob_packet(
    self.base.get_oid(),
    t,
    nibbles,
    action,
    skill,
    skill_level,
    option,
    self.base.get_position(),
    @physics.Movement::from_physics_object(
      self.base.phobj,
      self.stance.int_value(),
    ),
  ).dispatch()
}

///|
pub fn give_buff(self : Mob, buff : MobBuff) -> Unit {
  self.buffs.push(buff)
}

///|
pub fn use_skill(self : Mob, skill : MobSkill) -> Unit {
  match self.skill_stands.get(skill.get_id()) {
    Some(anim) => self.animations[StanceType::SKILL] = anim
    None => self.animations.remove(StanceType::SKILL)
  }
  self.set_stance(Stance::from_type(StanceType::SKILL))
  if skill.is_buff() && self.buffs.is_empty() {
    self.buffs.push(skill.get_buff())
  }
}

///|
pub fn use_attack(self : Mob, attack : MobSpecialAttack) -> Unit {
  match self.attack_stands.get(attack.get_id()) {
    Some(anim) => self.animations[StanceType::SKILL] = anim
    None => self.animations.remove(StanceType::SKILL)
  }
  self.set_stance(Stance::from_type(StanceType::SKILL))
}

///|
pub fn get_head_position(
  self : Mob,
  position~ : @struct.Point[Int] = self.get_position()
) -> @struct.Point[Int] {
  let head = match self.animations[self.stance.t] {
    Some(anim) => anim.get_head()
    None => @struct.Point::default()
  }
  position
  .shift_x(
    if self.stance.face_right && not(self.no_flip) {
      -head.x
    } else {
      head.x
    },
  )
  .shift_y(head.y)
}

///|
pub fn Mob::send_movement(
  self : Mob,
  start : @struct.Point[Int],
  movements : Array[@physics.Movement]
) -> Unit {
  if self.control {
    return
  }
  self.base.set_position(start)
  self.movements = movements
  if self.movements.is_empty() {
    return
  }
  let lastmove = self.movements[0]
  let laststance = lastmove.newstate
  self.set_stance(laststance |> Stance::from_byte)
  self.base.phobj.fhid = lastmove.fh
}

///|
pub fn get_move_skill(
  self : Mob,
  move_id : Int,
  level : Int
) -> @utils.Future[Result[MobSkill, Error]] {
  self.skill_cache.get_or_init(move_id, fn() { MobSkill::load(move_id, level) })
}

///|
pub fn get_move_attack(self : Mob, move_id : Int) -> MobSpecialAttack! {
  match self.attacks.get(move_id) {
    Some(attack) => attack
    None => {
      let new_attack = MobSpecialAttack::new!(self.src, self.id, move_id)
      self.attacks.set(move_id, new_attack)
      new_attack
    }
  }
}

///|
pub fn get_position(self : Mob) -> @struct.Point[Int] {
  self.base.get_position()
}

///|
struct MobSpecialAttack {
  use_effect : &MobSkillUseEffect
  // hit_effect : MobSkillHitEffect
  move_id : Int
}

///|
pub fn MobSpecialAttack::get_id(self : MobSpecialAttack) -> Int {
  self.move_id
}

///|
pub fn MobSpecialAttack::new(
  mob_src : @resource.NxNode,
  _mob_id : Int,
  move_id : Int
) -> MobSpecialAttack! {
  // let mut strid = ""
  // if mob_id < 10000000 {
  //   strid = @string_format.extend_id(mob_id, 7)
  // } else {
  //   strid = mob_id.to_string()
  // }
  let src = mob_src["attack" + move_id.to_string()]["info"]

  // sound_ = SingleSkillSound::new(strid)

  let has_multi_effect = src["effect0"].get_children_count() > 0
  let has_area_warning_effect = src["areaWarning"].get_children_count() > 0
  let use_effect = if has_multi_effect || has_area_warning_effect {
    MobMultiUseEffect::new!(src, has_area_warning_effect) as &MobSkillUseEffect
  } else {
    MobSingleUseEffect::new!(src) as &MobSkillUseEffect
  }
  { move_id, use_effect }

  // hit_effect_ = std::make_unique<MobSingleHitEffect>(src["level"][4]);

  // hit_effect_ =
  // std::make_unique<MobSingleHitEffect>(src["attack1"]["info"]); hit_effect_
  // = std::make_unique<NoHitEffect>();

  // action_ = std::make_unique<NoAction>();
}

///|
pub fn show_effect(
  self : Mob,
  animation : @graphics.Animation,
  pos : Int,
  z : Int,
  f : Bool
) -> Unit {
  if not(self.base.is_active()) {
    return
  }
  let shift = match pos {
    0 => self.get_head_position(position=@struct.Point::default())
    _ => @struct.Point::default()
  }
  let args = @graphics.DrawArgument::new14(shift, f)
  self.effects.add(animation, args~, z~)
}

///|
pub fn kill(self : Mob, animation : Int) -> Unit {
  match animation {
    0 => self.base.deactivate()
    1 => {
      self.dying = true
      self.apply_death()
    }
    2 => {
      self.fading = true
      self.dying = true
    }
    _ => ()
  }
}

///|
fn apply_death(self : Mob) -> Unit {
  self.set_stance(Stance::from_type(StanceType::DIE))
  // die_sound_.play();
  self.dying = true
}

///|
pub fn apply_useeffects(self : MobSpecialAttack, mob : Mob) -> Unit {
  self.use_effect.apply(mob)
  // sound_->play_use();
}

///|
pub fn calculate_damage(
  self : Mob,
  attack : @combat.Attack
) -> Array[(Int, Bool)] {
  let leveldelta = @math.maximum(self.level - attack.playerlevel, 0)
  let damagetype = attack.damagetype
  let (mindamage, maxdamage, hitchance, critical) = match damagetype {
    @combat.AttackDamageType::DMG_WEAPON(min~, max~) => {
      let mindamage = self.calculate_mindamage(leveldelta, min, false)
      let maxdamage = self.calculate_maxdamage(leveldelta, max, false)
      let hitchance = self.calculate_hitchance(leveldelta, attack.accuracy)
      let critical = attack.critical
      (mindamage, maxdamage, hitchance, critical)
    }
    @combat.AttackDamageType::DMG_MAGIC(matk) => {
      let mindamage = self.calculate_mindamage(
        leveldelta,
        matk.to_double(),
        true,
      )
      let maxdamage = self.calculate_maxdamage(
        leveldelta,
        matk.to_double(),
        true,
      )
      let hitchance = self.calculate_hitchance(leveldelta, attack.accuracy)
      let critical = attack.critical
      (mindamage, maxdamage, hitchance, critical)
    }
    @combat.AttackDamageType::DMG_FIXED(fixdamage) => {
      let mindamage = fixdamage.to_double()
      let maxdamage = fixdamage.to_double()
      let hitchance = 1.0
      let critical = 0.0
      (mindamage, maxdamage, hitchance, critical)
    }
  }
  let result = Array::makei(attack.hitcount, fn(_i) {
    self.next_damage(mindamage, maxdamage, hitchance, critical)
  })
  self.update_movement()
  result
}

///|
fn next_damage(
  self : Mob,
  mindamage : Double,
  maxdamage : Double,
  hitchance : Double,
  critical : Double
) -> (Int, Bool) {
  let hit = self.randomizer.below(hitchance)
  if not(hit) {
    return (0, false)
  }
  let damagecap = 999999
  let iscritical = self.randomizer.below(critical)
  let mut damage = self.randomizer.next_real(from=mindamage, maxdamage)
  if iscritical {
    damage *= 1.5
  }
  let intdamage = damage.to_int()
    |> @math.maximum(1)
    |> @math.minimum(damagecap)
  return (intdamage, iscritical)
}

///|
fn calculate_mindamage(
  self : Mob,
  leveldelta : Int,
  damage : Double,
  magic : Bool
) -> Double {
  let mindamage = if magic {
    damage - (1.0 + 0.01 * leveldelta.to_double()) * self.mdef.to_double() * 0.6
  } else {
    damage * (1.0 - 0.01 * leveldelta.to_double()) - self.wdef.to_double() * 0.6
  }
  return @math.maximum(mindamage, 1.0)
}

///|
fn calculate_maxdamage(
  self : Mob,
  leveldelta : Int,
  damage : Double,
  magic : Bool
) -> Double {
  let maxdamage = if magic {
    damage - (1.0 + 0.01 * leveldelta.to_double()) * self.mdef.to_double() * 0.5
  } else {
    damage * (1.0 - 0.01 * leveldelta.to_double()) - self.wdef.to_double() * 0.5
  }
  return @math.maximum(maxdamage, 1.0)
}

///|
fn calculate_hitchance(
  self : Mob,
  leveldelta : Int,
  player_accuracy : Int
) -> Double {
  let hitchance = player_accuracy.to_double() /
    (self.avoid.to_double() * (1.84 + 0.07 * leveldelta.to_double()) + 1.0)
  @math.maximum(hitchance, 0.01)
}

///|
pub fn apply_damage(self : Mob, damage : Int, toleft : Bool) -> Unit {
  // self.hit_sound.play()

  if self.dying && self.stance.t != StanceType::DIE {
    self.apply_death()
  } else if self.control &&
    self.is_alive() &&
    damage >= self.knockback &&
    not(self.is_boss) {
    self.counter = 170
    self.set_stance({ t: StanceType::HIT, face_right: toleft })
    self.update_movement()
  }
}

///|
pub fn show_hp(self : Mob, percent : Int, playerlevel : Int) -> Unit {
  if self.hp_percent == 0 {
    let delta = self.level - playerlevel
    if delta >= 10 {
      self.name_label.change_color(@struct.ColorName::RED)
    } else if delta >= 5 {
      self.name_label.change_color(@struct.ColorName::YELLOW)
    } else if delta <= -5 {
      self.name_label.change_color(@struct.ColorName::GREEN)
    }
  }
  let percent = percent |> @math.minimum(100) |> @math.maximum(0)
  self.hp_percent = percent
  self.show_hp.set_for(2000)
}
