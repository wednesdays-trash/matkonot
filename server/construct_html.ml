let create_link url =
    Printf.sprintf "<li><a href=%s>%s</a></li>" url url


let create_page recipes =
    let body = List.map create_link recipes |> String.concat "" in
    "<html><body><ul>" ^ body ^ "</ul></body></html>"
