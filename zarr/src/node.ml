exception Node_invariant

(* Check if the path's name satisfies path invariants *)
let rep_ok name =
  (String.empty <> name) &&
  not (String.contains name '/') &&
  not (String.for_all (Char.equal '.') name) &&
  not (String.starts_with ~prefix:"__" name)

module GroupNode = struct
  type t =
    | Root
    | Cons of t * string

  let create parent name =
    if rep_ok name then Cons (parent, name)
    else raise Node_invariant

  let ( / ) = create

  let root = Root 

  let of_path = function
    | "/" -> Root
    | s ->
      if String.(not @@ starts_with ~prefix:"/" s || ends_with ~suffix:"/" s)
      then raise Node_invariant
      else List.fold_left create Root (List.tl @@ String.split_on_char '/' s)

  let name = function
    | Root -> ""
    | Cons (_, n) -> n

  let parent = function
    | Root -> None
    | Cons (parent, _) -> Some parent

  let rec ( = ) x y =
    match x, y with
    | Root, Root -> true
    | Root, Cons _ | Cons _, Root -> false
    | Cons (p, n), Cons (q, m) -> ( = ) p q && String.equal n m

  let rec fold f acc = function
    | Root -> f acc Root
    | Cons (parent, _) as p -> fold f (f acc p) parent

  let to_path = function
    | Root -> "/"
    | p ->
      String.concat "" @@
      fold (fun acc -> function
        | Root -> acc
        | Cons (_, n) -> "/" :: n :: acc) [] p

  let ancestors p =
    fold (fun acc -> function
      | Root -> acc
      | Cons (parent, _) -> parent :: acc) [] p

  let to_key p =
    let str = to_path p in
    String.(length str - 1 |> sub str 1)

  let to_prefix = function
    | Root -> ""
    | p -> to_key p ^ "/"

  let to_metakey p =
    to_prefix p ^ "zarr.json"

  let is_child_group x y =
    match x, y with
    | _, Root -> false
    | v, Cons (parent, _) -> parent = v

  let show = to_path

  let pp fmt t =
    Format.fprintf fmt "%s" @@ show t
end

module ArrayNode = struct
  type t = {parent : GroupNode.t option; name : string}

  let create g name =
    if rep_ok name then {parent = Some g; name}
    else raise Node_invariant

  let ( / ) = create

  let root = {parent = None; name = ""}

  let of_path p =
    let g = GroupNode.of_path p in
    match GroupNode.parent g with
    | Some _ as parent -> {parent; name = GroupNode.name g}
    | None -> raise Node_invariant
      
  let ( = )
    {parent = p; name = n}
    {parent = q; name = m} = p = q && n = m

  let name {parent = _; name = n} = n

  let parent {parent = p; _} = p

  let to_path {parent = p; name} = match p with
    | None -> "/"
    | Some g when GroupNode.(g = root) -> "/" ^ name
    | Some g -> GroupNode.to_path g ^ "/" ^ name
  
  let ancestors {parent; _} = match parent with
    | None -> []
    | Some g -> g :: GroupNode.ancestors g

  let is_parent {parent; _} y = match parent with
    | None -> false
    | Some g -> GroupNode.(g = y)

  let to_key {parent; name} = match parent with
    | Some g -> GroupNode.to_prefix g ^ name
    | None -> "" 

  let to_metakey = function
    | {parent = None; _} -> "zarr.json"
    | p -> to_key p ^ "/zarr.json"
  
  let show = to_path

  let pp fmt t = Format.fprintf fmt "%s" @@ show t
end
