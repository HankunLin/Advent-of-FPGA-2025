def solution_part1(puzzle_input):
    """
    Solution for Part 1 of AoC 2025 - Day 1: Secret Entrance:
    - Takes puzzle input as a string and processes it to return the actual password (solution for Part 1) as an integer.
    - Scenario details:
      - There exists a safe with a dial from 0 to 99 with a password inside.
      - The initial position of the dial is 50 and the dial can be turned left (-) or right (+).
      - The actual password is the amount of times the dial lands on zero after any rotation (including no rotations).
    """
    dial_position = 50
    actual_password = 0
    with open(puzzle_input, "r") as file:
        for line in file:
            direction, steps = line[0], int(line[1:])
            if direction == "R":
                dial_position = (dial_position + steps) % 100
            elif direction == "L":
                dial_position = (dial_position - steps) % 100
            if dial_position == 0:
                actual_password += 1

    return actual_password


print(
    str(solution_part1("input.txt"))
    + " is the solution for Part 1 of AoC 2025 - Day 1: Secret Entrance."
)


def solution_part2(puzzle_input):
    """
    Solution for Part 2 of AoC 2025 - Day 1: Secret Entrance:
    - Iterates on the solution for Part 1 to count every single time the dial crosses zero while turning (if the dial crosses zero multiple times in one turn, each crossing counts, but if it stays on zero, it doesn't count).
    - Takes puzzle input as a string and processes it to return the actual password (solution for Part 2) as an integer.
    """
    dial_position = 50
    actual_password = 0
    with open(puzzle_input, "r") as file:
        for line in file:
            direction, steps = line[0], int(line[1:])
            if direction == "R":
                for _ in range(steps):
                    dial_position = (dial_position + 1) % 100
                    if dial_position == 0:
                        actual_password += 1
            elif direction == "L":
                for _ in range(steps):
                    dial_position = (dial_position - 1) % 100
                    if dial_position == 0:
                        actual_password += 1

    return actual_password


print(
    str(solution_part2("input.txt"))
    + " is the solution for Part 2 of AoC 2025 - Day 1: Secret Entrance."
)
