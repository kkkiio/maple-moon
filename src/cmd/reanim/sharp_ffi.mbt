///|
extern "js" fn require_sharp() -> @js.Value = "() => require('sharp')"

///|
let sharp : @js.Value = require_sharp()

///|
/// Read file as Buffer
extern "js" fn read_file_buffer_ffi(path : String) -> @js.Value =
  "(path) => require('node:fs').readFileSync(path)"

///|
/// Write Buffer to file
extern "js" fn write_file_buffer_ffi(path : String, buffer : @js.Value) -> Unit =
  "(path, buffer) => require('node:fs').writeFileSync(path, buffer)"

///|
/// Create sharp instance from buffer
fn sharp_from_buffer(buffer : @js.Value) -> @js.Value {
  sharp.apply([buffer])
}

///|
/// Create empty canvas
extern "js" fn sharp_create_ffi(w : Int, h : Int) -> @js.Value =
  #| (w, h) => require('sharp')({ create: { width: w, height: h, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } } })

///|
/// Extract region from image (async)
extern "js" fn extract_ffi(
  image : @js.Value,
  left : Int,
  top : Int,
  width : Int,
  height : Int,
) -> @js.Promise =
  #| (img, l, t, w, h) => img.clone().extract({ left: l, top: t, width: w, height: h }).png().toBuffer()

///|
/// Composite images onto base (async)
extern "js" fn composite_ffi(
  base : @js.Value,
  inputs : @js.Value,
) -> @js.Promise =
  #| (base, inputs) => base.composite(inputs).png().toBuffer()
