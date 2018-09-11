open Cohttp_lwt_unix


type error =
    | BadInput of string


type recipe =
    { title : string;
      url : string;
      ingredients : string;
      thumbnail_url : string;
      source : string;
    }


let print_error err = match err with
    | BadInput input -> Printf.printf "Bad Input: %s\n" input


let valid_chars =
    "אבגדהוזחטיכלמנסעפצקרשת'"
        |> Base.String.to_list


let is_valid_char chr =
    List.exists ((==) chr) valid_chars


let validate_input input =
    let all_chars_are_valid = input
        |> String.to_seq
        |> Seq.map is_valid_char
        |> Seq.fold_left (fun a b -> if a && b then true else false) true
    in

    if all_chars_are_valid
        then Ok input 
        else Error (BadInput input)


let find_recipes_with_ingredient ing db =
    let query = Printf.sprintf "SELECT * FROM recipes WHERE INSTR(ingredients, '%s')" ing in
    let statement = Sqlite3.prepare db query in
    let result = Base.Linked_queue.create () in

    while Sqlite3.step statement == Sqlite3.Rc.ROW do
        Sqlite3.row_data statement
            |> (fun arr -> Array.get arr 1)
            |> Sqlite3.Data.to_string
            |> fun url -> Base.Linked_queue.enqueue result url
    done;

    Base.Linked_queue.to_list result


let ingredient_from_uri uri = uri
    |> Uri.pct_decode
    |> String.split_on_char '/'
    |> List.rev
    |> List.hd


let server handler =
    let callback = fun _ req _ -> handler req in
    Server.create ~mode:(`TCP (`Port 8000)) (Server.make ~callback ())


let () =
    let db = Sqlite3.db_open "matkonot.db" in

    let request_handler req =
        let body = req 
            |> Request.uri 
            |> Uri.to_string
            |> ingredient_from_uri
            |> validate_input
            |> (function
                | Ok ing -> find_recipes_with_ingredient ing db
                | Error _ -> [])
            |> Construct_html.create_page
        in
        Server.respond_string ~status:`OK ~body ()
    in

    server request_handler |> Lwt_main.run |> ignore

