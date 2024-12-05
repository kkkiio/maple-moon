pub(all) enum CharsetAlignment {
  LEFT
  CENTER
  RIGHT
} derive(Eq, Compare)

struct Charset {
  chars : Map[Char, Texture]
  alignment : CharsetAlignment
}

pub fn Charset::from_resource(
  src : NxNode,
  alignment : CharsetAlignment
) -> Charset {
  let chars = Map::new()
  for sub in src {
    let name = sub.name()
    if name == "" || sub.get_bitmap().is_empty() {
      continue
    }
    let mut c = name[0]
    if c == '\\' {
      c = '/'
    }
    chars.set(c, Texture::from_resource(sub))
  }
  { chars, alignment }
}

pub fn Charset::default() -> Charset {
  { chars: Map::new(), alignment: CharsetAlignment::LEFT }
}

pub fn draw_char(self : Charset, c : Char, args : DrawArgument) -> Unit {
  let iter = self.chars.get(c)
  match iter {
    Some(iter) => iter.draw(args)
    None => ()
  }
}

pub fn getw(self : Charset, c : Char) -> Int {
  let iter = self.chars.get(c)
  iter.map(fn(it) { it.width() }).or(0)
}

pub fn draw_text(self : Charset, text : String, args : DrawArgument) -> Int {
  let mut shift : Int = 0
  let mut total : Int = 0
  match self.alignment {
    CharsetAlignment::CENTER => {
      text
      .to_array()
      .each(
        fn(c) {
          let width = self.getw(c)
          self.draw_char(
            c,
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
      text
      .to_array()
      .each(
        fn(c) {
          self.draw_char(
            c,
            args + DrawArgument::from_point(Point::new(shift, 0)),
          )
          shift += self.getw(c) + 1
        },
      )
    CharsetAlignment::RIGHT =>
      text
      .to_array()
      .rev_each(
        fn(c) {
          shift += self.getw(c)
          self.draw_char(
            c,
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
      for c in text.iter() {
        self.draw_char(c, args + DrawArgument::from_point(Point::new(shift, 0)))
        shift += hspace
      }
    CharsetAlignment::RIGHT =>
      text
      .to_array()
      .rev_each(
        fn(c) {
          shift += hspace
          self.draw_char(
            c,
            args - DrawArgument::from_point(Point::new(shift, 0)),
          )
        },
      )
  }
  shift
}

struct GameText {
  charset : Charset
  text : String
  hspace : Int
}

pub fn GameText::new(
  charset : Charset,
  text : String,
  hspace : Int
) -> GameText {
  { charset, text, hspace }
}

pub fn draw(self : GameText, args : DrawArgument) -> Int {
  self.charset.draw_text_with_hspace(self.text, self.hspace, args)
}
