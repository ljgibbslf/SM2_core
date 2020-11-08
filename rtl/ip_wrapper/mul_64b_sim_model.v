`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         OpenIC SIG
// Engineer:        15201710458@163.com/lf_gibbs@163.com
// 
// Create Date:    13:49:50 07/11/2020 
// Design Name: 
// Module Name:    mul_64b_sim_model 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 64bit 无符号数 乘法器 仿真模型
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//                仿真模型中直接使用 *，仅用于仿真验证
//////////////////////////////////////////////////////////////////////////////////
module mul_64b_sim_model(
    input [63:0]    a,
    input [63:0]    b,

    output [127:0]  p
);
	assign	p = a * b;

endmodule