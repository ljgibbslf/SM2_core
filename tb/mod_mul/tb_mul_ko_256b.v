`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   22:36:45 04/01/2020
// Design Name:   mul_ko_256b
// Module Name:   D:/master_grdtn/pro_fpga_sm2/tb/tb_mul_ko_256b.v
// Project Name:  pro_fpga_sm2
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: mul_ko_256b
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_mul_ko_256b;

	// Inputs
	reg clk;
	reg rst_n;
	reg mul_vld_i;
	reg [255:0] mul_a_i;
	reg [255:0] mul_b_i;

	// Outputs
	wire mul_fin_o;
	wire [511:0] mul_r_o;
	wire mul_fin_o_x1;
	wire [511:0] mul_r_o_x1;

    wire [511:0] mul_r_ref;
    wire         flg_diff;

	// Instantiate the Unit Under Test (UUT)
	// mul_ko_256b uut (
	mul_256b_fw_ir uut (
		.clk(clk), 
		.rst_n(rst_n), 
		.mul_vld_i(mul_vld_i), 
		.mul_a_i(mul_a_i), 
		.mul_b_i(mul_b_i), 
		.mul_fin_o(mul_fin_o), 
		.mul_r_o(mul_r_o)
	);

    //mul_sos_256b_64x1_ir uut_1 (
    mul_sos_256b_64x2_ir uut_1 (
		.clk(clk), 
		.rst_n(rst_n), 
		.mul_vld_i(mul_vld_i), 
		.mul_a_i(mul_a_i), 
		.mul_b_i(mul_b_i), 
		.mul_fin_o(mul_fin_o_x1), 
		.mul_r_o(mul_r_o_x1)
	);
    // mul_ko_256bx1_ir uut_1 (
	// 	.clk(clk), 
	// 	.rst_n(rst_n), 
	// 	.mul_vld_i(mul_vld_i), 
	// 	.mul_a_i(mul_a_i), 
	// 	.mul_b_i(mul_b_i), 
	// 	.mul_fin_o(mul_fin_o_x1), 
	// 	.mul_r_o(mul_r_o_x1)
	// );

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
            wait(mul_fin_o_x1);
            @(posedge clk);
            mul_vld_i = 0;
            @(posedge clk);
        end

	end

    //产生随机输入
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            mul_a_i              <= 256'd0;
            mul_b_i              <= 256'd0;
        end else if(mul_fin_o_x1)begin //在输出后产生一个随机输入
            //  mul_a_i              <= {64'h1,64'h2,64'h3,64'h4};
            //  mul_b_i              <= {64'h5,64'h6,64'h7,64'h8};
            mul_a_i              <= {$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom};
            mul_b_i              <= {$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom};
        end
    end

    always #5 clk = ~clk;  

    //参考
    assign              mul_r_ref   =   mul_a_i * mul_b_i;
    assign              flg_diff    =   (mul_fin_o && ~(mul_r_ref == mul_r_o))
                                    ||  (mul_fin_o_x1 && ~(mul_r_ref == mul_r_o_x1));

    always@(flg_diff)begin
        if(flg_diff) begin
            $display("%X,%X,%X,%X\n",mul_r_ref[511-:128],mul_r_ref[383-:128],mul_r_ref[255-:128],mul_r_ref[127-:128]);
            $display("%X,%X,%X,%X",mul_r_o[511-:128],mul_r_o[383-:128],mul_r_o[255-:128],mul_r_o[127-:128]);
            $display("%X,%X,%X,%X",mul_r_o_x1[511-:128],mul_r_o_x1[383-:128],mul_r_o_x1[255-:128],mul_r_o_x1[127-:128]);
        end
    end
      
endmodule

