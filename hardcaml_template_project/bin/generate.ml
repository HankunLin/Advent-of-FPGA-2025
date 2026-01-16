open! Core
open! Hardcaml
open! Hardcaml_demo_project

(* generates verilog rtl solution *)
let generate_day1_solution_rtl () =
  let module C = Circuit.With_interface (Day1_solution.I) (Day1_solution.O) in
  let scope = Scope.create ~auto_label_hierarchical_ports:true () in
  let circuit = C.create_exn ~name:"day1_solution_rtl" (Day1_solution.create scope) in
  let rtl_circuits =
    Rtl.create ~database:(Scope.circuit_database scope) Verilog [ circuit ]
  in
  let rtl = Rtl.full_hierarchy rtl_circuits |> Rope.to_string in
  print_endline rtl
;;

let day1_solution_rtl_command =
  Command.basic
    ~summary:"Generate RTL for Day 1 solution"
    [%map_open.Command
      let () = return () in
      fun () -> generate_day1_solution_rtl ()]
;;

let () =
  Command_unix.run
    (Command.group ~summary:"Day 1 RTL generator"[ "day1-solution", day1_solution_rtl_command ])
;;
