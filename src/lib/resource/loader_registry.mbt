/// Loader interface for text resources.
pub(open) trait TextResourceLoader {
  fn load_text(self : Self, path : String) -> String
}

///|
/// A runtime wrapper around a concrete text loader.
pub struct TextLoader {
  loader : &TextResourceLoader
}

///|
/// Create a text loader wrapper.
pub fn TextLoader::new(loader~ : &TextResourceLoader) -> TextLoader {
  { loader, }
}

///|
/// Load text for a resource path.
pub fn TextLoader::load_text(self : TextLoader, path : String) -> String {
  self.loader.load_text(path)
}

///|
/// Global registry for named text loaders.
let text_loader_registry : Map[String, TextLoader] = {}

///|
/// Register a text loader by name.
pub fn register_text_loader(name : String, loader : TextLoader) -> Unit {
  text_loader_registry.set(name, loader)
}

///|
/// Get a text loader by name.
pub fn get_text_loader(name : String) -> TextLoader {
  match text_loader_registry.get(name) {
    Some(loader) => loader
    None => panic()
  }
}

///|
/// CSV text loader interface (compatibility wrapper).
pub(open) trait CsvTextLoader {
  fn load_text(self : Self, path : String) -> String
}

///|
/// A CSV loader wrapper kept for compatibility.
pub struct CsvLoader {
  inner : TextLoader
}

///|
/// Create a CSV loader wrapper.
pub fn CsvLoader::new(loader~ : &CsvTextLoader) -> CsvLoader {
  let text_loader = TextLoader::new(loader=CsvTextLoaderAdapter::new(loader))
  { inner: text_loader }
}

///|
/// Load text for a CSV resource path.
pub fn CsvLoader::load_text(self : CsvLoader, path : String) -> String {
  self.inner.load_text(path)
}

///|
/// Adapter from CsvTextLoader to TextResourceLoader.
priv struct CsvTextLoaderAdapter {
  loader : &CsvTextLoader
}

///|
fn CsvTextLoaderAdapter::new(loader : &CsvTextLoader) -> CsvTextLoaderAdapter {
  { loader, }
}

///|
impl TextResourceLoader for CsvTextLoaderAdapter with fn load_text(self, path) -> String {
  self.loader.load_text(path)
}

///|
/// Register CSV loader by name.
pub fn register_csv_loader(name : String, loader : CsvLoader) -> Unit {
  register_text_loader(name, loader.inner)
}

///|
/// Get CSV loader by name.
pub fn get_csv_loader_by_name(name : String) -> CsvLoader {
  { inner: get_text_loader(name) }
}

///|
/// Register default CSV loader.
pub fn set_csv_loader(loader : CsvLoader) -> Unit {
  register_csv_loader("csv/default", loader)
}

///|
/// Get default CSV loader.
pub fn get_csv_loader() -> CsvLoader {
  get_csv_loader_by_name("csv/default")
}
