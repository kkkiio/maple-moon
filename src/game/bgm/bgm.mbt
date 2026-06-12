///|
priv struct BgmState {
  mut current_key : String?
  mut current_entity : @entity.Entity?
}

///|
let bgm_state : Ref[BgmState] = Ref({ current_key: None, current_entity: None })

///|
fn bgm_asset_path(bgm_key : String) -> String? {
  guard bgm_key.find("/") is Some(split) else { return None }
  let group = bgm_key[:split]
  let name = bgm_key[split + 1:]
  if !group.has_prefix("Bgm") || !group.has_suffix(".img") || name.is_empty() {
    return None
  }
  Some("assets/sound/\{group}/\{name}.mp3")
}

///|
fn current_key() -> String? {
  bgm_state.val.current_key
}

///|
/// Stop and clear the current background music.
pub fn clear_bgm() -> Unit {
  let state = bgm_state.val
  match state.current_entity {
    Some(entity) => {
      @audio.stop_audio(entity)
      entity.destroy()
    }
    None => ()
  }
  state.current_entity = None
  state.current_key = None
}

///|
/// Sync the current background music to the requested map bgm key.
pub fn sync_map_bgm(bgm_key : String) -> Unit {
  if bgm_key.is_empty() {
    clear_bgm()
    return
  }
  if current_key() == Some(bgm_key) {
    return
  }

  clear_bgm()

  guard bgm_asset_path(bgm_key) is Some(path) else {
    @log.warn("unsupported map bgm key", data={ "bgm_key": bgm_key })
    return
  }

  let entity = @entity.Entity()
  @audio.attach_audio(
    entity,
    @audio.AudioPlayer::from_path(path),
    settings=@audio.PlaybackSettings::looped().with_volume(0.7),
  )
  let state = bgm_state.val
  state.current_key = Some(bgm_key)
  state.current_entity = Some(entity)
  @log.info("map bgm started", data={ "bgm_key": bgm_key, "path": path })
}
