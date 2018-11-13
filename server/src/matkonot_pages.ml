open Containers


let css = Utils.read_file "pages/milligram.min.css"


let apply_css page =
    page |> String.replace ~sub:"{{css}}" ~by:css ~which:`Left


let index  = Utils.read_file "pages/index.html"  |> apply_css
let search = Utils.read_file "pages/search.html" |> apply_css
let error  = Utils.read_file "pages/error.html"  |> apply_css


let make_error_page message =
  let gen_page msg_string =
    String.replace error
      ~sub:"{{content}}"
      ~by:msg_string
      ~which:`Left
  in                       
  Printf.ksprintf gen_page message
