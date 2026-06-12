///|
extern "js" fn log_debug(msg : String) -> Unit =
  #| (m) => {
  #|   const isNode = typeof process !== "undefined" && !!process.versions?.node;
  #|   if (isNode) {
  #|     const flag = process.env?.MAPLE_DEBUG ?? "";
  #|     if (flag !== "1" && flag !== "true" && flag !== "TRUE") {
  #|       return;
  #|     }
  #|   }
  #|   console.debug(m);
  #| }

///|
extern "js" fn log_info(msg : String) -> Unit =
  #| (m) => console.info(m)

///|
extern "js" fn log_warn(msg : String) -> Unit =
  #| (m) => console.warn(m)

///|
extern "js" fn log_error(msg : String) -> Unit =
  #| (m) => console.error(m)
