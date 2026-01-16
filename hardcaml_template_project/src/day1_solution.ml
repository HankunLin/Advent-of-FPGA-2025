open! Core
open! Hardcaml
open! Signal

(* Day 1 solution with valid-ready handshaking protocol *)

module I = struct
  type 'a t =
    { clock : 'a
    ; reset : 'a (* resets dial position to 50 and counters to 0 *)
    ; instruction_valid : 'a (* upstream asserts when instruction is available *)
    ; direction : 'a (* direction of rotation: 0=left, 1=right *)
    ; count : 'a [@bits 16] (* # of dial clicks to rotate *)
    }
  [@@deriving hardcaml]
end

module O = struct
  type 'a t =
    { hits : 'a [@bits 32] (* # of times where the dial lands on 0 after a rotation *)
    ; passes : 'a [@bits 32] (* # of times where the dial passes 0 *)
    ; instruction_ready : 'a (* asserted when module can accept new instruction *)
    }
  [@@deriving hardcaml]
end

module States = struct
  type t =
    | Idle
    | Reducing (* Reduce count to < 100 *)
    | Processing
  [@@deriving sexp_of, compare ~localize, enumerate]
end

let create _scope (inputs : _ I.t) : _ O.t =
  let spec = Reg_spec.create ~clock:inputs.clock () in
  (* State machine for handshaking *)
  let sm = Always.State_machine.create (module States) spec in
  (* Registers *)
  let dial = Always.Variable.reg spec ~width:7 in
  let hits = Always.Variable.reg spec ~width:32 in
  let passes = Always.Variable.reg spec ~width:32 in
  let count_remaining = Always.Variable.reg spec ~width:16 in
  let latched_direction = Always.Variable.reg spec ~width:1 in
  (* Handshaking: transaction occurs when valid and ready are both high *)
  let transaction = Signal.(inputs.instruction_valid &: sm.is Idle) in
  (* Use dial value, defaulting to 50 when reset is active *)
  let dial_current =
    Signal.mux2 inputs.reset (Signal.of_int_trunc ~width:7 50) dial.value
  in
  (* Multi-cycle modulo reducer: subtract 100 repeatedly *)
  let count_reduced = Signal.(count_remaining.value -: of_int_trunc ~width:16 100) in
  let needs_reduction = Signal.(count_remaining.value >=: of_int_trunc ~width:16 100) in
  (* Compute next dial position (count_remaining is already < 100) *)
  let dial_ext = Signal.uresize dial_current ~width:16 in
  let count_mod = count_remaining.value in
  (* Right: (dial + count) % 100, Left: (dial + (100 - count)) % 100 *)
  let dial_next_right_16 = Signal.(dial_ext +: count_mod) in
  let dial_next_left_16 =
    Signal.(dial_ext +: (of_int_trunc ~width:16 100 -: count_mod))
  in
  let dial_next_16 =
    Signal.mux2 latched_direction.value dial_next_right_16 dial_next_left_16
  in
  (* Final mod 100 on result (only need to subtract once since inputs < 200) *)
  let dial_next_final =
    Signal.mux2
      Signal.(dial_next_16 >=: of_int_trunc ~width:16 100)
      Signal.(dial_next_16 -: of_int_trunc ~width:16 100)
      dial_next_16
  in
  let dial_next = Signal.select dial_next_final ~high:6 ~low:0 in
  (* Check if dial lands on zero *)
  let is_hit = Signal.(dial_next ==: Signal.zero 7) in
  (* Sequential logic with Always DSL *)
  let open Always in
  compile
    [ if_
        inputs.reset
        [ dial <-- Signal.of_int_trunc ~width:7 50
        ; hits <-- Signal.zero 32
        ; passes <-- Signal.zero 32
        ; count_remaining <-- Signal.zero 16
        ; latched_direction <-- Signal.zero 1
        ; sm.set_next Idle
        ]
        [ sm.switch
            [ ( Idle
              , [ when_
                    transaction
                    [ count_remaining <-- inputs.count
                    ; latched_direction <-- inputs.direction
                    ; sm.set_next Reducing
                    ]
                ] )
            ; ( Reducing
              , [ if_
                    needs_reduction
                    [ count_remaining <-- count_reduced (* Subtract 100 and stay *) ]
                    [ (* count < 100, ready to compute dial *) sm.set_next Processing ]
                ] )
            ; ( Processing
              , [ dial <-- dial_next
                ; when_ is_hit [ (hits <-- Signal.(hits.value +:. 1)) ]
                ; sm.set_next Idle
                ] )
            ]
        ]
    ];
  { O.hits = hits.value
  ; passes = passes.value
  ; instruction_ready = sm.is Idle (* Ready when in Idle state *)
  }
;;
