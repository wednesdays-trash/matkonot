open Containers


let read_file name =
  IO.(with_in name read_all)
