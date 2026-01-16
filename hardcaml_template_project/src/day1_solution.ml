open! Core
open! Hardcaml
open! Signal

(* Day 1 solution with valid-ready handshaking protocol *)
(* Part 1: Count "hits" - times dial lands on 0 after a rotation *)
(* Part 2: Count "passes" - times dial crosses through 0 during rotation *)

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
    ; passes : 'a
         [@bits 32] (* # of times where the dial passes through 0 during rotation *)
    ; instruction_ready : 'a (* asserted when module can accept new instruction *)
    ; dial_position : 'a [@bits 7] (* current dial position for debug/monitoring *)
    ; busy : 'a (* high when processing a rotation *)
    }
  [@@deriving hardcaml]
end

module States = struct
  type t =
    | Idle (* Waiting for input *)
    | Rotate (* Process click-by-click rotation *)
    | Done (* Rotation complete, check for hit and return to Idle *)
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
  let remaining = Always.Variable.reg spec ~width:16 in
  (* clicks left in rotation *)
  let current_direction = Always.Variable.reg spec ~width:1 in
  (* stored direction *)
  (* Handshaking: transaction occurs when valid and ready are both high *)
  let transaction = Signal.(inputs.instruction_valid &: sm.is Idle) in
  (* Compute next dial position for single-click rotation *)
  (* Right (direction=1): dial+1, wrap 99->0 *)
  (* Left (direction=0): dial-1, wrap 0->99 *)
  let dial_plus_one =
    Signal.mux2
      Signal.(dial.value ==: of_int_trunc ~width:7 99)
      (Signal.zero 7)
      Signal.(dial.value +:. 1)
  in
  let dial_minus_one =
    Signal.mux2
      Signal.(dial.value ==: Signal.zero 7)
      (Signal.of_int_trunc ~width:7 99)
      Signal.(dial.value -:. 1)
  in
  let dial_next_step = Signal.mux2 current_direction.value dial_plus_one dial_minus_one in
  (* Check if this step crosses zero (dial lands on 0 after this click) *)
  let is_pass = Signal.(dial_next_step ==: Signal.zero 7) in
  (* Sequential logic with Always DSL *)
  let open Always in
  compile
    [ if_
        inputs.reset
        [ dial <-- Signal.of_int_trunc ~width:7 50
        ; hits <-- Signal.zero 32
        ; passes <-- Signal.zero 32
        ; remaining <-- Signal.zero 16
        ; current_direction <-- Signal.zero 1
        ; sm.set_next Idle
        ]
        [ sm.switch
            [ ( Idle
              , [ when_
                    transaction
                    [ (* Load instruction parameters *)
                      remaining <-- inputs.count
                    ; current_direction <-- inputs.direction
                    ; (* If count is 0, stay in Idle (no rotation needed) *)
                      if_
                        Signal.(inputs.count ==: Signal.zero 16)
                        [ sm.set_next Idle ]
                        [ sm.set_next Rotate ]
                    ]
                ] )
            ; ( Rotate
              , [ (* Process one click per cycle *)
                  dial <-- dial_next_step
                ; (remaining <-- Signal.(remaining.value -:. 1))
                ; (* Count passes: when dial lands on 0 during rotation *)
                  when_ is_pass [ (passes <-- Signal.(passes.value +:. 1)) ]
                ; (* Check if this is the last click *)
                  if_
                    Signal.(remaining.value ==:. 1)
                    [ (* Last click - go to Done to finalize *) sm.set_next Done ]
                    [ (* More clicks remaining - stay in Rotate *) sm.set_next Rotate ]
                ] )
            ; ( Done
              , [ (* Check if final dial position is 0 (a hit) *)
                  when_
                    Signal.(dial.value ==: Signal.zero 7)
                    [ (hits <-- Signal.(hits.value +:. 1)) ]
                ; sm.set_next Idle
                ] )
            ]
        ]
    ];
  { O.hits = hits.value
  ; passes = passes.value
  ; instruction_ready = sm.is Idle (* Ready when in Idle state *)
  ; dial_position = dial.value
  ; busy = Signal.(~:(sm.is Idle))
  }
;;
