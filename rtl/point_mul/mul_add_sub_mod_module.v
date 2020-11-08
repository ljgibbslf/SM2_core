`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         SHU
// Engineer:        lf
// 
// Create Date:    23:16:54 04/13/2020 
// Design Name: 
// Module Name:    mul_add_sub_mod_module 
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
//  复用实现模乘，模加以及模减运算模块
//  op_sel_i : 
//  2'b00 :  模乘 
//  2'b01 :  模加 
//  2'b10 :  模减 
//  乘法时使用运算有效信号以及完成信号，加减法固定为组合逻辑
//////////////////////////////////////////////////////////////////////////////////
module mul_add_sub_mod_module(
    input           clk,
    input           rst_n,

    input           op_vld_i,//运算有效信号,在乘法时使用

    input [1:0]     op_sel_i,

    input [255:0]   op_mod_num_i,

    input [255:0]   op_a_i,
    input [255:0]   op_b_i,

    output          op_done_o,
    output [255:0]  op_rslt_o
);

localparam      OP_MUL = 2'b00;
localparam      OP_ADD = 2'b01;
localparam      OP_SUB = 2'b10;

//大数乘法模块信号
wire [511:0]    mul_r_mid;
wire            mul_fin_mid;
wire            mul_vld;

//快速模约减/模加减模块信号
wire [511:0]    spd_mod_inpt;  
wire [255:0]    spd_mod_otpt;  
wire            spd_mod_vld;
wire [255:0]    spd_mod_res;
wire [255:0]    op_add_sub_res;

wire            add_sub_vld;

mul_ko_256b U_mul_ko_256b (
    .clk(clk), 
    .rst_n(rst_n), 
    .mul_vld_i(mul_vld), 
    .mul_a_i(op_a_i), 
    .mul_b_i(op_b_i), 
    .mul_fin_o(mul_fin_mid), 
    .mul_r_o(mul_r_mid)
    );
assign          mul_vld = op_sel_i == OP_MUL && op_vld_i;

spd_mod_sub_stgb U_spd_mod_sub (
    .clk            (clk), 
    .rst_n          (rst_n), 

    .op_mod_num_i   (op_mod_num_i),
    .op_sel_i       (op_sel_i),

    .mod_vld_i      (spd_mod_vld),
    .p512_a         (spd_mod_inpt),

    .op_add_sub_res (op_add_sub_res),

    .mod_fin_o      (op_done_o),
    .p256_b         (spd_mod_res)
    );

assign          spd_mod_vld =   mul_fin_mid || add_sub_vld;
assign          add_sub_vld =   (op_sel_i == OP_ADD || op_sel_i == OP_SUB) && op_vld_i;

//在非乘法时复用约减模块进行模加减运算
assign          spd_mod_inpt = op_sel_i == OP_MUL ? mul_r_mid : {op_a_i,op_b_i};

//输出逻辑
assign          op_rslt_o   =   op_sel_i == OP_MUL ? spd_mod_res : op_add_sub_res;

endmodule