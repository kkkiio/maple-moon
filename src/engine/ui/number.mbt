///|
using @resource {type NxFrame, type NxAnimation}

///|
using @selene_math {type Vec2}

///|
/// 类似于 Charset, 但是专门用于 DamageSkin, 存储 selene @ms_animation.Picture
struct DamageSkin {
  sprites : Map[Char, @ms_animation.Animation]
}

///|
pub impl Default for DamageSkin with fn default() {
  { sprites: Map([]) }
}

///|
pub impl @json.FromJson for DamageSkin with fn from_json(json, path) {
  let sprites = Map([])
  guard json is Object(obj) else { return { sprites, } }
  for name, sub in obj {
    guard sub is { "__i": String(_), .. } else { continue }
    guard name.length() == 1 else { continue }
    let c = name.to_array()[0]
    try {
      let tex : @resource.NxTexture = @json.from_json(
        sub,
        path=path.add_key(name),
      )
      // Wrap texture into an animation since single frames need to support offsets
      let frame = NxFrame::{
        texture: tex,
        delay: None,
        head: None,
        bounds: None,
      }
      let anim = NxAnimation::{ frames: [frame], blend: false, zigzag: false }
      let pic = @ms_animation.from_nx_animation(anim)
      sprites.set(c, pic)
    } catch {
      _ => ()
    }
  }
  { sprites, }
}

///|
fn DamageSkin::get_width(self : DamageSkin, c : Char) -> Int {
  match self.sprites.get(c) {
    Some(anim) => @ms_animation.animation_dimensions(anim).0.to_int()
    None => 0
  }
}

///|
// Global registry for active numbers
let active_numbers : Array[Number] = []

///|
pub fn number_system(_world : @ecs.World) -> Unit {
  let delta = @cmp.minimum(@time.delta(), max_number_delta_sec)
  active_numbers.retain(fn(num) {
    let finished = num.update(delta)
    if finished {
      false
    } else {
      true
    }
  })
}

///|
struct Number {
  parent_entity : @entity.Entity
  move_obj : @physics.MovingObject
  opacity : @utils.Linear
}

///|
pub(all) enum NumberType {
  HIT_NORMAL
  HIT_CRITICAL
  HURT
  HEAL_HP
  HEAL_MP
}

///|
// Internal update logic
fn Number::update(self : Number, delta : Double) -> Bool {
  let next_y = self.move_obj.crnt_y() + rise_speed_per_sec * delta
  self.move_obj.set_y(next_y)

  // Update opacity/lifetime
  self.opacity.add(-fade_per_sec * delta)
  let finished = self.opacity.last() <= 0.0
  if finished {
    self.parent_entity.destroy()
  } else {
    // Update position (World Coordinates)
    // move_obj stores world coordinates. get_absolute adds view offset which we DON'T want for selene entities.
    let x = self.move_obj.crnt_x()
    let y = self.move_obj.crnt_y()
    let pos_vec = @selene_math.Vec2(x, y)
    @transform2d.set_xy(self.parent_entity, pos_vec)
  }
  finished
}

///|
let rise_speed_per_sec : Double = -31.25

///|
let fade_per_sec : Double = 2.0

///|
let max_number_delta_sec : Double = 0.05

///|
pub fn Number::set_x(self : Number, headx : Int) -> Unit {
  self.move_obj.set_x(headx.to_double())
}

///|
fn get_advance(t : NumberType, c : Char, first : Bool) -> Int {
  let advances : ReadOnlyArray[Int] = [24, 20, 22, 22, 24, 23, 24, 22, 24, 24]
  let index = c.to_int() - 48
  if index < advances.length() {
    let mut advance = advances[index]
    match t {
      HIT_CRITICAL => if first { advance += 8 } else { advance += 4 }
      _ => if first { advance += 2 }
    }
    return advance
  }
  return 0
}

///|
pub fn Number::row_height(critical : Bool) -> Int {
  if critical {
    36
  } else {
    30
  }
}

///|
/// 存储大号和小号两种尺寸的 DamageSkin
pub(all) struct Skins {
  big : DamageSkin
  small : DamageSkin
} derive(Default)

///|
pub(all) struct NumberSet {
  red_skins : Skins
  cri_skins : Skins
  violet_skins : Skins
  blue_skins : Skins
} derive(Default)

///|
pub fn NumberSet::load() -> NumberSet {
  // 'No' for Number
  let no_red_1 = load_damage_skin("NoRed1")
  let no_red_0 = load_damage_skin("NoRed0")
  let no_cri_1 = load_damage_skin("NoCri1")
  let no_cri_0 = load_damage_skin("NoCri0")
  let no_violet_1 = load_damage_skin("NoViolet1")
  let no_violet_0 = load_damage_skin("NoViolet0")
  let no_blue_1 = load_damage_skin("NoBlue1")
  let no_blue_0 = load_damage_skin("NoBlue0")
  let red_skins : Skins = { big: no_red_1, small: no_red_0 }
  let cri_skins : Skins = { big: no_cri_1, small: no_cri_0 }
  let violet_skins : Skins = { big: no_violet_1, small: no_violet_0 }
  let blue_skins : Skins = { big: no_blue_1, small: no_blue_0 }
  { red_skins, cri_skins, violet_skins, blue_skins }
}

///|
fn load_damage_skin(name : String) -> DamageSkin {
  (@resource.require_json("assets/Effect/BasicEff.img/" + name + ".json")
  |> @json.from_json) catch {
    _ => abort("invalid damage skin resource: BasicEff.img/\{name}")
  }
}

///|
/// 显示漂浮数字（如伤害值、治疗量等）. 样式包括多种颜色, 居中, 数字交错跳动, 缓慢向上飘动, 淡出.
/// 
/// 如果数值 (<= 0)，显示 "MISS"（通过 DamageSkin 中的 'M' 字符对应的图片）。
pub fn NumberSet::show_number(
  self : NumberSet,
  t : NumberType,
  damage : Int,
  starty : Int,
  x? : Int = 0,
) -> Unit {
  let skins = match t {
    HIT_NORMAL => self.red_skins
    HIT_CRITICAL => self.cri_skins
    HURT => self.violet_skins
    HEAL_HP => self.red_skins
    HEAL_MP => self.blue_skins
  }

  // Calculate layout first (unchanged logic)
  let (miss, shift, multiple, first_num, rest_num) = if damage > 0 {
    let number = damage.to_string().to_array()
    let first_num = number[0]
    let (rest_num, multiple) = if number.length() > 1 {
      (number[1:], true)
    } else {
      ([], false)
    }
    let mut total = get_advance(t, first_num, true)
    for i in 0..<rest_num.length() {
      let c = rest_num[i]
      let advance = if i < rest_num.length() - 1 {
        let n = rest_num[i + 1]
        (get_advance(t, c, false) + get_advance(t, n, false)) / 2
      } else {
        get_advance(t, c, false)
      }
      total += advance
    }
    let shift = total / 2
    (false, shift, multiple, first_num, rest_num)
  } else {
    let shift = skins.small.get_width('M') / 2
    (true, shift, false, Char::default(), [])
  }

  // Create Parent Entity
  let parent_entity = @entity.Entity()
  @transform2d.set_xy(parent_entity, Vec2::zero())

  // Spawn Children
  let start_offset = Point(0, -shift)
  let mut current_offset = start_offset
  fn spawn_sprite(skin : DamageSkin, c : Char, offset : @struct.Point[Int]) {
    match skin.sprites.get(c) {
      Some(anim) => {
        let offset_vec = @selene_math.Vec2(
          offset.x.to_double(),
          offset.y.to_double(),
        )
        let child = parent_entity.spawn_child()
        @transform2d.set_xy(child, offset_vec)
        let sprite = @ms_animation.sprite_from_animation(
          anim,
          @graphics.DAMAGE_NUMBER_ZINDEX,
        )
        @sprite.sprites().set(child, sprite)
      }
      None => ()
    }
  }

  if miss {
    spawn_sprite(skins.small, 'M', current_offset)
  } else {
    spawn_sprite(skins.big, first_num, current_offset)
    if multiple {
      let first_advance = get_advance(t, first_num, true)
      current_offset = current_offset.shift_x(first_advance)
      for i in 0..<rest_num.length() {
        let c = rest_num[i]
        let yshift = Point(0, if i % 2 == 0 { -2 } else { 2 })
        spawn_sprite(skins.small, rest_num[i], current_offset + yshift)
        let advance = if i < rest_num.length() - 1 {
          let n = rest_num[i + 1]
          let c_advance = get_advance(t, c, false)
          let n_advance = get_advance(t, n, false)
          (c_advance + n_advance) / 2
        } else {
          get_advance(t, c, false)
        }
        current_offset = current_offset.shift_x(advance)
      }
    }
  }
  let move_obj = MovingObject(on_pos_change=fn(_) {
    // TODO
  })
  move_obj.set_x(x.to_double())
  move_obj.set_y(starty.to_double())
  let opacity = Linear(1.5)
  let number = { parent_entity, move_obj, opacity }
  active_numbers.push(number)
}

///|
using @physics {type MovingObject}

///|
using @utils {type Linear}
