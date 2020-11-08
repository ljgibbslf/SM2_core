`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         SHU
// Engineer:        lf
// 
// Create Date:    09:49:50 04/11/2020 
// Design Name: 
// Module Name:    mul_256b_fw_ir 
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
//使用 128b 乘法器搭建 256b 全字长乘法器
//四路并行乘法器实现
//延迟 0+1clk 输入打拍
//////////////////////////////////////////////////////////////////////////////////
module mul_256b_fw_ir(
    input           clk,
    input           rst_n,

    input           mul_vld_i,//运算有效信号

    input [255:0]   mul_a_i,
    input [255:0]   mul_b_i,

    output          mul_fin_o,
    output reg [511:0]  mul_r_o
);

//输入信号分割 {A,B}x{C,D} 与预处理
reg [127:0]         mul_A;
reg [127:0]         mul_B;
reg [127:0]         mul_C;
reg [127:0]         mul_D;

//中间变量
wire [383:0]        mul_r_tmp;

//输入信号分割 {A,B}x{C,D}并寄存
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        {mul_A,mul_B}   <=   256'd0;
        {mul_C,mul_D}   <=   256'd0;
    end else begin
        {mul_A,mul_B}   <=   mul_a_i;
        {mul_C,mul_D}   <=   mul_b_i;
    end
end

//64位 无符号数乘法 IP
wire [127 : 0]       mul_128a_a = mul_B;
wire [127 : 0]       mul_128a_b = mul_D;
wire [255 : 0]       mul_128a_p;

//128位 无符号数乘法 IP
wire [127 : 0]       mul_128b_a = mul_A;
wire [127 : 0]       mul_128b_b = mul_D;
wire [255 : 0]       mul_128b_p;

//128位 无符号数乘法 IP
wire [127 : 0]       mul_128c_a = mul_B;
wire [127 : 0]       mul_128c_b = mul_C;
wire [255 : 0]       mul_128c_p;

//128位 无符号数乘法 IP
wire [127 : 0]       mul_128d_a = mul_A;
wire [127 : 0]       mul_128d_b = mul_C;
wire [255 : 0]       mul_128d_p;

mul_128b_fw_ir U_mul_128_a (
    .clk(clk), 
    .rst_n(rst_n), 
    .mul_vld_i(mul_vld_i), 
    .mul_a_i(mul_128a_a), 
    .mul_b_i(mul_128a_b), 
    .mul_r_o(mul_128a_p),
    .mul_fin_o()
    );

mul_128b_fw_ir U_mul_128_b (
    .clk(clk), 
    .rst_n(rst_n), 
    .mul_vld_i(mul_vld_i), 
    .mul_a_i(mul_128b_a), 
    .mul_b_i(mul_128b_b), 
    .mul_r_o(mul_128b_p),
    .mul_fin_o()
    );

mul_128b_fw_ir U_mul_128_c (
    .clk(clk), 
    .rst_n(rst_n), 
    .mul_vld_i(mul_vld_i), //等待加法结束后的一周期开始
    .mul_a_i(mul_128c_a), 
    .mul_b_i(mul_128c_b), 
    .mul_r_o(mul_128c_p),
    .mul_fin_o()
    );

mul_128b_fw_ir U_mul_128_d (
    .clk(clk), 
    .rst_n(rst_n), 
    .mul_vld_i(mul_vld_i), //等待加法结束后的一周期开始
    .mul_a_i(mul_128d_a), 
    .mul_b_i(mul_128d_b), 
    .mul_r_o(mul_128d_p),
    .mul_fin_o()
    );

assign          mul_r_tmp       =   mul_128a_p[255:128] + mul_128b_p + mul_128c_p + {mul_128d_p,128'd0};
assign          mul_fin_o       =   1'b0;
// assign          mul_r_o         =   {mul_r_tmp , mul_128a_p[127:0]};
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_r_o              <= 1'b0;
    end else begin
        mul_r_o              <= {mul_r_tmp , mul_128a_p[127:0]};
    end
end
endmodule