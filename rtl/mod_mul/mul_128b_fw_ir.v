`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         SHU
// Engineer:        lf
// 
// Create Date:    09:49:50 04/11/2020 
// Design Name: 
// Module Name:    mul_128b_fw_ir 
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
//使用 64b 乘法器搭建 128b 全字长乘法器
//四路并行乘法器实现
//延迟 0+1clk 输入打拍
//////////////////////////////////////////////////////////////////////////////////
module mul_128b_fw_ir(
    input           clk,
    input           rst_n,

    input           mul_vld_i,//运算有效信号

    input [127:0]   mul_a_i,
    input [127:0]   mul_b_i,

    output          mul_fin_o,
    output [255:0]  mul_r_o
);

//输入信号分割 {A,B}x{C,D} 与预处理
reg  [63:0]         mul_A;
reg  [63:0]         mul_B;
reg  [63:0]         mul_C;
reg  [63:0]         mul_D;

//中间变量
wire [191:0]        mul_r_tmp;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        {mul_A,mul_B}   <=   128'd0;
        {mul_C,mul_D}   <=   128'd0;
    end else begin
        {mul_A,mul_B}   <=   mul_a_i;
        {mul_C,mul_D}   <=   mul_b_i;
    end
end

//64位 无符号数乘法 IP
wire [63 : 0]       mul_64a_a = mul_B;
wire [63 : 0]       mul_64a_b = mul_D;
wire [127 : 0]      mul_64a_p;

//64位 无符号数乘法 IP
wire [63 : 0]       mul_64b_a = mul_A;
wire [63 : 0]       mul_64b_b = mul_D;
wire [127 : 0]      mul_64b_p;

//64位 无符号数乘法 IP
wire [63 : 0]       mul_64c_a = mul_B;
wire [63 : 0]       mul_64c_b = mul_C;
wire [127 : 0]      mul_64c_p;

//64位 无符号数乘法 IP
wire [63 : 0]       mul_64d_a = mul_A;
wire [63 : 0]       mul_64d_b = mul_C;
wire [127 : 0]      mul_64d_p;

//64位 无符号数乘法 IP
mul_64b U_mul_64_a (
  .a(mul_64a_a), // input [63 : 0] a
  .b(mul_64a_b), // input [63 : 0] b
  .p(mul_64a_p) //  output [127 : 0] p
);

//64位 无符号数乘法 IP
mul_64b U_mul_64_b (
  .a(mul_64b_a), // input [63 : 0] a
  .b(mul_64b_b), // input [63 : 0] b
  .p(mul_64b_p) //  output [127 : 0] p
);

//64位 无符号数乘法 IP
mul_64b U_mul_64_c (
  .a(mul_64c_a), // input [63 : 0] a
  .b(mul_64c_b), // input [63 : 0] b
  .p(mul_64c_p) //  output [127 : 0] p
);

//64位 无符号数乘法 IP
mul_64b U_mul_64_d (
  .a(mul_64d_a), // input [63 : 0] a
  .b(mul_64d_b), // input [63 : 0] b
  .p(mul_64d_p) //  output [127 : 0] p
);
assign          mul_r_tmp       =   mul_64a_p[127:64] + mul_64b_p + mul_64c_p + {mul_64d_p,64'd0};
assign          mul_fin_o       =   1'b0;
assign          mul_r_o         =   {mul_r_tmp , mul_64a_p[63:0]};

endmodule