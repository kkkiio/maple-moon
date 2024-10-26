struct Module {
  mut characters : Array[CharEntry]
  mut selected_index : Int?
  task_scheduler : (BgTask) -> Unit
  // to reconnect
  mut input_acc_pass : (String, String)?
  mut select_cid : Int?
}

pub fn Module::new(task_scheduler : (BgTask) -> Unit) -> Module {
  {
    characters: [],
    selected_index: None,
    task_scheduler,
    input_acc_pass: None,
    select_cid: None,
  }
}

pub fn make_handlers(self : Module) -> Array[(@net.Opcode, @net.PacketHandler)] {
  [
    (@net.LOGIN_RESULT, LoginResultHandler::new()),
    (SERVER_STATUS, ServerStatusHandler::new()),
    (SERVER_LIST, ServerlistHandler::new()),
    (CHAR_LIST, ({ module: self } : CharlistHandler)),
    (CHARNAME_RESPONSE, CharnameResponseHandler::new()),
    (SERVER_IP, ServerIPHandler::new(self)),
    (ADD_NEWCHAR_ENTRY, ({ module: self } : AddNewCharEntryHandler)),
  ]
  // (DELCHAR_RESPONSE, DeleteCharResponseHandler::new()),
  // (RECOMMENDED_WORLDS, RecommendedWorldsHandler::new()),
}

pub fn get_selected_char(self : Module) -> CharEntry? {
  self.selected_index.map(fn(index) { self.characters[index] })
}

pub fn new_login_start_packet() -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::LOGIN_START)
}

pub fn login(self : Module, acc : String, pass : String) -> Unit {
  self.input_acc_pass = Some((acc, pass))
  let packet = @net.OutPacket::new(@net.OutPacketOpcode::LOGIN)
  let volume_serial_number = @config.global().get_volume_serial_number()
  let part1 = volume_serial_number.substring(start=0, end=2)
  let part2 = volume_serial_number.substring(start=2, end=4)
  let part3 = volume_serial_number.substring(start=4, end=6)
  let part4 = volume_serial_number.substring(start=6, end=8)
  let h = @net.hex_to_dec?(part4).unwrap()
  let w = @net.hex_to_dec?(part3).unwrap()
  let i = @net.hex_to_dec?(part2).unwrap()
  let d = @net.hex_to_dec?(part1).unwrap()
  packet
  ..write_string(acc)
  ..write_string(pass)
  ..skip(6)
  ..write_byte(h)
  ..write_byte(w)
  ..write_byte(i)
  ..write_byte(d)
  .dispatch()
}

/// Handler for a packet that contains the response to an attempt at logging in
struct LoginResultHandler {} derive(Default)

pub fn LoginResultHandler::new() -> LoginResultHandler {
  LoginResultHandler::default()
}

pub fn handle(self : LoginResultHandler, recv : @net.InPacket) -> Unit!Error {
  // auto loginwait = UI::get().get_element<UILoginWait>();

  // if (loginwait && loginwait->get().is_active()) {
  //     std::function<void()> okhandler = loginwait->get().get_handler();

  //     // Remove previous UIs
  //     UI::get().remove(UIElement::Type::LOGIN_NOTICE);
  //     UI::get().remove(UIElement::Type::LOGIN_WAIT);
  //     UI::get().remove(UIElement::Type::TOS);
  //     UI::get().remove(UIElement::Type::GENDER);

  // The packet should contain a 'reason' integer which can signify
  // various things
  match recv.read_int!() {
    // Login successful
    // The packet contains information on the account, so we initialize
    // the account with it.
    0 => {
      let account = parse_account!(recv)
      @config.global().set_admin(account.admin)
      // Save the "Login ID" if the box for it on the login screen is
      // checked
      //             if (Setting<SaveLogin>::get().load()) {
      //                 Setting<DefaultAccount>::get().save(account.name);
      //             }

      // AfterLoginPacket("1111").dispatch();

      // Request the list of worlds and channels online.
      fn_server_req()
    }
    //         // Login unsuccessful
    //         // The LoginNotice displayed will contain the specific information
    //         switch (reason) {
    //             case 2:
    //                 UI::get().emplace<UILoginNotice>(
    //                     UILoginNotice::Message::BLOCKED_ID,
    //                     okhandler);
    //                 break;
    //             case 5:
    //                 UI::get().emplace<UILoginNotice>(
    //                     UILoginNotice::Message::NOT_REGISTERED,
    //                     okhandler);
    //                 break;
    //             case 7:
    //                 UI::get().emplace<UILoginNotice>(
    //                     UILoginNotice::Message::ALREADY_LOGGED_IN,
    //                     okhandler);
    //                 break;
    //             case 13:
    //                 UI::get().emplace<UILoginNotice>(
    //                     UILoginNotice::Message::UNABLE_TO_LOGIN_WITH_IP,
    //                     okhandler);
    //                 break;
    23 =>
      // UI::get().emplace<UITermsOfService>(okhandler); break;
      fn_tos()
    //             default:
    //                 // Other reasons
    //                 if (reason > 0) {
    //                     auto reasonbyte = static_cast<int8_t>(reason - 1);

    //                     UI::get().emplace<UILoginNotice>(reasonbyte, okhandler);
    //                 }

    //                 break;
    //         }
    _ as reason => @log.warn({ "reason": reason }, "login failed")
  }
  // }
}

struct ServerStatusHandler {} derive(Default)

pub fn ServerStatusHandler::new() -> ServerStatusHandler {
  ServerStatusHandler::default()
}

pub fn handle(self : ServerStatusHandler, recv : @net.InPacket) -> Unit!Error {
  // Possible values for status:
  // 0 - Normal
  // 1 - Highly populated
  // 2 - Full
  recv.read_short!() |> ignore // status
}

struct ServerlistHandler {
  mut worlds : Array[World]
}

pub fn ServerlistHandler::new() -> ServerlistHandler {
  { worlds: [] }
}

pub fn handle(self : ServerlistHandler, recv : @net.InPacket) -> Unit!Error {
  while recv.available() {
    let world = parse_world!(recv)
    if world.wid != -1 {
      self.worlds.push(world)
    } else { // end of list
      let worlds = self.worlds
      self.worlds = []
      @log.debug({ "load": worlds[0].chloads[0] }, "server list")
      enter_world(0, 0)
      break
    }
  }
}

fn enter_world(worldId : Int, channelId : Int) -> Unit {
  @config.global().set_worldid(worldId)
  @config.global().set_channelid(channelId)
  fn_char_list_req(worldId, channelId)
}

fn fn_char_list_req(worldId : Int, channelId : Int) -> Unit {
  new_char_list_request_packet(worldId, channelId).dispatch()
}

fn new_char_list_request_packet(
  worldId : Int,
  channelId : Int
) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::CHAR_LIST_REQUEST)
  ..write_byte((0).to_byte())
  ..write_byte(worldId.to_byte())
  ..write_byte(channelId.to_byte())
}

struct CharlistHandler {
  module : Module
}

pub fn handle(self : CharlistHandler, recv : @net.InPacket) -> Unit!Error {
  let channel_id = recv.read_ubyte!()
  let characters = []

  // Parse all characters
  let charcount = recv.read_byte!()
  for i = 0; i < charcount; i = i + 1 {
    characters.push(parse_charentry!(recv))
  }
  self.module.characters = characters
  self.module.selected_index = None
  let pic = recv.read_byte!()
  let slots = recv.read_int!()

  // TODO: allow player to select character
  if characters.length() > 0 {
    match pic {
      // 0 => check_pic("")
      2 => {
        let cid = match self.module.select_cid {
          Some(cid) => cid
          None => characters[0].id
        }
        self.module.select_cid = Some(cid)
        new_select_char_packet(cid).dispatch()
      }
      _ => fail!("pic=\{pic} not ok")
    }
  } else {
    @log.info({}, "no characters, creating new one")
    new_name_char_packet(test_name).dispatch()
  }
}

struct ServerIPHandler {
  module : Module
}

fn ServerIPHandler::new(module : Module) -> ServerIPHandler {
  { module, }
}

pub fn handle(self : ServerIPHandler, recv : @net.InPacket) -> Unit! {
  recv.skip_byte!()
  let (_, port) = parse_login!(recv)
  let cid = recv.read_int!()
  match self.module.characters.search_by(fn(c) { c.id == cid }) {
    Some(i) => self.module.selected_index = Some(i)
    None => fail!("no character with id=\{cid}")
  }
  @net.PacketProcessor::get().connect_channel(port)
  (self.module.task_scheduler)({ cid, })
}

struct CharnameResponseHandler {} derive(Default)

pub fn CharnameResponseHandler::new() -> CharnameResponseHandler {
  CharnameResponseHandler::default()
}

pub fn handle(self : CharnameResponseHandler, recv : @net.InPacket) -> Unit! {
  let name = recv.read_string!()
  let used = recv.read_bool!()
  let c = ExplorerCreator::new(
    etc_loader().load_res(["MakeCharInfo.img", "Info"]),
  )
  c.send_naming_result(name, used)
}

struct AddNewCharEntryHandler {
  module : Module
}

pub fn handle(self : AddNewCharEntryHandler, recv : @net.InPacket) -> Unit! {
  recv.skip!(1)
  let character = parse_charentry!(recv)
  self.module.characters.push(character)
}

struct DeleteCharResponseHandler {} derive(Default)

struct RecommendedWorldsHandler {} derive(Default)

fn fn_server_req() -> Unit {
  new_server_request_packet().dispatch()
}

fn new_server_request_packet() -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::SERVERLIST_REQUEST)
}

fn fn_tos() -> Unit {
  new_tos_packet().dispatch()
}

fn new_tos_packet() -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::ACCEPT_TOS)..write_byte(
    (1).to_byte(),
  )
}

fn parse_account(recv : @net.InPacket) -> Account!Error {
  recv.skip_short!()
  let accid = recv.read_int!()
  let female = recv.read_byte!()
  let admin = recv.read_bool!()
  recv.skip_byte!() // Admin
  recv.skip_byte!() // Country Code
  let name = recv.read_string!()
  recv.skip_byte!()
  let muted = recv.read_bool!()
  recv.skip_long!() // muted until
  recv.skip_long!() // creation date
  recv.skip_int!() // Remove "Select the world you want to play in"
  let pin = recv.read_bool!() // 0 - Enabled, 1 - Disabled
  let pic = recv.read_byte!() // 0 - Register, 1 - Ask, 2 - Disabled
  { accid, female, admin, name, muted, pin, pic }
}

struct Account {
  accid : Int
  female : Int
  admin : Bool
  name : String
  muted : Bool
  pin : Bool
  pic : Int
}

pub struct StatsEntry {
  name : String
  female : Bool
  level : Int
  job : Int
  str : Int
  dex : Int
  int : Int
  luk : Int
  hp : Int
  max_hp : Int
  mp : Int
  max_mp : Int
  ap : Int
  sp : Int
  fame : Int
  exp : Int64
  mapid : Int
  portal : Int
}

pub struct LookEntry {
  female : Bool
  skin : Int
  faceid : Int
  hairid : Int
  equips : Map[Int, Int]
  maskedequips : Map[Int, Int]
  petids : Array[Int]
}

pub struct CharEntry {
  stats : StatsEntry
  look : LookEntry
  id : Int
}

struct World {
  name : String
  message : String
  chloads : Array[Int]
  channelcount : Int
  flag : Int
  wid : Int
}

fn parse_world(recv : @net.InPacket) -> World! {
  let wid = recv.read_byte!()
  if wid == -1 {
    return { name: "", message: "", chloads: [], channelcount: 0, flag: 0, wid }
  }
  let name = recv.read_string!()
  let flag = recv.read_ubyte!()
  let message = recv.read_string!()
  recv.skip!(5)
  let chloads = []
  let channelcount = recv.read_ubyte!()
  for i = 0; i < channelcount; i = i + 1 {
    recv.read_string!() |> ignore // channel name
    chloads.push(recv.read_int!())
    recv.skip!(1)
    recv.skip!(2)
  }
  recv.skip!(2) // balloon size
  // recv.skip(10);  // balloon size 1 and msg "test"

  { name, message, chloads, channelcount, flag, wid }
}

fn parse_charentry(recv : @net.InPacket) -> CharEntry! {
  let id = recv.read_int!()
  let stats = parse_stats!(recv)
  let look = parse_look!(recv)
  recv.read_bool!() |> ignore // 'rankinfo' bool
  if recv.read_bool!() {
    let currank = recv.read_int!()
    let rankmv = recv.read_int!()
    let curjobrank = recv.read_int!()
    let jobrankmv = recv.read_int!()
    let rankmc = if rankmv > 0 { '+' } else if rankmv < 0 { '-' } else { '=' }
    let jobrankmc = if jobrankmv > 0 {
      '+'
    } else if jobrankmv < 0 {
      '-'
    } else {
      '='
    }
    // stats.rank = (currank, rankmc)
    // stats.jobrank = (curjobrank, jobrankmc)
  }
  { stats, look, id }
}

pub fn parse_stats(recv : @net.InPacket) -> StatsEntry! {
  let name = recv.read_padded_string!(13)
  let female = recv.read_bool!()
  recv.read_byte!() |> ignore // skin
  recv.read_int!() |> ignore // face
  recv.read_int!() |> ignore // hair
  let petids = []
  for i = 0; i < 3; i = i + 1 {
    petids.push(recv.read_long!())
  }
  let level = recv.read_ubyte!()
  let job = recv.read_ushort!()
  let str = recv.read_ushort!()
  let dex = recv.read_ushort!()
  let int = recv.read_ushort!()
  let luk = recv.read_ushort!()
  let hp = recv.read_ushort!()
  let max_hp = recv.read_ushort!()
  let mp = recv.read_ushort!()
  let max_mp = recv.read_ushort!()
  let ap = recv.read_ushort!()
  let sp = recv.read_ushort!()
  let exp = recv.read_uint!()
  let fame = recv.read_short!()
  recv.skip!(4) // gachaexp
  let mapid = recv.read_int!()
  let portal = recv.read_ubyte!()
  recv.skip!(4) // timestamp
  {
    name,
    level,
    job,
    str,
    dex,
    int,
    luk,
    hp,
    max_hp,
    mp,
    max_mp,
    ap,
    sp,
    fame,
    exp: exp.to_int64(),
    female,
    mapid,
    portal,
  }
}

fn parse_look(recv : @net.InPacket) -> LookEntry! {
  let female = recv.read_bool!()
  let skin = recv.read_ubyte!()
  let faceid = recv.read_int!()
  recv.read_bool!() |> ignore // megaphone
  let hairid = recv.read_int!()
  let equips = {}
  loop recv.read_ubyte!() {
    0xFF => ()
    eqslot => {
      equips.set(eqslot, recv.read_int!())
      continue recv.read_ubyte!()
    }
  }
  let maskedequips = {}
  loop recv.read_ubyte!() {
    0xFF => ()
    mskeqslot => {
      maskedequips.set(mskeqslot, recv.read_int!())
      continue recv.read_ubyte!()
    }
  }
  maskedequips.set(-111, recv.read_int!())
  let petids = []
  for i in 0..<3 {
    petids.push(recv.read_int!())
  }
  { female, skin, faceid, hairid, equips, maskedequips, petids }
}

fn parse_login(recv : @net.InPacket) -> (String, Int)! {
  recv.skip_byte!()
  let addrstr = []
  for i = 0; i < 4; i = i + 1 {
    addrstr.push(recv.read_byte!())
  }
  let portstr = recv.read_short!()
  (addrstr.join("."), portstr)
}

/// Requests being logged-in to a channel server with the specified character
pub fn new_player_login_packet(cid : Int) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::PLAYER_LOGIN)..write_int(cid)
}

fn etc_loader() -> @resource.SyncLoader {
  @resource.SyncLoader::new("etc")
}

pub trait BgTask {
  update(Self) -> Bool
}

struct ConnectChannelTask {
  cid : Int
}

pub fn update(self : ConnectChannelTask) -> Bool {
  if @net.PacketProcessor::get().get_status() == @net.READY {
    new_player_login_packet(self.cid).dispatch()
    true
  } else {
    false
  }
}

pub fn connect_if_needed(self : Module) -> Unit {
  guard let CLOSED = @net.PacketProcessor::get().get_status() else {
    _ => return
  }
  guard let Some((acc, pass)) = self.input_acc_pass else { None => return  }
  login(self, acc, pass)
}
