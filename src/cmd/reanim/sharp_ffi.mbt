///|
#module("sharp")
extern "js" fn sharp_default(arg : @js.Value) -> @js.Value = "default"

///|
/// Read file as Buffer
#module("node:fs")
extern "js" fn read_file_buffer_ffi(path : String) -> @js.Value = "readFileSync"

///|
/// Write Buffer to file
#module("node:fs")
extern "js" fn write_file_buffer_ffi(path : String, buffer : @js.Value) -> Unit = "writeFileSync"

///|
/// Create sharp instance from buffer
fn sharp_from_buffer(buffer : @js.Value) -> @js.Value {
  sharp_default(buffer)
}

///|
/// Create empty canvas
fn sharp_create_ffi(w : Int, h : Int) -> @js.Value {
  let background = @js.Object::new()
  background["r"] = 0
  background["g"] = 0
  background["b"] = 0
  background["alpha"] = 0

  let create = @js.Object::new()
  create["width"] = w
  create["height"] = h
  create["channels"] = 4
  create["background"] = background.to_value()

  let options = @js.Object::new()
  options["create"] = create.to_value()
  sharp_default(options.to_value())
}

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
