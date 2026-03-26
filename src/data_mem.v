// ============================================================
// Module : data_mem.v
// Purpose: Data Memory — 256 words (1 KB), byte-addressable
//          Supports LW/LH/LB/LHU/LBU and SW/SH/SB
//          Write synchronous (rising edge), read combinational
// Project: Low-Latency Pipelined RISC-V 32-bit Processor
// ============================================================
module data_mem (
    input  wire        clk,
    input  wire        memread,
    input  wire        memwrite,
    input  wire [2:0]  funct3,    // determines transfer width
    input  wire [31:0] addr,      // byte address
    input  wire [31:0] wdata,     // data to write
    output reg  [31:0] rdata      // data read
);
    // Byte-addressable storage: 1024 bytes
    reg [7:0] mem [0:1023];

    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = 8'b0;
    end

    // ---- Synchronous Write ----
    always @(posedge clk) begin
        if (memwrite) begin
            case (funct3)
                3'b000: // SB (store byte)
                    mem[addr] <= wdata[7:0];
                3'b001: // SH (store half-word)
                    {mem[addr+1], mem[addr]} <= wdata[15:0];
                3'b010: // SW (store word)
                    {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]}
                        <= wdata[31:0];
                default: ;
            endcase
        end
    end

    // ---- Combinational Read ----
    always @(*) begin
        if (memread) begin
            case (funct3)
                3'b000: // LB (load byte, sign-extended)
                    rdata = {{24{mem[addr][7]}}, mem[addr]};
                3'b001: // LH (load half-word, sign-extended)
                    rdata = {{16{mem[addr+1][7]}}, mem[addr+1], mem[addr]};
                3'b010: // LW (load word)
                    rdata = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
                3'b100: // LBU (load byte, zero-extended)
                    rdata = {24'b0, mem[addr]};
                3'b101: // LHU (load half-word, zero-extended)
                    rdata = {16'b0, mem[addr+1], mem[addr]};
                default: rdata = 32'b0;
            endcase
        end else
            rdata = 32'b0;
    end
endmodule
