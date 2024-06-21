pub enum SoundName {
  BUTTON_CLICK
  BUTTON_OVER
  CHAR_SELECT
  DLG_NOTICE
  MENU_DOWN
  MENU_UP
  RACE_SELECT
  SCROLL_UP
  SELECT_MAP
  TAB
  WORLD_SELECT
  DRAG_START
  DRAG_END
  WORLD_MAP_OPEN
  WORLD_MAP_CLOSE
  GAME_START
  JUMP
  DROP
  PICKUP
  PORTAL
  LEVEL_UP
  TOMBSTONE
} derive(Eq, Compare, Debug)

struct Sound {
  id : Int
}

pub fn Sound::new(name : SoundName) -> Sound {
  { id: audio.soundids[name].unwrap() }
}

pub fn Sound::new_from_itemid(itemid : Int) -> Sound {
  let fitemid = format_id(itemid)
  let id = match audio.itemids[fitemid] {
    Some(id) => id
    None => {
      let pid = 10000 * (itemid / 10000)
      let fpid = format_id(pid)
      match audio.itemids[fpid] {
        Some(id) => id
        None => audio.itemids["02000000"].unwrap()
      }
    }
  }
  { id, }
}

pub fn Sound::default() -> Sound {
  { id: 0 }
}

pub fn play(self : Sound) -> Unit {
  if self.id > 0 {
    audio.play_impl(self.id)
  }
}

fn Audio::new() -> Result[Audio, String] {
  // if !BASS_Init(-1, 44100, 0, null, 0) {
  //   return Err("BASS_Init failed")
  // }

  let loader = sound_loader()
  let uisrc = loader.load_res("UI.img")
  let samples = []
  let soundids = []
  let itemids = []
  let add_sound_by_enum = fn(name : SoundName, src : NxNode) -> Unit {
    match sound_from_resource(src) {
      Some((id, sample_id)) => {
        samples.push((id, sample_id))
        soundids.push((name, id))
      }
      None => ()
    }
  }
  add_sound_by_enum(SoundName::BUTTON_CLICK, uisrc["BtMouseClick"])
  add_sound_by_enum(SoundName::BUTTON_OVER, uisrc["BtMouseOver"])
  add_sound_by_enum(SoundName::CHAR_SELECT, uisrc["CharSelect"])
  add_sound_by_enum(SoundName::DLG_NOTICE, uisrc["DlgNotice"])
  add_sound_by_enum(SoundName::MENU_DOWN, uisrc["MenuDown"])
  add_sound_by_enum(SoundName::MENU_UP, uisrc["MenuUp"])
  add_sound_by_enum(SoundName::RACE_SELECT, uisrc["RaceSelect"])
  add_sound_by_enum(SoundName::SCROLL_UP, uisrc["ScrollUp"])
  add_sound_by_enum(SoundName::SELECT_MAP, uisrc["SelectMap"])
  add_sound_by_enum(SoundName::TAB, uisrc["Tab"])
  add_sound_by_enum(SoundName::WORLD_SELECT, uisrc["WorldSelect"])
  add_sound_by_enum(SoundName::DRAG_START, uisrc["DragStart"])
  add_sound_by_enum(SoundName::DRAG_END, uisrc["DragEnd"])
  add_sound_by_enum(SoundName::WORLD_MAP_OPEN, uisrc["WorldmapOpen"])
  add_sound_by_enum(SoundName::WORLD_MAP_CLOSE, uisrc["WorldmapClose"])
  let gamesrc = loader.load_res("Game.img")
  add_sound_by_enum(SoundName::GAME_START, gamesrc["GameIn"])
  add_sound_by_enum(SoundName::JUMP, gamesrc["Jump"])
  add_sound_by_enum(SoundName::DROP, gamesrc["DropItem"])
  add_sound_by_enum(SoundName::PICKUP, gamesrc["PickUpItem"])
  add_sound_by_enum(SoundName::PORTAL, gamesrc["Portal"])
  add_sound_by_enum(SoundName::LEVEL_UP, gamesrc["LevelUp"])
  add_sound_by_enum(SoundName::TOMBSTONE, gamesrc["Tombstone"])
  let add_sound_by_name = fn(itemid : String, src : NxNode) -> Unit {
    match sound_from_resource(src) {
      Some((id, sample_id)) => {
        samples.push((id, sample_id))
        itemids.push((itemid, id))
      }
      None => ()
    }
  }
  let itemsrc = loader.load_res("Item.img").get_object()
  itemsrc.iter(fn(name, node) { add_sound_by_name(name, node["Use"]) })

  // let volume = Setting.SFXVolume.get().load()

  // if !set_sfxvolume(volume) {
  //   return Error.Code.AUDIO
  // }

  Ok(
    {
      samples: @immut/sorted_map.from_array(samples),
      itemids: @immut/sorted_map.from_array(itemids),
      soundids: @immut/sorted_map.from_array(soundids),
    },
  )
}

pub fn close() -> Unit {
  // BASS_Free()
}

pub fn set_sfxvolume(volume : Int) -> Bool {
  // BASS_SetConfig(BASS_CONFIG_GVOL_SAMPLE, volume * 100) == TRUE
  true
}

pub fn play_impl(self : Audio, id : Int) -> Unit {
  match self.samples[id] {
    None => ()
    Some(sample_id) =>
      // let channel = BASS_SampleGetChannel(sample_id, false)
      // BASS_ChannelPlay(channel, true)
      ()
  }
}

pub fn sound_from_resource(src : NxNode) -> (Int, Int)? {
  let desc = src.desc
  let aid = desc.as_object().bind(fn(obj) { obj["__a"] })
  match aid {
    Some(aid) => {
      let id = aid.as_number().unwrap().to_int()

      // let sample = BASS_SampleLoad(true, data, 82, ad.length(), 4, BASS_SAMPLE_OVER_POS)
      // if sample != 0 {
      //   Some((id,sample))
      // } else {
      // let data2 = reinterpret_cast<const char *>(ad.data())
      // let sample2 = BASS_SampleLoad(true, reinterpret_cast<const void *>(data2 + 82), 82, ad.length(), 4, BASS_SAMPLE_OVER_POS)
      // if sample2 == 0 {
      //   // auto ec = BASS_ErrorGetCode()
      //   None
      // } else {
      //   Some((id,sample2))
      // }
      // }
      Some((id, 0))
    }
    None => None
  }
}

pub fn format_id(itemid : Int) -> String {
  @string_format.extend_id(itemid, 8)
}

pub struct Music {
  path : String
}

pub fn Music::new(path : String) -> Music {
  { path, }
}

pub fn play(self : Music) -> Unit {
  // static let mut stream = 0
  // static let mut bgmpath = ""

  // if self.path == bgmpath {
  //   return
  // }

  // let ad = nl.nx.sound.resolve(self.path)
  // let data = reinterpret_cast<const void *>(ad.data())

  // if data {
  //   if stream != 0 {
  //     BASS_ChannelStop(stream)
  //     BASS_StreamFree(stream)
  //   }

  //   stream = BASS_StreamCreateFile(true, data, 82, ad.length(), BASS_SAMPLE_FLOAT | BASS_SAMPLE_LOOP)
  //   BASS_ChannelPlay(stream, true)

  //   bgmpath = self.path
  // }
}

pub fn play_once(self : Music) -> Unit {
  // static let mut stream = 0
  // static let mut bgmpath = ""

  // if self.path == bgmpath {
  //   return
  // }

  // let ad = nl.nx.sound.resolve(self.path)
  // let data = reinterpret_cast<const void *>(ad.data())

  // if data {
  //   if stream != 0 {
  //     BASS_ChannelStop(stream)
  //     BASS_StreamFree(stream)
  //   }

  //   stream = BASS_StreamCreateFile(true, data, 82, ad.length(), BASS_SAMPLE_FLOAT)
  //   BASS_ChannelPlay(stream, true)

  //   bgmpath = self.path
  // }
}

pub fn init_music(self : Audio) -> Result[Unit, String] {
  // let volume = Setting.BGMVolume.get().load()

  // if self.set_bgmvolume(volume).not() {
  //   return Err("Failed to set BGM volume")
  // }

  Ok(())
}

pub fn set_bgmvolume(self : Audio, volume : Int) -> Bool {
  // BASS_SetConfig(BASS_CONFIG_GVOL_STREAM, volume * 100) == TRUE
  true
}

pub fn update_context() -> Unit {

}

struct Audio {
  samples : @immut/sorted_map.Map[Int, Int]
  soundids : @immut/sorted_map.Map[SoundName, Int]
  itemids : @immut/sorted_map.Map[String, Int]
}

let audio : Audio = Audio::new().unwrap()
