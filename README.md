# Digital System Hardware Engineering: UART to 7-Segment Display Driver

## 📋 Overview

This project implements a complete **UART (Universal Asynchronous Receiver-Transmitter) communication system with integrated 7-segment display driver** using Verilog HDL. The system demonstrates advanced digital hardware design principles through an ensemble architecture that combines transmitter, receiver, encryption, and display control modules. Data transmitted via UART is encrypted during transmission and decrypted upon reception, then displayed on a 4-digit 7-segment display.

---

## 🛠️ Tech Stack

- **Hardware Description Language**: Verilog HDL
- **Simulation**: Simulation-based testing with testbenches
- **Clock Frequency**: 50 MHz base clock
- **Supported Baud Rates**: 300, 1200, 4800, 9600, 19200, 38400, 57600, 115200 bps
- **Communication Protocol**: UART with parity and framing error detection
- **Display Interface**: 7-segment LED multiplexing (4-digit display)
- **Data Encoding**: Custom encryption/decryption scheme (+3 offset cipher)

---

## ✨ Features

### Core Functionality
- **UART Transmitter Module**: Handles data transmission with configurable baud rates and parity bit generation
- **UART Receiver Module**: Implements robust reception with:
  - Baud rate synchronization (16x oversampling)
  - Noise filtering and signal validation
  - Parity error detection
  - Framing error detection
  - Start bit synchronization

- **Encryption/Decryption**: Custom cipher that applies a +3 offset to 4-bit data chunks
- **7-Segment Display Driver**: 4-digit multiplexed display with:
  - BCD to 7-segment conversion
  - Clock divider for display multiplexing
  - Dynamic digit selection
  - Error condition display ("FFFF")

- **Communication Channel**: Simulated transmission medium connecting TX and RX lines
- **Error Handling**: Comprehensive error detection and display capabilities

### Advanced Features
- **Parity Checking**: Odd parity implementation for data integrity
- **16x Oversampling**: Robust noise immunity in data reception
- **Packet Structure**: 11-bit packet format (Start, 8-data, Parity, Stop)
- **Data Validation**: Only displays valid data when both framing and parity checks pass
- **Dynamic Baud Rate Selection**: 3-bit selector for 8 standard baud rates

---

## 🔨 How It Was Built

### Architecture Design Process

#### 1. **Requirements Analysis**
- Designed a UART system supporting multiple baud rates
- Planned encryption for transmitted data
- Integrated 7-segment display output for visual feedback

#### 2. **Modular Decomposition**
The project was built as an **ensemble architecture** with specialized modules:

```
UART_Segment7 (Top Module)
├── Transmitter Chain
│   ├── Tx_baud_rate_generator (configurable timing)
│   ├── Tx_data_reception (input buffer)
│   ├── encoder (encryption with +3 offset)
│   ├── parity_generator (odd parity calculation)
│   ├── Tx_packet_creator (frame assembly)
│   └── Tx_transmission (bit-by-bit serial output)
├── Receiver Chain
│   ├── Rx_baud_rate_generator (16x oversampling)
│   ├── Rx_data_reception (noise filtering & synchronization)
│   ├── Rx_data_extraction (packet disassembly)
│   ├── parity_generator (verification parity calc)
│   ├── Rx_parity_comparison (error detection)
│   ├── Rx_framing_control (sync validation)
│   └── Rx_validation_control (output gating)
├── Display Chain
│   ├── digit_producer (data formatting for display)
│   ├── TOP (display controller)
│   ├── bcd_control (digit multiplexing)
│   ├── clock_divider (refresh timing)
│   └── segment7 (BCD-to-7segment decoder)
└── channel (simulated communication medium)
```

#### 3. **Baud Rate Calculation**
For each baud rate, the counter maximum is calculated:
```
max_counter = (50MHz / (16 × baud_rate)) - 1
```
Example: 9600 baud → max_counter = 325

#### 4. **Implementation Strategy**
- **Transmitter**: Simple state machine with bit-by-bit transmission
- **Receiver**: Complex synchronization logic with:
  - Start bit detection via duration counters
  - Sample validation using majority voting (noise filtering)
  - Packet assembly over 176 clock cycles per packet
- **Display**: Multiplexed output refreshing at high frequency for flicker-free display

#### 5. **Testing & Validation**
- Testbench simulates data flow through complete system
- Tests include:
  - Data encryption/decryption verification
  - Parity error detection
  - Framing error conditions
  - Multiple baud rate configurations
  - Display output validation

---

## 📚 What I Learned Creating This Ensemble Architecture

### 1. **Modular Hardware Design Excellence**
- Breaking complex systems into specialized, reusable modules improves maintainability
- Each module has a single responsibility, making debugging significantly easier
- Interfaces between modules should be clean and well-defined (inputs/outputs)

### 2. **Synchronization Challenges in Digital Systems**
- Clock domain crossing requires careful timing analysis
- The 16x oversampling technique demonstrates practical noise immunity
- Majority voting (checking if zeroes > ones) is more robust than single-sample decision making
- Start bit synchronization is critical for packet alignment

### 3. **State Machine Thinking**
- Transmitter and receiver operate as implicit state machines
- Duration counters and iteration counters manage complex sequential behavior
- Understanding timing requirements is crucial (e.g., 176 cycles for one 11-bit packet at 16x oversampling)

### 4. **Timing and Constraints**
- Baud rate accuracy directly impacts system reliability
- Clock division must be precise (50MHz ÷ (16 × baud_rate))
- Display refresh rate must exceed human perception (flicker-free > 60Hz)

### 5. **Error Detection Mechanisms**
- Parity bits provide simple yet effective error detection
- Framing errors indicate synchronization issues
- Validation logic gates output based on error flags
- Error display ("FFFF") provides user feedback

### 6. **Encrypted Communication Benefits**
- Simple +3 offset cipher demonstrates basic cryptography concepts
- Encryption/decryption happens at bit-level for efficiency
- Awareness of security vs. performance tradeoffs

### 7. **Display Multiplexing Techniques**
- Multiplexing allows 4 displays from single 7-segment decoder
- High refresh rates create illusion of static display
- Clock dividers manage timing without modifying main clock

### 8. **HDL-Specific Insights**
- `always @(posedge)` vs `always @(Data)` have very different behaviors
- Blocking vs non-blocking assignments matter for timing
- Wire vs reg usage affects synthesizability
- Testbenches are essential for digital design validation

---

## 🚀 How to Run the Project

### Prerequisites
- Verilog simulator (Iverilog, ModelSim, Vivado, or similar)
- Waveform viewer (GTKWave or built-in viewer)
- Optional: FPGA board (Xilinx, Altera) for hardware implementation

### Simulation Steps

#### 1. **Using Iverilog (Free/Open Source)**

```bash
# Compile the design and testbench
iverilog -o simulation Design.v Testbench.v

# Run simulation and generate waveform dump
vvp simulation

# View waveforms (requires GTKWave)
gtkwave dump.vcd
```

#### 2. **Using ModelSim**

```bash
# Create new project and add files
vlib work
vmap work work

# Compile
vlog Design.v Testbench.v

# Simulate
vsim -voptargs=+acc work.tb_uart_Communication

# Add waves and run
add wave -recursive *
run 10000000 ns
```

#### 3. **Using Vivado (Xilinx)**

```
1. Create new project
2. Add Design.v and Testbench.v as Design Sources
3. Run Simulation
4. Observe waveforms in Waveform Viewer
```

### Testbench Configuration

The testbench (`Testbench.v`) includes configurable parameters:

```verilog
reg [2:0] baud_select = 3'b011;  // 9600 baud (change for different rates)
reg [7:0] System_Data = 8'b10001010;  // Input data (modify for testing)
```

**Testbench Flow:**
1. Initialize clock at 50 MHz (10ns period)
2. Assert and release reset signal
3. Send data via Tx_WR pulse
4. Monitor Tx_BUSY signal for transmission completion
5. Send second test data (0xFF = 8'b11111111)
6. Observe received data on 7-segment display
7. Simulation runs for 10,000,000 ns (~200ms)

### Expected Results

- **Output Display**: Transmitted data appears on 4-digit 7-segment display
- **Encrypted Value**: Original 8-bit data is transformed by +3 offset cipher
- **Display Format**: 
  - Digit 1: High nibble of encrypted data
  - Digit 2: Low nibble of encrypted data
  - Digits 3-4: Second transmitted byte display
  - Error condition: All "F" characters indicate parity/framing error

### Debugging Tips

1. **Monitor these signals in waveform viewer:**
   - `System_Data`: Input to transmitter
   - `TxD`: Serial TX line
   - `RxD`: Serial RX line
   - `Rx_DATA`: Received data after validation
   - `Rx_VALID`: Data ready signal
   - `Rx_FERROR` / `Rx_PERROR`: Error flags
   - `Led_Disp[6:0]`: 7-segment output
   - `anode[3:0]`: Digit selection signals

2. **Common issues:**
   - **No output on display**: Check `Rx_VALID` signal and error flags
   - **Wrong baud rate**: Verify `baud_select` matches counter calculations
   - **Display shows "FFFF"**: Indicates parity or framing error detected
   - **Data mismatch**: Verify encryption/decryption is applying ±3 offset correctly

3. **Performance observation:**
   - One packet transmission takes ~1.14 ms at 9600 baud
   - Display refresh rate at ~4 kHz (flicker-free)
   - Total end-to-end latency: ~2-3 ms per character

---

## 💡 How It Could Be Improved

### 1. **Enhanced Error Handling**
- Implement Hamming codes for multi-bit error correction
- Add CRC (Cyclic Redundancy Check) for stronger error detection
- Implement automatic retransmission on error detection (ARQ protocol)

### 2. **Security Enhancements**
- Replace simple +3 cipher with AES encryption
- Implement key exchange mechanism
- Add authentication handshake before communication

### 3. **Protocol Improvements**
- Add START/STOP frame markers beyond single bit
- Implement multi-byte frame sequences
- Support variable-length packets
- Add flow control (XON/XOFF or hardware handshake)

### 4. **Performance Optimization**
- Implement buffering (FIFO) for continuous data streams
- Add DMA (Direct Memory Access) support
- Increase throughput with 16-bit or 32-bit words instead of 8-bit
- Pipeline receiver stages for higher baud rates

### 5. **Display Enhancement**
- Support custom character sets (hexadecimal, letters beyond 0-9)
- Implement scrolling text across display
- Add dot/decimal point control
- Support variable brightness with PWM

### 6. **Modularity Improvements**
- Parameterize module widths (generic bit widths)
- Create reusable UART IP blocks
- Implement configurable baud rate lookup tables
- Add reset synchronizers for clock domain crossing

### 7. **Testing & Verification**
- Develop comprehensive test suite with edge cases
- Implement formal verification for state machines
- Add coverage metrics for design validation
- Create protocol compliance test suite (RS-232)

### 8. **Documentation**
- Add detailed timing diagrams for each module
- Create state machine flowcharts
- Document signal timing constraints
- Provide hardware implementation guide

### 9. **Code Quality**
- Reduce code duplication (Tx and Rx generators are nearly identical)
- Add parameterized constants for magic numbers
- Implement reset synchronizers for better metastability handling
- Add formal protocol specifications

### 10. **Feature Additions**
- Support for configurable parity (none, odd, even)
- Programmable stop bits (1, 1.5, 2)
- Interrupt-driven operation
- Status registers for system monitoring

---

## 📁 Project Structure

```
Digital-System-Hardware-Engineering/
├── Design.v              # Main hardware design (897 lines)
├── Testbench.v           # Simulation testbench
├── README.md             # This file
└── Εργασία.pdf           # Original assignment specification (Greek)
```

### Module Count: 20 specialized modules
- **UART Transmitter**: 6 modules
- **UART Receiver**: 7 modules
- **Display Driver**: 5 modules
- **Utility**: 2 modules (channel, top-level wrapper)

---

## 📊 Design Metrics

| Metric | Value |
|--------|-------|
| Total Lines of Code | 897 |
| Number of Modules | 20 |
| Primary Clock Frequency | 50 MHz |
| Supported Baud Rates | 8 (300 to 115200 bps) |
| Data Width | 8 bits |
| Packet Size | 11 bits (1 start + 8 data + 1 parity + 1 stop) |
| Error Detection Methods | 2 (Parity, Framing) |
| Display Digits | 4 |
| Multiplexing Frequency | ~4 kHz |

---

## 🎓 Learning Outcomes

This project demonstrates proficiency in:
- ✅ Verilog HDL design and implementation
- ✅ Serial communication protocol design
- ✅ Hardware synchronization techniques
- ✅ Error detection and handling
- ✅ Modular architecture design
- ✅ State machine implementation
- ✅ Timing analysis and constraints
- ✅ Testbench development and validation
- ✅ FPGA design principles
- ✅ Signal integrity and noise immunity

---

## 📝 License & Attribution

This project is an academic submission for Aristotle University of Thessaloniki. It's published for educational purposes and portfolio demonstration.

**Note**: The current implementation contains intentional design decisions that demonstrate learning progression. Production-grade improvements are documented in the "How It Could Be Improved" section above.

---

## 👥 Authors

2 students from Aristotle University of Thessaloniki (AUTH)  
Digital System Low Level Hardware I (7th Semester)  
Created: April 2023

---

## 📞 Questions & Support

For questions about:
- **Verilog implementation details**: Review individual module comments in Design.v
- **Simulation setup**: Check the testbench configuration in Testbench.v
- **Design decisions**: Refer to the "How It Was Built" section above
- **Improvements needed**: See "How It Could Be Improved" section

---

**Last Updated**: May 2026  
**Status**: ✅ Complete and documented
