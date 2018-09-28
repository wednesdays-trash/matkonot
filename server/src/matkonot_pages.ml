open Containers

let css = Utils.read_file "pages/milligram.min.css"

let apply_css page =
    page |> String.replace ~which:`Left ~sub:"{{css}}" ~by:css

let index  = Utils.read_file "pages/index.html"  |> apply_css
let search = Utils.read_file "pages/search.html" |> apply_css
let error  = Utils.read_file "pages/error.html"  |> apply_css

