///|
using @resource {nx_animation_to_selene_animation}

///|
using @char_stance {type StanceId}

///|
using @types {type BodyDrawInfo}

///|
using @selene_ui {type Ui}

///|
struct CharLook {
  root_entity : @entity.Entity
  stance : @utils.Nominal[StanceId]
  // st_frame : @utils.Nominal[Int]
  // mut st_elapsed : Int
  expression : @utils.Nominal[ExpressionId]
  // mut exp_elapsed : Int
  mut flip : Bool
  mut actionstr : String
  // mut actframe : Int
  full_body : FullBody
  hair : Hair
  face : Face
  mut action : @types.NxStanceBodyAction?
  equips : @equip.CharEquips
  randomizer : @random.Rand
  draw_info : @types.BodyDrawInfo
  body_entities : Map[String, @entity.Entity]
  hair_entities : Map[HairLayer, @entity.Entity]
  weapon_entities : Map[String, @entity.Entity]
  equip_entities : Map[String, @entity.Entity]
  mut face_entity : @entity.Entity?
}

///|
pub(all) struct LookEntry {
  female : Bool
  skin : Int
  faceid : Int
  hairid : Int
  equips : Map[Int, Int]
  maskedequips : Map[Int, Int]
  petids : Array[Int]
} derive(Show, ToJson, Default)

///|
pub impl @json.FromJson for LookEntry with from_json(json, path) {
  fn parse_int_map(
    value : Json,
    path : @json.JsonPath,
  ) -> Map[Int, Int] raise @json.JsonDecodeError {
    guard value is Object(obj) else {
      raise @json.JsonDecodeError((path, "expect object"))
    }
    let result = Map::new()
    for key, item in obj {
      let slot_id = @strconv.parse_int(key) catch {
        _ => raise @json.JsonDecodeError((path.add_key(key), "invalid int key"))
      }
      let item_id : Int = @json.from_json(item, path=path.add_key(key))
      result.set(slot_id, item_id)
    }
    result
  }
  guard json
    is {
      "female": female,
      "skin": skin,
      "faceid": faceid,
      "hairid": hairid,
      "equips": equips,
      "maskedequips": maskedequips,
      "petids": petids,
      ..
    } else {
    raise @json.JsonDecodeError((path, "invalid LookEntry"))
  }
  {
    female: @json.from_json(female, path=path.add_key("female")),
    skin: @json.from_json(skin, path=path.add_key("skin")),
    faceid: @json.from_json(faceid, path=path.add_key("faceid")),
    hairid: @json.from_json(hairid, path=path.add_key("hairid")),
    equips: parse_int_map(equips, path.add_key("equips")),
    maskedequips: parse_int_map(maskedequips, path.add_key("maskedequips")),
    petids: @json.from_json(petids, path=path.add_key("petids")),
  }
}

///|
pub async fn CharLook::load(
  entity : @entity.Entity,
  entry : LookEntry,
  body : FullBody,
  hair : Hair,
  face : Face,
  draw_info : @types.BodyDrawInfo,
) -> CharLook {
  let equips = entry.equips
    .iter()
    .map(fn(it) {
      let (slot_id, itemid) = it
      () => {
        let itemdata = @item.ItemData::load_item_data(itemid)
        (slot_id, itemdata)
      }
    })
    |> Array::from_iter()
    |> @js.async_all()
    |> Map::from_array()
  CharLook::new(entity, equips, body, hair, face, draw_info)
}

///|
pub fn CharLook::new(
  entity : @entity.Entity,
  slot_equips : Map[Int, @item.ItemData],
  body : FullBody,
  hair : Hair,
  face : Face,
  draw_info : @types.BodyDrawInfo,
) -> CharLook {
  let root_entity = entity
  let equips = @equip.CharEquips::new()
  for slot_id, itemdata in slot_equips {
    equips.add_equip(itemdata, @slot.Id::from_int(slot_id), draw_info) catch {
      e => abort(e.to_string()) // TODO: handle error
    }
  }
  {
    root_entity,
    stance: @utils.Nominal::default(),
    // st_frame: @utils.Nominal::default(),
    // st_elapsed: 0,
    expression: @utils.Nominal::default(),
    // exp_elapsed: 0,
    flip: false,
    action: None,
    actionstr: "",
    // actframe: 0,
    full_body: body,
    hair,
    face,
    equips,
    randomizer: @random.Rand::new(),
    draw_info,
    body_entities: Map::new(),
    hair_entities: Map::new(),
    weapon_entities: Map::new(),
    equip_entities: Map::new(),
    face_entity: None,
  }
}

///|
fn CharLook::spawn_sprite_child(self : CharLook) -> @entity.Entity {
  let child = self.root_entity.spawn_child()
  match @selene_ui.uis.get(self.root_entity) {
    Some(ui) => @selene_ui.uis.set(child, ui)
    None => ()
  }
  child
}

///|
fn CharLook::updatetwohanded(self : CharLook) -> Unit {
  let basestance = StanceId::baseof(self.stance.get())
  self.set_stance(basestance)
}

///|
pub fn CharLook::set_pos(self : CharLook, pos : @selene_math.Vec2D) -> Unit {
  @position.positions.set(self.root_entity, @position.Position(pos))
}

///|
/// Set animation playback speed for all sprite entities used by this look.
pub fn CharLook::set_animation_speed(self : CharLook, speed : Double) -> Unit {
  fn set_speed_if_animation(entity : @entity.Entity) {
    if @sprite.sprites.get(entity)
      is Some({ sprite_type: Animation(_, ..), .. }) {
      @sprite.set_animation_speed(entity, speed)
    }
  }

  for entity in self.body_entities.values() {
    set_speed_if_animation(entity)
  }
  for entity in self.hair_entities.values() {
    set_speed_if_animation(entity)
  }
  for entity in self.equip_entities.values() {
    set_speed_if_animation(entity)
  }
  for entity in self.weapon_entities.values() {
    set_speed_if_animation(entity)
  }
  match self.face_entity {
    Some(entity) => set_speed_if_animation(entity)
    None => ()
  }
}

///|
pub fn CharLook::play_animations(self : CharLook) -> Unit {
  // let acmove = @struct.Point::default()
  // let relargs = @graphics.DrawArgument::new14(acmove, self.flip)
  // let interstance = self.stance.get()
  // let interexpression = self.expression.get()
  // let interframe = self.st_frame.get()
  // let interexpframe = self.exp_frame.get()
  let stance : StanceId = self.stance.get()
  let expression : ExpressionId = self.expression.get()
  // let stance_frame : Int = self.st_frame.get()
  // if interstance == StanceId::DEAD {
  //   return self.draw_dead(
  //     args, interstance, interexpression, interframe, interexpframe,
  //   )
  // }
  // if StanceId::is_climbing(interstance) {
  //   return self.draw_climbing(args, interstance, interframe)
  // }
  fn should_loop(stance : StanceId) -> Bool {
    match stance {
      StanceId::STAND1
      | StanceId::STAND2
      | StanceId::WALK1
      | StanceId::WALK2
      | StanceId::ALERT
      | StanceId::SIT
      | StanceId::FLY
      | StanceId::PRONE => true
      StanceId::LADDER | StanceId::ROPE => true
      _ => false
    }
  }

  let loop_ = should_loop(stance)
  fn reset_sprites_hide(entities : Iter[@entity.Entity]) {
    for entity in entities {
      if @sprite.sprites.get(entity) is Some(sprite) {
        sprite.visible = false
      }
    }
  }

  if StanceId::is_climbing(stance) {
    self.play_climbing_animations(stance)
    return
  }

  // Extract body delays for synchronization
  let body_delays : Array[Int?] = match self.full_body.stances.get(stance) {
    Some(map) =>
      match map.get("body") {
        Some((body_frames, _)) => body_frames.map(fn(f) { f.delay })
        None => []
      }
    None => []
  }
  reset_sprites_hide(self.body_entities.values())
  reset_sprites_hide(self.hair_entities.values())

  let flip_x = self.flip
  for
    layer in [
      HairLayer::BELOW_BODY,
      HairLayer::HAIR_LAYER_DEFAULT,
      HairLayer::SHADE,
      ..match self.equips.getcaptype() {
        @equip.CapType::NONE => [HairLayer::OVER_HEAD]
        @equip.CapType::HEADBAND =>
          [HairLayer::HAIR_LAYER_DEFAULT, HairLayer::OVER_HEAD]
        @equip.CapType::HALF_COVER => [HairLayer::HAIR_LAYER_DEFAULT]
        _ => []
      },
    ] {
    guard self.hair.stances.get(stance).bind(v => v.get(layer)) is Some(anim) else {
      continue
    }
    // Inject body delays into hair frames
    let frames = anim.frames.mapi(fn(i, f) {
      let delay = if i < body_delays.length() {
        body_delays[i]
      } else {
        f.delay
      }
      { ..f, delay, }
    })
    let anim = { ..anim, frames, }
    let animation = nx_animation_to_selene_animation(anim, loop_~) // TODO: cache animation
    let transform = facing_transform(flip_x)
    let entity = self.hair_entities.get_or_init(layer, fn() {
      self.spawn_sprite_child()
    })
    let sprite = ensure_sprite_with_z(
      entity,
      animation,
      layer.z() + @graphics.CHAR_LOOK_ZINDEX,
      transform,
    )
    sprite.visible = true
    @sprite.play_animation(entity, animation, loop_~, transform~)
  }
  if self.full_body.stances.get(stance) is Some(stance_stances) {
    for name, it in stance_stances {
      let (frames, layers) = it
      if frames.length() != layers.length() {
        @log.error("frames.length() != layers.length()", data={
          "name": name,
          "frames": frames.length(),
          "layers": layers.length(),
        })
        panic()
      }
      let nx_anim = @resource.NxAnimation::{
        frames,
        blend: false,
        zigzag: false,
      } // Reconstruct approximate NxAnimation container
      let animation = nx_animation_to_selene_animation(nx_anim, loop_~)
      let transform = facing_transform(self.flip)

      // Calculate frame mapping for this animation (needed for correct Z-index lookup)
      let entity = self.body_entities.get_or_init(name, fn() {
        self.spawn_sprite_child()
      })
      let current_frame = if @sprite.sprites.get(entity)
        is Some({ sprite_type: Animation(_, frame~, ..), .. }) {
        // Use frame directly as requested, correcting for potential bounds
        if frame < layers.length() {
          frame
        } else {
          0
        }
      } else {
        0
      }
      let sprite = ensure_sprite_with_z(
        entity,
        animation,
        layers[current_frame].int_value() + @graphics.CHAR_LOOK_ZINDEX,
        transform,
      )
      sprite.visible = true
      @sprite.play_animation(entity, animation, loop_~, transform~)
    }
  }
  // Weapon animation
  // Equipment Animation
  reset_sprites_hide(self.equip_entities.values())
  reset_sprites_hide(self.weapon_entities.values()) // Also hide weapon sprites as they are now handled by equip entities

  // We need to iterate over all equipped items
  for item in self.equips.iter() {
    let (slot, clothing) = item
    // Get parts for the current stance
    if clothing.get_parts_for_stance(stance) is Some(stance_parts) {
      for part, it in stance_parts {
        let (frames, layers) = it
        if frames.length() != layers.length() {
          @log.error("equipment frames.length() != layers.length()", data={
            "slot": slot.to_string(),
            "part": part,
            "frames": frames.length(),
            "layers": layers.length(),
          })
          continue
        }
        if frames.length() == 0 {
          continue
        }

        // Get or init entity for this specific part
        // We use slot + part as key to avoid collision (e.g. Mail + mail vs Mail + mailArm)
        let key = slot.to_string() + "_" + part
        let entity = self.equip_entities.get_or_init(key, fn() {
          self.spawn_sprite_child()
        })

        // Determine Z-index
        // Ideally we should pick the Z-index of the current frame, but for now we pick the first one
        // or we need to pass the layer array to attach_equipment and let it handle per-frame Z?
        // Since play_animation sets a single Z for the whole animation in Selene's Sprite,
        // we usually take the Z of the first frame or force them to be consistent.
        // Looking at the data, usually layers are consistent across frames for a single motion.
        let current_frame = if @sprite.sprites.get(entity)
          is Some({ sprite_type: Animation(_, frame~, ..), .. }) {
          if frame < layers.length() {
            frame
          } else {
            0
          }
        } else {
          0
        }
        let z_layer = if layers.length() > 0 {
          layers[current_frame].int_value()
        } else {
          0
        }
        attach_equipment(
          entity,
          stance,
          self.flip,
          frames,
          z_layer,
          body_delays,
          loop_,
        )
      }
    }
  }

  // Face Animation
  match self.face.expressions.get(expression) {
    Some(face_frames) => {
      let entity = match self.face_entity {
        Some(e) => e
        None => {
          let e = self.spawn_sprite_child()
          self.face_entity = Some(e)
          e
        }
      }
      attach_face(
        entity,
        stance,
        self.flip,
        face_frames,
        self.draw_info,
        self.full_body,
      )
    }
    None => ()
  }
}

///|
pub fn CharLook::is_twohanded(self : CharLook, st : StanceId) -> Bool {
  match st {
    StanceId::STAND1 | StanceId::WALK1 => false
    StanceId::STAND2 | StanceId::WALK2 => true
    _ => self.equips.is_two_handed()
  }
}

///|
/// Sets the direction of the character
pub fn CharLook::set_facing_right(self : CharLook, facing_right : Bool) -> Unit {
  self.flip = facing_right
}

///|
pub fn CharLook::set_stance(self : CharLook, st : StanceId) -> Unit {
  if self.action is Some(_) || st == StanceId::NONE {
    return
  }
  let adjstance = self.equips.adjust_stance(st)
  if self.stance.get() != adjstance {
    self.stance.set(adjstance)
    // self.st_frame.set(0)
    // self.st_elapsed = 0
  }
  self.play_animations()
}

///|
fn CharLook::change_body(self : CharLook, body : FullBody) -> CharLook {
  { ..self, full_body: body }
}

///|
fn CharLook::change_hair(self : CharLook, hair : Hair) -> CharLook {
  { ..self, hair, }
}

///|
fn CharLook::change_face(self : CharLook, face : Face) -> CharLook {
  { ..self, face, }
}

///|
let default_stance : StanceId = StanceId::STAND1

///|
// pub fn CharLook::update(self : CharLook, timestep : Int) -> Bool {
// if timestep == 0 {
//   self.stance.normalize()
//   self.st_frame.normalize()
//   self.expression.normalize()
//   self.exp_frame.normalize()
//   return false
// }
// let ani_end = match self.action {
//   None => {
//     let delay = self.get_delay(self.stance.get(), self.st_frame.get())
//     let delta = delay - self.st_elapsed
//     if timestep >= delta {
//       self.st_elapsed = timestep - delta
//       let nextframe : Int = self.getnextframe(
//         self.stance.get(),
//         self.st_frame.get(),
//       )
//       let threshold : Double = delta.to_double() / timestep.to_double()
//       self.st_frame.next(nextframe, threshold)
//       self.set_sprites()
//       nextframe == 0
//     } else {
//       self.stance.normalize()
//       self.st_frame.normalize()
//       self.st_elapsed += timestep
//       false
//     }
//   }
//   Some(action) => {
//     let delay : Int = action.get_delay()
//     let delta : Int = delay - self.st_elapsed
//     if timestep >= delta {
//       self.st_elapsed = timestep - delta
//       self.actframe = self.draw_info.next_action_frame(
//         self.actionstr,
//         self.actframe,
//       )
//       let aniend = if self.actframe > 0 {
//         self.action = self.draw_info.get_action(self.actionstr, self.actframe)
//         let threshold : Double = delta.to_double() / timestep.to_double()
//         self.stance.next(action.get_stance(), threshold)
//         self.st_frame.next(action.get_frame(), threshold)
//         false
//       } else {
//         self.action = None
//         self.actionstr = ""
//         self.set_stance(StanceId::STAND1)
//         true
//       }
//       self.set_sprites()
//       aniend
//     } else {
//       self.stance.normalize()
//       self.st_frame.normalize()
//       self.st_elapsed += timestep
//       false
//     }
//   }
// }
// self.update_face(timestep)
// ani_end
// }

///|
// fn CharLook::update_face(self : CharLook, timestep : Int) -> Unit {
// let face = self.face
// let expdelay : Int = face.get_delay(
//   self.expression.get(),
//   self.exp_frame.get(),
// )
// let expdelta : Int = expdelay - self.exp_elapsed
// if timestep >= expdelta {
//   self.exp_elapsed = timestep - expdelta
//   let nextexpframe : Int = face.nextframe(
//     self.expression.get(),
//     self.exp_frame.get(),
//   )
//   let fcthreshold : Double = expdelta.to_double() / timestep.to_double()
//   self.exp_frame.next(nextexpframe, fcthreshold)
//   if nextexpframe == 0 {
//     if self.expression.get() == ExpressionId::DEFAULT {
//       self.expression.next(ExpressionId::BLINK, fcthreshold)
//     } else {
//       self.expression.next(ExpressionId::DEFAULT, fcthreshold)
//     }
//   }
//   self.set_sprites()
// } else {
//   self.expression.normalize()
//   self.exp_frame.normalize()
//   self.exp_elapsed += timestep
// }
// }

///|
pub fn CharLook::get_delay(self : CharLook, st : StanceId, fr : Int) -> Int {
  self.draw_info.get_delay(st, fr)
}

///|
pub fn CharLook::getnextframe(self : CharLook, st : StanceId, fr : Int) -> Int {
  self.draw_info.next_frame(st, fr)
}

///|
pub fn CharLook::get_equips(self : CharLook) -> @equip.CharEquips {
  self.equips
}

///|
pub fn CharLook::add_equip(
  self : CharLook,
  itemdata : @item.ItemData,
  slot : @slot.Id,
) -> Unit raise {
  self.equips.add_equip(itemdata, slot, self.draw_info)
  self.updatetwohanded()
  self.play_animations()
}

///|
pub fn CharLook::remove_equip(self : CharLook, slot : @slot.Id) -> Unit {
  self.equips.remove_equip(slot)
  if slot == @slot.Id::WEAPON {
    self.updatetwohanded()
  }
  self.play_animations()
}

///|
pub fn CharLook::get_stance(self : CharLook) -> StanceId {
  self.stance.get()
}

///|
pub fn CharLook::get_frame(self : CharLook) -> Int {
  // Try to find the "body" entity which drives the main animation
  match self.body_entities.get("body") {
    Some(entity) =>
      match @sprite.sprites.get(entity) {
        Some({ sprite_type: Animation(_, frame~, ..), .. }) => frame
        _ => 0
      }
    None => 0
  }
}

///|
pub fn CharLook::get_attackdelay(
  self : CharLook,
  no : Int,
  first_frame : Int,
) -> Int {
  match self.action {
    Some(_) => return self.draw_info.get_attack_delay(self.actionstr, no)
    None => ()
  }
  let mut delay : Int = 0
  for frame in 0..<first_frame {
    delay += self.get_delay(self.stance.get(), frame)
  }
  return delay
}

///|
pub fn CharLook::attack(self : CharLook, degenerate : Bool) -> Unit {
  guard self.equips.get_weapon() is Some(weapon) else { return }
  let attacktype = weapon.get_attack()
  if attacktype == 9 && not(degenerate) {
    self.set_stance(StanceId::SHOT)
    self.set_action("handgun")
  } else {
    self.set_stance(self.getattackstance(attacktype, degenerate))
    // self.st_frame.set(0)
    // self.st_elapsed = 0
  }
  // TODO: weapon sound
  // weapon.get_usesound(degenerate).play()
}

///|
pub fn CharLook::attack_by_stance(
  self : CharLook,
  newstance : StanceId,
) -> Unit {
  if not(self.action is None) || newstance == StanceId::NONE {
    return
  }
  match newstance {
    StanceId::SHOT => self.set_action("handgun")
    _ => self.set_stance(newstance)
  }
}

///|
pub fn CharLook::set_action(self : CharLook, acstr : String) -> Unit {
  if acstr == self.actionstr || acstr.is_empty() {
    return
  }
  let ac_stance = StanceId::from_name(acstr).unwrap_or(NONE)
  if ac_stance != NONE {
    self.set_stance(ac_stance)
  } else {
    self.action = self.draw_info.get_action(acstr, 0)
    match self.action {
      Some(action) => {
        // self.actframe = 0
        // self.st_elapsed = 0
        self.actionstr = acstr
        self.set_stance(action.get_stance())
        // self.st_frame.set(action.get_frame())
      }
      None => ()
    }
  }
}

///|
fn CharLook::getattackstance(
  self : CharLook,
  attack : Int,
  degenerate : Bool,
) -> StanceId {
  if self.stance.get() == StanceId::PRONE {
    return StanceId::PRONESTAB
  }
  if attack <= 0 || attack >= degen_stances.length() {
    return StanceId::STAND1
  }
  let stances = if degenerate {
    degen_stances[attack]
  } else {
    attack_stances[attack]
  }
  if stances.length() == 0 {
    return StanceId::STAND1
  }
  let index = @randx.next_int(self.randomizer, stances.length())
  return stances[index]
}

// let attack_S1A1M1D = 1
// let attack_SPEAR = 2
// let attack_BOW = 3
// let attack_CROSSBOW = 4
// let attack_S2A2M2 = 5
// let attack_WAND = 6
// let attack_CLAW = 7
// let attack_GUN = 9

///|
let degen_stances : FixedArray[FixedArray[StanceId]] = [
  [StanceId::NONE],
  [StanceId::NONE],
  [StanceId::NONE],
  [StanceId::SWINGT1, StanceId::SWINGT3],
  [StanceId::SWINGT1, StanceId::STABT1],
  [StanceId::NONE],
  [StanceId::NONE],
  [StanceId::SWINGT1, StanceId::STABT1],
  [StanceId::NONE],
  [StanceId::SWINGP1, StanceId::STABT2],
]

///|
let attack_stances : FixedArray[FixedArray[StanceId]] = [
  [StanceId::NONE],
  [
    StanceId::STABO1,
    StanceId::STABO2,
    StanceId::SWINGO1,
    StanceId::SWINGO2,
    StanceId::SWINGO3,
  ],
  [StanceId::STABT1, StanceId::SWINGP1],
  [StanceId::SHOOT1],
  [StanceId::SHOOT2],
  [
    StanceId::STABO1,
    StanceId::STABO2,
    StanceId::SWINGT1,
    StanceId::SWINGT2,
    StanceId::SWINGT3,
  ],
  [StanceId::SWINGO1, StanceId::SWINGO2],
  [StanceId::SWINGO1, StanceId::SWINGO2],
  [StanceId::NONE],
  [StanceId::SHOT],
]

///|
pub impl ToJson for CharLook with to_json(_) -> Json {
  {} // TODO
}

///|
pub fn CharLook::get_face(self : CharLook) -> Face {
  self.face
}

///|
pub fn CharLook::get_hair(self : CharLook) -> Hair {
  self.hair
}

///|
pub fn CharLook::get_body(self : CharLook) -> FullBody {
  self.full_body
}

///|
struct NoopDrawable(Unit) derive(ToJson)

///|
pub fn CharLook::get_root_entity(self : CharLook) -> @entity.Entity {
  self.root_entity
}

///|
pub fn CharLook::is_animation_finished(self : CharLook) -> Bool {
  match self.body_entities.get("body") {
    Some(entity) => @sprite.is_animation_finished(entity)
    None => false
  }
}

///|
/// 添加 face sprite
/// 
/// 根据当前的 表情 (Expression) 获取对应的脸部纹理 (通常默认表情是静态的，但也支持眨眼等动画)。
/// 
/// 关键点 - 身体同步 (Body Synchronization):
/// 代码首先读取当前身体姿态 (Stance) 的每一帧时长数据 (body_delays)。
/// 即使脸部图片本身可能只有一张（如默认表情），我们也会根据身体动画的帧数来构建脸部动画。
/// 这意味着：如果身体做 stabO1 (刺击) 动作有 3 帧，我们也会生成一个包含 3 帧的脸部动画。
/// 
/// 位置校准 (Positioning/Pivot):
/// 在 MapleStory 的资源中，每一帧身体动作，头部的相对位置都在变化（比如走路时头会上下颠簸）。
/// 对于动画的每一帧 i，我们调用 self.draw_info.get_face_pos(stance, i)。这个函数会查找配置表 (WZ/Json 数据)，计算出当前这一帧，脸部相对于角色原点应该在什么位置。
/// 我们通过修改 Sprite 的 Pivot (锚点) 来实现这个位移：pivot = source_pivot - face_pos。
/// 
/// 设定 Z-index 为 FACE_ACC - 1, 在头发图层（刘海）之下。
fn attach_face(
  entity : @entity.Entity,
  stance : StanceId,
  flip_x : Bool,
  face_frames : Map[Int, FaceFrame],
  draw_info : BodyDrawInfo,
  full_body : FullBody,
) -> Unit {
  let frames = []
  let mut i = 0
  while face_frames.get(i) is Some(f) {
    let frame = @resource.NxFrame::{
      texture: f.texture,
      delay: Some(f.delay),
      head: None,
      bounds: None,
    }
    frames.push(frame)
    i += 1
  }
  if frames.length() > 0 {
    let nx_anim = @resource.NxAnimation::{ frames, blend: false, zigzag: false }
    let animation = nx_animation_to_selene_animation(nx_anim, loop_=true)
    let transform = facing_transform(flip_x)

    // Face Animation Sync
    let body_delays : Array[Int?] = match full_body.stances.get(stance) {
      Some(map) =>
        match map.get("body") {
          Some((body_frames, _)) => body_frames.map(fn(f) { f.delay })
          None => []
        }
      None => []
    }
    let face_frames = []
    if body_delays.length() > 0 {
      for i = 0; i < body_delays.length(); i = i + 1 {
        let face_pos = draw_info.get_face_pos(stance, i)
        let source_frame = animation.frames[0]
        let frame = {
          ..source_frame,
          pivot: source_frame.pivot -
          @selene_math.Vec2D(face_pos.x.to_double(), face_pos.y.to_double()),
          duration: body_delays[i].unwrap_or(100).to_double() / 1000.0,
        }
        face_frames.push(frame)
      }
    } else {
      let face_pos = draw_info.get_face_pos(stance, 0)
      let frame = {
        ..animation.frames[0],
        pivot: animation.frames[0].pivot -
        @selene_math.Vec2D(face_pos.x.to_double(), face_pos.y.to_double()),
      }
      face_frames.push(frame)
    }
    let animation = @sprite.Animation::new(face_frames, loop_=true)
    let sprite = ensure_sprite_with_z(
      entity,
      animation,
      @graphics.CHAR_LOOK_ZINDEX +
      @clothing.ClothingLayer::FACE_ACC.int_value() -
      1,
      transform,
    )
    sprite.visible = true
    @sprite.play_animation(entity, animation, loop_=true, transform~)
  }
}

///|
fn facing_transform(flip_x : Bool) -> @selene_math.Transform {
  if flip_x {
    @selene_math.Transform::from_scale(-1.0, 1.0)
  } else {
    @selene_math.Transform::new()
  }
}

///|
fn ensure_sprite_with_z(
  entity : @entity.Entity,
  animation : @sprite.Animation,
  z : Int,
  transform : @selene_math.Transform,
) -> @sprite.Sprite {
  if @sprite.sprites.get(entity) is Some(sprite) {
    @sprite.set_animation_transform(entity, transform)
    if sprite.zindex != z {
      let sprite = { ..sprite, zindex: z }
      @sprite.sprites.set(entity, sprite)
      return sprite
    }
    return sprite
  }
  let sprite = @sprite.Sprite::from_animation(animation, z, transform~)
  @sprite.sprites.set(entity, sprite)
  sprite
}

///|
fn attach_equipment(
  entity : @entity.Entity,
  stance : StanceId,
  flip_x : Bool,
  frames : Array[@resource.NxFrame],
  z : Int,
  body_delays : Array[Int?],
  loop_ : Bool,
) -> Unit {
  // Clone and inject delays
  let frames = frames.mapi(fn(i, f) {
    let delay = if i < body_delays.length() { body_delays[i] } else { f.delay }
    { ..f, delay, }
  })
  let nx_anim = @resource.NxAnimation::{ frames, blend: false, zigzag: false }
  let animation = nx_animation_to_selene_animation(nx_anim, loop_~)
  let transform = facing_transform(flip_x)
  let sprite = ensure_sprite_with_z(
    entity,
    animation,
    z + @graphics.CHAR_LOOK_ZINDEX,
    transform,
  )
  sprite.visible = true
  @sprite.play_animation(entity, animation, loop_~, transform~)
}

///|
fn CharLook::play_climbing_animations(
  self : CharLook,
  stance : StanceId,
) -> Unit {
  let loop_ = true
  fn reset_sprites_hide(entities : Iter[@entity.Entity]) {
    for entity in entities {
      if @sprite.sprites.get(entity) is Some(sprite) {
        sprite.visible = false
      }
    }
  }

  // Extract body delays for synchronization
  let body_delays : Array[Int?] = match self.full_body.stances.get(stance) {
    Some(map) =>
      match map.get("body") {
        Some((body_frames, _)) => body_frames.map(fn(f) { f.delay })
        None => []
      }
    None => []
  }
  reset_sprites_hide(self.body_entities.values())
  reset_sprites_hide(self.hair_entities.values())
  let flip_x = self.flip

  // Hair Animation (Include BACK for climbing, exclude front layers)
  for
    layer in [
      HairLayer::BELOW_BODY,
      HairLayer::BACK,
      HairLayer::BELOW_CAP,
      HairLayer::HAIR_LAYER_DEFAULT,
    ] {
    guard self.hair.stances.get(stance).bind(v => v.get(layer)) is Some(anim) else {
      continue
    }
    // Inject body delays into hair frames
    let frames = anim.frames.mapi(fn(i, f) {
      let delay = if i < body_delays.length() {
        body_delays[i]
      } else {
        f.delay
      }
      { ..f, delay, }
    })
    let anim = { ..anim, frames, }
    let animation = nx_animation_to_selene_animation(anim, loop_~)
    let transform = facing_transform(flip_x)
    let entity = self.hair_entities.get_or_init(layer, fn() {
      self.spawn_sprite_child()
    })
    let z_index = if layer == HairLayer::BACK {
      @types.BodyLayer::HEAD.int_value() + 5
    } else {
      layer.z()
    }
    let sprite = ensure_sprite_with_z(
      entity,
      animation,
      z_index + @graphics.CHAR_LOOK_ZINDEX,
      transform,
    )
    sprite.visible = true
    @sprite.play_animation(entity, animation, loop_~, transform~)
  }

  // Body Animation
  if self.full_body.stances.get(stance) is Some(stance_stances) {
    for name, it in stance_stances {
      let (frames, layers) = it
      if frames.length() != layers.length() {
        @log.error("frames.length() != layers.length()", data={
          "name": name,
          "frames": frames.length(),
          "layers": layers.length(),
        })
        panic()
      }
      let nx_anim = @resource.NxAnimation::{
        frames,
        blend: false,
        zigzag: false,
      }
      let animation = nx_animation_to_selene_animation(nx_anim, loop_~)
      let transform = facing_transform(self.flip)
      let entity = self.body_entities.get_or_init(name, fn() {
        self.spawn_sprite_child()
      })
      // Simplified frame logic for climbing (loop 0)
      let current_frame = 0
      let sprite = ensure_sprite_with_z(
        entity,
        animation,
        layers[current_frame].int_value() + @graphics.CHAR_LOOK_ZINDEX,
        transform,
      )
      sprite.visible = true
      @sprite.play_animation(entity, animation, loop_~, transform~)
    }
  }

  // Equipment Animation
  reset_sprites_hide(self.equip_entities.values())
  reset_sprites_hide(self.weapon_entities.values())
  for item in self.equips.iter() {
    let (slot, clothing) = item
    if clothing.get_parts_for_stance(stance) is Some(stance_parts) {
      for part, it in stance_parts {
        let (frames, layers) = it
        if frames.length() == 0 {
          continue
        }
        let key = slot.to_string() + "_" + part
        let entity = self.equip_entities.get_or_init(key, fn() {
          self.spawn_sprite_child()
        })
        let current_frame = if @sprite.sprites.get(entity)
          is Some({ sprite_type: Animation(_, frame~, ..), .. }) {
          if frame < layers.length() {
            frame
          } else {
            0
          }
        } else {
          0
        }
        let z_layer = if layers.length() > 0 {
          layers[current_frame].int_value()
        } else {
          0
        }
        attach_equipment(
          entity,
          stance,
          self.flip,
          frames,
          z_layer,
          body_delays,
          loop_,
        )
      }
    }
  }

  // Skip Face Animation for Climbing
  match self.face_entity {
    Some(e) =>
      if @sprite.sprites.get(e) is Some(sprite) {
        sprite.visible = false
      }
    None => ()
  }
}
