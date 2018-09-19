open Cohttp_lwt_unix
open Containers
open Containers.Result

let page_title = "קצת מתכונים"
let database_file_name = "matkonot.db"
let port = 3222


let (==) = Equal.physical

type error =
    | BadInput of string
    | NoResultsForIngredient of string
    | UnknownPage of string


type recipe =
    { title : string
    ; url : string
    ; ingredients : string
    ; thumbnail_url : string
    ; source : string
    }


type matkonot_pages =
    { index : string
    ; search : string
    ; error_404 : string
    }


let show_error err = 
    let fmt = Printf.sprintf in
    match err with
    | BadInput input -> fmt "Bad Input: %s\n" input
    | NoResultsForIngredient ingred -> fmt "No recipes including %s were found :(" ingred
    | UnknownPage uri -> fmt "This URL (%s) doesn't lead to anywhere interesting" uri


module Validation = struct
    let valid_chars =
        String.to_list "אבגדהוזחטיכלמנסעפצקרשת'םףץךן "

    let is_valid_char chr =
        List.mem chr valid_chars ~eq:Char.equal

    let validate_input input =
        let all_chars_are_valid = input
            |> String.to_list
            |> List.map is_valid_char
            |> Utils.all_true
        in

        if all_chars_are_valid
            then Ok input 
            else Error (BadInput input)
end


let find_recipes_with_ingredient ingred ~db =
    let query = Printf.sprintf "SELECT * FROM recipes WHERE INSTR(ingredients, '%s')" ingred in
    let statement = Sqlite3.prepare db query in
    let recipes = Vector.create () in

    while Sqlite3.step statement == Sqlite3.Rc.ROW do
        let data = Sqlite3.row_data statement in
        let get i = Array.get data i |> Sqlite3.Data.to_string in
        let recipe = { 
          title = get 0;
          url = get 1;
          ingredients = get 2;
          thumbnail_url = get 3;
          source = get 4;
        } in
        Vector.push recipes recipe
    done;

    if Vector.length recipes > 0
        then Ok (Vector.to_list recipes)
        else Error (NoResultsForIngredient ingred)


let server handler =
    let callback = fun _ req _ -> handler req in
    Server.create ~mode:(`TCP (`Port port)) (Server.make ~callback ())


let create_search_page template title recipes =
    let create_link recipe =
        Printf.sprintf "<li><a href=%s>%s</a></li>" recipe.url recipe.title
    in
    let body = List.map create_link recipes |> String.concat "\n" in
    template
        |> Base.String.substr_replace_first ~pattern:"{{title}}" ~with_:title
        |> Base.String.substr_replace_first ~pattern:"{{results}}" ~with_:body


let run_server () =
    let db = Sqlite3.db_open database_file_name in

    let headers = Cohttp.Header.init_with "Content-Type" "text/html; charset=utf-8" in

    let make_body ingredient =
        ingredient
            |> Validation.validate_input
            >>= find_recipes_with_ingredient ~db
            |> (function
                | Ok recipes -> create_search_page Matkonot_pages.search ingredient recipes
                | Error e -> show_error e)
    in

    let file_resp uri = match Uri.path uri with
        | "/" -> Matkonot_pages.index
        | _ -> Matkonot_pages.error_404
    in 

    let request_handler req =
        let uri = Request.uri req in
        match Uri.get_query_param uri "query" with
        | Some ing -> Server.respond_string ~headers ~status:`OK ~body:(make_body ing) ()
        | None     -> Server.respond_string ~headers ~status:`OK ~body:(file_resp uri) ()
    in

    print_endline ("Running server on http://localhost:" ^ string_of_int port);
    server request_handler |> Lwt_main.run |> ignore

let () =
    run_server ()

