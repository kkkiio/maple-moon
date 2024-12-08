///|
struct Module {
  processor : @net.PacketProcessor
  mut characters : Array[@character.CharEntry]
  mut selected_index : Int?
  mut receiving_server_list : Array[World]
  mut login_task : LoginTask?
  mut connect_task : ConnectChannelTask?
  // to reconnect
  mut input_acc_pass : (String, String)?
  mut select_cid : Int?
}

///|
pub fn Module::new(processor : @net.PacketProcessor) -> Module {
  {
    processor,
    characters: [],
    selected_index: None,
    receiving_server_list: [],
    login_task: None,
    connect_task: None,
    input_acc_pass: None,
    select_cid: None,
  }
}

///|
pub fn make_handlers(
  self : Module,
  transition : (Int, Int) -> Unit,
  load_player : (@character.CharEntry) -> @player.Player!,
  inventory : @inventory.Inventory,
  setup_game_ui : (@player.Player) -> Unit
) -> Map[@net.Opcode, (@net.InPacket) -> Unit] {
  [
    (
      @net.LOGIN_RESULT,
      @net.with_log(
        @net.LOGIN_RESULT,
        fn(recv : @net.InPacket) { self.handle_login_result!(recv) },
      ),
    ),
    (
      @net.SERVER_STATUS,
      @net.with_log(
        @net.SERVER_STATUS,
        fn(recv : @net.InPacket) { handle_server_status!(recv) },
      ),
    ),
    (
      @net.SERVER_LIST,
      @net.with_log(
        @net.SERVER_LIST,
        fn(recv : @net.InPacket) { handle_server_list!(self, recv) },
      ),
    ),
    (
      @net.CHAR_LIST,
      @net.with_log(
        @net.CHAR_LIST,
        fn(recv : @net.InPacket) { handle_char_list!(self, recv) },
      ),
    ),
    (
      @net.CHARNAME_RESPONSE,
      @net.with_log(
        @net.CHARNAME_RESPONSE,
        fn(recv : @net.InPacket) { handle_charname_response!(recv) },
      ),
    ),
    (
      @net.SERVER_IP,
      @net.with_log(
        @net.SERVER_IP,
        fn(recv : @net.InPacket) { handle_server_ip!(self, recv) },
      ),
    ),
    (
      @net.ADD_NEWCHAR_ENTRY,
      @net.with_log(
        @net.ADD_NEWCHAR_ENTRY,
        fn(recv : @net.InPacket) { handle_add_new_char_entry!(self, recv) },
      ),
    ),
    (
      @net.SET_FIELD,
      @net.with_log(
        @net.SET_FIELD,
        fn(recv : @net.InPacket) {
          handle_set_field!(
            transition, self, load_player, inventory, setup_game_ui, recv,
          )
        },
      ),
    ),
  ]
  |> Map::from_array()
}

///|
pub fn get_selected_char(self : Module) -> @character.CharEntry? {
  self.selected_index.map(fn(index) { self.characters[index] })
}

///|
pub fn new_login_start_packet() -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::LOGIN_START)
}

///|
pub fn login(self : Module, account : String, password : String) -> Unit {
  self.input_acc_pass = Some((account, password))
  self.login_task = Some(
    { processor: self.processor, state: ACQ_CONN, account, password },
  )
  self.connect_task = None
}

///|
struct LoginTask {
  processor : @net.PacketProcessor
  mut state : LoginState
  account : String
  password : String
}

///|
enum LoginState {
  ACQ_CONN
  START_SEND
  LOGIN_SEND
}

///|
fn update(self : LoginTask) -> Unit {
  let p = self.processor
  match p.get_status() {
    READY =>
      match self.state {
        ACQ_CONN => {
          fn_login_start()
          self.state = START_SEND
        }
        START_SEND => {
          fn_login(self.account, self.password) // TODO: allow select account
          self.state = LOGIN_SEND
        }
        LOGIN_SEND => ()
      }
    OPENED => ()
    CLOSED => {
      p.connect_login()
      self.state = ACQ_CONN
    }
  }
}

///|
fn fn_login_start() -> Unit {
  new_login_start_packet().dispatch()
}

///|
fn fn_login(account : String, password : String) -> Unit {
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
  ..write_string(account)
  ..write_string(password)
  ..skip(6)
  ..write_byte(h)
  ..write_byte(w)
  ..write_byte(i)
  ..write_byte(d)
  .dispatch()
}

///| handle_login_result handles a packet that contains the response to an
/// attempt at logging in
pub fn handle_login_result(self : Module, recv : @net.InPacket) -> Unit!Error {
  self.login_task = None
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

///|
pub fn handle_server_status(recv : @net.InPacket) -> Unit!Error {
  // Possible values for status:
  // 0 - Normal
  // 1 - Highly populated
  // 2 - Full
  recv.read_short!() |> ignore // status
}

///|
pub fn handle_server_list(self : Module, recv : @net.InPacket) -> Unit!Error {
  while recv.available() {
    let world = parse_world!(recv)
    if world.wid != -1 {
      self.receiving_server_list.push(world)
    } else { // end of list
      let worlds = self.receiving_server_list
      self.receiving_server_list = []
      @log.debug({ "worlds": worlds }, "server list")
      enter_world(0, 0)
      break
    }
  }
}

///|
fn enter_world(worldId : Int, channelId : Int) -> Unit {
  @config.global().set_worldid(worldId)
  @config.global().set_channelid(channelId)
  fn_char_list_req(worldId, channelId)
}

///|
fn fn_char_list_req(worldId : Int, channelId : Int) -> Unit {
  new_char_list_request_packet(worldId, channelId).dispatch()
}

///|
fn new_char_list_request_packet(
  worldId : Int,
  channelId : Int
) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::CHAR_LIST_REQUEST)
  ..write_byte((0).to_byte())
  ..write_byte(worldId.to_byte())
  ..write_byte(channelId.to_byte())
}

///|
pub fn handle_char_list(mod : Module, recv : @net.InPacket) -> Unit!Error {
  recv.read_ubyte!() |> ignore // channel_id
  let characters = []
  let charcount = recv.read_byte!()
  for i = 0; i < charcount; i = i + 1 {
    characters.push(parse_charentry!(recv))
  }
  mod.characters = characters
  mod.selected_index = None
  let pic = recv.read_byte!()
  recv.read_int!() |> ignore // slots
  if characters.length() > 0 {
    match pic {
      2 => {
        let cid = match mod.select_cid {
          Some(cid) => cid
          None => characters[0].id
        }
        mod.select_cid = Some(cid)
        new_select_char_packet(cid).dispatch()
      }
      _ => fail!("pic=\{pic} not ok")
    }
  } else {
    @log.info({}, "no characters, creating new one")
    new_name_char_packet(test_name).dispatch()
  }
}

///|
pub fn handle_server_ip(mod : Module, recv : @net.InPacket) -> Unit! {
  recv.skip_byte!()
  let (_, port) = parse_login!(recv)
  let cid = recv.read_int!()
  match mod.characters.search_by(fn(c) { c.id == cid }) {
    Some(i) => mod.selected_index = Some(i)
    None => fail!("no character with id=\{cid}")
  }
  mod.processor.connect_channel(port)
  mod.connect_task = Some({ processor: mod.processor, cid })
}

///|
pub fn handle_charname_response(recv : @net.InPacket) -> Unit! {
  let name = recv.read_string!()
  let used = recv.read_bool!()
  let c = ExplorerCreator::new(
    etc_loader().load_res(["MakeCharInfo.img", "Info"]),
  )
  c.send_naming_result(name, used)
}

///|
pub fn handle_add_new_char_entry(mod : Module, recv : @net.InPacket) -> Unit! {
  recv.skip!(1)
  let character = parse_charentry!(recv)
  mod.characters.push(character)
}

///|
fn fn_server_req() -> Unit {
  new_server_request_packet().dispatch()
}

///|
fn new_server_request_packet() -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::SERVERLIST_REQUEST)
}

///|
fn fn_tos() -> Unit {
  new_tos_packet().dispatch()
}

///|
fn new_tos_packet() -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::ACCEPT_TOS)..write_byte(
    (1).to_byte(),
  )
}

///|
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

///|
struct Account {
  accid : Int
  female : Int
  admin : Bool
  name : String
  muted : Bool
  pin : Bool
  pic : Int
} derive(Show)

///|
struct World {
  name : String
  message : String
  chloads : Array[Int]
  channelcount : Int
  flag : Int
  wid : Int
} derive(Show)

///|
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

///|
fn parse_charentry(recv : @net.InPacket) -> @character.CharEntry! {
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
    @log.debug(
      {
        "currank": currank,
        "rankmc": rankmc,
        "curjobrank": curjobrank,
        "jobrankmc": jobrankmc,
      },
      "rank",
    )
    // stats.rank = (currank, rankmc)
    // stats.jobrank = (curjobrank, jobrankmc)
  }
  { stats, look, id }
}

///|
fn parse_stats(recv : @net.InPacket) -> @char_stats.StatsEntry! {
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

///|
fn parse_look(recv : @net.InPacket) -> @character.LookEntry! {
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

///|
fn parse_login(recv : @net.InPacket) -> (String, Int)! {
  recv.skip_byte!()
  let addrstr = []
  for i = 0; i < 4; i = i + 1 {
    addrstr.push(recv.read_byte!())
  }
  let portstr = recv.read_short!()
  (String::concat(addrstr.map(fn(b) { b.to_string() }), separator="."), portstr)
}

///| Requests being logged-in to a channel server with the specified character
pub fn new_player_login_packet(cid : Int) -> @net.OutPacket {
  @net.OutPacket::new(@net.OutPacketOpcode::PLAYER_LOGIN)..write_int(cid)
}

///|
fn etc_loader() -> @resource.SyncLoader {
  @resource.SyncLoader::new("etc")
}

///|
pub(open) trait BgTask {
  update(Self) -> Bool
}

///|
struct ConnectChannelTask {
  processor : @net.PacketProcessor
  cid : Int
}

///|
pub fn update(self : ConnectChannelTask) -> Bool {
  if self.processor.get_status() == @net.READY {
    new_player_login_packet(self.cid).dispatch()
    true
  } else {
    false
  }
}

///|
pub fn reconnect_if_needed(self : Module) -> Unit {
  guard let Some((acc, pass)) = self.input_acc_pass else { None => return }
  login(self, acc, pass)
}

///|
pub fn update(self : Module) -> Unit {
  match self.login_task {
    Some(task) => task.update()
    None => ()
  }
  match self.connect_task {
    Some(task) => if task.update() { self.connect_task = None }
    None => ()
  }
}
