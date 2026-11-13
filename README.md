### AMBA APB-Interfaced SPI Master IP Core

A synthesizable Serial Peripheral Interface (SPI) Master IP Core compliant with the AMBA APB (Advanced Peripheral Bus) protocol, designed in Verilog HDL. The IP acts as a bridge between a low-power APB host/processor bus and external full-duplex SPI slave peripherals.

 ### Key Features
* AMBA APB Slave Interface: Supports standard SETUP, ACCESS, and IDLE transfer states with PSEL, PENABLE, PWRITE, PADDR, PWDATA, PRDATA,PSLVERR and PREADY handshaking.
* serial clock with programmable polarity and phase(CPOL,CPHA).
* Programmable Baud Rate Generator: Configurable clock divider to derive SCLK from the system PCLK.
* Full-Duplex Serial Data Transfer: Simultaneous transmission (MOSI) and reception (MISO) using an internal shift register architecture.
* Active-Low Slave Select (SS_n): Automated assertion and de-assertion around data frames.
* Bit-Order & Status Reporting: Configurable MSB-first / LSB-first transfer support along with status flags .

 ### SPI Transfer Format
* During SPI transfer ,data is simultaneoulsy transmitted (shifted out serially) and received (shifted in serially).
* A serial clock line synchronizes shifting and sampling of info on the two serial data lines.
* A slave select line allows the SPI core to select an SPI slave device.

###  Modes of Operation
*Run mode: Basic mode of operation.
*Wait mode:SPI stopping wait signal(SPISWAI)bit=0,the SPI operates like in Run mode,if SPISWAI bit=1,SPI goes into a power conservative state with SPI clock generation turned off.
*Stop mode: SPI  is inactive in stop mode for reduced power consumption ,any transmission in progress stops,but is resumed after the cpu goes into run mode.

### Core Registers
Register address map
  ADDRESS          Regsiter                Access
  0               SPI control Register1    RW
  1               SPI control Register2    RW
  2               SPI baud rate Register   RW
  3               SPI status Register      R
  5               SPI data register        RW

### Architecture Overview
The design is partitioned into modular, synthesizable RTL blocks:
### 1.APB slave interface

<img width="2752" height="1536" alt="apb_slave_interface" src="https://github.com/user-attachments/assets/dd6be076-4fbf-41ee-81e7-fc87bad4ab54" />

APB Slave Interface (apb_slave_interface) Operation
The apb_slave_interface module acts as the AMBA APB-compliant configuration, status, and data gateway between the host processor and the SPI Master core:
* APB Transfer FSM (IDLE → SETUP → ENABLE): Decodes APB bus handshaking signals (PSEL_i, PENABLE_i, and PWRITE_i) to generate internal read/write enable strobes (rd_enb, wr_enb) and drives PREADY_o high during the ENABLE phase alongside slave error reporting (PSLVERR_o).
* Memory-Mapped Control & Data Registers: Implements internal 8-bit registers decoded via PADDR_i:
  * SPI_CR1 (3'b000): Configures SPI enable (spe), master/slave mode (mstr_o), clock polarity (cpol_o), clock phase (cpha_o), bit ordering (lsbfe_o), slave-select output enable (ssoe), and interrupt enables (spie, sptie).
  * SPI_CR2 (3'b001): Controls wait-mode behavior (spiswai_o) and mode-fault detection (modfen) with bit masking (cr2_mask).
  * SPI_BR (3'b010): Holds the baud rate prescaler (sppr_o) and rate divisor (spr_o) fields with bit masking (br_mask).
  * SPI_SR (3'b011, Read-Only): Reports real-time status flags including SPI Interrupt Flag (spif), Transmit Buffer Empty (sptef), and Mode Fault (modf).
  * SPI_DR (3'b101): Buffers outgoing transmit bytes (mosi_data_o) with a send_data_o pulse and captures incoming miso_data_i upon receive_data_i assertion.
* Operating Mode Controller (spi_mode_o): Manages transitions across Run Mode (2'b00), Wait Mode (2'b01), and Stop Mode (2'b10) based on the spe and spiswai_o control bits.
* Interrupt Generation (spi_interrupt_request_o): Combines spif, modf, and sptef flags gated by spie and sptie to assert interrupt requests to the host controller.

### 2.Slave select control 

<img width="2752" height="1536" alt="slave_select_control" src="https://github.com/user-attachments/assets/fa3c6258-65d8-4e82-8baa-6de31044fd68" />

SPI Slave Select Control (spi_slave_control) Operation
The spi_slave_control module manages the active-low slave select line (ss_o), transfer-in-progress status (tip_o), and frame-completion signaling (receive_data_o) during serial data transactions:
* Transfer Window Calculation: Computes the exact frame duration in PCLK cycles using target = (baudratedivisor_i / 2) * 16, spanning 8 full SCLK periods for an 8-bit serial transfer.
* Active-Low Slave Select (ss_o) & Status (tip_o): Keeps ss_o high (idle) and tip_o low (tip_o = ~ss_o) by default. When send_data_i is asserted in Master Mode (mstr_i = 1) during Run Mode (2'b00) or Wait Mode (2'b01) with spiswai_i de-asserted, ss_o is pulled low and the internal cycle counter (count) starts from 0.
* Frame Completion & Receive Strobe (receive_data_o): Holds ss_o low until count reaches target - 1. At the final cycle of the frame, an internal flag (rcv) is asserted, driving receive_data_o high on the next clock edge to latch the received byte before returning ss_o to its inactive high state.
* Stop Mode & Reset Behavior: Immediately de-asserts ss_o to 1, resets count to 16'hffff, and clears receive_data_o when PRESET_n is asserted or when the core enters Stop Mode (2'b10).

### 3.Serial clock generator

<img width="2752" height="1536" alt="serial_clk_generator" src="https://github.com/user-attachments/assets/fc9b26fb-61ec-4cab-bece-2a1a7b60cfa5" />

Serial Clock Generator (serial_clock_gen) Operation.
The serial_clock_gen module derives the SPI serial clock (sclk_o) and data sampling/launching timing strobes from the system PCL`:
* Baud Rate Divisor Calculation: Computes the clock division factor dynamically using the formula baudratedivisor_o = (sppr_i + 1) * 2^(spr_i + 1), allowing programmable SCLK frequencies via prescaler (sppr_i) and rate selection (spr_i) bits.
* Clock Polarity & Mode Gating: Sets the idle clock level (pre_sclk_s) according to cpol_i (1 when CPOL = 1, 0 when CPOL = 0). sclk_o toggles only when Slave Select (ss_i) is active low, spiswai_i is de-asserted, and the core is in Run Mode (2'b00) or Wait Mode (2'b01). In Stop Mode or idle states, sclk_o is held at its idle polarity and the internal counter (count_s) resets to zero.
* MISO Sample & MOSI Launch Strobes: Generates single-cycle timing pulses aligned to the selected (CPOL, CPHA) phase configuration:
* MISO Receive (miso_receive_sclk_o / miso_receive_sclk0_o): Asserted at the half-period boundary (count_s == baudratedivisor_o/2 - 1) to sample incoming MISO data on the valid SCLK edge.
* MOSI Send (mosi_send_sclk_o / mosi_send_sclk0_o): Asserted one PCLK cycle earlier (count_s == baudratedivisor_o/2 - 2) to launch MOSI data onto the bus ahead of the sampling edge, ensuring setup-time compliance.

### 4.Shift register

<img width="2752" height="1536" alt="shift_register" src="https://github.com/user-attachments/assets/4708cac3-271b-456d-a882-6fec82432903" />
SPI Shift Register (shift_register) Operation
The shift_register module handles parallel-to-serial transmission on mosi_o and serial-to-parallel reception from miso_i during active SPI transfers:
* Parallel Transmit Data Loading: Captures the 8-bit outgoing byte data_mosi_i into the internal transmit buffer (shift_reg) when send_data_i is asserted.
* Configurable Bit Ordering (lsbfe_i): Supports both LSB-first (lsbfe_i = 1, indexing 0 to 7 via count and count2) and MSB-first (lsbfe_i = 0, indexing 7 down to 0 via count1 and count3) bit serialization and deserialization.
* Phase-Aligned Serial Shifting (cpol_i, cpha_i): Operates whenever slave select (ss_i) is active low, selecting the appropriate launch and sample timing strobes based on the SPI clock mode:
  * Opposite Polarity and Phase ((!cpha_i && cpol_i) || (cpha_i && !cpol_i)): Drives bits out onto mosi_o on mosi_send_sclk0_i and samples incoming miso_i bits into temp_reg on miso_receive_sclk0_i.
  * Matching Polarity and Phase ((!cpha_i && !cpol_i) || (cpha_i && cpol_i)): Drives bits out onto mosi_o on mosi_send_sclk_i and samples incoming miso_i bits into temp_reg on miso_receive_sclk_i.
* Parallel Receive Data Readout: Outputs the assembled 8-bit received byte from temp_reg onto data_miso_o when receive_data_i is asserted at the end of the frame, driving 8'h00 otherwise.

### SPI top module

<img width="2752" height="1536" alt="top_module" src="https://github.com/user-attachments/assets/39d98818-1601-4a7f-8836-3e554cf22359" />
Top-Level Wrapper (spi_top) Operation
The spi_top module integrates all four functional sub-blocks into a unified AMBA APB-compliant SPI Master IP core, routing internal control signals, clock strobes, and data buses between the host interface and external SPI pins:
* External Interface Connectivity: Exposes the APB slave bus ports (PCLK, PRESET_n, PWRITE_i, PSEL_i, PENABLE_i, PADDR_i, PWDATA_i, PRDATA_o, PREADY_o, PSLVERR_o) alongside the standard 4-wire SPI signals (sclk_o, mosi_o, miso_i, ss_o) and interrupt output (spi_interrupt_request_o).
* Sub-Module Integration & Interconnects:
  * apb_slave_interface (apb): Receives APB bus transactions from the host and distributes configuration parameters (cpol, cpha, lsbfe, mstr, spiswai, spr, sppr), operating mode status (spi_mode), and transmit data (mosi_data, send_data) to the core sub-blocks.
  * serial_clock_gen (s1): Uses the prescaler (sppr), rate divisor (spr), and operating mode (spi_mode) to drive sclk_o and supply phase-aligned launch/sample strobes (mosi_send_sclk, mosi_send_sclk0, miso_receive_sclk, miso_receive_sclk0) plus baudratedivisor to the shift register and slave control logic.
  * spi_slave_control (ssc): Tracks the frame duration using baudratedivisor and send_data, generating the internal slave-select signal (ssoe, routed to ss_o), transfer-in-progress indicator (tip), and end-of-frame receive pulse (receive_data).
  * shift_register (s2): Serializes mosi_data onto mosi_o and deserializes miso_i into miso_data using the clock strobes from s1, returning the received byte to apb when receive_data is asserted.

### Simulation Results
<img width="1862" height="785" alt="image" src="https://github.com/user-attachments/assets/1fe06c99-cb7e-4ec4-a1c8-2b7461228350" />
<img width="1868" height="798" alt="image" src="https://github.com/user-attachments/assets/c0c09719-e433-4d25-bf1c-f12ce84b9964" />
<img width="1852" height="802" alt="image" src="https://github.com/user-attachments/assets/9229c2eb-11d8-40b2-afaa-1e7be85a6cf3" />
<img width="1860" height="362" alt="image" src="https://github.com/user-attachments/assets/f481fbad-d6be-4fe6-9c06-f2ab94727b19" />

### RTL Linting (Synopsys VC Static)

<img width="1600" height="828" alt="WhatsApp Image 2026-11-13 at 23 12 11" src="https://github.com/user-attachments/assets/039d050d-36d1-41b2-bab3-ae05221ff53e" />

The RTL design (spi_top) was analyzed using Synopsys VC Static (X-2025.06) to verify coding standards, structural integrity, and synthesizability

* Management Summary: 0 Fatals, 0 Errors, and 0 RTL coding or structural warnings across LANGUAGE_CHECK and STRUCTURAL_CHECK stages (11 informational messages: ReportPortInfo-ML and RegInputOutput-ML).
* Code Quality Verification: Confirmed zero inferred latches, clean sensitivity lists, and proper bit-width alignment across all sub-modules.
* Environment Note: The single DB_CANT_LOAD warning in DESIGN_READ is due to an unlinked `.db` technology library in the server setup and does not indicate any RTL defect.

### Logic Synthesis & Timing Analysis (Synopsys Design Compiler)

<img width="1600" height="826" alt="WhatsApp Image 2026-11-13 at 23 14 43" src="https://github.com/user-attachments/assets/2fe1e97c-2ce3-4ac4-925e-7974fe2082d3" />

The lint-clean RTL design was synthesized into a gate-level netlist using Synopsys Design Compiler and verified for setup timing closure:
* Target Clock (PCLK): 20.00 ns period (50 MHz)
* Critical Path:apb/SPI_BR_reg[2] through serial_clock_gen (s1) to spi_slave_control (ssc/rcv_reg/D)
* Data Required Time: 19.15 ns (including -0.85 ns library setup time)
* Data Arrival Time: 19.14 ns.
* Worst Setup Slack: +0.01 ns (MET) — Zero setup timing violations


