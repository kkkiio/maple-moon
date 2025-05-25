///|
typealias Range[T] = @struct.Range[T]

///|
struct GraphicsGL {
  quads : Array[Quad]
  vwidth : Int
  vheight : Int
  screen : Rectangle[Int]
  atlas : Atlas
  text_cache : @lru_cache.Cache[TextKey, Image]
  mut locked : Bool
}

///|
priv struct Atlas {
  width : Int
  height : Int
  minlosize : Int
  leftovers : @quadtree.Tree[Int, Leftover]
  offsets : Map[String, TexOffset]
  mut next_id : Int
  mut border_x : Int
  mut border_y : Int
  mut y_range : Range[Int]
}

///|
fn GraphicsGL::new(vwidth : Int, vheight : Int) -> GraphicsGL {
  let gl = get_gl()
  let tex2d = gl.ge("TEXTURE_2D")
  let minfilter = gl.ge("TEXTURE_MIN_FILTER")
  let magfilter = gl.ge("TEXTURE_MAG_FILTER")
  let wraps = gl.ge("TEXTURE_WRAP_S")
  let wrapt = gl.ge("TEXTURE_WRAP_T")
  gl.texParameteri(tex2d, minfilter, gl.gi("NEAREST"))
  gl.texParameteri(tex2d, magfilter, gl.gi("NEAREST"))
  gl.texParameteri(tex2d, wraps, gl.gi("CLAMP_TO_EDGE"))
  gl.texParameteri(tex2d, wrapt, gl.gi("CLAMP_TO_EDGE"))
  gl.enable(gl.ge("BLEND")) // enable alpha blending
  // The Canvas 2D API produces only premultiplied alpha values.
  // https://webgl2fundamentals.org/webgl/lessons/webgl-text-texture.html
  gl.pixelStorei(gl.ge("UNPACK_PREMULTIPLY_ALPHA_WEBGL"), true)
  // gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA); 
  gl.blendFunc(gl.ge("ONE"), gl.ge("ONE_MINUS_SRC_ALPHA"))
  //   gl.bindVertexArray(null);
  let atlasw = 8192
  let atlash = 8192
  {
    quads: [],
    atlas: Atlas::new(atlasw, atlash),
    vwidth,
    vheight,
    screen: Rectangle::from4(0, vwidth, 0, vheight),
    text_cache: @lru_cache.Cache::new(32),
    locked: false,
  }
}

///|
fn Atlas::new(width : Int, height : Int) -> Atlas {
  {
    width,
    height,
    minlosize: 32,
    leftovers: @quadtree.Tree::new(),
    offsets: Map::new(),
    next_id: 1,
    border_x: 0,
    border_y: 1, // reserve (0,0) for color_fill
    y_range: Range::default(),
  }
}

///|
let gl : GraphicsGL = GraphicsGL::new(1366, 768)

///|
pub fn GraphicsGL::get() -> GraphicsGL {
  gl
}

///|
pub fn lock(self : GraphicsGL) -> Unit {
  self.locked = true
}

///|
pub fn unlock(self : GraphicsGL) -> Unit {
  self.locked = false
}

///|
pub fn draw_screen_fill(
  self : GraphicsGL,
  red : Double,
  green : Double,
  blue : Double,
  alpha : Double
) -> Unit {
  self.draw_rectangle(0, 0, self.vwidth, self.vheight, red, green, blue, alpha)
}

///|
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
    Quad::new(x, x + width, y, y + height, TexOffset::default(), color, 0.0),
  )
}

///|
pub fn draw_bitmap(
  self : GraphicsGL,
  bmp : @resource.Bitmap,
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
  if not(rect.overlaps(self.screen)) {
    return
  }
  guard bmp.image.poll() is Some(image) else { return }
  self.quads.push(
    Quad::new(
      rect.left(),
      rect.right(),
      rect.top(),
      rect.bottom(),
      self.atlas.get_offset(bmp.id, image),
      color,
      angle,
    ),
  )
}

///|
fn draw_text(
  self : GraphicsGL,
  image : Image,
  textId : String,
  point : Point[Int],
  nametag : Bool,
  text_y_clip~ : Range[Int]? = None
) -> Unit {
  if self.locked {
    return
  }
  guard image.poll() is Some(image) else { return }
  let rect = Rectangle::from4(
    point.x,
    point.x + image.width(),
    point.y,
    point.y + image.height(),
  )
  if not(rect.overlaps(self.screen)) {
    return
  }
  if nametag {
    // If ever changing code in here confirm placements with map 10000
    let left = rect.left() - 1
    let right = rect.right() + 1
    let top = rect.top() - 1
    let bottom = rect.bottom()
    let ntcolor = Color::new_rgba(0.0, 0.0, 0.0, 0.6)
    let null_offset = TexOffset::default()
    self.quads.push(
      Quad::new(left, right, top, bottom, null_offset, ntcolor, 0.0),
    )
    self.quads.push(
      Quad::new(left - 1, left, top + 1, bottom - 1, null_offset, ntcolor, 0.0),
    )
    self.quads.push(
      Quad::new(
        right,
        right + 1,
        top + 1,
        bottom - 1,
        null_offset,
        ntcolor,
        0.0,
      ),
    )
  }
  let offset = self.atlas.get_offset(textId, image)
  // TODO: add text_y_clip
  text_y_clip |> ignore
  self.quads.push(
    Quad::new(
      rect.left(),
      rect.right(),
      rect.top(),
      rect.bottom(),
      offset,
      @struct.clr_opaque,
      0.0,
    ),
  )
}

///|
pub fn create_text_image(self : GraphicsGL, key : TextKey) -> Image {
  if self.text_cache.get(key) is Some(image) {
    return image
  }
  let fontName = if key.font_id.is_bold() {
    @config.configFontPathBold.load()
  } else {
    @config.configFontPathNormal.load()
  }
  let text_align = match key.text_alignment {
    TextAlignment::LEFT => "start"
    TextAlignment::CENTER => "center"
    TextAlignment::RIGHT => "end"
  }
  let r = key.color.r()
  let g = key.color.g()
  let b = key.color.b()
  let img = text_create_image(
    key.text,
    key.font_id.height(),
    fontName,
    "rgb(\{r} \{g} \{b} / \{key.color.a()/255})", // rgb($r $g $b / $a)
    text_align,
    key.max_width.or(0),
  )
  self.text_cache.set(key, img)
  img
}

///|
struct TextKey {
  text : String
  font_id : FontId
  text_alignment : TextAlignment
  color : @struct.IntColor
  max_width : Int?
} derive(Eq, Hash)

///|
pub(all) enum TextAlignment {
  LEFT
  CENTER
  RIGHT
} derive(Eq, Hash)

///|
pub fn flush(self : GraphicsGL, opacity : Double) -> Unit {
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
        TexOffset::default(),
        color,
        0.0,
      ),
    )
  }
  let triangles = Vertices::new(self.quads.length() * 6)
  self.quads.eachi(fn(i, quad) {
    setv(triangles, i * 6 + 0, quad.vertices[0])
    setv(triangles, i * 6 + 1, quad.vertices[1])
    setv(triangles, i * 6 + 2, quad.vertices[2])
    // 
    setv(triangles, i * 6 + 3, quad.vertices[0])
    setv(triangles, i * 6 + 4, quad.vertices[2])
    setv(triangles, i * 6 + 5, quad.vertices[3])
  })
  glFlush(triangles)
  if coverscene {
    self.quads.pop() |> ignore
  }
}

///|
pub fn clear(self : GraphicsGL) -> Unit {
  self.atlas.clear()
  self.text_cache.clear()
}

///|
fn Atlas::clear(self : Atlas) -> Unit {
  let used = self.width * self.border_y + self.border_x * self.y_range.b
  let usedpercent = used.to_double() / (self.width * self.height).to_double()
  if usedpercent > 80.0 {
    self.clear_internal()
  }
}

///|
pub fn clear_scene(self : GraphicsGL) -> Unit {
  if not(self.locked) {
    self.quads.clear()
    // self.circles.clear();
  }
}

///|
fn get_offset(
  self : Atlas,
  id : String,
  bmp : @resource.LoadedImage
) -> TexOffset {
  match self.offsets.get(id) {
    Some(c) => return c
    None => ()
  }
  let width = bmp.width()
  let height = bmp.height()
  if width <= 0 || height <= 0 {
    return TexOffset::default()
  }
  fn add_leftover(leftover) {
    let ok = self.leftovers.add(self.next_id, leftover)
    guard ok else { abort("duplicate key") }
    self.next_id += 1
  }

  let (x, y) = match
    self.leftovers.ceiling_key(Leftover::fromxywh(0, 0, width, height)) {
    Some(k) => {
      let leftover = self.leftovers.remove(k).unwrap()
      let x = leftover.left
      let y = leftover.top
      let width_delta = leftover.width() - width
      let height_delta = leftover.height() - height
      // self.wasted -= width * height
      if width_delta >= self.minlosize && height_delta >= self.minlosize {
        add_leftover(
          Leftover::fromxywh(x + width, y + height, width_delta, height_delta),
        )
        if width >= self.minlosize {
          add_leftover(Leftover::fromxywh(x, y + height, width, height_delta))
        }
        if height >= self.minlosize {
          add_leftover(Leftover::fromxywh(x + width, y, width_delta, height))
        }
      } else if width_delta >= self.minlosize {
        add_leftover(
          Leftover::fromxywh(x + width, y, width_delta, height + height_delta),
        )
      } else if height_delta >= self.minlosize {
        add_leftover(
          Leftover::fromxywh(x, y + height, width + width_delta, height_delta),
        )
      }
      (x, y)
    }
    None => {
      if self.border_x + width > self.width {
        self.border_x = 0
        self.border_y = self.border_y + self.y_range.b
        if self.border_y + height > self.height {
          self.clear_internal()
        } else {
          self.y_range = Range::default()
        }
      }
      let x = self.border_x
      let y = self.border_y
      self.border_x = self.border_x + width
      if height > self.y_range.b {
        if x >= self.minlosize && height - self.y_range.b >= self.minlosize {
          add_leftover(
            Leftover::fromxywh(0, self.y_range.a, x, height - self.y_range.b),
          )
        }
        // self.wasted += x * (height - self.y_range.b)
        self.y_range = Range::new(y + height, height)
      } else if height < self.y_range.a - y {
        if width >= self.minlosize &&
          self.y_range.a - y - height >= self.minlosize {
          add_leftover(
            Leftover::fromxywh(
              x,
              y + height,
              width,
              self.y_range.a - y - height,
            ),
          )
        }
      }
      // self.wasted += width * (self.y_range.a - y - height)
      (x, y)
    }
  }
  glTexSubImage2D(x, y, bmp)
  let offset = TexOffset::new(x, y, width, height)
  self.offsets.set(id, offset)
  offset
}

///|
fn clear_internal(self : Atlas) -> Unit {
  self.border_x = 0
  self.border_y = 1
  self.y_range = Range::default()
  self.offsets.clear()
  self.leftovers.clear()
  self.next_id = 1
}

///|
priv struct Quad {
  vertices : FixedArray[Vertex]
} derive(Show)

///|
fn Quad::new(
  left : Int,
  right : Int,
  top : Int,
  bottom : Int,
  offset : TexOffset,
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
    vertices.each(fn(v) -> Unit {
      let vertice_x = v.localcoord_x - center_x
      let vertice_y = v.localcoord_y - center_y
      let rounded_x = (vertice_x.to_double() * cos - vertice_y.to_double() * sin).round()
      let rounded_y = (vertice_x.to_double() * sin + vertice_y.to_double() * cos).round()
      v.localcoord_x = rounded_x.to_int() + center_x
      v.localcoord_y = rounded_y.to_int() + center_y
    })
  }
  { vertices, }
}

///|
priv struct Vertex {
  mut localcoord_x : Int
  mut localcoord_y : Int
  texcoord_x : Int
  texcoord_y : Int
  color : Color
} derive(Show)

///|
fn Vertex::new(
  localcoord_x : Int,
  localcoord_y : Int,
  texcoord_x : Int,
  texcoord_y : Int,
  color : Color
) -> Vertex {
  { localcoord_x, localcoord_y, texcoord_x, texcoord_y, color }
}

///|
priv struct Leftover {
  left : Int
  right : Int
  top : Int
  bottom : Int
}

///|
fn Leftover::fromxywh(x : Int, y : Int, width : Int, height : Int) -> Leftover {
  let left = x
  let right = x + width
  let top = y
  let bottom = y + height
  { left, right, top, bottom }
}

///|
fn Leftover::width(self : Leftover) -> Int {
  self.right - self.left
}

///|
fn Leftover::height(self : Leftover) -> Int {
  self.bottom - self.top
}

///|
impl @quadtree.QuadCompare for Leftover with compare_to(
  self : Leftover,
  other : Leftover
) -> @quadtree.Direction {
  let wg = self.width() >= other.width()
  let hg = self.height() >= other.height()
  match (wg, hg) {
    (true, true) => @quadtree.Direction::TR
    (true, false) => @quadtree.Direction::BR
    (false, true) => @quadtree.Direction::TL
    (false, false) => @quadtree.Direction::BL
  }
}

///|
priv struct TexOffset {
  left : Int
  right : Int
  top : Int
  bottom : Int
}

///|
fn TexOffset::new(x : Int, y : Int, width : Int, height : Int) -> TexOffset {
  { left: x, right: x + width, top: y, bottom: y + height }
}

///|
fn TexOffset::default() -> TexOffset {
  { left: 0, right: 0, top: 0, bottom: 0 }
}

///|
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

///|
pub(all) enum FontId {
  A11M
  A11B
  A12M
  A12B
  A13M
  A13B
  A15B
  A18M
} derive(Eq, Show, Hash)

///|
pub fn is_bold(self : FontId) -> Bool {
  match self {
    A11B | A12B | A13B | A15B => true
    _ => false
  }
}

///|
pub fn FontId::height(self : FontId) -> Int {
  match self {
    A11M | A11B => 11
    A12M | A12B => 12
    A13M | A13B => 13
    A15B => 15
    A18M => 18
  }
}
