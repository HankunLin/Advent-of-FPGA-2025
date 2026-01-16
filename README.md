# Advent of FPGA (2025)

The [2025 Advent of FPGA Challenge](https://blog.janestreet.com/advent-of-fpga-challenge-2025/) is a hardware engineering challenge hosted by [Jane Street](https://www.janestreet.com/) based on the annual [Advent of Code](https://adventofcode.com/) (AoC) puzzles. The Advent of FPGA expands on the AoC and Jane Street’s puzzle solving culture by challenging participants to solve AoC puzzles by building synthesizable RTL with realistic I/O points. Additional emphasis and recognition is provided for those who build solutions using Hardcaml, Jane Street’s OCaml-based hardware DSL.

**Key details for the challenge:**
- Deadline: all solutions should be submitted [here](https://docs.google.com/forms/d/e/1FAIpQLSeAZ9iw-kS6Di0NtJgCL4ejG9ZWm3li2qrHajT3j3XDBn1uIA/viewform) by January 16, 2026
- Things to submit: open-sourced code, testbenches, and a README explaining the approach and how to run it
- RTL: any RTL language (i.e. Verilog, VHDL, Hardcaml) may be used and designs should be synthesizable with a realistic resource usage (no need to synthesize or run on FPGA)
- Original work only: no duplicates or obviously AI-generated submissions are allowed

**Resources for Hardcaml:**
- https://github.com/janestreet/hardcaml_template_project/tree/with-extensions 
- https://www.janestreet.com/web-app/hardcaml-docs/introduction/why 
- https://blog.janestreet.com/advent-of-hardcaml-2024/ 
- https://ocamlstreet.gitbook.io/hardcaml-wiki

# My Problem (AoC Day 1: Secret Entrance)

Due to time constraints and my experience with Hardcaml, I will be solving the AoC Day 1 problem [“Secret Entrance”](https://adventofcode.com/2025/day/1) for the Advent of FPGA.

TLDR of Part 1 of Day 1: Secret Entrance:
- You are trying to obtain the password for a secret North Pole base which is locked in a safe that has a dial with an arrow on it; around the dial are the numbers 0 through 99 in order. These numbers click as the arrow on the dial reaches each number.
- The puzzle input for the problem contains a sequence of rotations, one per line, that tell you how to open the safe.
- A rotation starts with an L or R which indicates the direction the rotation should be in:
  - L: left towards lower numbers
  - R: right towards higher numbers
- The rotation then has a numerical value which indicates how many clicks the dial should be rotated in that direction.
- The dial starts by pointing at 50.
- The actual password is the number of times the dial is left pointing at 0 after any rotation in the sequence.

TLDR of Part 2 of Day 1: Secret Entrance:
- Part 2 iterates on the solution for Part 1 where the solution is the number of times the dial crosses 0 instead of the number of times the dial is left pointing at 0 after any rotation.

# Solution Approach

To find the solution, I first solved the problem using Python, a high-level language which I find effective for laying out and solving problems.
This solution served as my base logic for solving the problem and is available as solution.py

