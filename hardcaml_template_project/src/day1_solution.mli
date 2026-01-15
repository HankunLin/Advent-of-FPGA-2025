(* Day 1 solution - lock dial counter *)

open! Core
open! Hardcaml

module I : sig
  type 'a t =
    { clock : 'a
    ; reset : 'a
    ; valid : 'a
    ; dir : 'a
    ; count : 'a [@bits 32]
    }
  [@@deriving hardcaml]
end

module O : sig
  type 'a t =
    { hits : 'a [@bits 32]
    ; passes : 'a [@bits 32]
    ; ready : 'a
    }
  [@@deriving hardcaml]
end

module States : sig
  type t =
    | Idle
    | Accepting_inputs
    | Done
  [@@deriving sexp_of, compare ~localize, enumerate]
end

val create : Scope.t -> Signal.t I.t -> Signal.t O.t
