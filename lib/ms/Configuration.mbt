// app/src/main/cpp/src/Configuration.h
// app/src/main/cpp/src/Configuration.cpp
fn set_hardware_info(self : Configuration) -> Unit {
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
  mut rightclicksell : Bool
  mut show_weekly : Bool
  mut start_shown : Bool
  mut macs : String
  mut hwid : String
  mut max_width : Int
  mut max_height : Int
  mut volumeSerialNumber : String
  mut worldid : Int
  mut channelid : Int
  mut admin : Bool
  settings : @hashmap.HashMap[String, String]
}

fn Configuration::default() -> Configuration {
  {
    rightclicksell: false,
    show_weekly: true,
    start_shown: false,
    macs: "",
    hwid: "",
    max_width: 2560,
    max_height: 1440,
    volumeSerialNumber: "",
    worldid: 0,
    channelid: 0,
    admin: false,
    settings: @hashmap.HashMap::new(),
  }
}

fn set_hwid(
  self : Configuration,
  hwid : String,
  volumeSerialNumber : String
) -> Unit {
  let part1 = volumeSerialNumber.substring(start=0, end=2)
  let part2 = volumeSerialNumber.substring(start=2, end=4)
  let part3 = volumeSerialNumber.substring(start=4, end=6)
  let part4 = volumeSerialNumber.substring(start=6, end=8)
  self.hwid = "\(hwid)_\(part4)\(part3)\(part2)\(part1)"
}

fn set_macs(self : Configuration, macs : String) -> Unit {
  self.macs = macs
}

let default_settings : @immut/hashmap.Map[String, String] = @immut/hashmap.from_array(
  [],
)
