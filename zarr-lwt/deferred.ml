type 'a t = 'a Lwt.t
let return = Lwt.return
let iter = Lwt_list.iter_p
let iter_s = Lwt_list.iter_s
let fold_left = Lwt_list.fold_left_s
let map = Lwt_list.map_p
let concat_map f l = Lwt.map List.concat (Lwt_list.map_p f l)

module Infix = struct
  let (>>=) = Lwt.Infix.(>>=)
  let (>>|) = Lwt.Infix.(>|=) 
end