type Image

fn width(self : Image) -> Int = "bitmap" "width"

fn height(self : Image) -> Int = "bitmap" "height"

fn loading(self : Image) -> Bool = "bitmap" "loading"

fn load(self : Image) -> @resource.LoadedImage = "bitmap" "load"

fn poll(self : Image) -> @resource.LoadedImage? {
  if self.loading() {
    return None
  }
  Some(self.load())
}

fn glTexSubImage2D(xoffset : Int, yoffset : Int, bmp : @resource.LoadedImage) = "gl" "texSubImage2D"

fn glFlush(v : Vertices) = "gl" "flush"

type Vertices

fn Vertices::new(length : Int) -> Vertices = "gl" "newVertices"

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
