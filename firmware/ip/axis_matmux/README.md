# AXI-Stream Matrix Multiplexer (axis_matmux)

A configurable matrix multiplexer core that performs weighted summation of input streams with bit-shift operations.

## Features

- Configurable number of inputs (power of 2, up to 16)
- Configurable number of outputs (1-16)
- Configurable number of DDS blocks
- Configurable pipeline stages for timing optimization
- AXI4-Lite slave interface for configuration
- AXI-Stream interfaces for data

## Parameters

| Parameter    | Description                                      | Range    | Default |
|-------------|--------------------------------------------------|----------|---------|
| IN_WIDTH    | Number of input bits (actual inputs = 2^IN_WIDTH) | 1-4      | 2       |
| N_OUT       | Number of outputs                                | 1-16     | 1       |
| N_DDS       | Number of DDS blocks                            | Any      | 8       |
| STAGE_DELAY | Pipeline stages between each adder level        | Any      | 1       |

## Register Map

The core provides an AXI4-Lite slave interface for configuration. The register map is as follows:

### Configuration Register (0x100, Read-only)
```
[31:16] Reserved
[15:8]  N_OUT - Number of outputs
[7:4]   Reserved
[3:0]   IN_WIDTH - Number of input bits
```

### Matrix Configuration Registers (0x00-0xFC)
Each output has a a vector of 4 32-bit registers that configures the shift amounts for 4 inputs each (total 16 inputs):
```
[31:29] Reserved
[28:24] Shift amount for input 4*i + 3
[23:21] Reserved
[20:16] Shift amount for input 4*i + 2
[15:13] Reserved
[12:8]  Shift amount for input 4*i + 1
[7:5]   Reserved
[4:0]   Shift amount for input 4*i + 0
```

For outputs with more than 4 inputs, additional registers are used:
- Output 0: 0x00 (inputs 0-3), 0x04 (inputs 4-7), 0x08 (inputs 8-11), 0x0C (inputs 12-15)
- Output 1: 0x10 (inputs 0-3), 0x14 (inputs 4-7), 0x18 (inputs 8-11), 0x1C (inputs 12-15)
...
- Output 16: 0xF0 (inputs 0-3), 0xF4 (inputs 4-7), 0xF8 (inputs 8-11), 0xFC (inputs 12-15)

NOTE: the core assumes that addresses are aligned to 4 bytes (32-bit words).

## Operation

The core performs the following operation for each output i:
```
Out_i = Σ(In_j >> shift_matrix[i][j])
```
where:
- Out_i is output stream i
- In_j is input stream j
- shift_matrix[i][j] is the configured shift amount for input j contributing to output i

## Implementation Details

The core is split into three modules:

1. `axis_matmux.sv` - Top level module that instantiates the AXI slave and core logic
2. `axis_matmux_axi.sv` - AXI4-Lite slave interface for configuration
3. `axis_matmux_core.sv` - Real-time data path implementing the matrix multiplication

The core uses an efficient adder tree implementation with configurable pipeline stages to meet timing requirements. Each output has its own independent adder tree, allowing for parallel processing of multiple output streams.

## Example Usage

1. Configure the core parameters:
```verilog
axis_matmux #(
    .IN_WIDTH(3),      // 8 inputs
    .N_OUT(4),         // 4 outputs
    .N_DDS(8),         // 8 DDS blocks
    .STAGE_DELAY(2)    // 2 pipeline stages per adder level
) matmux_inst ( ... );
```

2. Read the configuration register to verify setup:
```
Read 0x00 -> Returns 0x0004_0003 for 4 outputs, IN_WIDTH=3
```

3. Configure shift matrix for output 0:
```
Write 0x04 -> Configure shifts for inputs 0-3
Write 0x08 -> Configure shifts for inputs 4-7
```

4. Start streaming data through AXI-Stream interfaces 

## Performace
For N_IN = 2, N_OUT = 1, IN_WIDTH = 16, and STAGE_DELAY = 1:
Ran synthasis with clock period of 3.000 ns, got worst slack of 1.896 ns => maximum clock period is 1.104 ns = 906.79MHz

For N_IN = 16, N_OUT = 16, IN_WIDTH = 16, and STAGE_DELAY = 1:
Ran synthasis with clock period of 3.000 ns, got worst slack of 1.923 ns => maximum clock period is 1.077 ns = 928.51MHz
