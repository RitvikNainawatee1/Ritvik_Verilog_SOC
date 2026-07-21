# Week 7 — Pipelining

## Objective

Understand how pipelining works, why hazards arise, and how to
resolve them. By the end of this week you should be able to trace
through the bubble sort program, identify every hazard, and write
a concrete resolution plan. That plan is your implementation
blueprint for Week 8.

---

## The Core Idea

A single-cycle CPU wastes hardware. While an instruction is in the
ALU, the register file and memory sit idle. Pipelining overlaps
execution — while instruction N is in EX, instruction N+1 is in ID,
and instruction N+2 is in IF. Like a factory assembly line.

The 5-stage Pipeline:

```
IF  →  ID  →  EX  →  MEM  →  WB
```

| Stage | What happens                                           |
| ----- | ------------------------------------------------------ |
| IF    | Fetch instruction from Code Memory using PC            |
| ID    | Decode instruction, read register file                 |
| EX    | ALU operation, compute memory address, evaluate branch |
| MEM   | Read or write Data Memory                              |
| WB    | Write result back to register file                     |

In steady state, 5 instructions are active simultaneously —
one in each stage.

---

## Pipeline Registers

Between every two stages sits a **pipeline register** — a bank of
flip-flops that captures the outputs of one stage and holds them
stable for the next stage on the following clock cycle.

```
IF  →  [IF/ID reg]  →  ID  →  [ID/EX reg]  →  EX  →  [EX/MEM reg]  →  MEM  →  [MEM/WB reg]  →  WB
```

These are not new concepts — they are the exact same `register`
module you built in Week 2. The only question is what signals to
put inside each one.

Each pipeline register carries:

- The data values the next stage needs (register outputs, ALU result, memory data)
- The control signals for all remaining stages of this instruction

Control signals are decoded once in ID and passed forward through
pipeline registers until the stage that needs them.

---

## Hazards

Pipelining breaks when an instruction needs a result that hasn't
been produced yet. There are three types:

### 1. Data Hazards (RAW — Read After Write)

Instruction N+1 reads a register that instruction N hasn't
written back yet.

Example from bubble sort (lines 9 → 11):

```
9:  LOADF C, [array+B]    ← writes C in WB (4 cycles later)
10: LOADF D, [array+B+1]  ← reads B only — no hazard
11: CMP   D, C            ← reads C — hazard! C not written yet
```

**Resolution: Forwarding (Bypassing)**
The result exists in the MEM/WB pipeline register — it just hasn't
been written to the register file yet. Forward it directly to the
EX stage ALU input, skipping the register file entirely.

```
MEM/WB.result  ──────────────────────→  EX stage ALU input
                     (forwarding path)
```

### 2. Flags Hazard (i281-specific)

Unlike MIPS, the i281 branches on flags (ZF, NF, OF, CF), not
on registers directly. CMP writes the flags register in EX.
A branch immediately after CMP reads flags before they are written.

This is the most common hazard in bubble sort — lines 3→4, 7→8, 11→12:

```
3: CMP  A, D    ← writes flags in EX
4: BRGE End     ← reads flags — hazard!
```

**Resolution: Flags Forwarding + 1-cycle Stall**
Forward flags from the EX/MEM pipeline register to the branch
evaluation logic. Stall the pipeline for 1 cycle (insert a NOP
bubble into EX, freeze IF and ID) so the flags are computed
before the branch reads them.

Stall condition:

```
if (instruction in EX writes flags) AND (instruction in ID is a branch)
    → stall 1 cycle, insert bubble
```

### 3. Control Hazards (Branches and Jumps)

By the time a branch is resolved at the end of EX, the next
instruction has already entered IF. If the branch is taken,
that instruction must be discarded — flushed.

Occurs at every BRGE and JUMP — lines 4, 8, 12, 16, 18.

**Resolution: Flush on taken branch**
When a branch evaluates as taken, flush the IF/ID pipeline
register (overwrite it with a NOP/bubble).

- JUMP: always flush — unconditional
- BRGE etc: flush only if the condition is true

---

## Forwarding Unit Logic

The forwarding unit compares register addresses and selects
the correct data source for ALU inputs:

```
// EX hazard — value needed is in EX/MEM register:
if (EX_MEM.reg_write == 1 &&
    EX_MEM.write_reg == ID_EX.read_reg_A)
    forward_A = EX_MEM.alu_result

// MEM hazard — value needed is in MEM/WB register:
if (MEM_WB.reg_write == 1 &&
    MEM_WB.write_reg == ID_EX.read_reg_A &&
    no EX hazard applies)
    forward_A = MEM_WB.result   // alu_result or dmem_data

// Same logic for ALU input B

// Flags forwarding for branches:
if (EX_MEM.flags_write == 1)
    use EX_MEM.flags for branch evaluation
else
    use flags register
```

---

## Hazard Summary for Bubble Sort

Every hazard in the bubble sort program:

| Lines    | Instructions          | Hazard Type  | Resolution              |
| -------- | --------------------- | ------------ | ----------------------- |
| 3 → 4    | CMP → BRGE            | Flags RAW    | Stall 1 + forward flags |
| 7 → 8    | CMP → BRGE            | Flags RAW    | Stall 1 + forward flags |
| 9 → 11   | LOADF C → CMP reads C | Load-use RAW | Forward MEM/WB → EX     |
| 11 → 12  | CMP → BRGE            | Flags RAW    | Stall 1 + forward flags |
| 4, 8, 12 | BRGE (if taken)       | Control      | Flush IF/ID             |
| 16, 18   | JUMP                  | Control      | Always flush IF/ID      |

---

## Theory

### Patterson & Hennessy — Computer Organization and Design (3rd Ed.)

| Section | Topic                       |
| ------- | --------------------------- |
| §6.1    | An Overview of Pipelining   |
| §6.2    | A Pipelined Datapath        |
| §6.3    | Pipelined Control           |
| §6.4    | Data Hazards and Forwarding |
| §6.5    | Data Hazards and Stalls     |
| §6.6    | Branch Hazards              |

### Code References

These repos have complete pipelined processors in Verilog.
Read them to understand how pipeline registers, forwarding
units, and hazard detection units are structured — don't copy,
use them to understand the pattern before writing your own.

- github.com/tjsparks5/Pipelined-MIPS-Processor

- github.com/quintonarnaud/5_stage_pipeline_CPU_verilog

Note: Both are MIPS processors. The i281 differs in one key way —
branches evaluate flags, not registers. Everything else
(pipeline registers, forwarding paths, stall logic structure)
is identical.

---

## Assignment

No Verilog this week. Submit a PDF of written script with two parts.

### Part 1 — Pipeline Diagram

Draw the pipeline execution diagram for bubble sort lines 3–16.
Use this format, marking every stall bubble (\*\*) and flush (XX):

```
        Cycle:  1    2    3    4    5    6    7    8    9   ...
Line 3  CMP:    IF   ID   EX   MEM  WB
Line 4  BRGE:        IF   ID   **   EX   MEM  WB
Line 5  LOAD:             IF   **   ID   EX   MEM  WB
...
```

### Part 2 — Hazard Table

For every hazard in your diagram, complete this table:

| Instruction pair | Hazard type  | What causes it                             | Resolution          |
| ---------------- | ------------ | ------------------------------------------ | ------------------- |
| CMP → BRGE       | Flags RAW    | c14 writes flags, branch reads flags       | Stall + forward     |
| LOADF C → CMP    | Load-use RAW | C written in WB, read in EX 2 cycles later | Forward MEM/WB → EX |
| BRGE taken       | Control      | Wrong instruction fetched after branch     | Flush IF/ID         |
