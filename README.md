# AMBA AHB-Lite to APB Bridge RTL Design

## Overview
This project implements an AMBA AHB-Lite to APB Bridge in Verilog RTL.

The bridge converts high-speed AHB-Lite bus transactions into APB peripheral bus transactions.

This project was built to understand AMBA bus protocols, FSM-based protocol conversion, RTL design, and verification.

---

## Features
- AHB-Lite Slave Interface
- FSM-based Bridge Controller
- APB Controller
- APB Memory Slave Peripheral
- Top-Level Integration
- Verilog Testbench Verification
- Waveform Debugging

---

## Protocols Used
### AHB-Lite
AHB-Lite is a high-performance pipelined bus protocol used for communication between processors and high-speed peripherals.

Key signals:
- HADDR
- HWDATA
- HRDATA
- HWRITE
- HTRANS
- HREADYOUT

---

### APB
APB is a simpler peripheral bus protocol used for low-speed peripherals.

Two-phase protocol:
1. Setup Phase
2. Access Phase

Key signals:
- PADDR
- PWDATA
- PRDATA
- PWRITE
- PSEL
- PENABLE
- PREADY

---

## Architecture
Bridge architecture includes:

- AHB Slave Interface
- Bridge FSM
- APB Controller
- APB Memory Slave
- Top Module

Transaction flow:

AHB Master
↓
AHB Slave Interface
↓
Bridge FSM
↓
APB Controller
↓
APB Slave Peripheral

---

## FSM States
Bridge FSM states:

- IDLE
- WDATA_WAIT
- SETUP
- ACCESS
- DONE

State flow:

### Write Transfer
IDLE → WDATA_WAIT → SETUP → ACCESS → DONE → IDLE

### Read Transfer
IDLE → SETUP → ACCESS → DONE → IDLE

---

## Project Structure
```text
AHB_APB_Bridge_RTL
│
├── RTL
│   ├── ahb_slave_if.v
│   ├── bridge_fsm.v
│   ├── apb_controller.v
│   ├── apb_slave_mem.v
│   └── ahb_apb_bridge_top.v
│
├── tb
│   └── tb_ahb_apb_bridge.v
│
├── waveforms
│   └── ahb_apb_bridge_waveform.png
│
└── README.md
```

---

## Simulation
Simulation verified:
- Write transactions
- Read transactions
- FSM transitions
- AHB/APB handshake timing

Example simulation output:

```text
WRITE DONE: ADDR=00000000 DATA=aabbccdd
WRITE DONE: ADDR=00000004 DATA=11223344
WRITE DONE: ADDR=00000008 DATA=deadbeef

READ DONE: ADDR=00000000 DATA=aabbccdd
READ DONE: ADDR=00000004 DATA=11223344
READ DONE: ADDR=00000008 DATA=deadbeef
```

---

## Waveform Verification
Waveform analysis verified:
- AHB address phase
- AHB write data phase
- APB setup phase
- APB access phase
- Read data capture
- HREADYOUT stalling

See waveform screenshot:

`waveforms/ahb_apb_bridge_waveform.png`

---

## Tools Used
- Verilog
- Icarus Verilog
- EPWave
- GitHub

---

## Learning Outcomes
Through this project I learned:
- AMBA AHB-Lite protocol
- APB protocol timing
- FSM-based protocol conversion
- RTL design methodology
- Bus handshake debugging
- Waveform-based verification