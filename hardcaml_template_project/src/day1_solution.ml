open! Core
open! Hardcaml
open! Signal

(* Every hardcaml module should have an I and an O record, which define the module
   interface. *)
module I = struct
  type 'a t =
    { clock : 'a
    ; reset : 'a
    ; valid : 'a
    ; dir : 'a
    ; count : 'a [@bits 32]
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
    { hits : 'a [@bits 32]
    ; passes : 'a [@bits 32]
    ; ready : 'a
    }
  [@@deriving hardcaml]
end

module States = struct
  type t =
    | Idle
    | Accepting_inputs
    | Done
  [@@deriving sexp_of, compare ~localize, enumerate]
end

let create _scope ({ clock; reset; valid; dir; count } : _ I.t) : _ O.t =
  let spec = Reg_spec.create ~clock ~clear:reset () in
  (* Variables for dial, hits, and passes *)
  let dial = Always.Variable.reg spec ~width:7 in
  let hits = Always.Variable.reg spec ~width:32 in
  let passes = Always.Variable.reg spec ~width:32 in
  let ready = Signal.vdd in
  (* always ready to accept input for Pt.1 *)

  (* Sequential Logic *)
  let open Always in
  compile
    [ if_
        reset
        [ dial <-- Signal.of_int_trunc ~width:7 50
        ; hits <-- Signal.zero 32
        ; passes <-- Signal.zero 32
        ]
        [ if_
            valid
            [ (let dial_ext = Signal.uresize ~width:32 dial.value in
              let count_ext = Signal.uresize ~width:32 count in
              let sum_right = Signal.(dial_ext +: count_ext) in
              let sum_right_mod =
                Signal.mux2
                  Signal.(sum_right >=: Signal.of_int_trunc ~width:32 100)
                  Signal.(sum_right -: Signal.of_int_trunc ~width:32 100)
                  sum_right
              in
              let diff_left = Signal.(dial_ext -: count_ext) in
              let diff_left_mod =
                Signal.mux2
                  Signal.(dial_ext <: count_ext)
                  Signal.(Signal.of_int_trunc ~width:32 100 +: diff_left)
                  diff_left
              in
              let dial_next_val = Signal.mux2 dir sum_right_mod diff_left_mod in
              let dial_next = Signal.sel_bottom ~width:7 dial_next_val in
              dial <-- dial_next)
            ; (passes <-- Signal.(passes.value +: Signal.one 32))
            ; when_
                Signal.(dial.value ==: Signal.zero 7)
                [ (hits <-- Signal.(hits.value +: Signal.one 32)) ]
            ]
            []
        ]
    ];
  { O.hits = hits.value; O.passes = passes.value; O.ready }
;;
