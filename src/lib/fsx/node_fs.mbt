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

///|
/// Creates directories synchronously with `recursive: true` in Node.js runtime.
#module("node:fs")
extern "js" fn mkdir_sync_with_options(
  path : String,
  options : @js.Value,
) -> Unit = "mkdirSync"

///|
/// Creates a directory path recursively in Node.js runtime.
pub fn mkdir_sync_recursive(path : String) -> Unit {
  let options = @js.Object::new()
  options["recursive"] = true
  mkdir_sync_with_options(path, options.to_value())
}
