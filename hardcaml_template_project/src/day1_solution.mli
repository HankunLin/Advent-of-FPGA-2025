(* Day 1 solution - lock dial counter with valid-ready handshaking *)
(* Part 1: Count "hits" - times dial lands on 0 after a rotation *)
(* Part 2: Count "passes" - times dial crosses through 0 during rotation *)

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
    ; dial_position : 'a [@bits 7] (* current dial position for debug/monitoring *)
    ; busy : 'a (* high when processing a rotation *)
    }
  [@@deriving hardcaml]
end

module States : sig
  type t =
    | Idle (* Waiting for input *)
    | Rotate (* Process click-by-click rotation *)
    | Done (* Rotation complete, check for hit and return to Idle *)
  [@@deriving sexp_of, compare ~localize, enumerate]
end

val create : Scope.t -> Signal.t I.t -> Signal.t O.t
