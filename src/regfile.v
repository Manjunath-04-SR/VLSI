// ============================================================
// Module : regfile.v
// Purpose: 32 x 32-bit Register File
//          x0 is hardwired to 0 (writes to x0 are ignored)
//          Write on rising clock edge; read combinationally
//          Supports simultaneous write-then-read (WB→ID same cycle)
// Project: Low-Latency Pipelined RISC-V 32-bit Processor
// ============================================================
module regfile (
    input  wire        clk,
    input  wire        regwrite,  // write enable (from WB stage)
    input  wire [4:0]  rs1,       // source register 1 address
    input  wire [4:0]  rs2,       // source register 2 address
    input  wire [4:0]  rd,        // destination register address
    input  wire [31:0] wdata,     // data to write
    output wire [31:0] rdata1,    // read data 1
    output wire [31:0] rdata2     // read data 2
);
    reg [31:0] regs [1:31]; // x0 is constant 0, not stored

    integer i;
    initial begin
        for (i = 1; i < 32; i = i + 1)
            regs[i] = 32'b0;
    end

    // Synchronous write (rising edge), x0 writes ignored
    always @(posedge clk) begin
        if (regwrite && rd != 5'b0)
            regs[rd] <= wdata;
    end

    // Asynchronous read with write-through for same-cycle hazard
    assign rdata1 = (rs1 == 5'b0)                    ? 32'b0 :
                    (regwrite && rd == rs1 && rd != 5'b0) ? wdata :
                    regs[rs1];

    assign rdata2 = (rs2 == 5'b0)                    ? 32'b0 :
                    (regwrite && rd == rs2 && rd != 5'b0) ? wdata :
                    regs[rs2];
endmodule
