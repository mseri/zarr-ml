(** This module provides functionality for manipulating a Zarr node's
    metadata JSON document.

    The Zarr V3 specification defines two types of metadata documents: 
    array and group metadata. Both types are stored under the key
    [zarr.json] within the prefix of a group or array.*)

exception Parse_error of string
(** raised when parsing a metadata JSON document fails. *)

module FillValue : sig
  type t =
    | Char of char  (** A single character string. *)
    | Bool of bool  (** Must be a JSON boolean. *)
    | Int of int64  (** Value must be a JSON number with no fractional or exponent part that is within the representable range of the corresponding integer data type. *)
    | Float of float  (** Value representing a JSON float. *)
    | FloatBits of float  (** A JSON string specifying a byte representation of the float a hexstring. *)
    | IntComplex of Complex.t  (** A JSON 2-element array of integers representing a complex number. *)
    | FloatComplex of Complex.t  (** A JSON 2-element array of floats representing a complex number. *)
    | FFComplex of Complex.t 
    | FBComplex of Complex.t
    | BFComplex of Complex.t
    | BBComplex of Complex.t
  (** Provides an element value to use for uninitialised portions of
      a Zarr array. The permitted values depend on the data type. *)
end

module ArrayMetadata : sig
  (** A module which contains functionality to work with a parsed JSON
      Zarr array metadata document. *)

  type t
  (** A type representing a parsed array metadata document. *)

  val create :
    ?sep:[< `Dot | `Slash > `Slash ] ->
    ?dimension_names:string option list ->
    ?attributes:Yojson.Safe.t ->
    codecs:Codecs.Chain.t ->
    shape:int array ->
    ('a, 'b) Bigarray.kind ->
    'a ->
    int array ->
    t
  (** [create ~codecs ~shape kind fv cshp] Creates a new array metadata
      document with codec chain [codecs], shape [shape], fill value [fv],
      data type [kind] and chunk shape [cshp].

      @raise Failure if shape and chunks are incompatible. *)

  val encode : t -> string
  (** [encode t] returns a byte string representing a JSON Zarr array metadata. *)

  val decode : string -> t
  (** [decode s] decodes a bytes string [s] into a {!ArrayMetadata.t} type.

      @raise Parse_error if metadata string is invalid. *)

  val shape : t -> int array
  (** [shape t] returns the shape of the zarr array represented by metadata type [t]. *)

  val chunk_shape : t -> int array
  (** [chunk_shape t] returns the shape a chunk in this zarr array. *)

  val is_valid_kind : t -> ('a, 'b) Bigarray.kind -> bool
  (** [is_valid_kind t kind] checks if [kind] is a valid Bigarray kind that
      matches the data type of the zarr array represented by this metadata type. *)

  val fillvalue_of_kind : t -> ('a, 'b) Bigarray.kind -> 'a
  (** [fillvalue_of_kind t kind] returns the fill value of uninitialized
      chunks in this zarr array  given [kind]. Raises Failure if the kind
      is not compatible with this array's fill value. *)

  val attributes : t -> Yojson.Safe.t
  (** [attributes t] Returns a Yojson type containing user attributes assigned
      to the zarr array represented by [t]. *)

  val dimension_names : t -> string option list
  (** [dimension_name t] returns a list of dimension names. If none are
      defined then an empty list is returned. *)

  val codecs : t -> Codecs.Chain.t
  (** [codecs t] Returns a type representing the chain of codecs applied
      when decoding/encoding a Zarr array chunk. *)

  val index_coord_pair : t -> int array -> int array * int array
  (** [index_coord_pair t coord] maps a coordinate of this Zarr array to
      a pair of chunk index and coordinate {i within} that chunk. *)

  val chunk_indices : t -> int array -> int array list
  (** [chunk_indices t shp] returns a list of all chunk indices that would
      be contained in a zarr array of shape [shp] given the regular grid
      defined in array metadata [t]. *)

  val chunk_key : t -> int array -> string
  (** [chunk_key t idx] returns a key encoding of a the chunk index [idx]. *)

  val update_attributes : t -> Yojson.Safe.t -> t
  (** [update_attributes t json] returns a new metadata type with an updated
      attribute field containing contents in [json] *)

  val update_shape : t -> int array -> t
  (** [update_shape t new_shp] returns a new metadata type containing
      shape [new_shp]. *)

  val ( = ) : t -> t -> bool
  (** [a = b] returns true if [a] [b] are equal array metadata documents
      and false otherwise. *)
end

module GroupMetadata : sig
  (** A module which contains functionality to work with a parsed JSON
      Zarr group metadata document. *)

  type t
  (** A type representing a parsed group metadata document. *)

  val default : t
  (** Return a group metadata type with default values for all fields. *)

  val encode : t -> string
  (** [encode t] returns a byte string representing a JSON Zarr group metadata. *)

  val decode : string -> t
  (** [decode s] decodes a bytes string [s] into a {!t} type.

      @raise Parse_error if metadata string is invalid. *)

  val update_attributes : t -> Yojson.Safe.t -> t
  (** [update_attributes t json] returns a new metadata type with an updated
      attribute field containing contents in [json]. *)

  val show : t -> string
  (** [show t] pretty-prints the contents of the group metadata type t. *)

  val attributes : t -> Yojson.Safe.t
  (** [attributes t] Returns a Yojson type containing user attributes assigned
      to the zarr group represented by [t]. *)
end
