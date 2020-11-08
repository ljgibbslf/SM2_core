`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   20:15:29 05/14/2020
// Design Name:   spd_mod_sub_stgb
// Module Name:   D:/master_grdtn/pro_fpga_sm2/tb/tb_spd_mod_sub_stgb.v
// Project Name:  pro_fpga_sm2
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: spd_mod_sub_stgb
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 测试了 spd_mod_sub_stgb 模块的取模，模加，模减正确性，轮流测试共10ms随机激励
////////////////////////////////////////////////////////////////////////////////

module tb_spd_mod_sub_stgb;

	// Inputs
	reg clk;
	reg rst_n;
	reg mod_vld_i;
	reg [1:0] op_sel_i;
	// reg [255:0] op_mod_num_i;
	wire[511:0] p512_a;
	reg [255:0] p256_a;
	reg [255:0] p256_b;

	// Outputs
	wire [255:0] op_add_sub_res;
	wire mod_fin_o;
	wire [255:0] mul_mod_res;

    wire signed [257:0] add_sub_r_ref;
    wire   [255:0] mod_r_ref;
    wire         flg_diff;

    //常量 p256
    wire [255:0]    P256 = {
        8'hFF, 8'hFF, 8'hFF, 8'hFE, 8'hFF, 8'hFF, 8'hFF, 8'hFF, /* p */
        8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF,
        8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h00, 8'h00, 8'h00, 8'h00,
        8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF 
        } ;

    localparam      OP_MUL = 2'b00;
    localparam      OP_ADD = 2'b01;
    localparam      OP_SUB = 2'b10;

	// Instantiate the Unit Under Test (UUT)
	spd_mod_sub_stgb uut (
		.clk(clk), 
		.rst_n(rst_n), 
		.mod_vld_i(mod_vld_i), 
		.op_sel_i(op_sel_i), 
		.op_mod_num_i(P256), 
		.p512_a(p512_a), 
		.op_add_sub_res(op_add_sub_res), 
		.mod_fin_o(mod_fin_o), 
		.p256_b(mul_mod_res)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		rst_n = 0;
		mod_vld_i = 0;
		op_sel_i = OP_ADD;
        p256_a = 0;
        p256_b = 0;

		// Wait 100 ns for global reset to finish
		#100;
		rst_n = 1;
		#100;
        
		// Add stimulus here
        @(posedge clk);
        while (1) begin
            mod_vld_i = 1;
            wait(mod_fin_o);
            mod_vld_i = 0;
            
            @(posedge clk);
        end

	end

    //切换运算符进行测试
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            op_sel_i        <= OP_ADD;
        end else if (mod_fin_o) begin
            op_sel_i        <= op_sel_i == OP_SUB  ? OP_ADD : 
                               op_sel_i ==  OP_ADD ? OP_MUL : 
                                            OP_SUB;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            {p256_a,p256_b}              <= {{P256[255:1],1'b0},{P256[255:1],1'b0}};
        end else if(mod_fin_o)begin //每拍产生一个随机数
            // p512_a              <= {{256{1'b1}},P256};
            {p256_a,p256_b}              <= {$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,
        $urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom};
        end
    end

    always #5 clk = ~clk;

    //参考
    assign              add_sub_r_ref   =   op_sel_i == OP_ADD ? (p256_a + p256_b) : (p256_a - p256_b);
    assign              mod_r_ref   =   op_sel_i ==  OP_MUL ? p512_a % P256:
                                        add_sub_r_ref [257]    ? add_sub_r_ref + P256 : 
                                        add_sub_r_ref >= P256  ? add_sub_r_ref - P256 :
                                        add_sub_r_ref[255:0];
    assign              flg_diff    =   mod_fin_o && (
                                                    (~(mod_r_ref == op_add_sub_res) && ~op_sel_i ==  OP_MUL) ||
                                                    (~(mod_r_ref == mul_mod_res) && op_sel_i ==  OP_MUL)
                                                    );

    always@(flg_diff)begin
        $display("%X,%X\n",mod_r_ref[255-:128],mod_r_ref[127-:128]);
        $display("%X,%X",op_add_sub_res[255-:128],op_add_sub_res[127-:128]);
    end

    assign          p512_a  =   {p256_a,p256_b};
      
endmodule

