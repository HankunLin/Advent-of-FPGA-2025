open! Core
open! Hardcaml
open! Signal

(* define input(I) interface *)
module I = struct
  type 'a t =
    { clock : 'a (* main timing signal (updates on edge) *)
    ; reset : 'a (* resets dial position to 50 and counters to 0 *)
    ; instruction_valid : 'a (* when new input data can be processed (high when ready to send data)*)
    ; direction : 'a (* direction of rotation: 0=left, 1=right *)
    ; count : 'a [@bits 16] (* # of dial clicks to rotate *)
    }
  [@@deriving hardcaml]
end

(* define output(O) interface *)
module O = struct
  type 'a t =
    { hits : 'a [@bits 32] (* # of times where the dial lands on 0 after a rotation (password for Pt.1) *)
    ; passes : 'a [@bits 32] (* # of times where the dial passes through 0 during rotation (password for Pt.2) *)
    ; instruction_ready : 'a (* when new instructions can be accepted (high when ready to accept data)*)
    ; dial_position : 'a [@bits 7] (* current dial position (7 bits b/c 0-99 range for values) *)
    ; busy : 'a (* high when processing a rotation *)
    }
  [@@deriving hardcaml]
end

(* define states for state machine *)
module States = struct
  type t =
    | Idle (* wait for input *)
    | Rotate (* process each rotation click-by-click *)
    | Done (* rotation is complete, check for hits & passes, return to Idle *)
  [@@deriving sexp_of, compare ~localize, enumerate]
end

(* setup and describe hardware module *)
let create _scope (inputs : _ I.t) : _ O.t =
  let spec = Reg_spec.create ~clock:inputs.clock () in (* create register specification *)
  
  (* state machine (Always allows for sequential logic for updating on clock edges) *)
  let sm = Always.State_machine.create (module States) spec in
  
  (* registers *)
  let dial = Always.Variable.reg spec ~width:7 in (* dial range is 0-99, so only requires 7 bits *)
  let hits = Always.Variable.reg spec ~width:32 in
  let passes = Always.Variable.reg spec ~width:32 in
  let remaining = Always.Variable.reg spec ~width:16 in (* clicks left to go in rotation *)
  let current_direction = Always.Variable.reg spec ~width:1 in (* stored direction *)
  
  (* handshaking: transaction occurs when valid and ready are both high *)
  let transaction = Signal.(inputs.instruction_valid &: sm.is Idle) in (* transaction occurs when new instruction is valid and Idle state*)

  (* compute next dial position for click-by-click rotation *)
  (* right direction rotation (incease) *)
  let dial_plus_one =
    Signal.mux2
      Signal.(dial.value ==: of_int_trunc ~width:7 99) (* checks dial value if wrap-around needed (max 99)*)
      (Signal.zero 7)
      Signal.(dial.value +:. 1)
  in
  (* left direction rotation (decrease) *)
  let dial_minus_one =
    Signal.mux2
      Signal.(dial.value ==: Signal.zero 7) (* checks dial value if wrap-around needed (min 0)*)
      (Signal.of_int_trunc ~width:7 99)
      Signal.(dial.value -:. 1)
  in

  let dial_next_step = Signal.mux2 current_direction.value dial_plus_one dial_minus_one in (* use mux to select which way to increment dial based on direction of rotation *)
  let is_pass = Signal.(dial_next_step ==: Signal.zero 7) in (* check if dial passes through 0*)
  
  (* sequential logic w/Always *)
  let open Always in
  compile
    [ if_
        inputs.reset (* when asserted, reset all input registers to original values and state machine to Idle *)
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
                    [ (* load instruction values (direction to rotate and amount of clicks needed) *)
                      remaining <-- inputs.count 
                    ; current_direction <-- inputs.direction
                    ; (* if count is 0, stay in Idle (no rotation needed), else move to Rotate state *)
                      if_
                        Signal.(inputs.count ==: Signal.zero 16)
                        [ sm.set_next Idle ]
                        [ sm.set_next Rotate ]
                    ]
                ] )
            ; ( Rotate
              , [ (* for each cycle, dial updated with single step in instructed direction *)
                  dial <-- dial_next_step
                ; (remaining <-- Signal.(remaining.value -:. 1)) (* remaining clicks subtracted *)
                ; (* Count passes: when dial lands on 0 during rotation *)
                  when_ is_pass [ (passes <-- Signal.(passes.value +:. 1)) ] (* if dial lands on 0 during rotation, increment passes count *)
                ; (* if only 1 click remains, transition to Done state *)
                  if_ 
                    Signal.(remaining.value ==:. 1)
                    [ sm.set_next Done ] 
                    [ sm.set_next Rotate ]
                ] )
            ; ( Done
              , [ (* check if final dial position is 0 (a hit) *)
                  when_
                    Signal.(dial.value ==: Signal.zero 7)
                    [ (hits <-- Signal.(hits.value +:. 1)) ]
                ; sm.set_next Idle (* return to Idle state for next instruction*)
                ] )
            ]
        ]
    ];
  (* output values *)
  { O.hits = hits.value (* output number of hits (# of times dial lands on zero after rotation instruction) *)
  ; passes = passes.value (* output number of passes (# of times dial passes through zero during rotation) *)
  ; instruction_ready = sm.is Idle (* dial ready for new instructionwhen in Idle state *)
  ; dial_position = dial.value (* current dial position *)
  ; busy = Signal.(~:(sm.is Idle)) (* output if not in Idle state *)
  }
;;
