open! Core
open! Hardcaml

let%expect_test "day1_solution" =
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
    (* Wait for processing to complete (module returns to Idle) *)
    Cyclesim.cycle sim
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
      printf "Usage: INPUT_FILE=path/to/your_file.txt dune test\n";
      printf "Example: INPUT_FILE=../day1_input.txt dune test\n";
      ""
  in
  let lines =
    if String.is_empty input_file
    then []
    else (
      match Stdlib.Sys.file_exists input_file with
      | true -> In_channel.read_lines input_file
      | false ->
        printf "ERROR: File not found: %s\n" input_file;
        [])
  in
  printf "Processing %d instructions...\n" (List.length lines);
  (* Process each instruction with handshaking *)
  List.iter lines ~f:(fun line ->
    let line = String.strip line in
    if String.length line > 0
    then (
      let direction_char = line.[0] in
      let count_str = String.sub line ~pos:1 ~len:(String.length line - 1) in
      let count = Int.of_string count_str in
      let direction = Char.equal direction_char 'R' in
      (* R=true (right), L=false (left) *)
      send_instruction ~direction ~count));
  (* Print results *)
  let hits_val = Bits.to_int_trunc !(outputs.hits) in
  let passes_val = Bits.to_int_trunc !(outputs.passes) in
  printf "Hits: %d\n" hits_val;
  printf "Passes: %d\n" passes_val;
  printf "\n=== To test with your own input ===\n";
  printf "Set INPUT_FILE to your input file path:\n";
  printf "  INPUT_FILE=../your_file.txt dune test\n";
  printf "Then run: dune promote (to accept the results)\n";
  printf "\n✓ RESULT: %d is the password for part 1, %d passes\n" hits_val passes_val;
  [%expect
    {|
    === To test with your own input ===
    Set INPUT_FILE to your input file path:
      INPUT_FILE=../your_file.txt dune test
    Then run: dune promote (to accept the results)
    |}]
;;
