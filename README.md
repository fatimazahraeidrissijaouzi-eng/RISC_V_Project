# RISC-V RV32I Pipelined SoC with AXI4-Lite UART

A SystemVerilog hardware design and verification project implementing a **32-bit RISC-V (RV32I) processor**, a **five-stage pipeline**, and a **memory-mapped UART peripheral connected through AXI4-Lite**.

> **Project status (November 2026):** RTL and testbenches published; selected functional simulations passed locally. FPGA synthesis completed successfully with Quartus Prime Lite, and internal register-to-register timing was analyzed at a 50 MHz target. Full external I/O timing closure, exhaustive protocol verification, and physical FPGA-board validation are **not** claimed.

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
- Self-checking SystemVerilog testbenches, SVA-based checks, a historical **UVM-inspired** example, and a separate standard UVM 1.1d AXI4-Lite verification environment.

## Repository structure

| Path | Contents |
| --- | --- |
| [`rtl/`](rtl/) | Processor, pipeline, bridge, UART, and SoC RTL (23 modules/files) |
| [`tb/`](tb/) | Unit, integration, protocol, SVA, and UVM-inspired testbenches (31 files) |
| [`uvm/`](uvm/) | Standard UVM AXI4-Lite transactions, sequences, agent, scoreboard and functional coverage |
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

## Verified project highlights

The following results were captured in local ModelSim and Quartus Prime sessions (November 2026):

| Evidence | Observed result | Scope |
| --- | --- | --- |
| Pipeline SVA testbench | **137 checks, 0 errors** | Tested instruction sequence; 2 stalls, 9 forwarding events, 1 flush |
| Integrated RISC-V + UART SoC | **6 checks, 0 errors** | UART receive, MMIO transfer, AXI stall and UART transmit scenario |
| UVM-inspired SoC testbench | **6 tests, 0 errors** | Sequencer/driver/monitor-style scenario; not full UVM |
| Quartus Prime full compilation | **Successful, 0 errors, 24 warnings** | Intel Cyclone V target; 6,675 / 56,480 ALMs (12%) |
| UART RX synchronizer setup path | **+14.927 ns slack** | Specific `rx_meta` to `rx_sync` path at a 20 ns clock period |

These are **scenario-specific simulation and implementation reports**, not exhaustive verification, full I/O timing closure, or a physical FPGA demonstration.

## Validation report

See [Validation and Implementation Report](docs/VALIDATION_REPORT.md) for the recorded simulation results, Quartus Flow Summary, timing scope, warning review, and remaining limitations. This documentation does not claim exhaustive verification or physical FPGA-board testing.

## Verification

Relevant testbenches include:

- [`tb/tb_riscv_pipeline_core.sv`](tb/tb_riscv_pipeline_core.sv) — pipeline integration
- [`tb/tb_riscv_pipeline_sva.sv`](tb/tb_riscv_pipeline_sva.sv) — assertion-based checks
- [`tb/tb_riscv_axi4_lite_bridge.sv`](tb/tb_riscv_axi4_lite_bridge.sv) — AXI bridge
- [`tb/tb_uart_axi4_lite.sv`](tb/tb_uart_axi4_lite.sv) — UART AXI4-Lite interface
- [`tb/tb_riscv_uart_soc.sv`](tb/tb_riscv_uart_soc.sv) — full SoC
- [`tb/tb_riscv_uart_uvm_inspired.sv`](tb/tb_riscv_uart_uvm_inspired.sv) — sequencer, driver, monitor, scoreboard-inspired structure
- [`tb/tb_riscv_uart_multi_transactions.sv`](tb/tb_riscv_uart_multi_transactions.sv) — successive UART transactions

### Additional previously reported local simulation results (November 2026)

| Scenario | Reported checks | Reported errors |
| --- | ---: | ---: |
| AXI4-Lite bridge | 12 | 0 |
| Three UART values (`0x55`, `0xA5`, `0x3C`) | 6 | 0 |

These figures describe earlier local runs; they have **not been rerun or independently verified as part of this GitHub documentation update**. They are not evidence of exhaustive AXI compliance or physical-board validation.

An additional local run of `tb_riscv_pipeline_sva.sv` reported **137 checks, 0 errors**, with **2 stalls, 9 forwarding events and 1 flush** for the exercised program. This is scenario-based validation, not formal proof or exhaustive coverage.

### Standard UVM AXI4-Lite verification

A local ModelSim SE-64 10.6d / UVM 1.1d simulation on November 27, 2026 reported:

| Metric | Result |
| --- | ---: |
| Transactions | 29 (10 writes, 19 reads) |
| Passed scoreboard checks | 29 |
| Failed checks | 0 |
| UVM warnings / errors / fatals | 0 / 0 / 0 |
| Functional coverage (implemented covergroup) | 83.33% |
| Simulated time | 102 us |

The environment uses directed and constrained-random sequences, a sequencer, driver, monitor, agent, scoreboard and coverage subscriber. Coverage includes operation, address, response, write strobes and operation/response cross. Partial and zero write strobes remain unexercised by the current sequence. The reported percentage is not exhaustive AXI4-Lite or SoC coverage. Results are from the supplied local simulation transcript, not an independent rerun.

Run from the repository root in ModelSim (adjust the UVM include path for your installation):

```tcl
vlib uvm_work
vlog -sv -work uvm_work uvm/axi4lite_if.sv
vlog -sv -work uvm_work -L mtiUvm -L uvm_work +incdir+C:/modeltech64_10.6d/verilog_src/uvm-1.1d/src +incdir+uvm uvm/axi4lite_pkg.sv
vlog -sv -work uvm_work rtl/*.sv
vlog -sv -work uvm_work -L mtiUvm -L uvm_work uvm/tb_uvm_top.sv
vsim -coverage -L mtiUvm -L uvm_work uvm_work.tb_uvm_top
run -all
```


### Latest local UVM and SVA results (November 27, 2026)

The latest local ModelSim transcript reports 40 transactions (14 writes, 26 reads), 40 passed scoreboard checks, zero failed checks, zero UVM warnings/errors/fatals, and 100% functional coverage of the locally implemented covergroup at 139 us. Seven SVA assertions were loaded with zero reported failures; five stability assertions had zero recorded passes and two response assertions had one recorded pass each. Backpressure verification remains incomplete. These results were not independently rerun. The local source revisions are not yet synchronized with this repository; the earlier results above describe the published environment.

## Simulation with ModelSim

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

SystemVerilog · UVM 1.1d · ModelSim · Quartus Prime Lite 25.1 · VS Code · GitHub

## FPGA synthesis and timing (Quartus Prime Lite)

The integrated SoC top `riscv_uart_soc` was compiled for an **Intel Cyclone V 5CGXFC7C6F23C6** target. The reported local compilation completed with **0 errors** (warnings remain). The timing constraints use a **20.000 ns clock period (50 MHz)**. Internal setup and hold analyses reported positive slack, including a reported worst internal setup slack of **+6.325 ns**. The UART receive synchronizer's `rx_meta` → `rx_sync` setup path was analyzed with **+14.927 ns** slack.

**Important scope limitation:** the design has **59 unconstrained output ports** in the timing report, including debug signals and UART TX. No physical board or pin assignments were used; therefore these results **do not establish full external I/O timing closure or hardware operation**. The `uart_rx` input is synchronized and its asynchronous path to the first synchronizer register is excluded from synchronous timing analysis.

## Limitations and next steps

- Extend AXI4-Lite error handling, corner-case and backpressure regression.
- Automate repeatable test runs and preserve simulator logs and Quartus reports as reproducible evidence.
- Complete board-specific I/O constraints and pin assignments **if** a target FPGA board becomes available; perform hardware validation only then.
- Expand functional coverage and document results with reproducible evidence.
- The historical UVM-inspired testbench is distinct from the standard UVM environment in `uvm/`; the latter has scenario-specific coverage, not exhaustive protocol verification.

## Notes

This repository is intended as a hardware/FPGA portfolio project. It contains multiple educational and historical core/testbench variants; not all are intended to be instantiated or simulated simultaneously.
