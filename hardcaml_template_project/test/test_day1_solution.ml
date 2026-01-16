open! Core
open! Hardcaml

(* code runs automatically when file is executed *)
let () =
  (* define simulation module (w/ I/O interfaces) *)
  let module Sim =
    Cyclesim.With_interface
      (Hardcaml_demo_project.Day1_solution.I)
      (Hardcaml_demo_project.Day1_solution.O)
  in
  
  (* create the simulation *)
  let sim =
    Sim.create
      (Hardcaml_demo_project.Day1_solution.create (Scope.create ~flatten_design:true ())) (* generated design is flat and easier to simulate*)
  in
  let inputs = Cyclesim.inputs sim in
  let outputs = Cyclesim.outputs sim in

  (* helper function for sending rotation instructions to hardware module and handshake protocol*)
  let send_instruction ~direction ~count =
    (* convert inputs to bits *)
    inputs.direction := Bits.of_bool direction;
    inputs.count := Bits.of_int_trunc ~width:16 count;
    inputs.instruction_valid := Bits.vdd; (* asserts valid instruction signal for new instruction *)
    
    (* wait for ready signal *)
    let rec wait_ready () =
      if Bits.to_bool !(outputs.instruction_ready)
      then ()
      else (
        Cyclesim.cycle sim; (* loop until ready condition is met *)
        wait_ready ())
    in
    wait_ready ();
    (* Transaction completes on this cycle (both valid and ready are high) *)
    Cyclesim.cycle sim; (* sim advances by 1 clock cycle (instruction registered by hardware) *)
    inputs.instruction_valid := Bits.gnd; (* indicates instruction sent *)
    
    (* wait for hardware processing to complete (can take multiple cycles until function returns to idle) *)
    let rec wait_complete () =
      if Bits.to_bool !(outputs.instruction_ready)
      then ()
      else (
        Cyclesim.cycle sim;
        wait_complete ())
    in
    wait_complete ()
  in
  
  (* reset the hardware module *)
  inputs.reset := Bits.vdd; (* registers & sm returns to initial values*)
  inputs.instruction_valid := Bits.gnd;
  Cyclesim.cycle sim;
  inputs.reset := Bits.gnd;
  Cyclesim.cycle sim; (* cycle to go back to new state *)
  
  (* input file is read line-by-line *)
  let input_file =
    match Stdlib.Sys.getenv_opt "INPUT_FILE" with
    | Some path -> path
    (* if input file not set... *)
    | None ->
      printf "ERROR: INPUT_FILE not set\n";
      printf "Usage: INPUT_FILE=input.txt dune test\n";
      exit 1
  in
  
  (* path to input file by testbench*)
  let resolved_file =
    if Stdlib.Sys.file_exists input_file
    then input_file
    else if Stdlib.Sys.file_exists ("../" ^ input_file)
    then "../" ^ input_file
    (* file not found, tell user where to put input file*)
    else (
      printf "ERROR: File not found: %s\n" input_file;
      printf "Place your input file in hardcaml_template_project/\n";
      exit 1)
  in
  
  (* read & process rotation instructions *)
  let lines = In_channel.read_lines resolved_file in
  printf "Processing %d rotations from %s...\n" (List.length lines) resolved_file;
  (* read each instruction with handshaking *)
  List.iter lines ~f:(fun line ->
    let line = String.strip line in
    if String.length line > 0
    then (
      let direction_char = line.[0] in
      let count_str = String.sub line ~pos:1 ~len:(String.length line - 1) in
      let count = Int.of_string count_str in
      let direction = Char.equal direction_char 'R' in
      (* R=true (right=1), L=false (left=0) *)
      send_instruction ~direction ~count)); (* send instruction *)
  
  (* print results *)
  (* convert bits to integers *)
  let hits_val = Bits.to_int_trunc !(outputs.hits) in
  let passes_val = Bits.to_int_trunc !(outputs.passes) in
  let dial_pos = Bits.to_int_trunc !(outputs.dial_position) in
  printf "\n=== RESULTS ===\n";
  printf "Final dial position: %d\n" dial_pos;
  printf "Password (Pt.1): %d\n" hits_val;
  printf "Password (Pt.2): %d\n" passes_val
;;
