struct DamageNumber {
  charsets : FixedArray[@utils.BoolPair[@graphics.Charset]]
  t : DamageNumberType
  miss : Bool
  multiple : Bool
  first_num : Char
  rest_num : String
  shift : Int
  move_obj : @physics.MovingObject
  opacity : @utils.Linear
}

pub enum DamageNumberType {
  NORMAL
  CRITICAL
  TOPLAYER
}

pub fn int_value(self : DamageNumberType) -> Int {
  match self {
    NORMAL => 0
    CRITICAL => 1
    TOPLAYER => 2
  }
}

pub fn DamageNumber::draw(
  self : DamageNumber,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  let absolute = self.move_obj.get_absolute(viewx, viewy, alpha)
  let mut position = absolute - @struct.Point::new(0, self.shift)
  let interopc = self.opacity.get(~alpha)
  if self.miss {
    self.charsets[self.t.int_value()][true].draw_char(
      'M',
      @graphics.DrawArgument::new(position, opacity=interopc),
    )
  } else {
    self.charsets[self.t.int_value()][false].draw_char(
      self.first_num,
      @graphics.DrawArgument::new(position, opacity=interopc),
    )
    if self.multiple {
      let first_advance = get_advance(self.t, self.first_num, true)
      position = position.shift_x(first_advance)
      for i in 0..<self.rest_num.length() {
        let c = self.rest_num[i]
        let yshift = @struct.Point::new(0, if i % 2 == 0 { -2 } else { 2 })
        self.charsets[self.t.int_value()][true].draw_char(
          c,
          @graphics.DrawArgument::new(position + yshift, opacity=interopc),
        )
        let advance = if i < self.rest_num.length() - 1 {
          let n = self.rest_num[i + 1]
          let c_advance = get_advance(self.t, c, false)
          let n_advance = get_advance(self.t, n, false)
          (c_advance + n_advance) / 2
        } else {
          get_advance(self.t, c, false)
        }
        position = position.shift_x(advance)
      }
    }
  }
}

let fade_step : Double = @constants.timestep.to_double() / 500

pub fn update(self : DamageNumber) -> Bool {
  self.move_obj.move()
  self.opacity.add(-fade_step)
  self.opacity.last() <= 0.0
}

pub fn DamageNumber::set_x(self : DamageNumber, headx : Int) -> Unit {
  self.move_obj.set_x(headx.to_double())
}

fn get_advance(t : DamageNumberType, c : Char, first : Bool) -> Int {
  let advances = [24, 20, 22, 22, 24, 23, 24, 22, 24, 24]
  let index = c.to_int() - 48
  if index < advances.length() {
    let mut advance = advances[index]
    match t {
      CRITICAL => if first { advance += 8 } else { advance += 4 }
      _ => if first { advance += 2 }
    }
    return advance
  }
  return 0
}

pub fn DamageNumber::row_height(critical : Bool) -> Int {
  if critical {
    36
  } else {
    30
  }
}

struct DamageNumberSet {
  charsets : FixedArray[@utils.BoolPair[@graphics.Charset]]
}

pub fn DamageNumberSet::new() -> DamageNumberSet {
  let loader = effect_loader()
  let charsets = [
      @utils.BoolPair::new(
        @graphics.Charset::new(
          loader.load_res(["BasicEff.img", "NoRed1"]),
          @graphics.CharsetAlignment::LEFT,
        ),
        @graphics.Charset::new(
          loader.load_res(["BasicEff.img", "NoRed0"]),
          @graphics.CharsetAlignment::LEFT,
        ),
      ),
      @utils.BoolPair::new(
        @graphics.Charset::new(
          loader.load_res(["BasicEff.img", "NoCri1"]),
          @graphics.CharsetAlignment::LEFT,
        ),
        @graphics.Charset::new(
          loader.load_res(["BasicEff.img", "NoCri0"]),
          @graphics.CharsetAlignment::LEFT,
        ),
      ),
      @utils.BoolPair::new(
        @graphics.Charset::new(
          loader.load_res(["BasicEff.img", "NoViolet1"]),
          @graphics.CharsetAlignment::LEFT,
        ),
        @graphics.Charset::new(
          loader.load_res(["BasicEff.img", "NoViolet0"]),
          @graphics.CharsetAlignment::LEFT,
        ),
      ),
    ]
    |> FixedArray::from_array
  { charsets, }
}

pub fn new_damage_number(
  self : DamageNumberSet,
  t : DamageNumberType,
  damage : Int,
  starty : Int,
  ~x : Int = 0
) -> DamageNumber {
  let (miss, shift, multiple, first_num, rest_num) = if damage > 0 {
    let number = damage.to_string()
    let first_num = number[0]
    let (rest_num, multiple) = if number.length() > 1 {
      (number.substring(start=1), true)
    } else {
      ("", false)
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
    let shift = self.charsets[t.int_value()][true].getw('M') / 2
    (true, shift, false, Char::default(), "")
  }
  let move_obj = @physics.MovingObject::default()
  move_obj.set_x(x.to_double())
  move_obj.set_y(starty.to_double())
  move_obj.vspeed = -0.25
  let opacity = @utils.Linear::new(1.5)
  {
    charsets: self.charsets,
    t,
    miss,
    multiple,
    first_num,
    rest_num,
    shift,
    move_obj,
    opacity,
  }
}

pub fn effect_loader() -> @resource.Loader {
  @resource.Loader::new("effect")
}
