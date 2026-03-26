// ============================================================
// Module : alu_ctrl.v
// Purpose: ALU Control — translates aluop + funct3 + funct7
//          into a 4-bit ALU operation code
// Project: Low-Latency Pipelined RISC-V 32-bit Processor
//
// alu_ctrl encoding:
//   4'b0000  ADD
//   4'b0001  SUB
//   4'b0010  AND
//   4'b0011  OR
//   4'b0100  XOR
//   4'b0101  SLL  (shift left logical)
//   4'b0110  SRL  (shift right logical)
//   4'b0111  SRA  (shift right arithmetic)
//   4'b1000  SLT  (signed less-than)
//   4'b1001  SLTU (unsigned less-than)
//   4'b1010  PASS-B (for LUI: rd = imm)
// ============================================================
module alu_ctrl (
    input  wire [1:0] aluop,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg  [3:0] alu_ctrl
);
    always @(*) begin
        case (aluop)
            // load / store / AUIPC / JAL: always ADD
            2'b00: alu_ctrl = 4'b0000; // ADD

            // branch: comparison done externally; ALU unused → ADD
            2'b01: alu_ctrl = 4'b0000;

            // LUI: pass immediate through B input
            2'b11: alu_ctrl = 4'b1010; // PASS-B

            // R-type or I-type ALU: decode from funct3 (and funct7 bit 5)
            2'b10: begin
                case (funct3)
                    3'b000: // ADD / SUB  or  ADDI
                        alu_ctrl = (funct7[5]) ? 4'b0001 : 4'b0000;
                    3'b001: alu_ctrl = 4'b0101; // SLL / SLLI
                    3'b010: alu_ctrl = 4'b1000; // SLT / SLTI
                    3'b011: alu_ctrl = 4'b1001; // SLTU / SLTIU
                    3'b100: alu_ctrl = 4'b0100; // XOR / XORI
                    3'b101: // SRL / SRA  or  SRLI / SRAI
                        alu_ctrl = (funct7[5]) ? 4'b0111 : 4'b0110;
                    3'b110: alu_ctrl = 4'b0011; // OR  / ORI
                    3'b111: alu_ctrl = 4'b0010; // AND / ANDI
                    default: alu_ctrl = 4'b0000;
                endcase
            end
            default: alu_ctrl = 4'b0000;
        endcase
    end
endmodule
