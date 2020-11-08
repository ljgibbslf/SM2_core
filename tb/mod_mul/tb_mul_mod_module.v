`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company:     OpenIC SIG
// Engineer:    lf_gibbs@163.com
//
// Create Date:   21:17:41 04/02/2020
// Design Name:   mul_mod_module
// Module Name:   tb_mul_mod_module.v
// Project Name:  pro_fpga_sm2
// Target Device:  
// Tool versions:  
// Description: 
//  模乘模块验证
//  1. 产生随机输入，使能模乘模块
//  2. 等待模乘模块输出结果
//  3. 与直接模乘运算的结果进行比较
//  4. 开始下一次测试
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_mul_mod_module;

	// Inputs
	reg clk;
	reg rst_n;
	reg mul_vld_i;
	reg [255:0] mul_a_i;
	reg [255:0] mul_b_i;

	// Outputs
	wire mul_fin_o;         
	wire [255:0] mul_r_o;   

    wire [255:0] mod_r_ref;
    wire [511:0] mul_r_ref;
    wire         flg_diff;

    `define RANDOM_INPT 1

    //素数常量 p256
    wire [255:0]    P256 = {
        8'hFF, 8'hFF, 8'hFF, 8'hFE, 8'hFF, 8'hFF, 8'hFF, 8'hFF, /* p */
        8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF,
        8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h00, 8'h00, 8'h00, 8'h00,
        8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF 
        } ;

	// Instantiate the Unit Under Test (UUT)
    // 待测试模乘模块
	mul_mod_module uut (
		.clk(clk), 
		.rst_n(rst_n), 
        // .p256_i(P256),       //NC,内部设置为P256
		.mul_vld_i(mul_vld_i),  //输入使能
		.mul_a_i(mul_a_i), 
		.mul_b_i(mul_b_i), 
		.mul_fin_o(mul_fin_o),  //输出使能
		.mul_r_o(mul_r_o)       //输出结果
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

    //产生输入激励
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            mul_a_i              <= 256'd0;
            mul_b_i              <= 256'd0;
        end else if(mul_fin_o)begin //在输出后产生一个随机输入
            `ifdef RANDOM_INPT
                mul_a_i              <= {$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom};
                mul_b_i              <= {$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom,$urandom};
            `else
                mul_a_i              <= {64'h1,64'h2,64'h3,64'h4};
                mul_b_i              <= {64'h5,64'h6,64'h7,64'h8};
            `endif
        end
    end

    always #5 clk = ~clk; 

    //参考运算，使用 * % 运算符
    assign              mul_r_ref   =   (mul_a_i * mul_b_i);
    assign              mod_r_ref   =   mul_r_ref % P256;
    assign              flg_diff    =   mul_fin_o && ~(mod_r_ref == mul_r_o);

    //打印不同的输出
    always@(flg_diff)begin
        $display("Fail!\n");
        $display("REF: %X,%X\n",mod_r_ref[255-:128],mod_r_ref[127-:128]);
        $display("OUT: %X,%X",mul_r_o[255-:128],mul_r_o[127-:128]);
    end
      
endmodule

