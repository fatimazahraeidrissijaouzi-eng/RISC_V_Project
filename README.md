# RISC-V RV32I Pipelined SoC with AXI4-Lite UART

A SystemVerilog hardware design and verification project implementing a **32-bit RISC-V (RV32I) processor**, a **five-stage pipeline**, and a **memory-mapped UART peripheral connected through AXI4-Lite**.

> **Project status:** RTL and simulation testbenches published. Functional simulation scenarios have been exercised locally; complete regression, FPGA synthesis, timing closure, and hardware validation are not claimed.

## Architecture

```text
                 RISC-V RV32I CPU
              IF → ID → EX → MEM → WB
              | forwarding / hazards |
                          |
                  MMIO request interface
                          |
                 CPU / AXI4-Lite bridge
                          |
                   AXI4-Lite UART
                     |         |
                    TX        RX
```

The repository includes:
- RV32I core implementations, including pipelined and UART-integrated variants.
- Pipeline registers, forwarding logic, and hazard detection.
- An AXI4-Lite bridge and UART register interface.
- UART transmit, receive, baud-generation, and top-level modules.
- Self-checking SystemVerilog testbenches, SVA-based checks, and a **UVM-inspired** verification example (not a complete standard UVM environment).

## Repository structure

| Path | Contents |
| --- | --- |
| [`rtl/`](rtl/) | Processor, pipeline, bridge, UART, and SoC RTL (23 modules/files) |
| [`tb/`](tb/) | Unit, integration, protocol, SVA, and UVM-inspired testbenches (31 files) |
| [`program/`](program/) | RISC-V instruction images and historical test-program variants (5 files) |

Historical core backups and simulator-generated waveforms are intentionally not included in the active source tree.

## UART AXI4-Lite register map

The UART peripheral decodes these local offsets:

| Offset | Register | Purpose |
| --- | --- | --- |
| `0x00` | `TX_DATA` | Transmit data |
| `0x04` | `RX_DATA` | Receive data |
| `0x08` | `STATUS` | UART state and flags |
| `0x0C` | `CONTROL` | UART control |

The AXI4-Lite peripheral supports independently arriving write-address and write-data channels, and returns AXI response codes for supported/error cases. The SoC integrates a CPU-to-AXI4-Lite bridge. See [`rtl/uart_axi4_lite.sv`](rtl/uart_axi4_lite.sv) for the implementation.

## Verification

Relevant testbenches include:

- [`tb/tb_riscv_pipeline_core.sv`](tb/tb_riscv_pipeline_core.sv) — pipeline integration
- [`tb/tb_riscv_pipeline_sva.sv`](tb/tb_riscv_pipeline_sva.sv) — assertion-based checks
- [`tb/tb_riscv_axi4_lite_bridge.sv`](tb/tb_riscv_axi4_lite_bridge.sv) — AXI bridge
- [`tb/tb_uart_axi4_lite.sv`](tb/tb_uart_axi4_lite.sv) — UART AXI4-Lite interface
- [`tb/tb_riscv_uart_soc.sv`](tb/tb_riscv_uart_soc.sv) — full SoC
- [`tb/tb_riscv_uart_uvm_inspired.sv`](tb/tb_riscv_uart_uvm_inspired.sv) — sequencer, driver, monitor, scoreboard-inspired structure
- [`tb/tb_riscv_uart_multi_transactions.sv`](tb/tb_riscv_uart_multi_transactions.sv) — successive UART transactions

### Previously reported local simulation results (November 2026)

| Scenario | Reported checks | Reported errors |
| --- | ---: | ---: |
| AXI4-Lite bridge | 12 | 0 |
| RISC-V + UART SoC | 6 | 0 |
| UVM-inspired UART scenario | 6 | 0 |
| Three UART values (`0x55`, `0xA5`, `0x3C`) | 6 | 0 |

These figures describe earlier local runs; they have **not been rerun or independently verified as part of this GitHub publication**. They are not evidence of exhaustive AXI compliance, synthesis, or timing closure.

## Simulation with ModelSim / Questa

Run the simulator **from the repository root**, so `program/program.hex` resolves correctly. Compile the RTL first and **select one testbench top at a time**. For example:

```tcl
vlib work
vlog -sv rtl/*.sv
vlog -sv tb/tb_uart_axi4_lite.sv
vsim work.tb_uart_axi4_lite
run -all
```

On Windows, wildcard expansion and simulator versions may vary. If necessary, compile files explicitly in dependency order. Other testbenches may require different compile options or program images; do not compile every testbench as a single top-level test.

## Tools

SystemVerilog · ModelSim / Questa · VS Code

## Limitations and next steps

- Extend AXI4-Lite error handling, corner-case and backpressure regression.
- Automate repeatable test runs and capture simulator logs.
- Perform FPGA synthesis, constraints, timing analysis and hardware validation.
- Expand functional coverage and document results with reproducible evidence.

## Notes

This repository is intended as a hardware/FPGA portfolio project. It contains multiple educational and historical core/testbench variants; not all are intended to be instantiated or simulated simultaneously.
