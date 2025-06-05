///|
struct Number {
  charsets : @utils.BoolPair[@graphics.Charset]
  t : NumberType
  miss : Bool
  multiple : Bool
  first_num : Char
  rest_num : Array[Char]
  shift : Int
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
pub fn Number::draw(
  self : Number,
  viewx : Double,
  viewy : Double,
  alpha : Double
) -> Unit {
  let absolute = self.move_obj.get_absolute(viewx, viewy, alpha)
  let mut position = absolute - @struct.Point::new(0, self.shift)
  let interopc = self.opacity.get(alpha~)
  if self.miss {
    self.charsets[true].draw_char(
      'M',
      @graphics.DrawArgument::new(pos=position, opacity=interopc),
    )
  } else {
    self.charsets[false].draw_char(
      self.first_num,
      @graphics.DrawArgument::new(pos=position, opacity=interopc),
    )
    if self.multiple {
      let first_advance = get_advance(self.t, self.first_num, true)
      position = position.shift_x(first_advance)
      for i in 0..<self.rest_num.length() {
        let c = self.rest_num[i]
        let yshift = @struct.Point::new(0, if i % 2 == 0 { -2 } else { 2 })
        self.charsets[true].draw_char(
          c,
          @graphics.DrawArgument::new(pos=position + yshift, opacity=interopc),
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

///|
let fade_step : Double = @config.step_time_ms.to_double() / 500

///|
pub fn Number::update(self : Number) -> Bool {
  self.move_obj.do_move()
  self.opacity.add(-fade_step)
  self.opacity.last() <= 0.0
}

///|
pub fn Number::set_x(self : Number, headx : Int) -> Unit {
  self.move_obj.set_x(headx.to_double())
}

///|
fn get_advance(t : NumberType, c : Char, first : Bool) -> Int {
  let advances = [24, 20, 22, 22, 24, 23, 24, 22, 24, 24]
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
pub struct NumberSet {
  red_charset_pair : @utils.BoolPair[@graphics.Charset]
  cri_charset_pair : @utils.BoolPair[@graphics.Charset]
  violet_charset_pair : @utils.BoolPair[@graphics.Charset]
  blue_charset_pair : @utils.BoolPair[@graphics.Charset]
} derive(Default)

///|
pub fn NumberSet::load() -> @utils.Future[NumberSet] {
  let loader = effect_loader
  fn load_charset_pair(path0, path1) {
    loader
    .load_res(path0)
    .combine(loader.load_res(path1))
    .map(fn(res_pair) {
      @utils.BoolPair::new(
        @graphics.Charset::new(res_pair.0, @graphics.CharsetAlignment::LEFT),
        @graphics.Charset::new(res_pair.1, @graphics.CharsetAlignment::LEFT),
      )
    })
  }
  // 'No' for Number
  load_charset_pair(["BasicEff.img", "NoRed1"], ["BasicEff.img", "NoRed0"])
  .combine(
    load_charset_pair(["BasicEff.img", "NoCri1"], ["BasicEff.img", "NoCri0"]),
  )
  .combine(
    load_charset_pair(["BasicEff.img", "NoViolet1"], [
      "BasicEff.img", "NoViolet0",
    ]),
  )
  .combine(
    load_charset_pair(["BasicEff.img", "NoBlue1"], ["BasicEff.img", "NoBlue0"]),
  )
  .map(fn(it) {
    let (
      ((red_charset_pair, cri_charset_pair), violet_charset_pair),
      blue_charset_pair,
    ) = it
    {
      red_charset_pair,
      cri_charset_pair,
      violet_charset_pair,
      blue_charset_pair,
    }
  })
}

///|
pub fn new_number(
  self : NumberSet,
  t : NumberType,
  damage : Int,
  starty : Int,
  x~ : Int = 0
) -> Number {
  let charsets = match t {
    HIT_NORMAL => self.red_charset_pair
    HIT_CRITICAL => self.cri_charset_pair
    HURT => self.violet_charset_pair
    HEAL_HP => self.red_charset_pair
    HEAL_MP => self.blue_charset_pair
  }
  let (miss, shift, multiple, first_num, rest_num) = if damage > 0 {
    let number = damage.to_string().to_array()
    let first_num = number[0]
    let (rest_num, multiple) = if number.length() > 1 {
      (number[1:].to_array(), true)
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
    let shift = charsets[true].getw('M') / 2
    (true, shift, false, Char::default(), [])
  }
  let move_obj = @physics.MovingObject::default()
  move_obj.set_x(x.to_double())
  move_obj.set_y(starty.to_double())
  move_obj.vspeed = -0.25
  let opacity = @utils.Linear::new(1.5)
  { charsets, t, miss, multiple, first_num, rest_num, shift, move_obj, opacity }
}

///|
let effect_loader : @resource.AsyncLoader = @resource.AsyncLoader::new("effect")
