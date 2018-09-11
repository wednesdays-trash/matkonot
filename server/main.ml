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
        let data = Sqlite3.row_data statement in
        let get i = Array.get data i |> Sqlite3.Data.to_string in
        { title = get 0;
          url = get 1;
          ingredients = get 2;
          thumbnail_url = get 3;
          source = get 4;
        } |> fun recipe -> Base.Linked_queue.enqueue result recipe
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


let create_page recipes =
    let create_link recipe =
        Printf.sprintf "<li><a href=%s>%s</a></li>" recipe.url recipe.title
    in
    let body = List.map create_link recipes |> String.concat "" in
    "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">
    <html>
        <body>
            <ul dir='rtl'>" 
                ^ body ^
           "</ul>
        </body>
    </html>"


let () =
    let db = Sqlite3.db_open "matkonot.db" in

    let headers = Cohttp.Header.init_with "Content-Type" "text/html; charset=utf-8" in

    let request_handler req =
        let body = req 
            |> Request.uri 
            |> Uri.to_string
            |> ingredient_from_uri
            |> validate_input
            |> (function
                | Ok ing -> find_recipes_with_ingredient ing db
                | Error _ -> [])
            |> create_page
        in
        Server.respond_string ~headers ~status:`OK ~body ()
    in

    server request_handler |> Lwt_main.run |> ignore

