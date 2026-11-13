# RISC-V Pipelined SoC with UART AXI4-Lite

SystemVerilog project for a 32-bit RV32I RISC-V processor with a 5-stage pipeline (IF, ID, EX, MEM, WB), forwarding, hazard detection, and a memory-mapped UART peripheral connected over AXI4-Lite.

## Architecture
- RV32I pipeline with forwarding and load-use hazard detection
- UART transmitter/receiver and AXI4-Lite slave peripheral
- CPU-to-AXI4-Lite bridge with memory-mapped UART access
- SystemVerilog testbenches, assertions (SVA), and a UVM-inspired verification structure

## Tools
- ModelSim / Questa
- SystemVerilog
- VS Code

## Simulation results (local ModelSim runs, November 2026)
- AXI4-Lite bridge: 12 checks passed, 0 errors
- Integrated RISC-V + UART SoC: 6 checks passed, 0 errors
- UVM-inspired UART scenario: 6 checks passed, 0 errors
- Three successive UART values (0x55, 0xA5, 0x3C): 6 checks passed, 0 errors

These are functional simulation results for the tested scenarios, **not** proof of exhaustive verification, FPGA synthesis, or timing closure.

## Project layout
```text
rtl/       RTL modules (processor, pipeline, UART, bridge)
tb/        SystemVerilog testbenches and checks
program/   RISC-V program image(s)
```

## Status
Work in progress. Advanced AXI error/edge-case tests, synthesis and final documentation are still pending.

> Some source directories may not yet be uploaded. This README documents the project progress; it does not imply the complete local project is available in the repository.
