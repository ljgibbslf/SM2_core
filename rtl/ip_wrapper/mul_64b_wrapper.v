`timescale 1ns / 1ps
`include "../inc/sm2_cfg.v" 
//////////////////////////////////////////////////////////////////////////////////
// Company:         OpenIC SIG
// Engineer:        15201710458@163.com/lf_gibbs@163.com
// 
// Create Date:    09:49:50 07/11/2020 
// Design Name: 
// Module Name:    mul_64b_wrapper 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 64bit 无符号数 乘法器 IP wrapper
//                1.综合:定义实际使用的厂商乘法器 IP 
//                2.仿真:使用 dummy 乘法器 IP
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//                1.已支持并测试 : Xilinx(@fanli,11/2020)
//                2.接口定义与 Xilinx IP 一致
//////////////////////////////////////////////////////////////////////////////////
module mul_64b_wrapper(
    input [63:0]    a,
    input [63:0]    b,

    output [127:0]  p
);


`ifdef DESIGN_FPGA 

	FPAG_IP_NAME U_mul_64 (
	.a(a), // input [63 : 0] a
	.b(b), // input [63 : 0] b
	.p(p) //  output [127 : 0] p
	);

`elsif DESIGN_SIM

	mul_64b_sim_model U_mul_64 (
	.a(a), // input [63 : 0] a
	.b(b), // input [63 : 0] b
	.p(p) //  output [127 : 0] p
	);

`endif

endmodule