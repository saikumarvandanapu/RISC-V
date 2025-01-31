# Design and Implementation of RISC-V IP with Hard Macro Creation and Integration

## Objective
Design and Implemented RISC-V IP with Hard Macro Creation and Integration.

## Key Focus Areas
1. Designed and implemented two hard macros for RISC-V sub-modules, meeting area, power, and performance constraints.
2. Integrated the hard macros into the top-level design with optimized floor planning, placement, and routing.
3. Optimized design to meet timing closure and power constraints using static timing analysis.

## Inputs to Physical Design
- **Netlist (.v):** A logical representation of the design, typically in formats like Verilog or VHDL, that specifies the circuit's connectivity.
- **Liberty File (.lib):** Contains information about the timing, power, and functional characteristics of standard cells used in the design.
- **Design Constraints File (.sdc):** Specifies timing, area, and power constraints for the design.
- **Technology File (.tf):** Includes details about the manufacturing process, such as metal layer stack-up, design rules, and parasitic models.
- **Library Exchange Format (.lef):** Describes the physical design rules & abstract views of the standard cells, macros.
- **Design Exchange Format (.def):** Describes the design layout, including floorplan, cell placement, and routing information.
- **Power Intent File (.upf):** Specifies the power domains and power management strategies for low-power designs.
- **Table Lookup Plus File (.tluplus):** These files are crucial in the backend flow of VLSI physical design, specifically for parasitic extraction and delay calculation. They provide interconnect resistance and capacitance values.

## Creating Macros
- Here we have 30 Verilog files. Among those files, two blocks, ALU and Machine Counter, were converted into hard macros using the following tools:
  - **Design Compiler**
  - **ICC2**
  - **LM Shell (Library Manager)**

## Synthesis and Physical Design
- **Synthesis:** The process of converting the functional behavioral RTL into a gate-level netlist. Synthesis is done using **Synopsys Design Compiler**.
- **Physical Design:** The process of transforming a gate-level netlist into a physical layout on a chip (**GDS II**). The conversion from GLN to GDS II is performed using **Synopsys ICC2**.
- **Hard Macro Creation:** Hard macros are created by reading the **GDS II** files into the **Library Manager** and converting the **GDS** file into an **NDM** file.

## Design Specifications
- **Role:** Synthesis, P & R, and Timing Analysis
- **Technology Node:** 32nm
- **Layers:** 8 Metal layers
- **Hard Macros:** 2
- **Instance Count:** ~25k
- **Number of Clocks:** 1
  
## Tools Utilized
- **Synthesis:** Design Compiler (Synopsys)
- **P & R Tools:** IC Compiler II (Synopsys)
- **Extraction Tools:** Star-RC (Synopsys)
- **Static Timing Analysis:** Primetime (Synopsys)
- **Physical Verification:** Calibre (Siemens)

  ## Responsibilities
- Creating a design library and importing NDM, Technology files, Parasitic Models, and RTL.
- Writing MCMM Timing Constraints and reading them into the tool.
- Synthesizing and optimizing the design and writing Netlist, SDC, and DEF files.
- Creating the floorplan, shaping the blocks, and placing Pins, I/Os, and Macros.
- Creating a Power Plan – Power Rings, Straps, Rails, and PBNS.
- Performing CCD Optimization and inserting ICGs.
- Performing Clock Tree Synthesis.
- Performing Global & Detailed Routing and checking DRCs.
- Performing Signoff checks.
- Extracting RC using Star-RC.
- Exporting Netlist, GDS II, SDC, SPEF, and DEF files.
- Timing analysis of the design using the PrimeTime tool:
  - Obtaining timing reports.
  - Fixing timing violations by sizing the cells, inserting/deleting buffers, cell swapping, and improving the nets.

