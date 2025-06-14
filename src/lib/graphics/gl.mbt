///|
#external
priv type GL

///|
fn get_gl() -> GL = "gl" "get_gl"

///|
#external
type Image

///|
fn Image::width(self : Image) -> Int = "bitmap" "width"

///|
fn Image::height(self : Image) -> Int = "bitmap" "height"

///|
fn Image::loading(self : Image) -> Bool = "bitmap" "loading"

///|
fn Image::load(self : Image) -> @resource.LoadedImage = "bitmap" "load"

///|
fn poll(self : Image) -> @resource.LoadedImage? {
  if self.loading() {
    return None
  }
  Some(self.load())
}

///|
fn glTexSubImage2D(xoffset : Int, yoffset : Int, bmp : @resource.LoadedImage) = "gl" "texSubImage2D"

///|
fn glFlush(v : Vertices) = "gl" "flush"

///|
#external
priv type Vertices

///|
fn Vertices::new(length : Int) -> Vertices = "gl" "newVertices"

///|
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
) = "gl" "setVertices"
