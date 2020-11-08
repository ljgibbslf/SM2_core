`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   19:54:10 04/01/2020
// Design Name:   mul_ko_128b
// Module Name:   D:/master_grdtn/pro_fpga_sm2/tb/tb_mul_ko_128b.v
// Project Name:  pro_fpga_sm2
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: mul_ko_128b
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_mul_ko_128b;

	// Inputs
	reg clk;
	reg rst_n;
	reg mul_vld_i;
	reg [127:0] mul_a_i;
	reg [127:0] mul_b_i;

	// Outputs
	wire mul_fin_o;
	wire [255:0] mul_r_o;

	wire [255:0] mul_r_ref;
    wire         flg_diff;


	// Instantiate the Unit Under Test (UUT)
	mul_ko_128b uut (
		.clk(clk), 
		.rst_n(rst_n), 
		.mul_vld_i(mul_vld_i), 
		.mul_a_i(mul_a_i), 
		.mul_b_i(mul_b_i), 
		.mul_fin_o(mul_fin_o), 
		.mul_r_o(mul_r_o)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		rst_n = 0;
		mul_vld_i = 0;
		mul_a_i = 0;
		mul_b_i = 0;

		// Wait 100 ns for global reset to finish
		#100;
		rst_n = 1;
        
		// Add stimulus here
            @(posedge clk);
        while (1) begin
            mul_vld_i = 1;
            wait(mul_fin_o);
            mul_vld_i = 0;
            @(posedge clk);
        end
        
	end

    //产生随机输入
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            mul_a_i              <= 128'd0;
            mul_b_i              <= 128'd0;
        end else if(mul_fin_o)begin //在输出后产生一个随机输入
            // mul_a_i              <= {64'h1,64'h2};
            // mul_b_i              <= {64'h3,64'h4};
            mul_a_i              <= {$urandom,$urandom,$urandom,$urandom};
            mul_b_i              <= {$urandom,$urandom,$urandom,$urandom};
        end
    end

    always #5 clk = ~clk;  

    //参考
    assign              mul_r_ref   =   mul_a_i * mul_b_i;
    assign              flg_diff    =   mul_fin_o && ~(mul_r_ref == mul_r_o);
endmodule

