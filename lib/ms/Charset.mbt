pub enum CharsetAlignment {
  LEFT
  CENTER
  RIGHT
} derive(Eq, Compare, Debug)

struct Charset {
  chars : Map[Int, Texture]
  alignment : CharsetAlignment
}

pub fn Charset::from_resource(
  src : NxNode,
  alignment : CharsetAlignment
) -> Charset {
  let chars = Map::new()
  src.get_object().iter(
    fn(name, sub) {
      if sub["__b"].is_null() || name == "" {
        return
      }
      let mut c = name[0]
      if c == '\\' {
        c = '/'
      }
      chars.set(c.to_int(), Texture::from_resource(sub))
    },
  )
  { chars, alignment }
}

pub fn Charset::default() -> Charset {
  { chars: Map::new(), alignment: CharsetAlignment::LEFT }
}

pub fn draw_char(self : Charset, c : Int, args : DrawArgument) -> Unit {
  let iter = self.chars.get(c)
  match iter {
    Some(iter) => iter.draw(args)
    None => ()
  }
}

pub fn getw(self : Charset, c : Int) -> Int {
  let iter = self.chars.get(c)
  iter.map(fn(it) { it.width() }).or(0)
}

pub fn draw_text(self : Charset, text : String, args : DrawArgument) -> Int {
  let mut shift : Int = 0
  let mut total : Int = 0
  match self.alignment {
    CharsetAlignment::CENTER => {
      text.to_array().iter(
        fn(c) {
          let width = self.getw(c.to_int())
          self.draw_char(
            c.to_int(),
            args + DrawArgument::from_point(Point::new(shift, 0)),
          )
          shift += width + 2
          total += width
        },
      )
      shift -= total / 2
    }
    CharsetAlignment::LEFT =>
      // for c in text.chars() {
      text.to_array().iter(
        fn(c) {
          self.draw_char(
            c.to_int(),
            args + DrawArgument::from_point(Point::new(shift, 0)),
          )
          shift += self.getw(c.to_int()) + 1
        },
      )
    CharsetAlignment::RIGHT =>
      text.to_array().iter_rev(
        fn(c) {
          shift += self.getw(c.to_int())
          self.draw_char(
            c.to_int(),
            args - DrawArgument::from_point(Point::new(shift, 0)),
          )
        },
      )
  }
  shift
}

pub fn draw_text_with_hspace(
  self : Charset,
  text : String,
  hspace : Int,
  args : DrawArgument
) -> Int {
  let length = text.length()
  let mut shift : Int = 0
  match self.alignment {
    CharsetAlignment::CENTER => shift -= hspace * length / 2
    CharsetAlignment::LEFT =>
      text.to_array().iter(
        fn(c) {
          self.draw_char(
            c.to_int(),
            args + DrawArgument::from_point(Point::new(shift, 0)),
          )
          shift += hspace
        },
      )
    CharsetAlignment::RIGHT =>
      text.to_array().iter_rev(
        fn(c) {
          shift += hspace
          self.draw_char(
            c.to_int(),
            args - DrawArgument::from_point(Point::new(shift, 0)),
          )
        },
      )
  }
  shift
}
