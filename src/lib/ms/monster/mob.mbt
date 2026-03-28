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
pub(all) struct MobAnimation {
  nx : @resource.NxAnimation
  selene : @ms_animation.Animation
}

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
pub fn Stance::int_value(self : Stance) -> Int {
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
pub fn Stance::flip(self : Stance) -> Stance {
  { t: self.t, face_right: not(self.face_right) }
}

///|

///|
pub struct Mob {
  entity : @entity.Entity
  oid : Int
  phobj : @physics.PhysicsObject
  animations : Map[StanceType, MobAnimation]
  skill_cache : Map[Int, @utils.Future[Result[MobSkill, Error]]]
  attacks : Map[Int, MobSpecialAttack]
  skill_stands : Map[Int, MobAnimation]
  attack_stands : Map[Int, MobAnimation]
  buffs : Array[MobBuff]
  level : Int
  speed : Double
  fly_speed : Double
  watk : Int
  weapon_def : Int
  magic_def : Int
  avoid : Int
  knockback : Int
  touch_damage : Bool
  no_flip : Bool
  can_move : Bool
  can_jump : Bool
  can_fly : Bool
  is_boss : Bool
  // name_label : @graphics.Text
  randomizer : @random.Rand
  mut anim_time : Double
  mut movements : Array[@physics.Movement]
  mut counter : Int
  id : Int
  mut dying : Bool
  mut dead : Bool
  mut control : Bool
  mut aggro : Bool
  mut stance : Stance
  mut last_synced_stance : Stance?
  mut fly_direction : FlyDirection
  mut fading : Bool
  mut fade_in : Bool
  opacity : @utils.Linear
  src : NxMob
}

///|
pub enum FlyDirection {
  STRAIGHT
  UPWARDS
  DOWNWARDS
}

///|
pub async fn Mob::load(
  oi : Int,
  mid : Int,
  mode : Int,
  st : Int,
  fh : Int,
  newspawn : Bool,
  position : @struct.Point[Int],
  randomizer : @random.Rand,
) -> Mob {
  let mob_loader = @resource.require_async_loader("mob")
  let strid = @utils.stoi_left_pad0(mid, 7)
  try {
    let src = mob_loader.load_resource([strid + ".img"])
    let nx_mob : NxMob = src |> @json.from_json
    // let info : MobInfo = src["info"].value() |> @json.from_json
    // let animations = if info.link is Some(link) {
    //   let link_mob = mob_loader.load_res_async([link.to_string() + ".img"])
    //   load_animations(link_mob.value())
    // } else {
    //   load_animations(src.value())
    // }
    Mob::new(
      nx_mob,
      object_id=oi,
      monster_id=mid,
      mode,
      st,
      fh,
      newspawn,
      position,
      randomizer~,
    )
  } catch {
    e => fail("Mob::load failed, mid=\{mid}, e=\{e}")
  }
}

///|
pub struct MobInfo {
  magic_damage : Int
  md_damage : Int
  pa_damage : Int
  pd_damage : Int
  acc : Int
  body_attack : Bool
  eva : Int
  exp : Int
  fs : Double
  fly_speed : Double
  level : Int
  link : Int?
  max_hp : Int
  max_mp : Int
  mob_type : Int
  pushed : Int
  speed : Double
  summon_type : Int
  undead : Bool
  boss : Bool
  no_flip : Bool
} derive(ToJson)

///|
pub impl @json.FromJson for MobInfo with from_json(json, path) {
  let link = if json is { "link": String(link), .. } {
    Some(@strconv.parse_int(link)) catch {
      _ => raise @json.JsonDecodeError((path, "invalid link"))
    }
  } else {
    None
  }
  let fly_speed = if json is { "flySpeed": Number(fly_speed, ..), .. } {
    fly_speed
  } else {
    0.0
  }
  let boss = json is { "boss": Number(1, ..), .. }
  let no_flip = json is { "noFlip": Number(1, ..), .. }
  match json {
    {
      "MADamage": Number(ma_damage, ..),
      "MDDamage": Number(md_damage, ..),
      "PADamage": Number(pa_damage, ..),
      "PDDamage": Number(pd_damage, ..),
      "acc": Number(acc, ..),
      "bodyAttack": Number(body_attack, ..),
      "eva": Number(eva, ..),
      "exp": Number(exp, ..),
      "fs": Number(fs, ..),
      "level": Number(level, ..),
      "maxHP": Number(max_hp, ..),
      "maxMP": Number(max_mp, ..),
      "mobType": Number(mob_type, ..),
      "pushed": Number(pushed, ..),
      "speed": Number(speed, ..),
      "summonType": Number(summon_type, ..),
      "undead": Number(undead, ..),
      ..
    } =>
      {
        magic_damage: ma_damage.to_int(),
        md_damage: md_damage.to_int(),
        pa_damage: pa_damage.to_int(),
        pd_damage: pd_damage.to_int(),
        acc: acc.to_int(),
        body_attack: body_attack == 1,
        eva: eva.to_int(),
        exp: exp.to_int(),
        fs,
        fly_speed,
        level: level.to_int(),
        link,
        max_hp: max_hp.to_int(),
        max_mp: max_mp.to_int(),
        mob_type: mob_type.to_int(),
        pushed: pushed.to_int(),
        speed,
        summon_type: summon_type.to_int(),
        undead: undead == 1,
        boss,
        no_flip,
      }
    _ => raise @json.JsonDecodeError((path, "missing info fields"))
  }
}

///|
pub fn Mob::new(
  nx_mob : NxMob,
  mode : Int,
  st : Int,
  fh : Int,
  newspawn : Bool,
  position : @struct.Point[Int],
  object_id~ : Int,
  monster_id~ : Int,
  randomizer? : @random.Rand = @random.Rand::new(),
) -> Mob {
  let entity = @entity.Entity::new()
  let phobj = @physics.PhysicsObject::new(on_pos_change=fn(pos) {
    @transform2d.set_xy(entity, pos)
  })

  // Use data from nx_mob
  let info = nx_mob.info
  let level = info.level
  let watk = info.pa_damage
  let wdef = info.pd_damage
  let mdef = info.md_damage
  let avoid = info.eva
  let knockback = info.pushed
  let mut speed = info.speed
  let mut fly_speed = info.fly_speed
  let touch_damage = info.body_attack
  let is_boss = info.boss
  let no_flip = info.no_flip
  let can_jump = nx_mob.meta.can_jump
  let can_fly = nx_mob.meta.can_fly
  let can_move = nx_mob.meta.can_move
  let _name = mob_names[monster_id.to_string()]

  //TODO: sound

  // Skills are already parsed in nx_mob.skills
  let skill_stands = Map::new()
  for skill_id, entry in nx_mob.skills {
    skill_stands.set(skill_id, entry.animation)
  }

  // Attacks are already parsed in nx_mob.attacks
  let attack_stands : Map[Int, MobAnimation] = Map::new()
  for id, entry in nx_mob.attacks {
    attack_stands.set(id, entry.animation)
  }
  let animations = nx_mob.animations

  // init or risk crash
  match animations.get(StanceType::STAND) {
    Some(stand) => animations[StanceType::SKILL] = stand
    None => ()
  }
  speed += 100
  speed *= 0.001
  fly_speed += 100
  fly_speed *= 0.0005
  if can_fly {
    phobj.set_t(@physics.PhysicsObjectType::FLYING)
  }
  let id = monster_id
  phobj.set_position(position.to_vec2d())
  let control = mode > 0
  let aggro = mode == 2
  phobj.set_fhid(fh)
  phobj.set_flag(@physics.PhysicsObjectFlag::TURN_AT_EDGES)
  let dying = false
  let dead = false
  let stance = Stance::from_byte(st)
  match animations.get(stance.t) {
    Some(_) => ()
    None => ()
  }
  let fly_direction = STRAIGHT
  let counter = 0
  // let name_label = @graphics.Text::new(
  //   text=name,
  //   @graphics.FontId::A13M,
  //   @graphics.TextAlignment::CENTER,
  //   @struct.ColorName::WHITE,
  //   nametag=true,
  // )
  {
    entity,
    oid: object_id,
    phobj,
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
    weapon_def: wdef,
    magic_def: mdef,
    avoid,
    knockback,
    touch_damage,
    no_flip,
    can_move,
    can_jump,
    can_fly,
    is_boss,
    // name_label,
    randomizer,
    anim_time: 0.0,
    movements: [],
    counter,
    id,
    dying,
    dead,
    control,
    aggro,
    stance,
    last_synced_stance: None,
    fly_direction,
    fading: false,
    fade_in: newspawn,
    opacity: @utils.Linear::new(if newspawn { 0.0 } else { 1.0 }),
    src: nx_mob,
  }
}

///|
pub fn Mob::get_oid(self : Mob) -> Int {
  self.oid
}

///|
pub fn Mob::get_entity(self : Mob) -> @entity.Entity {
  self.entity
}

///|
pub fn Mob::update(self : Mob, physics : @physics.Physics) -> Int {
  if not(self.entity.is_alive()) {
    return self.phobj.fhlayer
  }
  let mut aniend = false
  match self.animations.get(self.stance.t) {
    Some(anim) => {
      self.anim_time += @logic_fps.STEP_TIME_MS.to_double()
      // Estimate duration from frames
      let total_delay = anim.nx.frames
        .iter()
        .fold(init=0, fn(acc, f) { acc + f.delay.unwrap_or(100) })
      if self.anim_time >= total_delay.to_double() {
        if self.stance.t == StanceType::DIE {
          aniend = true // Die animation ends
        } else {
          // Loop
          self.anim_time = 0.0
          aniend = true
        }
      }
    }
    None => ()
  }
  if aniend && self.stance.t == StanceType::SKILL {
    self.set_stance({ t: StanceType::STAND, face_right: self.stance.face_right })
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
    self.destroy()
    return -1
  }

  // TODO: add buffs animation?
  if not(self.dying) {
    if not(self.can_fly) {
      if self.phobj.is_flag_not_set(@physics.PhysicsObjectFlag::TURN_AT_EDGES) {
        self.stance = self.stance.flip()
        self.phobj.set_flag(@physics.PhysicsObjectFlag::TURN_AT_EDGES)
        if self.stance.t == StanceType::HIT {
          self.set_stance({
            t: StanceType::STAND,
            face_right: self.stance.face_right,
          })
        }
      }
    }
    match self.stance.t {
      StanceType::MOVE =>
        if self.can_fly {
          self.phobj.set_hforce(
            if self.stance.face_right {
              self.fly_speed
            } else {
              -self.fly_speed
            },
          )
          match self.fly_direction {
            FlyDirection::UPWARDS => self.phobj.set_vforce(-self.fly_speed)
            FlyDirection::DOWNWARDS => self.phobj.set_vforce(self.fly_speed)
            _ => ()
          }
        } else {
          self.phobj.set_hforce(
            if self.stance.face_right {
              self.speed
            } else {
              -self.speed
            },
          )
        }
      StanceType::HIT =>
        if self.can_move {
          let kbforce = if self.phobj.on_ground { 0.2 } else { 0.1 }
          self.phobj.set_hforce(
            if self.stance.face_right { // backwards
              -kbforce
            } else {
              kbforce
            },
          )
        }
      StanceType::JUMP => self.phobj.set_vforce(-5.0)
      _ => ()
    }
    physics.move_object(self.phobj)
    if self.control {
      self.counter += 1
      let next = match self.stance.t {
        StanceType::HIT => self.counter > 200
        StanceType::JUMP => self.phobj.on_ground
        _ =>
          aniend &&
          self.counter > @randx.next_int(self.randomizer, from=200, 500)
      }
      if next {
        self.next_move()
        self.update_movement()
        self.counter = 0
      }
    }
  } else {
    self.phobj.moving_object.normalize()
    physics.get_fht().update_fh(self.phobj)
  }
  return self.phobj.fhlayer
}

///|
fn Mob::next_move(self : Mob) -> Unit {
  if self.can_move {
    match self.stance.t {
      StanceType::HIT | StanceType::STAND =>
        self.set_stance({
          t: StanceType::MOVE,
          face_right: @randx.next_bool(self.randomizer),
        })
      StanceType::MOVE | StanceType::JUMP =>
        if self.can_jump &&
          self.phobj.on_ground &&
          @randx.below(self.randomizer, 0.25) {
          self.set_stance({
            t: StanceType::JUMP,
            face_right: self.stance.face_right,
          })
        } else {
          match @randx.next_int(self.randomizer, 3) {
            0 =>
              self.set_stance({
                t: StanceType::STAND,
                face_right: self.stance.face_right,
              })
            1 => self.set_stance({ t: StanceType::MOVE, face_right: false })
            _ => self.set_stance({ t: StanceType::MOVE, face_right: true })
          }
        }
      _ => ()
    }
    if self.stance.t == StanceType::MOVE && self.can_fly {
      self.fly_direction = @randx.choose(self.randomizer, [
        FlyDirection::STRAIGHT,
        FlyDirection::UPWARDS,
        FlyDirection::DOWNWARDS,
      ])
    }
  } else {
    self.set_stance({ t: StanceType::STAND, face_right: self.stance.face_right })
  }
}

///|
pub fn Mob::set_stance(self : Mob, newstance : Stance) -> Unit {
  if self.stance != newstance {
    self.stance = newstance
    self.anim_time = 0.0
  }
}

///|

///|
pub fn Mob::destroy(self : Mob) -> Unit {
  @sprite.sprites().remove(self.entity)
  self.entity.destroy()
}

///|
pub fn Mob::get_layer(self : Mob) -> Int {
  self.phobj.fhlayer
}

///|
/// Change this mob's control mode:
/// 0 - no control, 1 - control, 2 - aggro
pub fn Mob::set_control(self : Mob, mode : Int) -> Unit {
  self.control = mode > 0
  self.aggro = mode == 2
}

///|
pub fn Mob::is_alive(self : Mob) -> Bool {
  self.entity.is_alive() && not(self.dying)
}

///|
pub fn Mob::is_in_range(self : Mob, range : @struct.Rectangle[Int]) -> Bool {
  if range.get_horizontal().delta().is_neg() ||
    range.get_vertical().delta().is_neg() {
    @log.fatal("invalid range", data={ "range": range })
  }
  if not(self.entity.is_alive()) {
    return false
  }
  match self.animations.get(self.stance.t) {
    Some(anim) => {
      // Use frame 0 bounds as hitbox approximation (Selene handles animation playback)
      let raw_bounds = anim.nx.frames[0].bounds.unwrap_or(
        @struct.Rectangle::default(),
      )
      let bounds = if self.stance.face_right && not(self.no_flip) {
        raw_bounds.flip_x()
      } else {
        raw_bounds
      }
      range.overlaps(bounds.shift(self.get_position()))
    }
    None => false
  }
}

///|
pub fn Mob::get_live_range(self : Mob) -> @struct.Rectangle[Int]? {
  if not(self.is_alive()) {
    return None
  }
  match self.animations.get(self.stance.t) {
    Some(anim) => {
      let raw_bounds = anim.nx.frames[0].bounds.unwrap_or(
        @struct.Rectangle::default(),
      )
      let bounds = if self.stance.face_right && not(self.no_flip) {
        raw_bounds.flip_x()
      } else {
        raw_bounds
      }
      Some(bounds.shift(self.get_position()))
    }
    None => None
  }
}

///|
pub fn Mob::create_touch_attack(self : Mob) -> @combat.MobAttack {
  if not(self.touch_damage) {
    return @combat.MobAttack::default()
  }
  let minattack = (self.watk.to_double() * 0.8).to_int()
  let maxattack = self.watk
  let attack = @randx.next_int(self.randomizer, from=minattack, maxattack)
  return @combat.MobAttack::new(attack, self.get_position(), self.id, self.oid)
}

///|
pub fn Mob::update_movement(self : Mob) -> Unit {
  @game_server.send(
    @server_proto.MoveMonsterMessage::{
      oid: self.oid,
      move_id: 1,
      nibbles: 0,
      action: 0,
      skill: 0,
      skill_level: 0,
      option: 0,
      start_pos: self.get_position(),
      movement: @physics.Movement::from_physics_object(
        self.phobj,
        self.stance.int_value(),
      ),
    },
    log_level=@log.Level::TRACE,
  )
}

///|
pub fn Mob::update_movement_ex(
  self : Mob,
  t : Int,
  nibbles : Int,
  action : Int,
  skill : Int,
  skill_level : Int,
  option : Int,
) -> Unit {
  @game_server.send(@server_proto.MoveMonsterMessage::{
    oid: self.oid,
    move_id: t,
    nibbles,
    action,
    skill,
    skill_level,
    option,
    start_pos: self.get_position(),
    movement: @physics.Movement::from_physics_object(
      self.phobj,
      self.stance.int_value(),
    ),
  })
}

///|
pub fn Mob::give_buff(self : Mob, buff : MobBuff) -> Unit {
  self.buffs.push(buff)
}

///|
pub fn Mob::use_skill(self : Mob, skill : MobSkill) -> Unit {
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
pub fn Mob::use_attack(self : Mob, attack : MobSpecialAttack) -> Unit {
  match self.attack_stands.get(attack.get_id()) {
    Some(anim) => self.animations[StanceType::SKILL] = anim
    None => self.animations.remove(StanceType::SKILL)
  }
  self.set_stance(Stance::from_type(StanceType::SKILL))
}

///|
pub fn Mob::get_head_position(
  self : Mob,
  position? : @struct.Point[Int],
) -> @struct.Point[Int] {
  let head = match self.animations.get(self.stance.t) {
    Some(anim) => anim.nx.frames[0].head.unwrap_or(@struct.Point::default())
    None => @struct.Point::default()
  }
  position
  .unwrap_or(self.get_position())
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
  movements : Array[@physics.Movement],
) -> Unit {
  if self.control {
    return
  }
  self.phobj.set_position(start.to_vec2d())
  self.movements = movements
  if self.movements.is_empty() {
    return
  }
  let lastmove = self.movements[0]
  let laststance = lastmove.newstate
  self.set_stance(laststance |> Stance::from_byte)
  self.phobj.set_fhid(lastmove.fh)
}

///|
pub fn Mob::get_move_skill(
  self : Mob,
  move_id : Int,
  level : Int,
) -> @utils.Future[Result[MobSkill, Error]] {
  self.skill_cache.get_or_init(move_id, fn() {
    @io_service.submit_background_task(async fn() {
      MobSkill::load(move_id, level)
    })
  })
}

///|
pub fn Mob::get_move_attack(
  self : Mob,
  move_id : Int,
) -> MobSpecialAttack raise {
  match self.attacks.get(move_id) {
    Some(ma) => ma
    None =>
      match self.src.attacks.get(move_id) {
        Some(entry) => {
          let new_attack = MobSpecialAttack::new(entry.info, self.id, move_id)
          self.attacks.set(move_id, new_attack)
          new_attack
        }
        None => abort("Attack not found: " + move_id.to_string())
      }
  }
}

///|
pub fn Mob::get_position(self : Mob) -> @struct.Point[Int] {
  self.phobj.get_position()
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
  info : NxMobAttackInfo,
  _mob_id : Int,
  move_id : Int,
) -> MobSpecialAttack raise {
  let effects_arr = info.effects.map(fn(e) {
    Effect::{ animation: e.animation.nx, z: e.z }
  })
  let has_multi = effects_arr.length() > 1 ||
    info.effects.iter().find_first(fn(e) { e.is_area_warning }) is Some(_)
  let use_effect : &MobSkillUseEffect = if has_multi {
    { effects: effects_arr } as &MobSkillUseEffect
  } else if effects_arr.length() == 1 {
    { effect: effects_arr[0] } as &MobSkillUseEffect
  } else {
    // Should not happen for valid attacks, but construct a dummy
    let dummy = Effect::{ animation: @json.from_json(Json::null()), z: 0 }
    { effect: dummy } as &MobSkillUseEffect
  }
  { move_id, use_effect }
  // hit_effect_ = std::make_unique<MobSingleHitEffect>(src["level"][4]);

  // hit_effect_ =
  // std::make_unique<MobSingleHitEffect>(src["attack1"]["info"]); hit_effect_
  // = std::make_unique<NoHitEffect>();

  // action_ = std::make_unique<NoAction>();
}

///|
pub fn Mob::show_effect(
  self : Mob,
  animation : @resource.NxAnimation,
  pos : Int,
  z : Int,
  flip : Bool,
) -> Unit {
  if not(self.entity.is_alive()) {
    return
  }
  // TODO: add shift
  ignore(pos)
  // let shift = match pos {
  //   0 => self.get_head_position(position=@struct.Point::default())
  //   _ => @struct.Point::default()
  // }
  @graphics.add_effect(
    self.entity,
    animation,
    z=@graphics.EFFECT_ZINDEX + z,
    flip~,
  )
}

///|
pub fn Mob::kill(self : Mob, animation : Int) -> Unit {
  match animation {
    0 => self.destroy()
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
fn Mob::apply_death(self : Mob) -> Unit {
  self.set_stance({ t: StanceType::DIE, face_right: self.stance.face_right })
  // die_sound_.play();
  self.dying = true
}

///|
pub fn MobSpecialAttack::apply_useeffects(
  self : MobSpecialAttack,
  mob : Mob,
) -> Unit {
  self.use_effect.apply(mob)
  // sound_->play_use();
}

///|
pub fn Mob::calculate_damage(
  self : Mob,
  attack : @combat.Attack,
) -> Array[(Int, Bool)] {
  let greater_level = @cmp.maximum(self.level - attack.playerlevel, 0)
  let damagetype = attack.damagetype
  let (mindamage, maxdamage, hitchance, critical) = match damagetype {
    @combat.AttackDamageType::DMG_WEAPON(min~, max~) => {
      let (mindamage, maxdamage) = calculate_weapon_damage(
        greater_level,
        min,
        max,
        self.weapon_def.to_double(),
      )
      let hitchance = self.calculate_hitchance(greater_level, attack.accuracy)
      let critical = attack.critical
      (mindamage, maxdamage, hitchance, critical)
    }
    @combat.AttackDamageType::DMG_MAGIC(matk) => {
      let (mindamage, maxdamage) = calculate_magic_damage(
        greater_level,
        matk.to_double(),
        matk.to_double(),
        self.magic_def.to_double(),
      )
      let hitchance = self.calculate_hitchance(greater_level, attack.accuracy)
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
fn Mob::next_damage(
  self : Mob,
  mindamage : Double,
  maxdamage : Double,
  hitchance : Double,
  critical : Double,
) -> (Int, Bool) {
  let hit = @randx.below(self.randomizer, hitchance)
  if not(hit) {
    return (0, false)
  }
  let damagecap = 999999
  let iscritical = @randx.below(self.randomizer, critical)
  let mut damage = @randx.next_real(self.randomizer, from=mindamage, maxdamage)
  if iscritical {
    damage *= 1.5
  }
  let intdamage = damage.to_int() |> @cmp.maximum(1) |> @cmp.minimum(damagecap)
  return (intdamage, iscritical)
}

///|
/// Calculate weapon damage
fn calculate_weapon_damage(
  greater_level : Int,
  min : Double,
  max : Double,
  def : Double,
) -> (Double, Double) {
  let final_min = (min * (1.0 - 0.01 * greater_level.to_double()) - def * 0.6)
    |> @cmp.maximum(1.0)
  let final_max = (max * (1.0 - 0.01 * greater_level.to_double()) - def * 0.5)
    |> @cmp.maximum(1.0)
  (final_min, final_max)
}

///|
/// Calculate magic damage
fn calculate_magic_damage(
  greater_level : Int,
  min : Double,
  max : Double,
  def : Double,
) -> (Double, Double) {
  let final_min = (min - (1.0 + 0.01 * greater_level.to_double()) * def * 0.6)
    |> @cmp.maximum(1.0)
  let final_max = (max - (1.0 + 0.01 * greater_level.to_double()) * def * 0.5)
    |> @cmp.maximum(1.0)
  (final_min, final_max)
}

///|
fn Mob::calculate_hitchance(
  self : Mob,
  greater_level : Int,
  player_accuracy : Int,
) -> Double {
  let hitchance = player_accuracy.to_double() /
    (self.avoid.to_double() * (1.84 + 0.07 * greater_level.to_double()) + 1.0)
  @cmp.maximum(hitchance, 0.01)
}

///|
pub fn Mob::apply_damage(self : Mob, damage : Int, toleft : Bool) -> Unit {
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
