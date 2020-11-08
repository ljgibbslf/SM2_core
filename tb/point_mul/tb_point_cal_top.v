`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:59:14 04/15/2020
// Design Name:   point_cal_top
// Module Name:   D:/master_grdtn/pro_fpga_sm2/tb/tb_point_cal_top.v
// Project Name:  pro_fpga_sm2
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: point_cal_top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_point_cal_top;

	// Inputs
	reg clk;
	reg rst_n;
	reg [15:0] ins_0_i;
	reg [15:0] ins_1_i;
	reg [15:0] ins_2_i;
	reg [255:0] data_path_i;
	reg ins_vld_i;

	// Outputs
	wire [255:0] var_x2_o;
	wire [255:0] var_y2_o;
	wire [255:0] var_z2_o;
	wire intr_cal_done_o;

    localparam          OP_X2 = 4'b0,OP_Y2 = 4'd1,OP_Z2 = 4'd2;
    localparam          OP_T0 = 4'd3,OP_T1 = 4'd4,OP_T2 = 4'd5;
    localparam          OP_X0 = 4'd6,OP_Y0 = 4'd7,OP_Z0 = 4'd8,OP_X1 = 4'd9,OP_Y1 = 4'd10,OP_Z1 = 4'd11;
    localparam          OP_NULL = 4'd15;

    localparam          OP_MUL = 2'b00;
    localparam          OP_ADD = 2'b01;
    localparam          OP_SUB = 2'b10;
    localparam          OP_NUL = 2'b11;

    localparam          INS_CAL         = 2'b00;
    localparam          INS_UPDT_REG    = 2'b01;
    localparam          INS_FIN         = 2'b10;//运算结束指令，默认将结果装载到常量寄存器
    localparam          INS_NULL        = 2'b11;

    localparam          INS_PD_RND =   12;
    localparam          INS_PA_RND =   10;

    reg [16*3*INS_PD_RND - 1:0]    ins_lst_reg;
    wire[16*3*INS_PD_RND - 1:0]    ins_lst_pd;
    wire[16*3*INS_PA_RND - 1:0]    ins_lst_pa;
    wire[15:0]                      ins_null = {OP_NUL,INS_NULL,OP_NULL,OP_NULL,OP_NULL};    

	// Instantiate the Unit Under Test (UUT)
	point_cal_top uut (
		.clk(clk), 
		.rst_n(rst_n), 
		.ins_0_i(ins_0_i), 
		.ins_1_i(ins_1_i), 
		.ins_2_i(ins_2_i), 
		.ins_vld_i(ins_vld_i), 
        .data_path_i(256'd0),
		.var_x2_o(var_x2_o), 
		.var_y2_o(var_y2_o), 
		.var_z2_o(var_z2_o), 
		.intr_cal_done_o(intr_cal_done_o)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		rst_n = 0;
		ins_0_i = 0;
		ins_1_i = 0;
		ins_2_i = 0;
		ins_vld_i = 0;
        data_path_i = 0;
        ins_lst_reg = 0;

		// Wait 100 ns for global reset to finish
		#100;
		rst_n = 1;
        
		// Add stimulus here
        @(posedge clk);

        //初始化寄存器
        
        //首次倍点运算
        ins_lst_reg = ins_lst_pd[16*3*INS_PD_RND - 1:0];
        @(posedge clk);
        repeat(INS_PD_RND) begin
            push_ins;
            wait(intr_cal_done_o)
            @(posedge clk);
            
        end

        write_ins(OP_NUL,INS_FIN,4'd0,4'd0,4'd0);//写结束运算命令
        @(posedge clk);

        //后续点加运算
        ins_lst_reg ={ins_lst_pa[16*3*INS_PA_RND - 16*3 -1:0],48'd0,96'd0};
        @(posedge clk);
        repeat(INS_PA_RND-1) begin
            push_ins;
            wait(intr_cal_done_o)
            @(posedge clk);
        end


        write_ins(OP_NUL,INS_FIN,4'd0,4'd0,4'd0);//写结束运算命令
        @(posedge clk);

        //后续倍点运算
        ins_lst_reg =  {ins_lst_pd[16*3*INS_PD_RND - 16*3 -1:0],48'd0};
        @(posedge clk);
        repeat(INS_PD_RND-1) begin
            push_ins;
            wait(intr_cal_done_o)
            @(posedge clk);
        end

        write_ins(OP_NUL,INS_FIN,4'd0,4'd0,4'd0);//写结束运算命令
        @(posedge clk);
        // write_ins(OP_MUL,INS_CAL,OP_X0,OP_X0,OP_X2);//计算 x2 = x0 * x0
        // repeat(10)begin
        //     @(posedge clk);
        // end

        // write_ins(OP_MUL,INS_CAL,OP_X0,OP_X2,OP_Y2);//计算 y2 = x0 * x2
        // repeat(10)begin
        //     @(posedge clk);
        // end

        // write_ins(OP_MUL,INS_CAL,OP_X2,OP_X2,OP_X2);//计算 x2 = x2 * x2
        // repeat(10)begin
        //     @(posedge clk);
        // end

        

	end

    //指令列表
    assign  ins_lst_pd     ={
        //rnd 0
        {OP_MUL,INS_CAL,OP_Z0,OP_Z0,OP_T2},//T2 = Z0*Z0
        ins_null,
        ins_null,

        //rnd 1
        {OP_SUB,INS_CAL,OP_X0,OP_T2,OP_X2},//x2 = X0 - T2
        {OP_ADD,INS_CAL,OP_X0,OP_T2,OP_Y2},//Y2 = X0 + T2
        ins_null,

        //rnd 2
        {OP_MUL,INS_CAL,OP_X2,OP_Y2,OP_Y2},//y2 = (y2 * x2)
        {OP_MUL,INS_CAL,OP_Y0,OP_Y0,OP_T0},//t0 = (y0 * y0)
        {OP_MUL,INS_CAL,OP_Y0,OP_Z0,OP_Z2},//z2 = (y0 * z0)

        //rnd 3
        {OP_ADD,INS_CAL,OP_T0,OP_T0,OP_T0},//T0 = T0 + T0
        {OP_ADD,INS_CAL,OP_Y2,OP_Y2,OP_T2},//T2 = Y2 + Y2
        ins_null,

        //rnd 4
        {OP_ADD,INS_CAL,OP_Z2,OP_Z2,OP_Z2},//Z2 = Z2 + Z2
        {OP_ADD,INS_CAL,OP_Y2,OP_T2,OP_Y2},//Y2 = Y2 + T2
        ins_null,

        //rnd 5
        {OP_MUL,INS_CAL,OP_Y2,OP_Y2,OP_T2},//T2 = (y2 * y2)
        {OP_MUL,INS_CAL,OP_X0,OP_T0,OP_T0},//t0 = (T0 * X0)
        {OP_MUL,INS_CAL,OP_T0,OP_T0,OP_T1},//T1 = (T0 * T0)

        //rnd 6
        {OP_ADD,INS_CAL,OP_T0,OP_T0,OP_T0},//T0 = T0 + T0
        ins_null,
        ins_null,

        //rnd 7
        {OP_ADD,INS_CAL,OP_T0,OP_T0,OP_X2},//X2 = T0 + T0
        ins_null,
        ins_null,

        //rnd 8
        {OP_SUB,INS_CAL,OP_T2,OP_X2,OP_X2},//X2 = T2 - X2
        ins_null,
        ins_null,

        //rnd 9
        {OP_ADD,INS_CAL,OP_T1,OP_T1,OP_T1},//T1 = T1 + T1
        {OP_SUB,INS_CAL,OP_T0,OP_X2,OP_T0},//T0 = T0 - X2
        ins_null,

        //rnd 10
        {OP_MUL,INS_CAL,OP_T0,OP_Y2,OP_Y2},//Y2 = Y2 * T0
        {OP_MUL,INS_CAL,OP_Z2,OP_Z2,OP_T2},//T2 = Z2 * Z2 预计算 Z2^2
        {OP_MUL,INS_CAL,OP_Z2,OP_Y1,OP_T0},//T0 = Z2 * Y1 预计算 Z2*Y1
        
        //rnd 11
        {OP_SUB,INS_CAL,OP_Y2,OP_T1,OP_Y2},//Y2 = Y2 - T1
        ins_null,
        ins_null
    };

    assign  ins_lst_pa     ={
        //rnd 0
        {OP_MUL,INS_CAL,OP_Z0,OP_Z0,OP_T2},
        {OP_MUL,INS_CAL,OP_Z0,OP_Y1,OP_T0},
        ins_null,

        //rnd 1
        {OP_MUL,INS_CAL,OP_T2,OP_T0,OP_T1},
        {OP_MUL,INS_CAL,OP_X1,OP_T2,OP_Z2},
        ins_null,

        //rnd 2
        {OP_SUB,INS_CAL,OP_Z2,OP_X0,OP_T0},
        {OP_SUB,INS_CAL,OP_T1,OP_Y0,OP_T1},
        ins_null,

        //rnd 3
        {OP_MUL,INS_CAL,OP_T0,OP_Z0,OP_Z2},
        {OP_MUL,INS_CAL,OP_T0,OP_T0,OP_T2},
        ins_null,

        //rnd 4
        {OP_MUL,INS_CAL,OP_T0,OP_T2,OP_Y2},
        {OP_MUL,INS_CAL,OP_T2,OP_X0,OP_T2},
        {OP_MUL,INS_CAL,OP_T1,OP_T1,OP_X2},

        //rnd 5
        {OP_SUB,INS_CAL,OP_X2,OP_Y2,OP_X2},
        {OP_ADD,INS_CAL,OP_T2,OP_T2,OP_T0},
        ins_null,

        //rnd 6
        {OP_SUB,INS_CAL,OP_X2,OP_T0,OP_X2},
        ins_null,
        ins_null,

        //rnd 7
        {OP_SUB,INS_CAL,OP_T2,OP_X2,OP_T2},
        ins_null,
        ins_null,

        //rnd 8
        {OP_MUL,INS_CAL,OP_T1,OP_T2,OP_T1},
        {OP_MUL,INS_CAL,OP_Y0,OP_Y2,OP_Y2},
        {OP_MUL,INS_CAL,OP_Z2,OP_Z2,OP_T2},

        //rnd 9
        {OP_SUB,INS_CAL,OP_T1,OP_Y2,OP_Y2},
        ins_null,
        ins_null
    };

    always #5 clk = ~ clk;

    //task 设置1条指令，并写入指令有效信号
    task write_ins(
        input [1:0] ins_op_mode,
        input [1:0] ins_type,
        input [3:0] ins_op_num_a,
        input [3:0] ins_op_num_b,
        input [3:0] ins_op_num_r
    ); 
    begin
        ins_0_i = {ins_op_mode,ins_type,ins_op_num_a,ins_op_num_b,ins_op_num_r};//计算 x2 = x0 * x2
        @(posedge clk);
        ins_vld_i = 1;
        @(posedge clk);
        ins_vld_i = 0;
    end
    endtask


    //task 将3条指令压栈 并移位指令reg
    task push_ins;
    begin
        ins_0_i = {ins_lst_reg[16*3*INS_PD_RND - 1-:16]};
        ins_1_i = {ins_lst_reg[16*3*INS_PD_RND - 17-:16]};
        ins_2_i = {ins_lst_reg[16*3*INS_PD_RND - 33-:16]};
        @(posedge clk);
        ins_vld_i = 1;
        @(posedge clk);
        ins_vld_i = 0;
        ins_lst_reg = {ins_lst_reg[16*3*INS_PD_RND - 49:0],48'd0};
    end
    endtask

    //task 初始化寄存器
    task init_regs(
        input [255:0] ins_op_mode,
        input [255:0] ins_type,
        input [255:0] ins_op_num_a,
        input [255:0] ins_op_num_b,
        input [255:0] ins_op_num_r
    );
    begin
        write_ins(INS_NULL,INS_NULL,OP_X0,OP_X0,OP_X2);
        @(posedge clk);
    end
    endtask
endmodule

