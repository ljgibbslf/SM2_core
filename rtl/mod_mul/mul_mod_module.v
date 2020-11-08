`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:16:54 04/01/2020 
// Design Name: 
// Module Name:    mul_mod_module 
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
//
//////////////////////////////////////////////////////////////////////////////////
module mul_mod_module(
    input           clk,
    input           rst_n,

    input           mul_vld_i,//运算有效信号

    input [255:0]   mul_a_i,
    input [255:0]   mul_b_i,

    output          mul_fin_o,
    output [255:0]   mul_r_o
);
wire [511:0]    mul_r_mid;
wire            mul_fin_mid;

mul_ko_256b U_mul_ko_256b (
    .clk(clk), 
    .rst_n(rst_n), 
    .mul_vld_i(mul_vld_i), 
    .mul_a_i(mul_a_i), 
    .mul_b_i(mul_b_i), 
    .mul_fin_o(mul_fin_mid), 
    .mul_r_o(mul_r_mid)
    );

spd_mod_sub U_spd_mod_sub (
    .clk(clk), 
    .rst_n(rst_n), 
    .mod_vld_i(mul_fin_mid),
    .p512_a(mul_r_mid), 
    .mod_fin_o(mul_fin_o),
    .p256_b(mul_r_o)
    );


endmodule
