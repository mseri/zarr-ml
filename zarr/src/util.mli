module ExtPoint : sig
  (** The type representing a JSON extension point metadata configuration. *)

  type 'a t = {name : string ; configuration : 'a}
  val ( = ) : ('a -> 'a -> bool) -> 'a t -> 'a t -> bool
end

(** A finite map over integer array keys. *)
module ArrayMap : sig
  include Map.S with type key = int array
  val add_to_list : int array -> 'a -> 'a list t -> 'a list t
  (** [add_to_list k v map] is [map] with [k] mapped to [l] such that [l]
      is [v :: ArrayMap.find k map] if [k] was bound in [map] and [v] otherwise.*)
end

(** Result monad operator syntax. *)
module Result_syntax : sig
  val (let*) : ('a, 'e) result -> ('a -> ('b, 'e) result ) -> ('b, 'e) result
  val (let+) : ('a, 'e) result -> ('a -> 'b) -> ('b, 'e) result
end

module Indexing : sig
  (** A module housing functions for creating and manipulating indices and
      slices for working with Zarr arrays. *)

  val slice_of_coords
    : int array list -> Owl_types.index array
  (** [slice_of_coords c] takes a list of array coordinates and returns
      a slice corresponding to the coordinates. Elements of each slice
      variant are sorted in increasing order.*)
      
  val coords_of_slice
    : Owl_types.index array -> int array -> int array array
  (** [coords_of_slice s shp] returns an array of coordinates given
      a slice [s] and array shape [shp]. *)

  val cartesian_prod
    : 'a list list -> 'a list list
  (** [cartesian_prod ll] returns a cartesian product of the elements of
      list [ll]. It is mainly used to generate a C-order of chunk indices
      in a regular Zarr array grid. *)

  val slice_shape
    : Owl_types.index array -> int array -> int array
  (** [slice_shape s shp] returns the shape of slice [s] within an array
      of shape [shp]. *)
end

val get_name : Yojson.Safe.t -> string
(** [get_name c] returns the name value of a JSON metadata extension point
    configuration of the form [{"name": value, "configuration": ...}],
    as defined in the Zarr V3 specification. *)

val prod : int array -> int
(** [prod x] returns the product of the elements of [x]. *)

val max : int array -> int
(** [max x] returns the maximum element of an integer array [x]. *)

val create_parent_dir : string -> Unix.file_perm -> unit
(** [create_parent_dir f p] creates all the parent directories of file name
    [f] if they don't exist given file permissions [p]. *)

val sanitize_dir : string -> string
(** [sanitize_dir d] Chops off any trailing '/' in directory path [d]. *)
