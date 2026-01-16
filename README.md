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

# How the Hardcaml solution works

The Hardcaml design lives in `hardcaml_template_project/src/day1_solution.ml` and is meant to behave like a little “dial machine” that you stream instructions into.

At a high level:

- The design keeps track of the current dial position (0–99), starting at 50.
- Each input instruction says “turn left/right by N clicks”.
- While it turns, it counts:
  - `passes`: every time the dial *crosses onto* 0 during the turn (Part 2)
  - `hits`: if the dial ends the full rotation on 0 (Part 1)

## Inputs/outputs and handshake

The module uses a simple ready/valid handshake so the testbench can safely stream one instruction at a time:

- Inputs: `direction` (0=left, 1=right), `count` (16-bit), and `instruction_valid`.
- Output: `instruction_ready` goes high when the module is idle and ready to accept a new instruction.

An instruction is “accepted” on a clock edge when both `instruction_valid` and `instruction_ready` are high.

## State machine

Internally, it’s a small FSM with a few registers:

- `dial` (7 bits): current dial position (wraps 0 ↔ 99)
- `remaining` (16 bits): how many clicks are left in the current instruction
- `current_direction` (1 bit): latched direction for the active instruction
- `passes`/`hits` (32 bits): the running counters

The FSM has three states:

- **Idle**: waits for a handshake. On a transaction, it latches `direction` and `count` into registers and moves to **Rotate**.
- **Rotate**: advances the dial one click per cycle.
  - Each cycle computes the next position with wraparound (99→0 when rotating right, 0→99 when rotating left).
  - If the *new* dial position is 0, it increments `passes` (this matches the “crosses 0” interpretation).
  - Decrements `remaining` each cycle; when the last click has been applied, it moves to **Done**.
- **Done**: checks whether the final `dial` is 0 and increments `hits` if so, then returns to **Idle**.

One realistic tradeoff here: the implementation is intentionally “one click per cycle”, which keeps the logic simple and obviously synthesizable, but it means a big `count` takes a lot of cycles to simulate (and would take that many cycles in hardware too).

## Testbench / how it runs end-to-end

The simulation harness is `hardcaml_template_project/test/test_day1_solution.ml`.

What it does:

1. Builds a cycle-accurate simulator (`Cyclesim`) for the Hardcaml module.
2. Resets the design (sets dial=50, counters=0, state=Idle).
3. Reads the puzzle input file line-by-line (`INPUT_FILE` env var; defaults to `input.txt`).
4. For each line:
   - Parses the direction and count.
   - Waits until `instruction_ready` is high.
   - Asserts `instruction_valid` for a cycle to complete the ready/valid handshake.
   - Waits until `instruction_ready` goes high again (meaning the FSM is back in **Idle**).
5. Prints the final `hits` (Part 1), `passes` (Part 2), and final dial position.

That handshake loop is why the testbench is robust: it doesn’t assume anything about how long a rotation takes — it just waits for the module to say it’s ready.

# How to run

This repo contains two ways to run Day 1:

- A Python reference implementation: `solution.py`
- A Hardcaml/OCaml implementation with a testbench + RTL generator: `hardcaml_template_project/`

## 1) Download the code

### Option A: download a ZIP

1. Click **Code → Download ZIP** on GitHub.
2. Unzip it.
3. `cd` into the unzipped folder.

### Option B: clone with git

```bash
git clone <REPO_URL>
cd "Advent of FPGA 2025"
```

## 2) Run the Python reference solution

### Prerequisites

- Python 3 (no extra packages required)

### Run

From the repo root:

```bash
python3 solution.py
```

It reads `input.txt` from the repo root and prints the Part 1 and Part 2 answers.

**Where to put the input file (Python):** place your AoC input at the repo root as `input.txt`.

## 3) Run the Hardcaml/OCaml solution (simulation + tests)

### Prerequisites

- `opam` (OCaml package manager)
- An OCaml compiler (either stock OCaml >= 5.1, or Jane Street’s OxCaml)

On macOS, a common setup is installing opam via Homebrew:

```bash
brew install opam
opam init
```

### Installing OCaml / OxCaml / Hardcaml

Hardcaml is distributed through opam. Jane Street recommends using Hardcaml with **OxCaml** (a bleeding-edge OCaml compiler that includes Jane Street compiler extensions, while staying compatible with typical OCaml code). In many Hardcaml repos, the OxCaml-compatible version of the code lives on a branch named `with-extensions`.

**Option A (recommended): OxCaml + Hardcaml**

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

**Option B: Stock OCaml + opam**

If you don’t want OxCaml, you can use regular OCaml (>= 5.1) and still build this project. The simplest way is to create a local opam switch for this repo (see below) and let `opam install . --deps-only` pull what you need.

### Build & test

From the repo root:

```bash
cd hardcaml_template_project

# Create a local switch for this project (one-time)
opam switch create . 5.1.1 -y
eval "$(opam env)"

# Install dependencies (one-time)
opam install . --deps-only --with-test -y

# Build
dune build

# Run the testbench
dune runtest
```

Input file behavior:

- **Recommended:** put your input at `hardcaml_template_project/input.txt` (this is the default).
- If you keep `input.txt` at the repo root instead, run:

```bash
INPUT_FILE=../input.txt dune runtest
```

- If your input file is somewhere else, you can also pass an absolute path:

```bash
INPUT_FILE="/absolute/path/to/input.txt" dune runtest
```

The testbench first checks the path you provide; if it doesn’t exist and you provided a relative path, it also tries `../<path>`.

The testbench prints the Part 1 and Part 2 results from the simulated hardware module.

## 4) Generate Verilog RTL

From `hardcaml_template_project/`:

```bash
dune exec -- bin/generate.exe day1-solution > generated_rtl/day1_solution.v
```

This writes the synthesized Verilog for the Hardcaml design to `hardcaml_template_project/generated_rtl/day1_solution.v`.

## Acknowledgements

- If `eval "$(opam env)"` seems to do nothing, run it in every new terminal session (or add it to your shell profile).
- If `dune` isn’t found after creating the switch, re-run `eval "$(opam env)"` and confirm the switch is active with `opam switch`.

