struct GraphicsGL {
  quads : Array[Quad]
  vwidth : Int
  vheight : Int
  screen : Rectangle[Int]
  fonts : @immut/hashmap.T[FontId, Font]
  atlas : Atlas
  mut locked : Bool
}

struct Atlas {
  width : Int
  height : Int
  minlosize : Int
  font_ymax : Int
  leftovers : @quadtree.Tree[Int, Leftover]
  offsets : Map[Int, Offset]
  mut wasted : Int
  mut next_id : Int
  mut border : Point[Int]
  mut y_range : Range[Int]
  debug : Bool
}

fn GraphicsGL::new(vwidth : Int, vheight : Int) -> GraphicsGL {
  let atlasw = 8192
  let atlash = 8192
  let loader = FontsLoader::new(atlasw)
  let font_normal = @config.configFontPathNormal.load()
  let font_bold = @config.configFontPathBold.load()
  loader.add_font(font_normal, FontId::A11M, 11)
  loader.add_font(font_bold, FontId::A11B, 11)
  loader.add_font(font_normal, FontId::A12M, 12)
  loader.add_font(font_bold, FontId::A12B, 12)
  loader.add_font(font_normal, FontId::A13M, 13)
  loader.add_font(font_bold, FontId::A13B, 13)
  loader.add_font(font_bold, FontId::A15B, 15)
  loader.add_font(font_normal, FontId::A18M, 18)
  let font_ymax = loader.font_ymax
  {
    quads: [],
    fonts: loader.fonts.iter() |> @immut/hashmap.from_iter,
    atlas: {
      width: atlasw,
      height: atlash,
      minlosize: 32,
      font_ymax,
      leftovers: @quadtree.Tree::new(),
      offsets: Map::new(),
      wasted: 0,
      next_id: 1,
      border: { x: 0, y: font_ymax },
      y_range: Range::default(),
      debug: false,
    },
    vwidth,
    vheight,
    screen: Rectangle::from4(0, vwidth, 0, vheight),
    locked: false,
  }
}

let gl : GraphicsGL = GraphicsGL::new(1366, 768)

pub fn GraphicsGL::get() -> GraphicsGL {
  gl
}

pub fn lock(self : GraphicsGL) -> Unit {
  self.locked = true
}

pub fn unlock(self : GraphicsGL) -> Unit {
  self.locked = false
}

pub fn draw_screen_fill(
  self : GraphicsGL,
  red : Double,
  green : Double,
  blue : Double,
  alpha : Double
) -> Unit {
  self.draw_rectangle(0, 0, self.vwidth, self.vheight, red, green, blue, alpha)
}

pub fn draw_rectangle(
  self : GraphicsGL,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  red : Double,
  green : Double,
  blue : Double,
  alpha : Double
) -> Unit {
  if self.locked {
    return
  }
  let color = Color::new_rgba(red, green, blue, alpha)
  self.quads.push(
    Quad::new(x, x + width, y, y + height, Offset::default(), color, 0.0),
  )
}

pub fn draw_bitmap(
  self : GraphicsGL,
  bmp : Bitmap,
  rect : Rectangle[Int],
  color : Color,
  angle : Double
) -> Unit {
  if self.locked {
    return
  }
  if color.invisible() {
    return
  }
  if bmp.loading() {
    return
  }

  // if (rect.overlaps(SCREEN).not()) {
  //     return;
  // }

  self.quads.push(
    Quad::new(
      rect.left(),
      rect.right(),
      rect.top(),
      rect.bottom(),
      self.atlas.get_offset(bmp),
      color,
      angle,
    ),
  )
}

pub fn draw_text(
  self : GraphicsGL,
  args : DrawArgument,
  vertical : Range[Int],
  layout : TextLayout,
  id : FontId,
  colorid : ColorName,
  background : TextBackground
) -> Unit {
  if self.locked {
    return
  }
  let color = args.color
  let text = layout.text
  if text.is_empty() || color.invisible() {
    return
  }
  let font = self.fonts[id].unwrap()
  let x = args.pos.x
  let y = args.pos.y
  let w = layout.width()
  let h = layout.height()
  let minheight = if vertical.first() > 0 {
    vertical.first()
  } else {
    self.screen.top()
  }
  let maxheight = if vertical.second() > 0 {
    vertical.second()
  } else {
    self.screen.bottom()
  }
  match background {
    // If ever changing code in here confirm placements with map 10000
    NAMETAG =>
      for line in layout {
        let left = x + line.position.x - 1
        let right = left + w + 3
        let top = y + line.position.y - font.linespace() + 6
        let bottom = top + h - 2
        let ntcolor = Color::new_rgba(0.0, 0.0, 0.0, 0.6)
        self.quads.push(
          Quad::new(left, right, top, bottom, Offset::default(), ntcolor, 0.0),
        )
        self.quads.push(
          Quad::new(
            left - 1,
            left,
            top + 1,
            bottom - 1,
            Offset::default(),
            ntcolor,
            0.0,
          ),
        )
        self.quads.push(
          Quad::new(
            right,
            right + 1,
            top + 1,
            bottom - 1,
            Offset::default(),
            ntcolor,
            0.0,
          ),
        )
      }
    TextBackground::NONE => ()
  }
  for line in layout {
    let position = line.position
    for word in line.words {
      let mut ax = position.x + layout.advance(word.first)
      let ay = position.y
      let abscolor = Color::from_name(word.color.or(colorid))
      for pos in word.first.until(word.last) {
        let c = text[pos]
        let ch = font.chars[c.to_int()]
        let char_x = x + ax + ch.bl
        let char_y = y + ay - ch.bt
        let char_width = ch.bw
        let char_height = ch.bh
        let mut char_bottom = char_y + char_height
        let offset = if char_bottom > maxheight {
          let bottom_adjust = char_bottom - maxheight
          if bottom_adjust < 10 {
            char_bottom -= bottom_adjust
            { ..ch.offset, bottom: ch.offset.bottom - bottom_adjust }
          } else {
            continue
          }
        } else {
          ch.offset
        }
        if char_y < minheight {
          continue
        }
        if ax == 0 && c == ' ' {
          continue
        }
        ax += ch.ax
        if char_width <= 0 || char_height <= 0 {
          continue
        }
        self.quads.push(
          Quad::new(
            char_x,
            char_x + char_width,
            char_y,
            char_bottom,
            offset,
            abscolor,
            0.0,
          ),
        )
      }
    }
  }
}

pub fn create_layout(
  self : GraphicsGL,
  chars : Array[Char],
  id : FontId,
  alignment : TextAlignment,
  maxwidth : Int,
  formatted : Bool,
  line_adj : Int
) -> TextLayout {
  let length = chars.length()
  if length == 0 {
    return TextLayout::new([])
  }
  let builder = LayoutBuilder::new(
    chars,
    self.fonts[id].unwrap(),
    alignment,
    maxwidth,
    formatted,
    line_adj,
  )
  let mut first = 0
  let mut offset = 0
  while offset < length {
    let last = (offset + 1)
      .until(length)
      .find_first(
        fn(i) {
          let u = chars[i]
          u == ' ' || u == '\\' || u == '#'
        },
      )
      .or(length)
    first = builder.add(first, offset, last)
    offset = last
  }
  builder.finish(first, offset)
}

fn flush(self : GraphicsGL, opacity : Double) -> Unit {
  let coverscene = opacity != 1.0
  if coverscene {
    let complement = 1.0 - opacity
    let color = Color::new_rgba(0.0, 0.0, 0.0, complement)
    self.quads.push(
      Quad::new(
        self.screen.left(),
        self.screen.right(),
        self.screen.top(),
        self.screen.bottom(),
        Offset::default(),
        color,
        0.0,
      ),
    )
  }
  let triangles = Vertices::new(self.quads.length() * 6)
  self.quads.eachi(
    fn(i, quad) {
      // debug(quad)
      setv(triangles, i * 6 + 0, quad.vertices[0])
      setv(triangles, i * 6 + 1, quad.vertices[1])
      setv(triangles, i * 6 + 2, quad.vertices[2])
      // 
      setv(triangles, i * 6 + 3, quad.vertices[0])
      setv(triangles, i * 6 + 4, quad.vertices[2])
      setv(triangles, i * 6 + 5, quad.vertices[3])
    },
  )
  glFlush(triangles)
  if coverscene {
    self.quads.pop() |> ignore
  }
}

fn clear(self : GraphicsGL) -> Unit {
  self.atlas.clear()
}

fn clear(self : Atlas) -> Unit {
  let used = self.width * self.border.y + self.border.x * self.y_range.b
  let usedpercent = used.to_double() / (self.width * self.height).to_double()
  if usedpercent > 80.0 {
    self.clear_internal()
  }
}

fn clear_scene(self : GraphicsGL) -> Unit {
  if self.locked.not() {
    self.quads.clear()
    // self.circles.clear();
  }
}

fn get_offset(self : Atlas, bmp : Bitmap) -> Offset {
  let id = bmp.id()
  match self.offsets.get(id) {
    Some(c) => return c
    None => ()
  }
  let width = bmp.width()
  let height = bmp.height()
  if width <= 0 || height <= 0 {
    return Offset::default()
  }
  let (x, y) = match
    self.leftovers.ceiling_key(Leftover::fromxywh(0, 0, width, height)) {
    Some(k) => {
      let leftover = self.leftovers.remove(k).unwrap()
      let x = leftover.left
      let y = leftover.top
      let width_delta = leftover.width() - width
      let height_delta = leftover.height() - height
      self.wasted -= width * height
      if width_delta >= self.minlosize && height_delta >= self.minlosize {
        let ok = self.leftovers.add(
          self.next_id,
          Leftover::fromxywh(x + width, y + height, width_delta, height_delta),
        )
        if ok.not() {
          abort("Atlas.get_offset: failed to add leftover")
        }
        self.next_id += 1
        if width >= self.minlosize {
          let ok = self.leftovers.add(
            self.next_id,
            Leftover::fromxywh(x, y + height, width, height_delta),
          )
          if ok.not() {
            abort("Atlas.get_offset: failed to add leftover")
          }
          self.next_id += 1
        }
        if height >= self.minlosize {
          let ok = self.leftovers.add(
            self.next_id,
            Leftover::fromxywh(x + width, y, width_delta, height),
          )
          if ok.not() {
            abort("Atlas.get_offset: failed to add leftover")
          }
          self.next_id += 1
        }
      } else if width_delta >= self.minlosize {
        let ok = self.leftovers.add(
          self.next_id,
          Leftover::fromxywh(x + width, y, width_delta, height + height_delta),
        )
        if ok.not() {
          abort("Atlas.get_offset: failed to add leftover")
        }
        self.next_id += 1
      } else if height_delta >= self.minlosize {
        let ok = self.leftovers.add(
          self.next_id,
          Leftover::fromxywh(x, y + height, width + width_delta, height_delta),
        )
        if ok.not() {
          abort("Atlas.get_offset: failed to add leftover")
        }
        self.next_id += 1
      }
      (x, y)
    }
    None => {
      if self.border.x + width > self.width {
        self.border = { x: 0, y: self.border.y + self.y_range.b }
        if self.border.y + height > self.height {
          self.clear_internal()
        } else {
          self.y_range = Range::default()
        }
      }
      let x = self.border.x
      let y = self.border.y
      self.border = self.border.shift_x(width)
      if height > self.y_range.b {
        if x >= self.minlosize && height - self.y_range.b >= self.minlosize {
          let ok = self.leftovers.add(
            self.next_id,
            Leftover::fromxywh(0, self.y_range.a, x, height - self.y_range.b),
          )
          if ok.not() {
            abort("Atlas.get_offset: failed to add leftover")
          }
          self.next_id += 1
        }
        self.wasted += x * (height - self.y_range.b)
        self.y_range = Range::new(y + height, height)
      } else if height < self.y_range.a - y {
        if width >= self.minlosize &&
          self.y_range.a - y - height >= self.minlosize {
          let ok = self.leftovers.add(
            self.next_id,
            Leftover::fromxywh(
              x,
              y + height,
              width,
              self.y_range.a - y - height,
            ),
          )
          if ok.not() {
            abort("Atlas.get_offset: failed to add leftover")
          }
          self.next_id += 1
        }
        self.wasted += width * (self.y_range.a - y - height)
      }
      (x, y)
    }
  }
  if self.debug {
    let used = self.width * self.border.y + self.border.x * self.y_range.b
    let usedpercent = used.to_double() / (self.width * self.height).to_double()
    let wastedpercent = self.wasted.to_double() / used.to_double()
    println("Used: [\{usedpercent}] Wasted: [\{wastedpercent}]")
  }
  glTexSubImage2D(x, y, bmp)
  let offset = Offset::new(x, y, width, height)
  self.offsets.set(id, offset)
  offset
}

fn clear_internal(self : Atlas) -> Unit {
  self.border = { x: 0, y: self.font_ymax }
  self.y_range = Range::default()
  self.offsets.clear()
  self.leftovers.clear()
  self.next_id = 1
  self.wasted = 0
}

struct Quad {
  vertices : FixedArray[Vertex]
} derive(Show)

fn Quad::new(
  left : Int,
  right : Int,
  top : Int,
  bottom : Int,
  offset : Offset,
  color : Color,
  rotation : Double
) -> Quad {
  // if left >= right || top >= bottom {
  //   abort("Invalid Quad: left >= right || top >= bottom")
  // }
  let vertices : FixedArray[Vertex] = [
    Vertex::new(left, top, offset.left, offset.top, color),
    Vertex::new(left, bottom, offset.left, offset.bottom, color),
    Vertex::new(right, bottom, offset.right, offset.bottom, color),
    Vertex::new(right, top, offset.right, offset.top, color),
  ]
  if rotation != 0.0 {
    let cos = @math.cos(rotation)
    let sin = @math.sin(rotation)
    let center_x = (left + right) / 2
    let center_y = (top + bottom) / 2
    vertices.each(
      fn(v) -> Unit {
        let vertice_x = v.localcoord_x - center_x
        let vertice_y = v.localcoord_y - center_y
        let rounded_x = (vertice_x.to_double() * cos -
        vertice_y.to_double() * sin).round()
        let rounded_y = (vertice_x.to_double() * sin +
        vertice_y.to_double() * cos).round()
        v.localcoord_x = rounded_x.to_int() + center_x
        v.localcoord_y = rounded_y.to_int() + center_y
      },
    )
  }
  { vertices, }
}

struct Vertex {
  mut localcoord_x : Int
  mut localcoord_y : Int
  texcoord_x : Int
  texcoord_y : Int
  color : Color
} derive(Show)

fn Vertex::new(
  localcoord_x : Int,
  localcoord_y : Int,
  texcoord_x : Int,
  texcoord_y : Int,
  color : Color
) -> Vertex {
  { localcoord_x, localcoord_y, texcoord_x, texcoord_y, color }
}

struct Leftover {
  left : Int
  right : Int
  top : Int
  bottom : Int
}

fn Leftover::fromxywh(x : Int, y : Int, width : Int, height : Int) -> Leftover {
  let left = x
  let right = x + width
  let top = y
  let bottom = y + height
  { left, right, top, bottom }
}

fn width(self : Leftover) -> Int {
  self.right - self.left
}

fn height(self : Leftover) -> Int {
  self.bottom - self.top
}

fn compare_to(self : Leftover, other : Leftover) -> @quadtree.Direction {
  let wg = self.width() >= other.width()
  let hg = self.height() >= other.height()
  match (wg, hg) {
    (true, true) => @quadtree.Direction::TR
    (true, false) => @quadtree.Direction::BR
    (false, true) => @quadtree.Direction::TL
    (false, false) => @quadtree.Direction::BL
  }
}

struct Offset {
  left : Int
  right : Int
  top : Int
  bottom : Int
}

fn Offset::new(x : Int, y : Int, width : Int, height : Int) -> Offset {
  { left: x, right: x + width, top: y, bottom: y + height }
}

fn Offset::default() -> Offset {
  { left: 0, right: 0, top: 0, bottom: 0 }
}

fn setv(vs : Vertices, i : Int, v : Vertex) -> Unit {
  vs.set(
    i,
    v.localcoord_x,
    v.localcoord_y,
    v.texcoord_x,
    v.texcoord_y,
    v.color.r(),
    v.color.g(),
    v.color.b(),
    v.color.a(),
  )
}

fn glFlush(v : Vertices) = "gl" "flush"

type Vertices

fn Vertices::new(length : Int) -> Vertices = "vertices" "new"

fn set(
  self : Vertices,
  i : Int,
  localcoord_x : Int,
  localcoord_y : Int,
  texcoord_x : Int,
  texcoord_y : Int,
  color_r : Double,
  color_g : Double,
  color_b : Double,
  color_a : Double
) = "vertices" "set"

fn glTexSubImage2D(xoffset : Int, yoffset : Int, bmp : @resource.Bitmap) = "gl" "texSubImage2D"

pub typealias Bitmap = @resource.Bitmap

struct FontsLoader {
  gloader : FtFontsLoader
  atlasw : Int
  fonts : Map[FontId, Font]
  mut font_ymax : Int
  mut font_border : Point[Int]
}

fn FontsLoader::new(atlasw : Int) -> FontsLoader {
  {
    gloader: FtFontsLoader::new(),
    atlasw,
    fonts: {  },
    font_ymax: 0,
    font_border: { x: 0, y: 0 },
  }
}

fn add_font(
  self : FontsLoader,
  name : String,
  id : FontId,
  pixelh : Int
) -> Unit {
  let mut width = 0
  let mut height = 0
  for c in (32).until(256) {
    let bmp = self.gloader.load_glyph(
      name.to_js_string(),
      pixelh,
      Char::from_int(c).to_string().to_js_string(),
    )
    let w = bmp.width()
    let h = bmp.height()
    width = width + w
    if h > height {
      height = h
    }
  }
  if self.font_border.x + width > self.atlasw {
    self.font_border = { x: 0, y: self.font_ymax }
    self.font_ymax = 0
  }
  let x = self.font_border.x
  let y = self.font_border.y
  self.font_border = { x: x + width, y }
  if height > self.font_ymax {
    self.font_ymax = height
  }
  let f = Font::new(~height)
  let mut ox = x
  let oy = y
  for c in (32).until(256) {
    let fc = self.gloader.load_glyph(
      name.to_js_string(),
      pixelh,
      Char::from_int(c).to_string().to_js_string(),
    )
    let ax = fc.advance_x()
    let bl = fc.bearing_x()
    let bt = fc.bearing_y()
    let bw = fc.width()
    let bh = fc.height()
    glTexSubImage2D(ox, oy, fc.load_bitmap())
    let offset = Offset::new(ox, oy, bw, bh)
    f.chars[c] = { ax, bw, bh, bl, bt, offset }
    ox += bw
  }
  self.fonts[id] = f
}

type FtFontsLoader

fn FtFontsLoader::new() -> FtFontsLoader = "font" "new_ftloader"

fn load_glyph(
  self : FtFontsLoader,
  name : Js_string,
  pixelh : Int,
  c : Js_string
) -> FtGlyph = "font" "load_glyph"

type FtGlyph

fn width(self : FtGlyph) -> Int = "font" "width"

fn height(self : FtGlyph) -> Int = "font" "height"

fn advance_x(self : FtGlyph) -> Int = "font" "advance_x"

fn bearing_x(self : FtGlyph) -> Int = "font" "bearing_x"

fn bearing_y(self : FtGlyph) -> Int = "font" "bearing_y"

fn load_bitmap(self : FtGlyph) -> Bitmap = "font" "load_bitmap"

pub enum FontId {
  A11M
  A11B
  A12M
  A12B
  A13M
  A13B
  A15B
  A18M
} derive(Eq, Show, Hash)

struct Font {
  height : Int
  chars : FixedArray[FontChar]
}

struct FontChar {
  ax : Int
  bw : Int
  bh : Int
  bl : Int
  bt : Int
  offset : Offset
}

fn Font::new(~height : Int = 0) -> Font {
  {
    height,
    chars: FixedArray::make(
      256,
      { ax: 0, bw: 0, bh: 0, bl: 0, bt: 0, offset: Offset::new(0, 0, 0, 0) },
    ),
  }
}

fn linespace(self : Font) -> Int {
  (self.height.to_double() * 1.35 + 1).to_int()
}

struct TextLayout {
  text : Array[Char]
  lines : Array[TextLine]
  advances : Array[Int]
  dimensions : Point[Int]
  end_offset : Point[Int]
}

fn TextLayout::new(
  text : Array[Char],
  ~lines : Array[TextLine] = [],
  ~advances : Array[Int] = [],
  ~w : Int = 0,
  ~h : Int = 0,
  ~ex : Int = 0,
  ~ey : Int = 0
) -> TextLayout {
  {
    text,
    lines,
    advances,
    dimensions: Point::new(w, h),
    end_offset: Point::new(ex, ey),
  }
}

fn width(self : TextLayout) -> Int {
  self.dimensions.x
}

fn height(self : TextLayout) -> Int {
  self.dimensions.y
}

fn advance(self : TextLayout, index : Int) -> Int {
  if index < self.advances.length() {
    self.advances[index]
  } else {
    0
  }
}

fn get_dimensions(self : TextLayout) -> Point[Int] {
  self.dimensions
}

fn get_endoffset(self : TextLayout) -> Point[Int] {
  self.end_offset
}

fn iter(self : TextLayout) -> Iter[TextLine] {
  self.lines.iter()
}

struct TextLine {
  words : FixedArray[TextWord]
  position : Point[Int]
}

struct TextWord {
  first : Int
  last : Int
  color : ColorName?
}

pub enum TextBackground {
  NONE
  NAMETAG
}

struct LayoutBuilder {
  text : Array[Char]
  font : Font
  alignment : TextAlignment
  mut color : ColorName?
  max_width : Int
  formatted : Bool
  mut ax : Int
  mut ay : Int
  lines : Array[TextLine]
  words : Array[TextWord]
  advances : Array[Int]
  mut width : Int
  mut endy : Int
  line_adj : Int
}

fn LayoutBuilder::new(
  text : Array[Char],
  font : Font,
  alignment : TextAlignment,
  max_width : Int,
  formatted : Bool,
  line_adj : Int
) -> LayoutBuilder {
  {
    text,
    font,
    alignment,
    max_width: if max_width == 0 {
      800
    } else {
      max_width
    },
    formatted,
    line_adj,
    color: None,
    ax: 0,
    ay: font.linespace(),
    lines: [],
    words: [],
    advances: [],
    width: 0,
    endy: 0,
  }
}

fn add(self : LayoutBuilder, prev : Int, first : Int, last : Int) -> Int {
  let text = self.text
  if first == last {
    return prev
  }
  let last_color = self.color
  let mut skip = 0
  let mut linebreak = false
  if self.formatted {
    if text[first] == '\\' {
      if first + 1 < last {
        if text[first + 1] == 'n' {
          linebreak = true
        } else if text[first + 1] == 'r' {
          linebreak = self.ax > 0
        }
        skip += 1
      }
      skip += 1
    } else if text[first] == '#' {
      if first + 1 < last {
        if text[first + 1] == 'k' {
          self.color = ColorName::DARKGREY |> @option.some
          skip += 1
        } else if text[first + 1] == 'b' {
          self.color = ColorName::BLUE |> @option.some
          skip += 1
        } else if text[first + 1] == 'r' {
          self.color = ColorName::RED |> @option.some
          skip += 1
        } else if text[first + 1] == 'c' {
          self.color = ColorName::ORANGE |> @option.some
          skip += 1
        } else if text[first + 1] == 'L' {
          skip += 1
        } else if text[first + 1] == 'l' {
          skip += 1
        }
      }
      skip += 1
    }
  }
  let mut wordwidth = 0
  if linebreak.not() {
    for i in first.until(last) {
      let c = text[i]
      if c.to_int() < 32 {
        if c == '\n' {
          linebreak = true
        } else if c == '\r' {
          linebreak = self.ax > 0
        }
        continue
      }
      wordwidth += self.font.chars[c.to_int()].ax
      if wordwidth > self.max_width {
        if last - first == 1 {
          return last
        }
        let prev = self.add(prev, first, i)
        return self.add(prev, i, last)
      }
    }
  }
  let newword = skip > 0
  let newline = linebreak || self.ax + wordwidth > self.max_width
  if newword || newline {
    self.add_word(prev, first, last_color)
  }
  if newline {
    self.add_line()
    self.endy = self.ay
    self.ax = 0
    self.ay += self.font.linespace()
    if self.lines.is_empty().not() {
      self.ay -= self.line_adj
    }
  }
  for pos in first.until(last) {
    let c = text[pos]
    let ch = self.font.chars[c.to_int()]
    self.advances.push(self.ax)
    if pos < first + skip || (newline && c == ' ') {
      continue
    }
    if c.to_int() < 32 {
      continue
    }
    self.ax += ch.ax
    if self.width < self.ax {
      self.width = self.ax
    }
  }
  if newword || newline {
    return first + skip
  }
  prev
}

fn add_word(
  self : LayoutBuilder,
  first : Int,
  last : Int,
  color : ColorName?
) -> Unit {
  self.words.push({ first, last, color })
}

fn add_line(self : LayoutBuilder) -> Unit {
  let mut line_x = 0
  let line_y = self.ay
  match self.alignment {
    TextAlignment::CENTER => line_x -= self.ax / 2
    TextAlignment::RIGHT => line_x -= self.ax
    TextAlignment::LEFT => ()
  }
  self.lines.push(
    {
      words: self.words |> FixedArray::from_array,
      position: { x: line_x, y: line_y },
    },
  )
  self.words.clear()
}

fn finish(self : LayoutBuilder, first : Int, last : Int) -> TextLayout {
  self.add_word(first, last, self.color)
  self.add_line()
  self.advances.push(self.ax)
  TextLayout::new(
    self.text,
    lines=self.lines,
    advances=self.advances,
    w=self.width,
    h=self.ay,
    ex=self.ax,
    ey=self.endy,
  )
}
