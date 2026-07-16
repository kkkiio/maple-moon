///|
/// Public resource address of the font used by standard player-facing game UI.
pub const ADDRESS = "res://UI/Fonts/FusionPixel/fusion-pixel-12px-proportional-zh_hans.ttf"

///|
/// Family name registered with Selene for the standard game UI font.
pub const FAMILY = "Fusion Pixel 12px Proportional"

///|
/// Raster size of standard game UI text, in logical pixels.
pub const SIZE = 12.0

///|
/// Load the standard game UI font from the active resource packs.
///
/// Selene caches the returned handle, so UI packages can call this function at
/// their resource-loading boundary without creating duplicate font assets.
///
/// # Example
/// ```moonbit nocheck
/// let font = load()
/// ignore(font)
/// ```
///
/// # Panics
/// Panics when the configured resource packs do not contain the game UI font.
pub fn load() -> @asset.FontHandle {
  @res.require_font(ADDRESS, FAMILY)
}

///|
/// Build the standard Fusion Pixel text style for player-facing game UI.
///
/// # Example
/// ```moonbit nocheck
/// let font = text_font(bold=true)
/// ignore(font)
/// ```
pub fn text_font(
  size? : Double = SIZE,
  bold? : Bool = false,
) -> @selene_ui.TextFont {
  @selene_ui.TextFont::from_font(load(), size~, bold~)
}
