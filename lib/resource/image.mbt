pub(readonly) type Image

fn loading(self : Image) -> Bool = "bitmap" "loading"

fn load(self : Image) -> LoadedImage = "bitmap" "load"

pub fn poll(self : Image) -> LoadedImage? {
  if self.loading() {
    return None
  }
  Some(self.load())
}

pub(readonly) type LoadedImage

pub fn width(self : LoadedImage) -> Int = "bitmap" "width"

pub fn height(self : LoadedImage) -> Int = "bitmap" "height"
