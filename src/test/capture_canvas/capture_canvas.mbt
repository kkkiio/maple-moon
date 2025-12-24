///|
pub type Canvas

///|
pub type Context2D

///|
pub type Image

///|

///|
priv struct GlobalState {
  mut canvas : Canvas?
  mut ctx : Context2D?
}

///|
let global_state : GlobalState = { canvas: None, ctx: None }

///|
pub fn get_canvas() -> Canvas? {
  global_state.canvas
}

///|
pub fn get_ctx() -> Context2D? {
  global_state.ctx
}

///|
pub fn set_canvas(c : Canvas) -> Unit {
  global_state.canvas = Some(c)
}

///|
pub fn set_ctx(c : Context2D) -> Unit {
  global_state.ctx = Some(c)
}

// canvas module

///|
pub extern "js" fn create_canvas(w : Int, h : Int) -> Canvas =
  #|(w, h) => {
  #|  const { createCanvas } = require('canvas'); 
  #|  return createCanvas(w, h);
  #|}

///|
pub extern "js" fn Canvas::get_context(
  self : Canvas,
  type_ : String,
) -> Context2D =
  #|(c, t) => c.getContext(t)

///|
pub extern "js" fn Canvas::to_buffer(self : Canvas, mime : String) -> Buffer =
  #|(c, m) => c.toBuffer(m)

///|
pub extern "js" fn create_image() -> Image =
  #|() => {
  #|  const { Image } = require('canvas');
  #|  return new Image();
  #|}

///|
pub extern "js" fn Image::set_src(self : Image, src : Buffer) -> Unit =
  #|(img, src) => { img.src = src; }

// context methods

///|
pub extern "js" fn Context2D::set_image_smoothing_enabled(
  self : Context2D,
  v : Bool,
) -> Unit =
  #|(ctx, v) => { ctx.imageSmoothingEnabled = v; }

///|
pub extern "js" fn Context2D::scale(
  self : Context2D,
  x : Double,
  y : Double,
) -> Unit =
  #|(ctx, x, y) => { ctx.scale(x, y); }

///|
pub extern "js" fn Context2D::translate(
  self : Context2D,
  x : Double,
  y : Double,
) -> Unit =
  #|(ctx, x, y) => { ctx.translate(x, y); }

///|
pub extern "js" fn Context2D::rotate(self : Context2D, angle : Double) -> Unit =
  #|(ctx, a) => { ctx.rotate(a); }

///|
pub extern "js" fn Context2D::transform(
  self : Context2D,
  a : Double,
  b : Double,
  c : Double,
  d : Double,
  e : Double,
  f : Double,
) -> Unit =
  #|(ctx, a, b, c, d, e, f) => { ctx.transform(a, b, c, d, e, f); }

///|
pub extern "js" fn Context2D::save(self : Context2D) -> Unit =
  #|(ctx) => { ctx.save(); }

///|
pub extern "js" fn Context2D::restore(self : Context2D) -> Unit =
  #|(ctx) => { ctx.restore(); }

///|
pub extern "js" fn Context2D::draw_image_with_size(
  self : Context2D,
  img : Image,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> Unit =
  #|(ctx, img, x, y, w, h) => { ctx.drawImage(img, x, y, w, h); }

///|
pub extern "js" fn Context2D::draw_image(
  self : Context2D,
  img : Image,
  sx : Double,
  sy : Double,
  sw : Double,
  sh : Double,
  dx : Double,
  dy : Double,
  dw : Double,
  dh : Double,
) -> Unit =
  #|(ctx, img, sx, sy, sw, sh, dx, dy, dw, dh) => { 
  #|  ctx.drawImage(img, sx, sy, sw, sh, dx, dy, dw, dh); 
  #|}

///|
pub type Buffer

///|
pub extern "js" fn Buffer::to_bytes(self : Buffer) -> Bytes =
  #|(buf) => {
  #|  return new Uint8Array(buf);
  #|}

///|
pub extern "js" fn Buffer::from_bytes(bytes : Bytes) -> Buffer =
  #|(bytes) => {
  #|  return Buffer.from(bytes);
  #|}
