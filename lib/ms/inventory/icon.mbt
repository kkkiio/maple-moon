typealias Texture = @graphics.Texture

typealias DrawArgument = @graphics.DrawArgument

pub enum IconType {
  ICON_NONE
  SKILL
  EQUIP
  ITEM
  KEY
} derive(Eq, Compare)

pub fn int_value(self : IconType) -> Int {
  match self {
    IconType::ICON_NONE => 0
    IconType::SKILL => 1
    IconType::EQUIP => 2
    IconType::ITEM => 3
    IconType::KEY => 4
  }
}

pub fn hash(self : IconType) -> Int {
  self.int_value()
}

pub fn hash_combine(self : IconType, hasher : Hasher) -> Unit {
  hasher.combine(self.int_value())
}

pub trait IconTypeTrait {
  drop_on_stage(Self) -> Unit
  drop_on_equips(Self, @stat.Id) -> Unit
  drop_on_items(Self, TypeId, @stat.Id, Int, Bool) -> Bool
  drop_on_bindings(Self, @struct.Point[Int], Bool) -> Unit
  set_count(Self, Int) -> Unit
  get_type(Self) -> IconType
}

pub struct NullType {} derive(Default)

pub fn drop_on_stage(self : NullType) -> Unit {

}

pub fn drop_on_equips(self : NullType, _eqslot : @stat.Id) -> Unit {

}

pub fn drop_on_items(
  self : NullType,
  _tab : TypeId,
  _eqslot : @stat.Id,
  _slot : Int,
  _equip : Bool
) -> Bool {
  true
}

pub fn drop_on_bindings(
  self : NullType,
  _cursorposition : @struct.Point[Int],
  _remove : Bool
) -> Unit {

}

pub fn set_count(self : NullType, _count : Int) -> Unit {

}

pub fn get_type(self : NullType) -> IconType {
  IconType::ICON_NONE
}

pub struct Icon {
  t : IconTypeTrait
  show_count : Bool
  mut count : Int
  texture : Texture
  mut dragged : Bool
  mut cursor_offset : @struct.Point[Int]
}

pub fn Icon::new(t : IconTypeTrait, texture : Texture, count : Int) -> Icon {
  let icon = {
    t,
    show_count: count > -1,
    count,
    texture,
    dragged: false,
    cursor_offset: @struct.Point::default(),
  }
  icon.texture.shift(@struct.Point::new(0, 32))
  icon
}

pub fn Icon::default() -> Icon {
  Icon::new(NullType::default(), Texture::default(), -1)
}

struct LazyVar[T] {
  mut value : T?
  newf : () -> T
}

pub fn LazyVar::make[T](newf : () -> T) -> LazyVar[T] {
  { value: None, newf }
}

pub fn get[T](self : LazyVar[T]) -> T {
  match self.value {
    Some(v) => v
    None => {
      let v = (self.newf)()
      self.value = Some(v)
      v
    }
  }
}

let countset : LazyVar[@graphics.Charset] = LazyVar::make(
  fn() {
    let ui_loader = @resource.ui_loader()
    @graphics.Charset::from_resource(
      ui_loader.load_res(["Basic.img", "ItemNo"]),
      @graphics.CharsetAlignment::LEFT,
    )
  },
)

pub fn draw(self : Icon, position : @struct.Point[Int]) -> Unit {
  let opacity : Double = if self.dragged { 0.5 } else { 1.0 }
  self.get_texture().draw(DrawArgument::new7(position, opacity))
  if self.show_count {
    countset
    .get()
    .draw_text(
      self.count.to_string(),
      DrawArgument::from_point(position + @struct.Point::new(0, 20)),
    )
    |> ignore
  }
}

pub fn dragdraw(self : Icon, cursorpos : @struct.Point[Int]) -> Unit {
  if self.dragged && self.texture.is_valid() {
    self.texture.draw(DrawArgument::new7(cursorpos - self.cursor_offset, 0.5))
  }
}

pub fn drop_on_stage(self : Icon) -> Unit {
  self.t.drop_on_stage()
}

pub fn drop_on_equips(self : Icon, eqslot : @stat.Id) -> Unit {
  self.t.drop_on_equips(eqslot)
}

pub fn drop_on_items(
  self : Icon,
  tab : TypeId,
  eqslot : @stat.Id,
  slot : Int,
  equip : Bool
) -> Bool {
  if self.texture.is_valid().not() {
    return false
  }
  let remove_icon : Bool = self.t.drop_on_items(tab, eqslot, slot, equip)
  if remove_icon {
    // Sound::new(SoundName::DRAG_END).play()
  }
  remove_icon
}

pub fn drop_on_bindings(
  self : Icon,
  cursorposition : @struct.Point[Int],
  remove : Bool
) -> Unit {
  self.t.drop_on_bindings(cursorposition, remove)
}

pub fn start_drag(self : Icon, offset : @struct.Point[Int]) -> Unit {
  self.cursor_offset = offset
  self.dragged = true
  // Sound::new(SoundName::DRAG_START).play()
}

pub fn reset(self : Icon) -> Unit {
  self.dragged = false
}

pub fn get_texture(self : Icon) -> Texture {
  self.texture
}

pub fn set_count(self : Icon, count : Int) -> Unit {
  self.count = count
  self.t.set_count(count)
}

pub fn get_type(self : Icon) -> IconType {
  self.t.get_type()
}

pub fn get_count(self : Icon) -> Int {
  self.count
}

pub fn get_drag(self : Icon) -> Bool {
  self.dragged
}
