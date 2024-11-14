fn load_desc_async(self : AsyncResourceLoader, path : String) -> PollableData = "resource" "load_desc_async"

fn load_desc(self : ResourceLoader, path : String) -> RawData = "resource" "load_desc"

fn as_jsonstring(v : RawData) -> String = "resource" "as_jsonstring"
