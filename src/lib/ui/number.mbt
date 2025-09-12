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
  alpha : Double,
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
pub fn NumberSet::load() -> NumberSet raise {
  fn load_charset_pair(res0, res1) raise {
    @utils.BoolPair::new(
      @graphics.Charset::new(res0, @graphics.CharsetAlignment::LEFT),
      @graphics.Charset::new(res1, @graphics.CharsetAlignment::LEFT),
    )
  }
  // 'No' for Number
  let no_red1 : Json = {
    "0": {
      "__h": 38,
      "__w": 37,
      "origin": [18, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoRed1#1749",
    },
    "1": {
      "__h": 37,
      "__w": 25,
      "origin": [12, 36],
      "__i": "spritesheets/Effect/BasicEff.img/NoRed1#1750",
    },
    "2": {
      "__h": 38,
      "__w": 34,
      "origin": [17, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoRed1#1751",
    },
    "3": {
      "__h": 38,
      "__w": 33,
      "origin": [16, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoRed1#1752",
    },
    "4": {
      "__h": 37,
      "__w": 36,
      "origin": [18, 36],
      "__i": "spritesheets/Effect/BasicEff.img/NoRed1#1753",
    },
    "5": {
      "__h": 38,
      "__w": 34,
      "origin": [17, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoRed1#1754",
    },
    "6": {
      "__h": 38,
      "__w": 36,
      "origin": [18, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoRed1#1755",
    },
    "7": {
      "__h": 38,
      "__w": 33,
      "origin": [16, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoRed1#1756",
    },
    "8": {
      "__h": 39,
      "__w": 36,
      "origin": [18, 38],
      "__i": "spritesheets/Effect/BasicEff.img/NoRed1#1757",
    },
    "9": {
      "__h": 38,
      "__w": 36,
      "origin": [18, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoRed1#1758",
    },
  }
  let no_red0 : Json = {
    "0": {
      "__h": 33,
      "__w": 31,
      "origin": [15, 32],
      "__i": "spritesheets/Effect/BasicEff.img/NoRed0#1738",
    },
    "1": {
      "__h": 32,
      "__w": 22,
      "origin": [11, 31],
      "__i": "spritesheets/Effect/BasicEff.img/NoRed0#1739",
    },
    "2": {
      "__h": 33,
      "__w": 29,
      "origin": [14, 32],
      "__i": "spritesheets/Effect/BasicEff.img/NoRed0#1740",
    },
    "3": {
      "__h": 32,
      "__w": 28,
      "origin": [14, 31],
      "__i": "spritesheets/Effect/BasicEff.img/NoRed0#1741",
    },
    "4": {
      "__h": 33,
      "__w": 31,
      "origin": [15, 32],
      "__i": "spritesheets/Effect/BasicEff.img/NoRed0#1742",
    },
    "5": {
      "__h": 32,
      "__w": 29,
      "origin": [14, 31],
      "__i": "spritesheets/Effect/BasicEff.img/NoRed0#1743",
    },
    "6": {
      "__h": 33,
      "__w": 31,
      "origin": [15, 32],
      "__i": "spritesheets/Effect/BasicEff.img/NoRed0#1744",
    },
    "7": {
      "__h": 32,
      "__w": 29,
      "origin": [14, 31],
      "__i": "spritesheets/Effect/BasicEff.img/NoRed0#1745",
    },
    "8": {
      "__h": 33,
      "__w": 31,
      "origin": [15, 32],
      "__i": "spritesheets/Effect/BasicEff.img/NoRed0#1746",
    },
    "9": {
      "__h": 33,
      "__w": 31,
      "origin": [15, 32],
      "__i": "spritesheets/Effect/BasicEff.img/NoRed0#1747",
    },
    "Miss": {
      "__h": 38,
      "__w": 98,
      "origin": [49, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoRed0#1748",
    },
  }
  let no_cri1 : Json = {
    "0": {
      "__h": 48,
      "__w": 43,
      "origin": [21, 45],
      "__i": "spritesheets/Effect/BasicEff.img/NoCri1#1727",
    },
    "1": {
      "__h": 44,
      "__w": 29,
      "origin": [14, 43],
      "__i": "spritesheets/Effect/BasicEff.img/NoCri1#1728",
    },
    "2": {
      "__h": 45,
      "__w": 40,
      "origin": [20, 44],
      "__i": "spritesheets/Effect/BasicEff.img/NoCri1#1729",
    },
    "3": {
      "__h": 46,
      "__w": 40,
      "origin": [20, 45],
      "__i": "spritesheets/Effect/BasicEff.img/NoCri1#1730",
    },
    "4": {
      "__h": 45,
      "__w": 43,
      "origin": [21, 44],
      "__i": "spritesheets/Effect/BasicEff.img/NoCri1#1731",
    },
    "5": {
      "__h": 46,
      "__w": 39,
      "origin": [19, 45],
      "__i": "spritesheets/Effect/BasicEff.img/NoCri1#1732",
    },
    "6": {
      "__h": 45,
      "__w": 43,
      "origin": [21, 44],
      "__i": "spritesheets/Effect/BasicEff.img/NoCri1#1733",
    },
    "7": {
      "__h": 45,
      "__w": 40,
      "origin": [20, 44],
      "__i": "spritesheets/Effect/BasicEff.img/NoCri1#1734",
    },
    "8": {
      "__h": 46,
      "__w": 41,
      "origin": [20, 45],
      "__i": "spritesheets/Effect/BasicEff.img/NoCri1#1735",
    },
    "9": {
      "__h": 46,
      "__w": 42,
      "origin": [21, 45],
      "__i": "spritesheets/Effect/BasicEff.img/NoCri1#1736",
    },
    "effect": {
      "__h": 57,
      "__w": 62,
      "origin": [41, 70],
      "__i": "spritesheets/Effect/BasicEff.img/NoCri1#1737",
    },
  }
  let no_cri0 : Json = {
    "0": {
      "__h": 38,
      "__w": 37,
      "origin": [18, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoCri0#1717",
    },
    "1": {
      "__h": 38,
      "__w": 25,
      "origin": [12, 36],
      "__i": "spritesheets/Effect/BasicEff.img/NoCri0#1718",
    },
    "2": {
      "__h": 38,
      "__w": 34,
      "origin": [17, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoCri0#1719",
    },
    "3": {
      "__h": 38,
      "__w": 33,
      "origin": [16, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoCri0#1720",
    },
    "4": {
      "__h": 38,
      "__w": 37,
      "origin": [18, 36],
      "__i": "spritesheets/Effect/BasicEff.img/NoCri0#1721",
    },
    "5": {
      "__h": 38,
      "__w": 33,
      "origin": [17, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoCri0#1722",
    },
    "6": {
      "__h": 38,
      "__w": 37,
      "origin": [18, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoCri0#1723",
    },
    "7": {
      "__h": 38,
      "__w": 33,
      "origin": [16, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoCri0#1724",
    },
    "8": {
      "__h": 39,
      "__w": 34,
      "origin": [18, 38],
      "__i": "spritesheets/Effect/BasicEff.img/NoCri0#1725",
    },
    "9": {
      "__h": 38,
      "__w": 36,
      "origin": [18, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoCri0#1726",
    },
  }
  let no_violet1 : Json = {
    "0": {
      "__h": 38,
      "__w": 37,
      "origin": [18, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoViolet1#1770",
    },
    "1": {
      "__h": 37,
      "__w": 25,
      "origin": [12, 36],
      "__i": "spritesheets/Effect/BasicEff.img/NoViolet1#1771",
    },
    "2": {
      "__h": 38,
      "__w": 34,
      "origin": [17, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoViolet1#1772",
    },
    "3": {
      "__h": 38,
      "__w": 33,
      "origin": [16, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoViolet1#1773",
    },
    "4": {
      "__h": 37,
      "__w": 36,
      "origin": [18, 36],
      "__i": "spritesheets/Effect/BasicEff.img/NoViolet1#1774",
    },
    "5": {
      "__h": 38,
      "__w": 34,
      "origin": [17, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoViolet1#1775",
    },
    "6": {
      "__h": 38,
      "__w": 36,
      "origin": [18, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoViolet1#1776",
    },
    "7": {
      "__h": 38,
      "__w": 33,
      "origin": [16, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoViolet1#1777",
    },
    "8": {
      "__h": 39,
      "__w": 36,
      "origin": [18, 38],
      "__i": "spritesheets/Effect/BasicEff.img/NoViolet1#1778",
    },
    "9": {
      "__h": 38,
      "__w": 36,
      "origin": [18, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoViolet1#1779",
    },
  }
  let no_violet0 : Json = {
    "0": {
      "__h": 33,
      "__w": 31,
      "origin": [15, 32],
      "__i": "spritesheets/Effect/BasicEff.img/NoViolet0#1759",
    },
    "1": {
      "__h": 32,
      "__w": 22,
      "origin": [11, 31],
      "__i": "spritesheets/Effect/BasicEff.img/NoViolet0#1760",
    },
    "2": {
      "__h": 33,
      "__w": 29,
      "origin": [14, 32],
      "__i": "spritesheets/Effect/BasicEff.img/NoViolet0#1761",
    },
    "3": {
      "__h": 32,
      "__w": 28,
      "origin": [14, 31],
      "__i": "spritesheets/Effect/BasicEff.img/NoViolet0#1762",
    },
    "4": {
      "__h": 33,
      "__w": 31,
      "origin": [15, 32],
      "__i": "spritesheets/Effect/BasicEff.img/NoViolet0#1763",
    },
    "5": {
      "__h": 32,
      "__w": 29,
      "origin": [14, 31],
      "__i": "spritesheets/Effect/BasicEff.img/NoViolet0#1764",
    },
    "6": {
      "__h": 33,
      "__w": 31,
      "origin": [15, 32],
      "__i": "spritesheets/Effect/BasicEff.img/NoViolet0#1765",
    },
    "7": {
      "__h": 32,
      "__w": 29,
      "origin": [14, 31],
      "__i": "spritesheets/Effect/BasicEff.img/NoViolet0#1766",
    },
    "8": {
      "__h": 33,
      "__w": 31,
      "origin": [15, 32],
      "__i": "spritesheets/Effect/BasicEff.img/NoViolet0#1767",
    },
    "9": {
      "__h": 33,
      "__w": 31,
      "origin": [15, 32],
      "__i": "spritesheets/Effect/BasicEff.img/NoViolet0#1768",
    },
    "Miss": {
      "__h": 38,
      "__w": 98,
      "origin": [49, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoViolet0#1769",
    },
  }
  let no_blue1 : Json = {
    "0": {
      "__h": 38,
      "__w": 37,
      "origin": [18, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoBlue1#1707",
    },
    "1": {
      "__h": 37,
      "__w": 25,
      "origin": [12, 36],
      "__i": "spritesheets/Effect/BasicEff.img/NoBlue1#1708",
    },
    "2": {
      "__h": 38,
      "__w": 34,
      "origin": [17, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoBlue1#1709",
    },
    "3": {
      "__h": 38,
      "__w": 33,
      "origin": [16, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoBlue1#1710",
    },
    "4": {
      "__h": 37,
      "__w": 36,
      "origin": [18, 36],
      "__i": "spritesheets/Effect/BasicEff.img/NoBlue1#1711",
    },
    "5": {
      "__h": 38,
      "__w": 34,
      "origin": [17, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoBlue1#1712",
    },
    "6": {
      "__h": 38,
      "__w": 36,
      "origin": [18, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoBlue1#1713",
    },
    "7": {
      "__h": 38,
      "__w": 33,
      "origin": [16, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoBlue1#1714",
    },
    "8": {
      "__h": 39,
      "__w": 36,
      "origin": [18, 38],
      "__i": "spritesheets/Effect/BasicEff.img/NoBlue1#1715",
    },
    "9": {
      "__h": 38,
      "__w": 36,
      "origin": [18, 37],
      "__i": "spritesheets/Effect/BasicEff.img/NoBlue1#1716",
    },
  }
  let no_blue0 : Json = {
    "0": {
      "__h": 33,
      "__w": 31,
      "origin": [15, 32],
      "__i": "spritesheets/Effect/BasicEff.img/NoBlue0#1697",
    },
    "1": {
      "__h": 32,
      "__w": 22,
      "origin": [11, 31],
      "__i": "spritesheets/Effect/BasicEff.img/NoBlue0#1698",
    },
    "2": {
      "__h": 33,
      "__w": 29,
      "origin": [14, 32],
      "__i": "spritesheets/Effect/BasicEff.img/NoBlue0#1699",
    },
    "3": {
      "__h": 32,
      "__w": 28,
      "origin": [14, 31],
      "__i": "spritesheets/Effect/BasicEff.img/NoBlue0#1700",
    },
    "4": {
      "__h": 33,
      "__w": 31,
      "origin": [15, 32],
      "__i": "spritesheets/Effect/BasicEff.img/NoBlue0#1701",
    },
    "5": {
      "__h": 32,
      "__w": 29,
      "origin": [14, 31],
      "__i": "spritesheets/Effect/BasicEff.img/NoBlue0#1702",
    },
    "6": {
      "__h": 33,
      "__w": 31,
      "origin": [15, 32],
      "__i": "spritesheets/Effect/BasicEff.img/NoBlue0#1703",
    },
    "7": {
      "__h": 32,
      "__w": 29,
      "origin": [14, 31],
      "__i": "spritesheets/Effect/BasicEff.img/NoBlue0#1704",
    },
    "8": {
      "__h": 33,
      "__w": 31,
      "origin": [15, 32],
      "__i": "spritesheets/Effect/BasicEff.img/NoBlue0#1705",
    },
    "9": {
      "__h": 33,
      "__w": 31,
      "origin": [15, 32],
      "__i": "spritesheets/Effect/BasicEff.img/NoBlue0#1706",
    },
  }
  let spritesheet_jsons : Map[String, @resource.SpritesheetMetadata] = {
    "spritesheets/Effect/BasicEff.img/NoRed1": @json.from_json(
      no_red1_spritesheet_json,
    ),
    "spritesheets/Effect/BasicEff.img/NoRed0": @json.from_json(
      no_red0_spritesheet_json,
    ),
    "spritesheets/Effect/BasicEff.img/NoCri1": @json.from_json(
      no_cri1_spritesheet_json,
    ),
    "spritesheets/Effect/BasicEff.img/NoCri0": @json.from_json(
      no_cri0_spritesheet_json,
    ),
    "spritesheets/Effect/BasicEff.img/NoViolet1": @json.from_json(
      no_violet1_spritesheet_json,
    ),
    "spritesheets/Effect/BasicEff.img/NoViolet0": @json.from_json(
      no_violet0_spritesheet_json,
    ),
    "spritesheets/Effect/BasicEff.img/NoBlue1": @json.from_json(
      no_blue1_spritesheet_json,
    ),
    "spritesheets/Effect/BasicEff.img/NoBlue0": @json.from_json(
      no_blue0_spritesheet_json,
    ),
  }
  let red_charset_pair = load_charset_pair(
    @resource.patch_spritesheet_json(no_red1, spritesheet_jsons),
    @resource.patch_spritesheet_json(no_red0, spritesheet_jsons),
  )
  let cri_charset_pair = load_charset_pair(
    @resource.patch_spritesheet_json(no_cri1, spritesheet_jsons),
    @resource.patch_spritesheet_json(no_cri0, spritesheet_jsons),
  )
  let violet_charset_pair = load_charset_pair(
    @resource.patch_spritesheet_json(no_violet1, spritesheet_jsons),
    @resource.patch_spritesheet_json(no_violet0, spritesheet_jsons),
  )
  let blue_charset_pair = load_charset_pair(
    @resource.patch_spritesheet_json(no_blue1, spritesheet_jsons),
    @resource.patch_spritesheet_json(no_blue0, spritesheet_jsons),
  )
  { red_charset_pair, cri_charset_pair, violet_charset_pair, blue_charset_pair }
}

///|
pub fn new_number(
  self : NumberSet,
  t : NumberType,
  damage : Int,
  starty : Int,
  x? : Int = 0,
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
let no_red1_spritesheet_json : Json = {
  "meta": {
    "image": "NoRed1.png",
    "size": { "w": 142, "h": 114 },
    "scale": "1",
  },
  "frames": {
    "1757.png": {
      "frame": { "x": 0, "y": 0, "w": 36, "h": 39 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 36, "h": 39 },
      "sourceSize": { "w": 36, "h": 39 },
    },
    "1749.png": {
      "frame": { "x": 36, "y": 0, "w": 37, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 37, "h": 38 },
      "sourceSize": { "w": 37, "h": 38 },
    },
    "1755.png": {
      "frame": { "x": 73, "y": 0, "w": 36, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 36, "h": 38 },
      "sourceSize": { "w": 36, "h": 38 },
    },
    "1758.png": {
      "frame": { "x": 0, "y": 39, "w": 36, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 36, "h": 38 },
      "sourceSize": { "w": 36, "h": 38 },
    },
    "1751.png": {
      "frame": { "x": 36, "y": 39, "w": 34, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 34, "h": 38 },
      "sourceSize": { "w": 34, "h": 38 },
    },
    "1754.png": {
      "frame": { "x": 70, "y": 39, "w": 34, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 34, "h": 38 },
      "sourceSize": { "w": 34, "h": 38 },
    },
    "1752.png": {
      "frame": { "x": 109, "y": 0, "w": 33, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 33, "h": 38 },
      "sourceSize": { "w": 33, "h": 38 },
    },
    "1756.png": {
      "frame": { "x": 109, "y": 38, "w": 33, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 33, "h": 38 },
      "sourceSize": { "w": 33, "h": 38 },
    },
    "1753.png": {
      "frame": { "x": 0, "y": 77, "w": 36, "h": 37 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 36, "h": 37 },
      "sourceSize": { "w": 36, "h": 37 },
    },
    "1750.png": {
      "frame": { "x": 36, "y": 77, "w": 25, "h": 37 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 25, "h": 37 },
      "sourceSize": { "w": 25, "h": 37 },
    },
  },
}

///|
let no_red0_spritesheet_json : Json = {
  "meta": {
    "image": "NoRed0.png",
    "size": { "w": 151, "h": 104 },
    "scale": "1",
  },
  "frames": {
    "1748.png": {
      "frame": { "x": 0, "y": 0, "w": 98, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 98, "h": 38 },
      "sourceSize": { "w": 98, "h": 38 },
    },
    "1738.png": {
      "frame": { "x": 0, "y": 38, "w": 31, "h": 33 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 31, "h": 33 },
      "sourceSize": { "w": 31, "h": 33 },
    },
    "1742.png": {
      "frame": { "x": 31, "y": 38, "w": 31, "h": 33 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 31, "h": 33 },
      "sourceSize": { "w": 31, "h": 33 },
    },
    "1744.png": {
      "frame": { "x": 62, "y": 38, "w": 31, "h": 33 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 31, "h": 33 },
      "sourceSize": { "w": 31, "h": 33 },
    },
    "1746.png": {
      "frame": { "x": 98, "y": 0, "w": 31, "h": 33 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 31, "h": 33 },
      "sourceSize": { "w": 31, "h": 33 },
    },
    "1747.png": {
      "frame": { "x": 98, "y": 33, "w": 31, "h": 33 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 31, "h": 33 },
      "sourceSize": { "w": 31, "h": 33 },
    },
    "1740.png": {
      "frame": { "x": 0, "y": 71, "w": 29, "h": 33 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 29, "h": 33 },
      "sourceSize": { "w": 29, "h": 33 },
    },
    "1743.png": {
      "frame": { "x": 29, "y": 71, "w": 29, "h": 32 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 29, "h": 32 },
      "sourceSize": { "w": 29, "h": 32 },
    },
    "1745.png": {
      "frame": { "x": 58, "y": 71, "w": 29, "h": 32 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 29, "h": 32 },
      "sourceSize": { "w": 29, "h": 32 },
    },
    "1741.png": {
      "frame": { "x": 87, "y": 71, "w": 28, "h": 32 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 28, "h": 32 },
      "sourceSize": { "w": 28, "h": 32 },
    },
    "1739.png": {
      "frame": { "x": 129, "y": 0, "w": 22, "h": 32 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 22, "h": 32 },
      "sourceSize": { "w": 22, "h": 32 },
    },
  },
}

///|
let no_cri1_spritesheet_json : Json = {
  "meta": {
    "image": "NoCri1.png",
    "size": { "w": 188, "h": 148 },
    "scale": "1",
  },
  "frames": {
    "1737.png": {
      "frame": { "x": 0, "y": 0, "w": 62, "h": 57 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 62, "h": 57 },
      "sourceSize": { "w": 62, "h": 57 },
    },
    "1727.png": {
      "frame": { "x": 62, "y": 0, "w": 43, "h": 48 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 43, "h": 48 },
      "sourceSize": { "w": 43, "h": 48 },
    },
    "1736.png": {
      "frame": { "x": 0, "y": 57, "w": 42, "h": 46 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 42, "h": 46 },
      "sourceSize": { "w": 42, "h": 46 },
    },
    "1735.png": {
      "frame": { "x": 42, "y": 57, "w": 41, "h": 46 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 41, "h": 46 },
      "sourceSize": { "w": 41, "h": 46 },
    },
    "1730.png": {
      "frame": { "x": 105, "y": 0, "w": 40, "h": 46 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 40, "h": 46 },
      "sourceSize": { "w": 40, "h": 46 },
    },
    "1732.png": {
      "frame": { "x": 105, "y": 46, "w": 39, "h": 46 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 39, "h": 46 },
      "sourceSize": { "w": 39, "h": 46 },
    },
    "1731.png": {
      "frame": { "x": 145, "y": 0, "w": 43, "h": 45 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 43, "h": 45 },
      "sourceSize": { "w": 43, "h": 45 },
    },
    "1733.png": {
      "frame": { "x": 145, "y": 45, "w": 43, "h": 45 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 43, "h": 45 },
      "sourceSize": { "w": 43, "h": 45 },
    },
    "1729.png": {
      "frame": { "x": 0, "y": 103, "w": 40, "h": 45 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 40, "h": 45 },
      "sourceSize": { "w": 40, "h": 45 },
    },
    "1734.png": {
      "frame": { "x": 40, "y": 103, "w": 40, "h": 45 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 40, "h": 45 },
      "sourceSize": { "w": 40, "h": 45 },
    },
    "1728.png": {
      "frame": { "x": 80, "y": 103, "w": 29, "h": 44 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 29, "h": 44 },
      "sourceSize": { "w": 29, "h": 44 },
    },
  },
}

///|
let no_cri0_spritesheet_json : Json = {
  "meta": {
    "image": "NoCri0.png",
    "size": { "w": 141, "h": 115 },
    "scale": "1",
  },
  "frames": {
    "1725.png": {
      "frame": { "x": 0, "y": 0, "w": 34, "h": 39 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 34, "h": 39 },
      "sourceSize": { "w": 34, "h": 39 },
    },
    "1717.png": {
      "frame": { "x": 34, "y": 0, "w": 37, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 37, "h": 38 },
      "sourceSize": { "w": 37, "h": 38 },
    },
    "1721.png": {
      "frame": { "x": 71, "y": 0, "w": 37, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 37, "h": 38 },
      "sourceSize": { "w": 37, "h": 38 },
    },
    "1723.png": {
      "frame": { "x": 0, "y": 39, "w": 37, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 37, "h": 38 },
      "sourceSize": { "w": 37, "h": 38 },
    },
    "1726.png": {
      "frame": { "x": 37, "y": 39, "w": 36, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 36, "h": 38 },
      "sourceSize": { "w": 36, "h": 38 },
    },
    "1719.png": {
      "frame": { "x": 73, "y": 39, "w": 34, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 34, "h": 38 },
      "sourceSize": { "w": 34, "h": 38 },
    },
    "1720.png": {
      "frame": { "x": 108, "y": 0, "w": 33, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 33, "h": 38 },
      "sourceSize": { "w": 33, "h": 38 },
    },
    "1722.png": {
      "frame": { "x": 108, "y": 38, "w": 33, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 33, "h": 38 },
      "sourceSize": { "w": 33, "h": 38 },
    },
    "1724.png": {
      "frame": { "x": 0, "y": 77, "w": 33, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 33, "h": 38 },
      "sourceSize": { "w": 33, "h": 38 },
    },
    "1718.png": {
      "frame": { "x": 33, "y": 77, "w": 25, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 25, "h": 38 },
      "sourceSize": { "w": 25, "h": 38 },
    },
  },
}

///|
let no_violet1_spritesheet_json : Json = {
  "meta": {
    "image": "NoViolet1.png",
    "size": { "w": 142, "h": 114 },
    "scale": "1",
  },
  "frames": {
    "1778.png": {
      "frame": { "x": 0, "y": 0, "w": 36, "h": 39 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 36, "h": 39 },
      "sourceSize": { "w": 36, "h": 39 },
    },
    "1770.png": {
      "frame": { "x": 36, "y": 0, "w": 37, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 37, "h": 38 },
      "sourceSize": { "w": 37, "h": 38 },
    },
    "1776.png": {
      "frame": { "x": 73, "y": 0, "w": 36, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 36, "h": 38 },
      "sourceSize": { "w": 36, "h": 38 },
    },
    "1779.png": {
      "frame": { "x": 0, "y": 39, "w": 36, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 36, "h": 38 },
      "sourceSize": { "w": 36, "h": 38 },
    },
    "1772.png": {
      "frame": { "x": 36, "y": 39, "w": 34, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 34, "h": 38 },
      "sourceSize": { "w": 34, "h": 38 },
    },
    "1775.png": {
      "frame": { "x": 70, "y": 39, "w": 34, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 34, "h": 38 },
      "sourceSize": { "w": 34, "h": 38 },
    },
    "1773.png": {
      "frame": { "x": 109, "y": 0, "w": 33, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 33, "h": 38 },
      "sourceSize": { "w": 33, "h": 38 },
    },
    "1777.png": {
      "frame": { "x": 109, "y": 38, "w": 33, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 33, "h": 38 },
      "sourceSize": { "w": 33, "h": 38 },
    },
    "1774.png": {
      "frame": { "x": 0, "y": 77, "w": 36, "h": 37 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 36, "h": 37 },
      "sourceSize": { "w": 36, "h": 37 },
    },
    "1771.png": {
      "frame": { "x": 36, "y": 77, "w": 25, "h": 37 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 25, "h": 37 },
      "sourceSize": { "w": 25, "h": 37 },
    },
  },
}

///|
let no_violet0_spritesheet_json : Json = {
  "meta": {
    "image": "NoViolet0.png",
    "size": { "w": 151, "h": 104 },
    "scale": "1",
  },
  "frames": {
    "1769.png": {
      "frame": { "x": 0, "y": 0, "w": 98, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 98, "h": 38 },
      "sourceSize": { "w": 98, "h": 38 },
    },
    "1759.png": {
      "frame": { "x": 0, "y": 38, "w": 31, "h": 33 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 31, "h": 33 },
      "sourceSize": { "w": 31, "h": 33 },
    },
    "1763.png": {
      "frame": { "x": 31, "y": 38, "w": 31, "h": 33 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 31, "h": 33 },
      "sourceSize": { "w": 31, "h": 33 },
    },
    "1765.png": {
      "frame": { "x": 62, "y": 38, "w": 31, "h": 33 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 31, "h": 33 },
      "sourceSize": { "w": 31, "h": 33 },
    },
    "1767.png": {
      "frame": { "x": 98, "y": 0, "w": 31, "h": 33 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 31, "h": 33 },
      "sourceSize": { "w": 31, "h": 33 },
    },
    "1768.png": {
      "frame": { "x": 98, "y": 33, "w": 31, "h": 33 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 31, "h": 33 },
      "sourceSize": { "w": 31, "h": 33 },
    },
    "1761.png": {
      "frame": { "x": 0, "y": 71, "w": 29, "h": 33 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 29, "h": 33 },
      "sourceSize": { "w": 29, "h": 33 },
    },
    "1764.png": {
      "frame": { "x": 29, "y": 71, "w": 29, "h": 32 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 29, "h": 32 },
      "sourceSize": { "w": 29, "h": 32 },
    },
    "1766.png": {
      "frame": { "x": 58, "y": 71, "w": 29, "h": 32 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 29, "h": 32 },
      "sourceSize": { "w": 29, "h": 32 },
    },
    "1762.png": {
      "frame": { "x": 87, "y": 71, "w": 28, "h": 32 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 28, "h": 32 },
      "sourceSize": { "w": 28, "h": 32 },
    },
    "1760.png": {
      "frame": { "x": 129, "y": 0, "w": 22, "h": 32 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 22, "h": 32 },
      "sourceSize": { "w": 22, "h": 32 },
    },
  },
}

///|
let no_blue1_spritesheet_json : Json = {
  "meta": {
    "image": "NoBlue1.png",
    "size": { "w": 142, "h": 114 },
    "scale": "1",
  },
  "frames": {
    "1715.png": {
      "frame": { "x": 0, "y": 0, "w": 36, "h": 39 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 36, "h": 39 },
      "sourceSize": { "w": 36, "h": 39 },
    },
    "1707.png": {
      "frame": { "x": 36, "y": 0, "w": 37, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 37, "h": 38 },
      "sourceSize": { "w": 37, "h": 38 },
    },
    "1713.png": {
      "frame": { "x": 73, "y": 0, "w": 36, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 36, "h": 38 },
      "sourceSize": { "w": 36, "h": 38 },
    },
    "1716.png": {
      "frame": { "x": 0, "y": 39, "w": 36, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 36, "h": 38 },
      "sourceSize": { "w": 36, "h": 38 },
    },
    "1709.png": {
      "frame": { "x": 36, "y": 39, "w": 34, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 34, "h": 38 },
      "sourceSize": { "w": 34, "h": 38 },
    },
    "1712.png": {
      "frame": { "x": 70, "y": 39, "w": 34, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 34, "h": 38 },
      "sourceSize": { "w": 34, "h": 38 },
    },
    "1710.png": {
      "frame": { "x": 109, "y": 0, "w": 33, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 33, "h": 38 },
      "sourceSize": { "w": 33, "h": 38 },
    },
    "1714.png": {
      "frame": { "x": 109, "y": 38, "w": 33, "h": 38 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 33, "h": 38 },
      "sourceSize": { "w": 33, "h": 38 },
    },
    "1711.png": {
      "frame": { "x": 0, "y": 77, "w": 36, "h": 37 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 36, "h": 37 },
      "sourceSize": { "w": 36, "h": 37 },
    },
    "1708.png": {
      "frame": { "x": 36, "y": 77, "w": 25, "h": 37 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 25, "h": 37 },
      "sourceSize": { "w": 25, "h": 37 },
    },
  },
}

///|
let no_blue0_spritesheet_json : Json = {
  "meta": {
    "image": "NoBlue0.png",
    "size": { "w": 122, "h": 98 },
    "scale": "1",
  },
  "frames": {
    "1697.png": {
      "frame": { "x": 0, "y": 0, "w": 31, "h": 33 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 31, "h": 33 },
      "sourceSize": { "w": 31, "h": 33 },
    },
    "1701.png": {
      "frame": { "x": 31, "y": 0, "w": 31, "h": 33 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 31, "h": 33 },
      "sourceSize": { "w": 31, "h": 33 },
    },
    "1703.png": {
      "frame": { "x": 62, "y": 0, "w": 31, "h": 33 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 31, "h": 33 },
      "sourceSize": { "w": 31, "h": 33 },
    },
    "1705.png": {
      "frame": { "x": 0, "y": 33, "w": 31, "h": 33 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 31, "h": 33 },
      "sourceSize": { "w": 31, "h": 33 },
    },
    "1706.png": {
      "frame": { "x": 31, "y": 33, "w": 31, "h": 33 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 31, "h": 33 },
      "sourceSize": { "w": 31, "h": 33 },
    },
    "1699.png": {
      "frame": { "x": 62, "y": 33, "w": 29, "h": 33 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 29, "h": 33 },
      "sourceSize": { "w": 29, "h": 33 },
    },
    "1702.png": {
      "frame": { "x": 93, "y": 0, "w": 29, "h": 32 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 29, "h": 32 },
      "sourceSize": { "w": 29, "h": 32 },
    },
    "1704.png": {
      "frame": { "x": 93, "y": 32, "w": 29, "h": 32 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 29, "h": 32 },
      "sourceSize": { "w": 29, "h": 32 },
    },
    "1700.png": {
      "frame": { "x": 0, "y": 66, "w": 28, "h": 32 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 28, "h": 32 },
      "sourceSize": { "w": 28, "h": 32 },
    },
    "1698.png": {
      "frame": { "x": 28, "y": 66, "w": 22, "h": 32 },
      "rotated": false,
      "trimmed": false,
      "spriteSourceSize": { "x": 0, "y": 0, "w": 22, "h": 32 },
      "sourceSize": { "w": 22, "h": 32 },
    },
  },
}
