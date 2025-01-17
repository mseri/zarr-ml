open Codecs_intf

(* https://zarr-specs.readthedocs.io/en/latest/v3/codecs/gzip/v1.0.html *)
module GzipCodec = struct
  let to_int = function
    | L0 -> 0 | L1 -> 1 | L2 -> 2 | L3 -> 3 | L4 -> 4
    | L5 -> 5 | L6 -> 6 | L7 -> 7 | L8 -> 8 | L9 -> 9

  let of_int = function
    | 0 -> Ok L0 | 1 -> Ok L1 | 2 -> Ok L2 | 3 -> Ok L3
    | 4 -> Ok L4 | 5 -> Ok L5 | 6 -> Ok L6 | 7 -> Ok L7
    | 8 -> Ok L8 | 9 -> Ok L9 | i ->
      Error (Printf.sprintf "Invalid Gzip level %d" i)

  let encode l x =
    Ezgzip.compress ~level:(to_int l) x

  let decode x =
    Result.get_ok @@ Ezgzip.decompress x

  let to_yojson l =
    `Assoc
    [("name", `String "gzip")
    ;("configuration", `Assoc ["level", `Int (to_int l)])]

  let of_yojson x =
    match Yojson.Safe.Util.(member "configuration" x |> to_assoc) with
    | [("level", `Int i)] -> Result.bind (of_int i) @@ fun l -> Ok (`Gzip l)
    | _ -> Error "Invalid Gzip configuration."
end

(* https://zarr-specs.readthedocs.io/en/latest/v3/codecs/crc32c/v1.0.html *)
module Crc32cCodec = struct
  let encoded_size input_size = input_size + 4

  let encode x =
    let size = String.length x in
    let buf = Buffer.create size in
    Buffer.add_string buf x;
    Buffer.add_int32_le buf @@
    Checkseum.Crc32c.(default |> unsafe_digest_string x 0 size |> to_int32);
    Buffer.contents buf

  let decode x = String.(length x - 4 |> sub x 0)

  let to_yojson =
    `Assoc [("name", `String "crc32c")]

  let of_yojson _ =
    (* checks for validity of configuration are done via
       BytesToBytes.of_yojson so just return valid result.*)
      Ok `Crc32c
end

module BytesToBytes = struct
  let encoded_size :
    int -> fixed_bytestobytes -> int
    = fun input_size -> function
    | `Crc32c -> Crc32cCodec.encoded_size input_size

  let encode x = function
    | `Gzip l -> GzipCodec.encode l x
    | `Crc32c -> Crc32cCodec.encode x

  let decode t x = match t with
    | `Gzip _ -> GzipCodec.decode x
    | `Crc32c -> Crc32cCodec.decode x

  let to_yojson = function
    | `Gzip l -> GzipCodec.to_yojson l
    | `Crc32c -> Crc32cCodec.to_yojson 

  let of_yojson x =
    match Util.get_name x with
    | "gzip" -> GzipCodec.of_yojson x
    | "crc32c" -> Crc32cCodec.of_yojson x
    | s -> Error (Printf.sprintf "codec %s is not supported." s)
end
