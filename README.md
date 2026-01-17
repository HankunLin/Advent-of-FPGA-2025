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

**My Background:**

I am currently a 2nd-year engineering student who has a developing interest in hardware engineering (particularly digital design). Other than practicing on [HDLBits](https://hdlbits.01xz.net/wiki/Main_Page), I have limited expeirence writing HDL, so I plan on using this challenge as an opportunity to get more involved as I begin self-learning digital design more in-depth.
Although I have never touched OCaml before this, I wanted to use this challenge as a gateway to use the language and potentially serve as a reference point for future projects using OCaml; hence, you may notice the large amount of comments on the code.

**TLDR for My Submission:**
- Code (open-sourced): This repository, and the main RTL code is in [hardcaml_template_project/src/day1_solution.ml](hardcaml_template_project/src/day1_solution.ml)
- Testbench: [hardcaml_template_project/test/test_day1_solution.ml](hardcaml_template_project/test/test_day1_solution.ml)
- My Approach and How to Run It: [My Approach](#how-the-solution-works) and [How to Run It](#how-to-run)
(note: I did not run this on an FPGA)

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
This solution served as my base logic for solving the problem and is available as [solution.py](solution.py)

# How the Solution Works

The main Hardcaml code is located in the file: `hardcaml_template_project/src/day1_solution.ml` and is meant to behave like a dial machine that you are able to stream instructions into.

At a high level:
- The design keeps track of the current dial position (0–99), starting at 50
- Each input instruction says “turn left/right by n clicks”
- While it turns, it counts:
  - `hits`: every time the dial ends a rotation instruction on 0 (password for part 1)
  - `passes`: every time the dial passes 0 during a rotation instruction (password for part 2)

This is similar in logic to my python code.

## I/O and Handshake

The module uses a simple ready/valid handshake so the testbench can safely stream one instruction at a time:

- Inputs: `direction` (0=left, 1=right), `count` (16-bit), and `instruction_valid`
- Output: `instruction_ready` goes high when the module is idle and is ready to accept a new instruction

An instruction is “accepted” on a clock edge when both `instruction_valid` and `instruction_ready` are high.

## State Machine

The state machine is a small FSM with a few registers and conditions:

- `dial` (7 bits): current dial position (wraps 0 -> 99)
- `remaining` (16 bits): clicks are left in the current instruction
- `current_direction` (1 bit): latched direction for the active instruction
- `passes`/`hits` (32 bits): running counters

The FSM has 3 states:

- **Idle**: waits for a handshake. On a transaction, it latches `direction` and `count` into registers and moves to **Rotate**.
- **Rotate**: advances the dial one click per cycle
  - Each cycle computes the next position with wraparound (99 -> 0 when rotating right, 0- > 99 when rotating left)
  - If the new dial position is 0, it increments `passes`
  - It also decrements `remaining` each cycle; when the last click has been applied, it moves to **Done**.
- **Done**: checks whether the final `dial` is 0 and increments `hits` if so, then returns to **Idle**.

## Testbench

The testbench is located in `hardcaml_template_project/test/test_day1_solution.ml`.

What it does:

1. Builds a cycle-accurate simulator (`Cyclesim`) for the Hardcaml module.
2. Resets the design (sets dial=50, counters=0, state=Idle).
3. Reads the puzzle input file line-by-line (`INPUT_FILE` env var; defaults to `input.txt`).
4. For each line:
   - Parses the direction and count
   - Waits until `instruction_ready` is high
   - Asserts `instruction_valid` for a cycle to complete the ready/valid handshake
   - Waits until `instruction_ready` goes high again (meaning the FSM is back in **Idle**)
5. Prints the final `hits` (Part 1), `passes` (Part 2), and final dial position.

# How to Run

Here is how to run the code by a Hardcaml/OCaml implementation with a testbench + RTL generator: `hardcaml_template_project/`

## 1) Download or Clone the Code

### Option A: download a ZIP

1. Click Code -> Download ZIP on GitHub.
2. Unzip it.
3. `cd` into the unzipped folder.

### Option B: clone with git

```bash
git clone <REPO_URL>
cd "Advent of FPGA 2025"
```

## 2) Run the Hardcaml/OCaml solution (simulation + tests)

### Prerequisites

- `opam` (OCaml package manager)
- An OCaml compiler (either stock OCaml >= 5.1, or Jane Street’s OxCaml)

On macOS (the OS I built it on), a common setup is installing opam via Homebrew:

```bash
brew install opam
opam init
```

### Installing OCaml / OxCaml / Hardcaml

Hardcaml is distributed through opam, and Jane Street recommends using Hardcaml with OxCaml (an OCaml compiler that includes Jane Street compiler extensions).

1. Follow the official OxCaml install guide (it sets up opam repos + a compiler switch):
  - https://oxcaml.org/get-oxcaml/
2. Select the OxCaml switch in your shell (example from the Hardcaml template README):

```bash
opam switch 5.2.0+ox
eval "$(opam env)"
```

3. Install Hardcaml and common Hardcaml project dependencies:

```bash
opam install -y hardcaml hardcaml_test_harness hardcaml_waveterm ppx_hardcaml
opam install -y core core_unix ppx_jane rope re dune
```

### Build & Test

From the repo root:

```bash
cd hardcaml_template_project

# Create a local switch for this project if needed
opam switch create . 5.1.1 -y
eval "$(opam env)"

# Install dependencies if needed
opam install . --deps-only --with-test -y

# Build
dune build

# Run the testbench
dune runtest
```

Input file behavior:

- **Recommended:** copy your puzzle instructions into the file `hardcaml_template_project/input.txt`, and run:

```bash
INPUT_FILE=../input.txt dune runtest
```

- If your input file is somewhere else, you can also pass an absolute path:

```bash
INPUT_FILE="/absolute/path/to/input.txt" dune runtest
```

The testbench then prints the Part 1 and Part 2 results from the simulated hardware module.

You can also use other file names, just change the command to:

```bash
INPUT_FILE=../<your_file_name>.txt dune runtest
```

**Troubleshooting**
- If those commands don't work, try:

```bash
dune clean
dune build

INPUT_FILE=../input.txt dune runtest
```
- Another potential fix is:

```bash
INPUT_FILE=../input.txt dune runtest -f --no-buffer
```

## 3) Generate Verilog RTL

From `hardcaml_template_project/`:

```bash
dune exec -- bin/generate.exe day1-solution > generated_rtl/day1_solution.v
```

This writes the synthesized Verilog for the Hardcaml design to `hardcaml_template_project/generated_rtl/day1_solution.v`.

## Acknowledgements

- Thank you to Jane Street for hosting this challenge and providing the Hardcaml project template which was very helpful for setting up and creating my solution. It was fun and I learned a lot from it!

