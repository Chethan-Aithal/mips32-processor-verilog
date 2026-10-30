`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2026 12:22:31
// Design Name: 
// Module Name: pipe_mips32
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pipe_MIPS32(
    input clk1,
    input clk2,
    output [31:0] pc_out,
    output halted_out
);


reg [31:0] PC, IF_ID_IR, IF_ID_NPC;
reg [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;
reg [2:0] ID_EX_type, EX_MEM_type, MEM_WB_type;

reg [31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;
reg EX_MEM_cond;

reg [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;

reg [31:0] Reg [0:31];
reg [31:0] Mem [0:1023];

parameter ADD=6'b000000, SUB=6'b000001, AND=6'b000010, OR=6'b000011,
          SLT=6'b000100, MUL=6'b000101, HLT=6'b111111,
          LW=6'b001000, SW=6'b001001,
          ADDI=6'b001010, SUBI=6'b001011, SLTI=6'b001100,
          BNEQZ=6'b001101, BEQZ=6'b001110;

parameter RR_ALU=3'b000, RM_ALU=3'b001, LOAD=3'b010,
          STORE=3'b011, BRANCH=3'b100, HALT=3'b101;

reg HALTED, TAKEN_BRANCH;
assign pc_out = PC;
assign halted_out = HALTED;


// IF
always @(posedge clk1) begin
    if(!HALTED) begin
        if(((EX_MEM_IR[31:26]==BEQZ) && EX_MEM_cond) ||
           ((EX_MEM_IR[31:26]==BNEQZ) && !EX_MEM_cond)) begin
            IF_ID_IR<=#2 Mem[EX_MEM_ALUOut];
            IF_ID_NPC<=#2 EX_MEM_ALUOut+1;
            PC<=#2 EX_MEM_ALUOut+1;
            TAKEN_BRANCH<=#2 1'b1;
        end else begin
            IF_ID_IR<=#2 Mem[PC];
            IF_ID_NPC<=#2 PC+1;
            PC<=#2 PC+1;
        end
    end
end


// ID
always @(posedge clk2) begin
    if(!HALTED) begin
        ID_EX_A<=#2 (IF_ID_IR[25:21]==0 ? 0 : Reg[IF_ID_IR[25:21]]);
        ID_EX_B<=#2 (IF_ID_IR[20:16]==0 ? 0 : Reg[IF_ID_IR[20:16]]);

        ID_EX_IR<=#2 IF_ID_IR;
        ID_EX_NPC<=#2 IF_ID_NPC;
        ID_EX_Imm<=#2 {{16{IF_ID_IR[15]}},IF_ID_IR[15:0]};

        case(IF_ID_IR[31:26])
            ADD,SUB,AND,OR,SLT,MUL: ID_EX_type<=#2 RR_ALU;
            ADDI,SUBI,SLTI: ID_EX_type<=#2 RM_ALU;
            LW: ID_EX_type<=#2 LOAD;
            SW: ID_EX_type<=#2 STORE;
            BNEQZ,BEQZ: ID_EX_type<=#2 BRANCH;
            HLT: ID_EX_type<=#2 HALT;
            default: ID_EX_type<=#2 HALT;
        endcase
    end
end


// EX
always @(posedge clk1) begin
    if(!HALTED) begin
        EX_MEM_type<=#2 ID_EX_type;
        EX_MEM_IR<=#2 ID_EX_IR;
        TAKEN_BRANCH<=#2 0;

        case(ID_EX_type)
            RR_ALU: begin
                case(ID_EX_IR[31:26])
                    ADD: EX_MEM_ALUOut<=#2 ID_EX_A+ID_EX_B;
                    SUB: EX_MEM_ALUOut<=#2 ID_EX_A-ID_EX_B;
                    AND: EX_MEM_ALUOut<=#2 ID_EX_A&ID_EX_B;
                    OR:  EX_MEM_ALUOut<=#2 ID_EX_A|ID_EX_B;
                    SLT: EX_MEM_ALUOut<=#2 (ID_EX_A<ID_EX_B);
                    MUL: EX_MEM_ALUOut<=#2 ID_EX_A*ID_EX_B;
                endcase
            end

            RM_ALU: begin
                case(ID_EX_IR[31:26])
                    ADDI: EX_MEM_ALUOut<=#2 ID_EX_A+ID_EX_Imm;
                    SUBI: EX_MEM_ALUOut<=#2 ID_EX_A-ID_EX_Imm;
                    SLTI: EX_MEM_ALUOut<=#2 (ID_EX_A<ID_EX_Imm);
                endcase
            end

            LOAD,STORE: begin
                EX_MEM_ALUOut<=#2 ID_EX_A+ID_EX_Imm;
                EX_MEM_B<=#2 ID_EX_B;
            end

            BRANCH: begin
                EX_MEM_ALUOut<=#2 ID_EX_NPC+ID_EX_Imm;
                EX_MEM_cond<=#2 (ID_EX_A==0);
            end
        endcase
    end
end


// MEM
always @(posedge clk2) begin
    if(!HALTED) begin
        MEM_WB_type<=EX_MEM_type;
        MEM_WB_IR<=#2 EX_MEM_IR;

        case(EX_MEM_type)
            RR_ALU,RM_ALU: MEM_WB_ALUOut<=#2 EX_MEM_ALUOut;
            LOAD: MEM_WB_LMD<=#2 Mem[EX_MEM_ALUOut];
            STORE: if(!TAKEN_BRANCH) Mem[EX_MEM_ALUOut]<=#2 EX_MEM_B;
        endcase
    end
end


// WB
always @(posedge clk1) begin
    if(!TAKEN_BRANCH) begin
        case(MEM_WB_type)
            RR_ALU: Reg[MEM_WB_IR[15:11]]<=#2 MEM_WB_ALUOut;
            RM_ALU: Reg[MEM_WB_IR[20:16]]<=#2 MEM_WB_ALUOut;
            LOAD:   Reg[MEM_WB_IR[20:16]]<=#2 MEM_WB_LMD;
            HALT:   HALTED<=#2 1'b1;
        endcase
    end
end

endmodule

