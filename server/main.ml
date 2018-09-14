open Cohttp_lwt_unix
open Base.Result.Monad_infix

let database_file_name = "matkonot.db"
let index_file_name = "index.html"
let port = 3222


type error =
    | BadInput of string
    | NoResultsForIngredient of string
    | UnknownPage of string


type recipe =
    { title : string;
      url : string;
      ingredients : string;
      thumbnail_url : string;
      source : string;
    }


let show_error err = 
    let fmt = Printf.sprintf in
    match err with
    | BadInput input -> fmt "Bad Input: %s\n" input
    | NoResultsForIngredient ingred -> fmt "No recipes including %s were found :(" ingred
    | UnknownPage uri -> fmt "This URL (%s) doesn't lead to anywhere interesting" uri


module Validation = struct
    let valid_chars =
        Base.String.to_list "אבגדהוזחטיכלמנסעפצקרשת'םףץך"

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
end


let find_recipes_with_ingredient ingred ~db =
    let query = Printf.sprintf "SELECT * FROM recipes WHERE INSTR(ingredients, '%s')" ingred in
    let statement = Sqlite3.prepare db query in
    let recipes = Base.Linked_queue.create () in

    while Sqlite3.step statement == Sqlite3.Rc.ROW do
        let data = Sqlite3.row_data statement in
        let get i = Array.get data i |> Sqlite3.Data.to_string in
        { title = get 0;
          url = get 1;
          ingredients = get 2;
          thumbnail_url = get 3;
          source = get 4;
        } |> fun recipe -> Base.Linked_queue.enqueue recipes recipe
    done;

    let result = Base.Linked_queue.to_list recipes in
    if List.length result > 0
        then Ok result
        else Error (NoResultsForIngredient ingred)


let server handler =
    let callback = fun _ req _ -> handler req in
    Server.create ~mode:(`TCP (`Port port)) (Server.make ~callback ())


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


let run_server () =
    let db = Sqlite3.db_open database_file_name in
    let headers = Cohttp.Header.init_with "Content-Type" "text/html; charset=utf-8" in

    let request_handler req =
        let uri = Request.uri req in
        match Uri.get_query_param uri "query" with
        | None -> Server.respond_file ~headers ~fname:index_file_name ()
        | Some ing -> Server.respond_string ~headers ~status:`OK () ~body:(
            ing
            |> Validation.validate_input
            >>= find_recipes_with_ingredient ~db
            |> (function
                | Ok recipes -> create_page recipes
                | Error e -> show_error e))
    in

    print_endline ("Running server on http://localhost:" ^ string_of_int port);
    server request_handler |> Lwt_main.run |> ignore


let () =
    if not (Sys.file_exists database_file_name)
        then print_endline ("No database found (expecting a file called " ^ database_file_name ^ ").")
        else run_server ()

