// ============================================================
// Module : imm_gen.v
// Purpose: Sign-extended immediate generator for all RV32I formats
//          R  : no immediate (outputs 0)
//          I  : instr[31:20]  sign-extended to 32 bits
//          S  : {instr[31:25], instr[11:7]}  sign-extended
//          B  : {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}
//          U  : {instr[31:12], 12'b0}
//          J  : {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}
// Project: Low-Latency Pipelined RISC-V 32-bit Processor
// ============================================================
module imm_gen (
    input  wire [31:0] instr,
    output reg  [31:0] imm
);
    wire [6:0] opcode = instr[6:0];

    localparam OP_I_ALU = 7'b001_0011;
    localparam OP_LOAD  = 7'b000_0011;
    localparam OP_JALR  = 7'b110_0111;
    localparam OP_STORE = 7'b010_0011;
    localparam OP_BRANCH= 7'b110_0011;
    localparam OP_LUI   = 7'b011_0111;
    localparam OP_AUIPC = 7'b001_0111;
    localparam OP_JAL   = 7'b110_1111;

    always @(*) begin
        case (opcode)
            // I-type (ADDI, ANDI, ORI, XORI, SLTI, SLTIU, SLLI, SRLI, SRAI)
            OP_I_ALU,
            OP_LOAD,
            OP_JALR:
                imm = {{20{instr[31]}}, instr[31:20]};

            // S-type
            OP_STORE:
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            // B-type
            OP_BRANCH:
                imm = {{19{instr[31]}}, instr[31], instr[7],
                        instr[30:25], instr[11:8], 1'b0};

            // U-type (LUI, AUIPC)
            OP_LUI,
            OP_AUIPC:
                imm = {instr[31:12], 12'b0};

            // J-type (JAL)
            OP_JAL:
                imm = {{11{instr[31]}}, instr[31], instr[19:12],
                        instr[20], instr[30:21], 1'b0};

            default:
                imm = 32'b0;
        endcase
    end
endmodule
