RISC-V OTTER Pipelined Processor with L1 Instruction Cache

This project implements a high-performance processor based on the open-source RISC-V ISA. The design is built around the OTTER MCU and demonstrates a complete 5-stage pipelined processor, along with a direct-mapped L1 instruction cache to improve instruction fetch performance.

The processor uses a classic five-stage pipeline consisting of instruction fetch, decode, execute, memory access, and writeback. Instructions are fetched and the program counter is updated in the fetch stage, decoded and read from the register file in the decode stage, executed in the execute stage for arithmetic operations, address generation, and branch comparison, accessed from data memory in the memory stage, and written back to the register file in the writeback stage. Dual-port memory eliminates structural hazards, allowing continuous instruction flow.

The pipeline accounts for both data and control hazards. Forwarding logic resolves most RAW data hazards by bypassing results directly from pipeline registers to dependent instructions, reducing unnecessary stalls. Load-use hazards are detected and handled through pipeline stalling when required. Control hazards are managed by stalling and squashing instructions as needed, ensuring correct program execution.

An L1 direct-mapped instruction cache is integrated into the fetch stage to improve performance through temporal and spatial locality. The cache contains 16 blocks with 8 words per block and supports read-only instruction memory access. Cache hits allow instructions to proceed without delay, while cache misses stall the program counter for one clock cycle as the instruction block is fetched from instruction memory and loaded into the cache. The design does not require dirty bits or replacement policies due to the direct-mapped structure.

The processor is verified using provided test programs to validate correct pipeline behavior, hazard handling, and cache functionality.
