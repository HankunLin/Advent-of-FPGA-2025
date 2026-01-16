(* Day 1 solution - lock dial counter with valid-ready handshaking *)

open! Core
open! Hardcaml

module I : sig
  type 'a t =
    { clock : 'a
    ; reset : 'a
    ; instruction_valid : 'a (* upstream asserts when instruction is available *)
    ; direction : 'a (* 0=left, 1=right *)
    ; count : 'a [@bits 16]
    }
  [@@deriving hardcaml]
end

module O : sig
  type 'a t =
    { hits : 'a [@bits 32]
    ; passes : 'a [@bits 32]
    ; instruction_ready : 'a (* asserted when module can accept new instruction *)
    }
  [@@deriving hardcaml]
end

module States : sig
  type t =
    | Idle
    | Reducing
    | Processing
  [@@deriving sexp_of, compare ~localize, enumerate]
end

val create : Scope.t -> Signal.t I.t -> Signal.t O.t
