///|
/// Global registry for async resource loaders.
let async_loader_registry : Map[String, AsyncLoader] = {}

///|
/// Register an async loader by name.
pub fn register_async_loader(name : String, loader : AsyncLoader) -> Unit {
  async_loader_registry.set(name, loader)
}

///|
/// Get a registered async loader by name.
pub fn get_async_loader(name : String) -> AsyncLoader {
  match async_loader_registry.get(name) {
    Some(loader) => loader
    None => panic()
  }
}

///|
/// Register mapx loader.
pub fn set_mapx_loader(loader : AsyncLoader) -> Unit {
  register_async_loader("mapx", loader)
}

///|
/// Get mapx loader.
pub fn get_mapx_loader() -> AsyncLoader {
  get_async_loader("mapx")
}

///|
/// Register map_latest loader.
pub fn set_map_latest_loader(loader : AsyncLoader) -> Unit {
  register_async_loader("map_latest", loader)
}

///|
/// Get map_latest loader.
pub fn get_map_latest_loader() -> AsyncLoader {
  get_async_loader("map_latest")
}

///|
/// Register background set loader.
pub fn set_background_set_loader(loader : AsyncLoader) -> Unit {
  register_async_loader("background_set", loader)
}

///|
/// Get background set loader.
pub fn get_background_set_loader() -> AsyncLoader {
  get_async_loader("background_set")
}

///|
/// Register object loader.
pub fn set_object_loader(loader : AsyncLoader) -> Unit {
  register_async_loader("object", loader)
}

///|
/// Get object loader.
pub fn get_object_loader() -> AsyncLoader {
  get_async_loader("object")
}

///|
/// Register tile loader.
pub fn set_tile_loader(loader : AsyncLoader) -> Unit {
  register_async_loader("tile", loader)
}

///|
/// Get tile loader.
pub fn get_tile_loader() -> AsyncLoader {
  get_async_loader("tile")
}

///|
/// Register mob loader.
pub fn set_mob_loader(loader : AsyncLoader) -> Unit {
  register_async_loader("mob", loader)
}

///|
/// Get mob loader.
pub fn get_mob_loader() -> AsyncLoader {
  get_async_loader("mob")
}

///|
/// Register skill loader.
pub fn set_skill_loader(loader : AsyncLoader) -> Unit {
  register_async_loader("skill", loader)
}

///|
/// Get skill loader.
pub fn get_skill_loader() -> AsyncLoader {
  get_async_loader("skill")
}

///|
/// Register character loader.
pub fn set_character_loader(loader : AsyncLoader) -> Unit {
  register_async_loader("character", loader)
}

///|
/// Get character loader.
pub fn get_character_loader() -> AsyncLoader {
  get_async_loader("character")
}

///|
/// Register afterimage loader.
pub fn set_afterimage_loader(loader : AsyncLoader) -> Unit {
  register_async_loader("afterimage", loader)
}

///|
/// Get afterimage loader.
pub fn get_afterimage_loader() -> AsyncLoader {
  get_async_loader("afterimage")
}

///|
/// Register body loader.
pub fn set_body_loader(loader : AsyncLoader) -> Unit {
  register_async_loader("body", loader)
}

///|
/// Get body loader.
pub fn get_body_loader() -> AsyncLoader {
  get_async_loader("body")
}

///|
/// Register effect loader.
pub fn set_effect_loader(loader : AsyncLoader) -> Unit {
  register_async_loader("effect", loader)
}

///|
/// Get effect loader.
pub fn get_effect_loader() -> AsyncLoader {
  get_async_loader("effect")
}

///|
/// Register face loader.
pub fn set_face_loader(loader : AsyncLoader) -> Unit {
  register_async_loader("face", loader)
}

///|
/// Get face loader.
pub fn get_face_loader() -> AsyncLoader {
  get_async_loader("face")
}

///|
/// Register hair loader.
pub fn set_hair_loader(loader : AsyncLoader) -> Unit {
  register_async_loader("hair", loader)
}

///|
/// Get hair loader.
pub fn get_hair_loader() -> AsyncLoader {
  get_async_loader("hair")
}

///|
/// Register item special loader.
pub fn set_item_special_loader(loader : AsyncLoader) -> Unit {
  register_async_loader("item_special", loader)
}

///|
/// Get item special loader.
pub fn get_item_special_loader() -> AsyncLoader {
  get_async_loader("item_special")
}

///|
/// Register item loader.
pub fn set_item_loader(loader : AsyncLoader) -> Unit {
  register_async_loader("item", loader)
}

///|
/// Get item loader.
pub fn get_item_loader() -> AsyncLoader {
  get_async_loader("item")
}

///|
/// Register UIWindow2 loader.
pub fn set_ui_window_2_loader(loader : AsyncLoader) -> Unit {
  register_async_loader("ui_window_2", loader)
}

///|
/// Get UIWindow2 loader.
pub fn get_ui_window_2_loader() -> AsyncLoader {
  get_async_loader("ui_window_2")
}

///|
/// Register UIWindow4 loader.
pub fn set_ui_window_4_loader(loader : AsyncLoader) -> Unit {
  register_async_loader("ui_window_4", loader)
}

///|
/// Get UIWindow4 loader.
pub fn get_ui_window_4_loader() -> AsyncLoader {
  get_async_loader("ui_window_4")
}

///|
/// Register npc loader.
pub fn set_npc_loader(loader : AsyncLoader) -> Unit {
  register_async_loader("npc", loader)
}

///|
/// Get npc loader.
pub fn get_npc_loader() -> AsyncLoader {
  get_async_loader("npc")
}

///|
/// Register string loader.
pub fn set_string_loader(loader : AsyncLoader) -> Unit {
  register_async_loader("string", loader)
}

///|
/// Get string loader.
pub fn get_string_loader() -> AsyncLoader {
  get_async_loader("string")
}

///|
/// Loader interface for text resources.
pub(open) trait TextResourceLoader {
  async load_text(self : Self, path : String) -> String
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
pub async fn TextLoader::load_text(self : TextLoader, path : String) -> String {
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
  async load_text(self : Self, path : String) -> String
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
pub async fn CsvLoader::load_text(self : CsvLoader, path : String) -> String {
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
impl TextResourceLoader for CsvTextLoaderAdapter with load_text(self, path) -> String {
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
