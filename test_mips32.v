`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2026 12:24:06
// Design Name: 
// Module Name: test_mips32
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


module test_mips32;

reg clk1,clk2;
integer k;

wire [31:0] pc_out;
wire halted_out;

pipe_MIPS32 mips(
    .clk1(clk1),
    .clk2(clk2),
    .pc_out(pc_out),
    .halted_out(halted_out)
);

// expose internal signals to waveform
wire [31:0] PC          = mips.PC;
wire [31:0] IF_ID_IR    = mips.IF_ID_IR;
wire [31:0] ID_EX_IR    = mips.ID_EX_IR;
wire [31:0] EX_MEM_IR   = mips.EX_MEM_IR;
wire [31:0] MEM_WB_IR   = mips.MEM_WB_IR;

wire [31:0] ID_EX_A     = mips.ID_EX_A;
wire [31:0] ID_EX_B     = mips.ID_EX_B;
wire [31:0] EX_MEM_ALUOut = mips.EX_MEM_ALUOut;
wire [31:0] MEM_WB_ALUOut = mips.MEM_WB_ALUOut;

wire [2:0] ID_EX_type   = mips.ID_EX_type;
wire [2:0] EX_MEM_type  = mips.EX_MEM_type;


// two-phase clock
initial begin
    clk1=0; clk2=0;
    repeat(20) begin
        #5 clk1=1; #5 clk1=0;
        #5 clk2=1; #5 clk2=0;
    end
end


// init
initial begin
    for(k=0;k<32;k=k+1)
        mips.Reg[k]=k;

    mips.Mem[0]=32'h2801000a;
    mips.Mem[1]=32'h28020014;
    mips.Mem[2]=32'h28030019;
    mips.Mem[3]=32'h0ce77800;
    mips.Mem[4]=32'h0ce77800;
    mips.Mem[5]=32'h00222000;
    mips.Mem[6]=32'h0ce77800;
    mips.Mem[7]=32'h00832800;
    mips.Mem[8]=32'hfc000000;
end


// control
initial begin
    mips.PC=0;
    mips.HALTED=0;
    mips.TAKEN_BRANCH=0;
end


// result
initial begin
    #280;
    for(k=0;k<6;k=k+1)
        $display("R%0d = %0d",k,mips.Reg[k]);
end


initial begin
    #300 $finish;
end

endmodule

