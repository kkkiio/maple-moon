///|
#external
pub type Image

///|
fn Image::loading(self : Image) -> Bool = "bitmap" "loading"

///|
fn Image::load(self : Image) -> LoadedImage = "bitmap" "load"

///|
pub fn Image::poll(self : Image) -> LoadedImage? {
  if self.loading() {
    return None
  }
  Some(self.load())
}

///|
pub fn Image::new_pending() -> Image = "bitmap" "new_pending"

///|
#external
pub type LoadedImage

///|
pub fn LoadedImage::width(self : LoadedImage) -> Int = "bitmap" "width"

///|
pub fn LoadedImage::height(self : LoadedImage) -> Int = "bitmap" "height"
