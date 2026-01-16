open! Core
open! Hardcaml

let () =
  let module Sim =
    Cyclesim.With_interface
      (Hardcaml_demo_project.Day1_solution.I)
      (Hardcaml_demo_project.Day1_solution.O)
  in
  (* Create the simulation *)
  let sim =
    Sim.create
      (Hardcaml_demo_project.Day1_solution.create (Scope.create ~flatten_design:true ()))
  in
  let inputs = Cyclesim.inputs sim in
  let outputs = Cyclesim.outputs sim in
  (* Helper for valid-ready handshaking protocol *)
  (* Now properly waits for multi-cycle rotation to complete *)
  let send_instruction ~direction ~count =
    inputs.direction := Bits.of_bool direction;
    inputs.count := Bits.of_int_trunc ~width:16 count;
    inputs.instruction_valid := Bits.vdd;
    (* Wait for ready signal (should be immediate when in Idle state) *)
    let rec wait_ready () =
      if Bits.to_bool !(outputs.instruction_ready)
      then ()
      else (
        Cyclesim.cycle sim;
        wait_ready ())
    in
    wait_ready ();
    (* Transaction completes on this cycle (both valid and ready are high) *)
    Cyclesim.cycle sim;
    inputs.instruction_valid := Bits.gnd;
    (* Wait for processing to complete (module returns to Idle/ready state) *)
    (* This may take many cycles for Part 2's click-by-click rotation *)
    let rec wait_complete () =
      if Bits.to_bool !(outputs.instruction_ready)
      then ()
      else (
        Cyclesim.cycle sim;
        wait_complete ())
    in
    wait_complete ()
  in
  (* Reset the circuit *)
  inputs.reset := Bits.vdd;
  inputs.instruction_valid := Bits.gnd;
  Cyclesim.cycle sim;
  inputs.reset := Bits.gnd;
  Cyclesim.cycle sim;
  (* Read input file - configurable via INPUT_FILE env var *)
  let input_file =
    match Stdlib.Sys.getenv_opt "INPUT_FILE" with
    | Some path -> path
    | None ->
      printf "ERROR: INPUT_FILE not set\n";
      printf "Usage: INPUT_FILE=input.txt dune test\n";
      exit 1
  in
  let resolved_file =
    if Stdlib.Sys.file_exists input_file
    then input_file
    else if Stdlib.Sys.file_exists ("../" ^ input_file)
    then "../" ^ input_file
    else (
      printf "ERROR: File not found: %s\n" input_file;
      printf "Place your input file in hardcaml_template_project/\n";
      exit 1)
  in
  let lines = In_channel.read_lines resolved_file in
  printf "Processing %d rotations from %s...\n" (List.length lines) resolved_file;
  (* Process each instruction with handshaking *)
  List.iter lines ~f:(fun line ->
    let line = String.strip line in
    if String.length line > 0
    then (
      let direction_char = line.[0] in
      let count_str = String.sub line ~pos:1 ~len:(String.length line - 1) in
      let count = Int.of_string count_str in
      let direction = Char.equal direction_char 'R' in
      (* R=true (right=1), L=false (left=0) *)
      send_instruction ~direction ~count));
  (* Print results *)
  let hits_val = Bits.to_int_trunc !(outputs.hits) in
  let passes_val = Bits.to_int_trunc !(outputs.passes) in
  let dial_pos = Bits.to_int_trunc !(outputs.dial_position) in
  printf "\n=== RESULTS ===\n";
  printf "Final dial position: %d\n" dial_pos;
  printf "Password (Pt.1): %d\n" hits_val;
  printf "Password (Pt.2): %d\n" passes_val
;;
