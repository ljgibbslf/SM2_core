`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         SHU
// Engineer:        lf
// 
// Create Date:    10:24:31 04/10/2020 
// Design Name: 
// Module Name:    mul_sos_256b_64x1_ir 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
// 使用双路 64b 乘法器搭建 256b 乘法器，使用 SOS 算法
// 输入打拍，直接输出
// 需要 8 + 1 (高位修正) + 1(输入打拍) clk
//////////////////////////////////////////////////////////////////////////////////
module mul_sos_256b_64x2_ir(
    input           clk,
    input           rst_n,

    input           mul_vld_i,//运算有效信号

    input [255:0]   mul_a_i,
    input [255:0]   mul_b_i,

    output  reg     mul_fin_o,
    output  [511:0] mul_r_o
);

integer i;

//划分为 64 比特字
reg  [63:0]     A_3,A_2,A_1,A_0;
reg  [63:0]     B_3,B_2,B_1,B_0;
wire            flg_AB_lod;

//结果寄存器 8个64比特寄存器 
reg  [63:0]     R [7:0];
wire            flg_R_lod;
reg  [63:0]     R7_adjst;
reg  [63:0]     R6_adjst;

//进位寄存器 65bit以防止溢出
reg  [64:0]     reg_carry;
reg  [64:0]     reg_carry_b;

//64位 无符号数乘法 IP
wire [63 : 0]       mul_64a_a;
wire [63 : 0]       mul_64a_b;
wire [127 : 0]      mul_64a_p;

//64位 无符号数乘法 IP b
wire [63 : 0]       mul_64b_a;
wire [63 : 0]       mul_64b_b;
wire [127 : 0]      mul_64b_p;

//计数器
reg  [2:0]          mul_cntr;       //3bit计数器
wire [0:0]          mul_cntr_b;     //1bit 运算数 B 计数器
wire [1:0]          mul_cntr_a;     //2bit 运算数 A 计数器
wire                mul_cntr_add;
wire                mul_cntr_clr;

//对有效信号取上升沿，并产生运算结束信号
reg                 mul_vld_r1;
wire                mul_vld_redge;
reg                 mul_vld_redge_r;

reg                 mul_fin_r1;

//对有效信号取上升沿，并产生运算结束信号
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_vld_r1              <=  1'b0;
        mul_vld_redge_r         <=  1'b0;
    end else begin
        mul_vld_r1              <= mul_vld_i;
        mul_vld_redge_r         <= mul_vld_redge;
    end
end

assign              mul_vld_redge   =   mul_vld_i && ~mul_vld_r1;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_cntr              <= 3'b0;
    end else if(mul_cntr_clr)begin
        mul_cntr              <= 3'b0;
    end else if(mul_cntr_add)begin
        mul_cntr              <= mul_cntr + 1'b1;
    
    end
end
assign                  mul_cntr_add  = ~(mul_cntr == 3'd0) || mul_vld_redge_r;
assign                  mul_cntr_clr  = mul_cntr_add && mul_cntr == 3'h7;
assign                  {mul_cntr_b,mul_cntr_a}  =   mul_cntr;
//输入打拍
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        {A_3,A_2,A_1,A_0}   <=  256'd0;
        {B_3,B_2,B_1,B_0}   <=  256'd0;
    end else if(flg_AB_lod)begin
        {A_3,A_2,A_1,A_0}   <=  mul_a_i;
        {B_3,B_2,B_1,B_0}   <=  mul_b_i;
    end
end

assign                  flg_AB_lod  =   mul_vld_redge;

//乘法器输入控制
assign              mul_64a_b   =   mul_cntr_b == 1'b0 ? B_0:
                                    mul_cntr_b == 1'b1 ? B_2:
                                    64'd0
                                    ;
// 乘法器B的操作数B和乘法器a均分2个操作数
assign              mul_64b_b   =   mul_cntr_b == 1'b0 ? B_1:
                                    mul_cntr_b == 1'b1 ? B_3:
                                    64'd0
                                    ;

assign              mul_64a_a   =   mul_cntr_a == 2'b00 ? A_0:
                                    mul_cntr_a == 2'b01 ? A_1:
                                    mul_cntr_a == 2'b10 ? A_2:
                                    mul_cntr_a == 2'b11 ? A_3:
                                    64'd0
                                    ;
// 乘法器B的操作数A和乘法器a一致
assign              mul_64b_a   =   mul_64a_a; 

//结果寄存器存储
always @(posedge clk or negedge rst_n) begin
    if(~rst_n | flg_R_lod) begin
        for ( i = 0; i < 8 ;i = i + 1 ) begin
            R[i]        <= 64'b0;
        end
        reg_carry           <=  65'd0;
        reg_carry_b         <=  65'd0;  //  乘法器B的进位变量
    end else begin
        case (mul_cntr_b)
            1'd0:
            begin
                if(mul_cntr_a == 2'd0 && !mul_fin_r1)begin //防止计数器转回后进行多余的运算
                    {reg_carry  ,R[0]}        <=    mul_64a_p + R[0];   
                    {reg_carry_b,R[1]}        <=    mul_64b_p + R[1];   
                end
                else if (mul_cntr_a == 2'd1)begin
                    {reg_carry  ,R[1]}        <=    mul_64a_p + reg_carry + R[1];
                    {reg_carry_b,R[2]}        <=    mul_64b_p + reg_carry_b + R[2];
                end
                else if (mul_cntr_a == 2'd2)begin
                    {reg_carry  ,R[2]}        <=    mul_64a_p + reg_carry   + R[2];
                    {reg_carry_b,R[3]}        <=    mul_64b_p + reg_carry_b + R[3];
                end
                else if (mul_cntr_a == 2'd3)begin
                    {reg_carry,     R[3]}        <=    mul_64a_p + reg_carry   + R[3];
                    {R[5]     ,     R[4]}        <=    mul_64b_p + reg_carry_b + R[4];
                end
            end
            1'd1:
            begin
                if(mul_cntr_a == 2'd0)begin
                    {reg_carry  ,R[2]}        <=    mul_64a_p + R[2];   
                    {reg_carry_b,R[3]}        <=    mul_64b_p + R[3];
                    {R[5],R[4]}               <=    {R[5],R[4]} + reg_carry;//此时reg_carry携带第一轮运算对r4的进位   
                end
                else if(mul_cntr_a == 2'd1)begin
                    {reg_carry,R[3]}        <=    mul_64a_p + reg_carry + R[3];
                    {reg_carry_b,R[4]}        <=    mul_64b_p + reg_carry_b + R[4];
                end
                else if(mul_cntr_a == 2'd2)begin
                    {reg_carry,R[4]}        <=    mul_64a_p + reg_carry + R[4];
                    {reg_carry_b,R[5]}        <=    mul_64b_p + reg_carry_b + R[5];
                end
                else if(mul_cntr_a == 2'd3)begin
                    {reg_carry,R[5]}        <=    mul_64a_p + reg_carry + R[5];
                    {R[7],R[6]}             <=    mul_64b_p + reg_carry_b + R[6];
                end
            end
        endcase
    end
end

//在输出前再通过一个周期 对结果进行修正 加上第三轮运算的进位
always @(posedge clk or negedge rst_n) begin
    if(~rst_n | flg_R_lod) begin
        R7_adjst        <=  64'd0;
        R6_adjst        <=  64'd0;
    end else begin
        {R7_adjst,R6_adjst}     <=  {R[7],R[6]} + reg_carry;
    end
end

assign                  flg_R_lod   =   flg_AB_lod;

//64位 无符号数乘法 IP
mul_64b U_mul_64_a (
  .a(mul_64a_a), // input [63 : 0] a
  .b(mul_64a_b), // input [63 : 0] b
  .p(mul_64a_p) //  output [127 : 0] p
);

//64位 无符号数乘法 IP B
mul_64b U_mul_64_b (
  .a(mul_64b_a), // input [63 : 0] a
  .b(mul_64b_b), // input [63 : 0] b
  .p(mul_64b_p) //  output [127 : 0] p
);

//输出端口
assign      mul_r_o = {R7_adjst,R6_adjst,R[5],R[4],R[3],R[2],R[1],R[0]};
// assign      mul_fin_o   =   mul_cntr_add && mul_cntr == 4'hf;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_fin_r1              <= 1'b0;
        mul_fin_o               <= 1'b0;
    end else begin
        mul_fin_r1             <= mul_cntr_add && mul_cntr == 4'h7;
        mul_fin_o              <= mul_fin_r1;
    end
end
endmodule