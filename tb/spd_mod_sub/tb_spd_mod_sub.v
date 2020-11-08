`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   21:38:29 03/31/2020
// Design Name:   spd_mod_sub
// Module Name:   D:/master_grdtn/pro_fpga_sm2/tb/tb_spd_mod_sub.v
// Project Name:  pro_fpga_sm2
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: spd_mod_sub
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_spd_mod_sub;

	// Inputs
	reg clk;
	reg rst_n;
	reg [511:0] p512_a;
    reg [255:0] p256_b_tb_cal_r;
    reg mod_vld_i;

	// Outputs
	wire [255:0] p256_b;
	wire [255:0] p256_b_tb_cal;
    wire         flg_diff;
    wire mod_fin_o;

    //常量 p256
    wire [255:0]    P256 = {
        8'hFF, 8'hFF, 8'hFF, 8'hFE, 8'hFF, 8'hFF, 8'hFF, 8'hFF, /* p */
        8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF,
        8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h00, 8'h00, 8'h00, 8'h00,
        8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF 
        } ;

	// Instantiate the Unit Under Test (UUT)
	spd_mod_sub uut (
		.clk(clk), 
		.rst_n(rst_n), 
        .mod_vld_i(mod_vld_i),
		.p512_a(p512_a), 
        .mod_fin_o(mod_fin_o),
		.p256_b(p256_b)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		rst_n = 0;
		p512_a = 0;
        mod_vld_i = 0;
		// Wait 100 ns for global reset to finish
		#100;
		rst_n = 1;
        
		// Add stimulus here
        // p512_a = {$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,
        // $urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom};
        // p512_a = {256'd0,P256};
        // repeat(3) begin
        //     @(posedge clk);
        //     p512_a = p512_a + {255'd0,1'd1,256'd0};
        // end

        // repeat(3) begin
        //     @(posedge clk);
        //     p512_a = p512_a + 1'd1;
        // end

        // Add stimulus here
            @(posedge clk);
            while (1) begin
                mod_vld_i = 1;
                wait(mod_fin_o);
                mod_vld_i = 0;
                @(posedge clk);
            end

	end

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            p512_a              <= {256'd0,P256};
        end else if(mod_fin_o)begin //每拍产生一个随机数
            // p512_a              <= {{256{1'b1}},P256};
            p512_a              <= {$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,
        $urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom};
        end
    end

    //直接取模，计算一个参考的结果
    assign  p256_b_tb_cal = p512_a % P256;

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            p256_b_tb_cal_r              <= 256'b0;
        end else begin
            p256_b_tb_cal_r              <= p256_b_tb_cal;
        end
    end
    
    //判断两者是否一致
    assign  flg_diff = mod_fin_o && ~(p256_b_tb_cal == p256_b);

    always@(flg_diff)begin
        $display("%X,%X\n",p256_b_tb_cal[255-:128],p256_b_tb_cal[127-:128]);
        $display("%X,%X",p256_b[255-:128],p256_b[127-:128]);
    end

    always #5 clk = ~clk;
      
endmodule

