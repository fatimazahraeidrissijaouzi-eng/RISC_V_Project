# RISC-V SoC — Validation and Implementation Report

**Status:** Portfolio-ready RTL simulation and FPGA compilation milestone (November 2026).  
**Scope:** RISC-V RV32I five-stage pipelined processor with memory-mapped AXI4-Lite UART.  
**Evidence origin:** Results reported from local ModelSim and Quartus Prime Lite sessions; this documentation update did **not** rerun the tools.

## 1. Functional simulation results

| Test | Reported result | Scope |
| --- | --- | --- |
| Pipeline SVA testbench | 137 checks, 0 errors | 2 stalls, 9 forwarding events, 1 flush in the tested program |
| Integrated RISC-V + UART SoC | 6 checks, 0 errors | Tested UART RX, MMIO/AXI interaction, UART TX |
| UVM-inspired SoC testbench | 6 tests, 0 errors | SystemVerilog verification concepts, **not** a full standard UVM environment |
| AXI4-Lite bridge (previously reported) | 12 checks, 0 errors | Selected bridge scenarios |
| UART three-byte scenario (previously reported) | 6 checks, 0 errors | 0x55, 0xA5, 0x3C |

These results do not establish exhaustive ISA or AXI4-Lite protocol compliance. Detailed simulator transcript files have not been attached to this report.

## 2. FPGA compilation

The local Quartus **Flow Summary** supplied on November 16, 2026 reports:

| Metric | Result |
| --- | --- |
| Flow status | Successful — November 14, 2026, 14:38:25 |
| Quartus version | 25.1std.0 Build 1129, Lite Edition |
| Revision / top-level | `riscv_uart_soc` |
| Device | Intel Cyclone V `5CGXFC7C6F23C6` |
| Logic utilization | 6,675 / 56,480 ALMs (12%) |
| Total registers | 9,298 |
| Pins | 72 / 268 (27%) |
| Block memory bits | 0 / 7,024,640 |
| DSP blocks | 0 / 156 |

A separate **Analysis & Synthesis** report from the same local build completed with **0 errors and 18 warnings**. The previously reported full compilation had **0 errors and 24 warnings**; these are different reporting scopes, not conflicting totals.

## 3. Timing analysis

- Target clock: **50 MHz** (20 ns period).
- The user-shared TimeQuest Fmax Summary screenshot reports **73.13 MHz** for the displayed analyzed clock domain/corner.
- Previously reported internal worst setup slack: **+6.325 ns**.
- Previously reported UART RX synchronizer `rx_meta` → `rx_sync` setup slack: **+14.927 ns**.
- The timing report identified **59 unconstrained output ports** (including debug outputs and UART TX).

**Interpretation:** The reported analyzed internal paths support the 50 MHz target for the reported configuration. Fmax and positive slack do **not** prove that all external interfaces satisfy timing. There is no claim of complete I/O timing closure or operation on a physical FPGA board.

## 4. Warning review (no source edits)

The local Analysis & Synthesis log includes:

| Warning | Observation | Disposition |
| --- | --- | --- |
| 18236 | Parallel processor count not explicitly assigned | Build-configuration advisory |
| 10850 | Instruction image has 18 words; memory declaration spans 256 words | Check expected program image and unused address behavior |
| 10030 | Undriven/internal memory write-related nets are defaulted by synthesis | Review if implementation behavior changes |
| 10240 | Loop variable `i` flagged in `register_file.sv` and `data_memory.sv` | Requires interpretation; not evidence by itself of a latch in stored register/memory data |
| 13024 / 13410 | Several `instruction_debug` output bits optimized to constant VCC/GND | Check against intended test program and debug observability |

These warnings are **documented, not resolved**. Successful compilation does not automatically establish that all warnings are harmless. The design files have intentionally been left unchanged.

## 5. Limitations and future work

1. The supplied validation is scenario-based; additional AXI4-Lite corner cases, backpressure, reset and error handling would strengthen confidence.
2. An automated, repeatable regression and preserved raw ModelSim/Quartus logs remain future improvements.
3. No physical FPGA board was available; pin assignments and board-level I/O timing validation are out of scope.
4. The UVM-inspired testbench demonstrates UVM-style concepts but is not a complete standard UVM implementation.
5. No RTL, testbench, program image, or Quartus project file was changed as part of this documentation update.

## 6. Reproduction notes

Use the repository root as the working directory so relative instruction-image paths resolve. Compile RTL dependencies and one chosen testbench top, then run the simulation and retain the transcript. Quartus results refer to the `riscv_uart_soc` revision targeting the Cyclone V device specified above. Reproducing numerical timing results also requires matching project settings, constraints, tool version and compilation seed.

**Project milestone:** Suitable to describe as *RTL designed, functionally simulated on selected scenarios, and successfully compiled for Cyclone V with reported internal timing analysis*. Do not describe it as fully hardware-validated or exhaustively verified.
