pub fn set_hardware_info(self : Configuration) -> Unit {
  self.set_hwid("9A9A9A9A9A9A", "9A9A9A9A")
  self.set_macs("11-22-33-44-55-66")
}

struct Configuration {
  mut macs : String
  mut hwid : String
  mut volume_serial_number : String
  mut worldid : Int
  mut channelid : Int
  mut admin : Bool
  settings : Map[String, String]
}

fn Configuration::default() -> Configuration {
  {
    macs: "",
    hwid: "",
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

pub(open) trait ConfigEntry {
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

pub let configFontPathNormal : StringEntry = StringEntry::new(
  "FontPathNormal", "Roboto-Regular",
)

pub let configFontPathBold : StringEntry = StringEntry::new(
  "FontPathBold", "Roboto-Bold",
)
