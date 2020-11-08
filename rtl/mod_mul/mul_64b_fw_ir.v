`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         SHU
// Engineer:        lf
// 
// Create Date:    09:49:50 04/12/2020 
// Design Name: 
// Module Name:    mul_64b_fw_ir 
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
//使用 32b 乘法器搭建 64b 全字长乘法器
//四路并行乘法器实现
//延迟 0+1clk 输入打拍
//////////////////////////////////////////////////////////////////////////////////
module mul_64b_fw_ir(
    input           clk,
    input           rst_n,

    input           mul_vld_i,//运算有效信号

    input [63:0]    mul_a_i,
    input [63:0]    mul_b_i,

    output          mul_fin_o,
    output [127:0]  mul_r_o
);

//输入信号分割 {A,B}x{C,D} 与预处理
reg  [31:0]         mul_A;
reg  [31:0]         mul_B;
reg  [31:0]         mul_C;
reg  [31:0]         mul_D;

//中间变量
wire [191:0]        mul_r_tmp;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        {mul_A,mul_B}   <=   64'd0;
        {mul_C,mul_D}   <=   64'd0;
    end else begin
        {mul_A,mul_B}   <=   mul_a_i;
        {mul_C,mul_D}   <=   mul_b_i;
    end
end

//32位 无符号数乘法 IP
wire [31 : 0]       mul_32a_a = mul_B;
wire [31 : 0]       mul_32a_b = mul_D;
wire [63  : 0]      mul_32a_p;

//32位 无符号数乘法 IP
wire [31 : 0]       mul_32b_a = mul_A;
wire [31 : 0]       mul_32b_b = mul_D;
wire [63  : 0]      mul_32b_p;

//32位 无符号数乘法 IP
wire [31 : 0]       mul_32c_a = mul_B;
wire [31 : 0]       mul_32c_b = mul_C;
wire [63  : 0]      mul_32c_p;

//32位 无符号数乘法 IP
wire [31 : 0]       mul_32d_a = mul_A;
wire [31 : 0]       mul_32d_b = mul_C;
wire [63  : 0]      mul_32d_p;

//64位 无符号数乘法 IP
mul_32b U_mul_32_a (
  .A(mul_32a_a), // input [63 : 0] a
  .B(mul_32a_b), // input [63 : 0] b
  .P(mul_32a_p) //  output [127 : 0] p
);

//32位 无符号数乘法 IP
mul_32b U_mul_32_b (
  .A(mul_32b_a), // input [63 : 0] a
  .B(mul_32b_b), // input [63 : 0] b
  .P(mul_32b_p) //  output [127 : 0] p
);

//32位 无符号数乘法 IP
mul_32b U_mul_32_c (
  .A(mul_32c_a), // input [63 : 0] a
  .B(mul_32c_b), // input [63 : 0] b
  .P(mul_32c_p) //  output [127 : 0] p
);

//32位 无符号数乘法 IP
mul_32b U_mul_32_d (
  .A(mul_32d_a), // input [63 : 0] a
  .B(mul_32d_b), // input [63 : 0] b
  .P(mul_32d_p) //  output [127 : 0] p
);
assign          mul_r_tmp       =   mul_32a_p[63:32] + mul_32b_p + mul_32c_p + {mul_32d_p,32'd0};
assign          mul_fin_o       =   1'b0;
assign          mul_r_o         =   {mul_r_tmp , mul_32a_p[31:0]};

endmodule