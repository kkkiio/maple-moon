extern "js" fn text_create_image(
  text : String,
  font_size : Int,
  font_name : String,
  color : String,
  text_align : String,
  max_width : Int
) -> @resource.Image =
  #| (t,f,n,c,a,m) => text.create_image(t,f,n,c,a,m)
