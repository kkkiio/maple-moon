///|
/// Returns whether the target path exists in Node.js runtime.
#module("node:fs")
pub fn exists_sync(path : String) -> Bool = "existsSync"

///|
/// Reads a UTF-8 text file synchronously from Node.js runtime.
#module("node:fs")
pub fn read_file_sync(path : String, encoding : String) -> String = "readFileSync"

///|
/// Writes UTF-8 text content synchronously to a file in Node.js runtime.
#module("node:fs")
pub fn write_file_sync(path : String, content : String) -> Unit = "writeFileSync"

///|
/// Creates a directory synchronously in Node.js runtime.
#module("node:fs")
pub fn mkdir_sync(path : String) -> Unit = "mkdirSync"
