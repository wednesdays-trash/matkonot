open Containers

let all_true bools =
    List.fold_left (fun a b -> if a && b then true else false) true bools

let read_file name =
    let ic = open_in name in
    let n = in_channel_length ic in
    let s = Bytes.create n in
    really_input ic s 0 n;
    close_in ic;
    s |> Bytes.to_string

