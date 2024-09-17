// app/src/main/cpp/src/Configuration.h
// app/src/main/cpp/src/Configuration.cpp
pub fn set_hardware_info(self : Configuration) -> Unit {
  self.set_hwid("9A9A9A9A9A9A", "9A9A9A9A")
  self.set_macs("11-22-33-44-55-66")
}

// const char *FILENAME = "Settings";
// const char *TITLE = "msclient";
// const char *VERSION = "0.4.0";
// const char *JOINLINK = "https://www.nexon.com/account/en/create";
// const char *WEBSITE = "http://maplestory.nexon.net/";
// const char *FINDID = "https://www.nexon.com/account/en/login";
// const char *FINDPASS = "https://www.nexon.com/account/en/reset-password";
// const char *RESETPIC = "https://www.nexon.com/account/en/login";
// const char *CHARGENX = "https://billing.nexon.net/PurchaseNX";
// const bool SHOW_FPS = false;
// const bool SHOW_PACKETS = true;
// const bool AUTO_LOGIN = false;
// const uint8_t auto_world = 0;
// const uint8_t auto_channel = 0;
// const std::string auto_acc = "";
// const std::string auto_pass = "";
// const std::string auto_pic = "";
// const int32_t auto_cid = 0;

// bool rightclicksell = false;
// bool show_weekly = true;
// bool start_shown = false;
// std::string MACS;
// std::string HWID;
// int16_t MAXWIDTH;
// int16_t MAXHEIGHT;
// std::string VolumeSerialNumber;
// uint8_t worldid;
// uint8_t channelid;
// bool admin;
// TypeMap<Entry> settings;

struct Configuration {
  // mut rightclicksell : Bool
  // mut show_weekly : Bool
  // mut start_shown : Bool
  mut macs : String
  mut hwid : String
  // mut max_width : Int
  // mut max_height : Int
  mut volume_serial_number : String
  mut worldid : Int
  mut channelid : Int
  mut admin : Bool
  settings : Map[String, String]
}

fn Configuration::default() -> Configuration {
  {
    // rightclicksell: false,
    // show_weekly: true,
    // start_shown: false,
    macs: "",
    hwid: "",
    // max_width: 2560,
    // max_height: 1440,
    volume_serial_number: "",
    worldid: 0,
    channelid: 0,
    admin: false,
    settings: Map::new(),
  }
}

let configuration : Configuration = Configuration::default()

pub fn global() -> Configuration {
  configuration
}

pub fn get_volume_serial_number(self : Configuration) -> String {
  self.volume_serial_number
}

pub fn get_hwid(self : Configuration) -> String {
  self.hwid
}

fn set_hwid(
  self : Configuration,
  hwid : String,
  volume_serial_number : String
) -> Unit {
  self.volume_serial_number = volume_serial_number
  let part1 = volume_serial_number.substring(start=0, end=2)
  let part2 = volume_serial_number.substring(start=2, end=4)
  let part3 = volume_serial_number.substring(start=4, end=6)
  let part4 = volume_serial_number.substring(start=6, end=8)
  self.hwid = "\{hwid}_\{part4}\{part3}\{part2}\{part1}"
}

pub fn get_macs(self : Configuration) -> String {
  self.macs
}

fn set_macs(self : Configuration, macs : String) -> Unit {
  self.macs = macs
}

pub fn get_admin(self : Configuration) -> Bool {
  self.admin
}

pub fn set_admin(self : Configuration, admin : Bool) -> Unit {
  self.admin = admin
}

pub fn get_worldid(self : Configuration) -> Int {
  self.worldid
}

pub fn set_worldid(self : Configuration, worldid : Int) -> Unit {
  self.worldid = worldid
}

pub fn get_channelid(self : Configuration) -> Int {
  self.channelid
}

pub fn set_channelid(self : Configuration, channelid : Int) -> Unit {
  self.channelid = channelid
}

pub trait ConfigEntry {
  name(Self) -> String
  new(String, String) -> Self
}

struct StringEntry {
  name : String
  default : String
}

pub fn name(self : StringEntry) -> String {
  self.name
}

pub fn StringEntry::new(name : String, default : String) -> StringEntry {
  { name, default }
}

pub fn load(self : StringEntry) -> String {
  configuration.settings.get(self.name).or(self.default)
}

pub fn save(self : StringEntry, value : String) -> Unit {
  configuration.settings[self.name] = value
}

struct BoolEntry {
  name : String
  mut value : String
}

pub fn name(self : BoolEntry) -> String {
  self.name
}

pub fn BoolEntry::new(name : String, value : String) -> BoolEntry {
  { name, value }
}

pub fn load(self : BoolEntry) -> Bool {
  self.value == "true"
}

pub fn save(self : BoolEntry, value : Bool) -> Unit {
  self.value = value.to_string()
}

struct IntEntry {
  name : String
  mut value : String
}

pub fn name(self : IntEntry) -> String {
  self.name
}

pub fn IntEntry::new(name : String, value : String) -> IntEntry {
  { name, value }
}

pub fn load(self : IntEntry) -> Int {
  @strconv.parse_int?(self.value).or(0)
}

pub fn save(self : IntEntry, value : String) -> Unit {
  self.value = value
}

// struct PointEntry {
//   name : String
//   mut value : String
// }

// pub fn name(self : PointEntry) -> String {
//   self.name
// }

// pub fn PointEntry::new(name : String, value : String) -> PointEntry {
//   { name, value }
// }

// pub fn load(self : PointEntry) -> Point[Int] {
//   // (\d+,\d+)
//   abort("TODO")
// }

// pub fn save(self : PointEntry, value : Point[Int]) -> Unit {
//   let x = value.x
//   let y = value.y
//   self.value = "(\(x),\(y))"
// }

// IP Address which the client will connect to
// let configServerIP : StringEntry = StringEntry::new("ServerIP", "127.0.0.1")

// Port which the client will connect to
// let configServerPort : StringEntry = StringEntry::new("ServerPort", "8484")

// Whether to start in full screen mode
// let configFullscreen : BoolEntry = BoolEntry::new("Fullscreen", "false")

// The width of the screen
// let configWidth : IntEntry = IntEntry::new("Width", "1366")

// The height of the screen
// let configHeight : IntEntry = IntEntry::new("Height", "768")

// Whether to use VSync
// let configVSync : BoolEntry = BoolEntry::new("VSync", "true")

// The normal font which will be used
pub let configFontPathNormal : StringEntry = StringEntry::new(
  "FontPathNormal", "Roboto-Regular",
)

// The bold font which will be used
pub let configFontPathBold : StringEntry = StringEntry::new(
  "FontPathBold", "Roboto-Bold",
)

// Music Volume
// Number from 0 to 100
// let configBGMVolume : IntEntry = IntEntry::new("BGMVolume", "50")

// Sound Volume
// Number from 0 to 100
// let configSFXVolume : IntEntry = IntEntry::new("SFXVolume", "50")

// Whether to save the last used account name
// let configSaveLogin : BoolEntry = BoolEntry::new("SaveLogin", "false")

// The last used account name
// let configDefaultAccount : StringEntry = StringEntry::new("Account", "")

// The last used world
// let configDefaultWorld : IntEntry = IntEntry::new("World", "0")

// The last used channel
// let configDefaultChannel : IntEntry = IntEntry::new("Channel", "0")

// The last used region
// let configDefaultRegion : IntEntry = IntEntry::new("Region", "5")

// The last used character
// let configDefaultCharacter : IntEntry = IntEntry::new("Character", "0")

// Whether to show UIChatBar
// let configChatopen : BoolEntry = BoolEntry::new("Chatopen", "false")

// The default position of UIStatsInfo
// configLet posSTATS : PointEntry = PointEntry::new("PosSTATS", { x: 72, y: 72 })

// The default position of UIEquipInventory
// configLet posEQINV : PointEntry = PointEntry::new("PosEQINV", { x: 250, y: 160 })

// The default position of UIItemInventory
// configLet posINV : PointEntry = PointEntry::new("PosINV", { x: 300, y: 160 })

// The default position of UISkillBook
// configLet posSKILL : PointEntry = PointEntry::new("PosSKILL", { x: 96, y: 96 })

// The default position of UIQuestLog
// configLet posQUEST : PointEntry = PointEntry::new("PosQUEST", { x: 300, y: 160 })

// The default position of UIWorldMap
// configLet posMAP : PointEntry = PointEntry::new("PosMAP", { x: 100, y: 35 })

// The default position of UIUserList
// configLet posUSERLIST : PointEntry = PointEntry::new("PosUSERLIST", { x: 104, y: 104 })

// The default position of UIChatBar
// configLet posCHAT : PointEntry = PointEntry::new("PosCHAT", { x: 0, y: 572 })

// The default position of UIMiniMap
// configLet posMINIMAP : PointEntry = PointEntry::new("PosMINIMAP", { x: 0, y: 0 })

// The default position of UIShop
// configLet posSHOP : PointEntry = PointEntry::new("PosSHOP", { x: 146, y: 48 })

// The default position of UINotice
// configLet posNOTICE : PointEntry = PointEntry::new("PosNOTICE", { x: 400, y: 285 })

// The default position of UIChat and UIRank
// configLet posMAPLECHAT : PointEntry = PointEntry::new("PosMAPLECHAT", { x: 50, y: 46 })

// The default position of UIChannel
// configLet posCHANNEL : PointEntry = PointEntry::new("PosCHANNEL", { x: 215, y: 100 })

// The default position of UIJoypad
// configLet posJOYPAD : PointEntry = PointEntry::new("PosJOYPAD", { x: 312, y: 134 })

// The default position of UIEvent
// configLet posEVENT : PointEntry = PointEntry::new("PosEVENT", { x: 99, y: 100 })

// The default position of UIKeyConfig
// configLet posKEYCONFIG : PointEntry = PointEntry::new("PosKEYCONFIG", { x: 65, y: 50 })

// The default position of UIOptionMenu
// configLet posOPTIONMENU : PointEntry = PointEntry::new("PosUSERLIST", { x: 170, y: -1 })

// The default position of UICharInfo
// configLet posCHARINFO : PointEntry = PointEntry::new("PosCHARINFO", { x: 264, y: 264 })

// The default type of UIMiniMap
// let configMiniMapType : IntEntry = IntEntry::new("MiniMapType", "0")

// Whether to use a simple version of UIMiniMap
// let configMiniMapSimpleMode : BoolEntry = BoolEntry::new(
//   "MiniMapSimpleMode", "false",
// )

// Whether to use default helpers for UIMiniMap
// let configMiniMapDefaultHelpers : BoolEntry = BoolEntry::new(
//   "MiniMapDefaultHelpers", "false",
// )
