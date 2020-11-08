`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         SHU
// Engineer:        lf
// 
// Create Date:    23:16:54 04/13/2020 
// Design Name: 
// Module Name:    point_cal_top 
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
//  点运算顶层 
//      由运算单元，存储单元以及控制单元组成
//      顶层包括一个指令输入FIFO接口,以及一个结果FIFO读取接口
//////////////////////////////////////////////////////////////////////////////////
module point_cal_top(
    input           clk,
    input           rst_n,

    // input [31:0]    ins_fifo_data_i,
    // input           ins_fifo_wena_i,
    // input           ins_fifo_rdy_i,

    // input           res_fifo_rena_i,
    // output[31:0]    res_fifo_rdata_o,
    // output          res_fifo_ept_o,

    input  [15:0]   ins_0_i,
    input  [15:0]   ins_1_i,
    input  [15:0]   ins_2_i,
    input           ins_vld_i,

    //数据接口
    input  [255:0]  data_path_i,
    // input           data_path_vld_i,

    output [255:0]  var_x2_o,
    output [255:0]  var_y2_o,
    output [255:0]  var_z2_o,

    output          intr_cal_done_o
);
localparam          OP_NUM_SEL_X2 = 4'b0,OP_NUM_SEL_Y2 = 4'd1,OP_NUM_SEL_Z2 = 4'd2;
localparam          OP_NUM_SEL_T0 = 4'd3,OP_NUM_SEL_T1 = 4'd4,OP_NUM_SEL_T2 = 4'd5;
localparam          OP_NUM_CNST_X0 = 4'd6,OP_NUM_CNST_Y0 = 4'd7,OP_NUM_CNST_Z0 = 4'd8,OP_NUM_CNST_X1 = 4'd9,OP_NUM_CNST_Y1 = 4'd10,OP_NUM_CNST_Z1 = 4'd11;
localparam          OP_NUM_CNST_P256 = 4'd12;

localparam          OP_MUL = 2'b00;
localparam          OP_ADD = 2'b01;
localparam          OP_SUB = 2'b10;

localparam          INS_CAL         = 2'b00;
localparam          INS_UPDT_REG    = 2'b01;
localparam          INS_FIN         = 2'b10;

//存储单元
reg [255:0]         cfg_prim_num;
wire                cfg_prim_num_updt_en;

wire [255:0]    P256 = {
    8'hFF, 8'hFF, 8'hFF, 8'hFE, 8'hFF, 8'hFF, 8'hFF, 8'hFF, /* p */
    8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF,
    8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h00, 8'h00, 8'h00, 8'h00,
    8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF 
    } ;

wire [255:0]    Gx = 256'h32C4AE2C1F1981195F9904466A39C9948FE30BBFF2660BE1715A4589334C74C7;

wire [255:0]    Gy = 256'hBC3736A2F4F6779C59BDCEE36B692153D0A9877CC62A474002DF32E52139F0A0;

//常量 2个运算点的三维坐标
reg [255:0]         cnst_x0,cnst_y0,cnst_z0,cnst_x1,cnst_y1,cnst_z1;
// wire                cnst_x0_updt_en,cnst_y0_updt_en,cnst_z0_updt_en;
// wire                cnst_x1_updt_en,cnst_y1_updt_en,cnst_z1_updt_en;

//变量 3个结果坐标以及3个临时变量
reg [255:0]         var_x2,var_y2,var_z2,var_t0,var_t1,var_t2;
wire[1:0]           var_x2_updt_en,var_y2_updt_en,var_z2_updt_en,var_t0_updt_en,var_t1_updt_en,var_t2_updt_en;

//控制单元
//从变量寄存器以及常量中选择操作数
wire [3:0]          op_mod_0_a_sel,op_mod_0_b_sel,op_mod_1_a_sel,op_mod_1_b_sel,op_mod_2_a_sel,op_mod_2_b_sel; 

//指令控制状态机
`define STT_W 5
`define STT_W1 `STT_W - 1

reg [`STT_W1:0]   state;
reg [`STT_W1:0]   nxt_state;

localparam IDLE                     = `STT_W'h1;
localparam CAL                      = `STT_W'h2;
localparam FETCH                    = `STT_W'h4;
localparam UPDT_REG                 = `STT_W'h8;
localparam FIN                      = `STT_W'h10;


//各操作数常量选择
// wire [255:0]        op_mod_0_a_cnst,op_mod_0_b_cnst,op_mod_1_a_cnst,op_mod_1_b_cnst,op_mod_2_a_cnst,op_mod_2_b_cnst;  
// wire [3:0]          op_mod_0_a_cnst_sel,op_mod_0_b_cnst_sel,op_mod_1_a_cnst_sel,op_mod_1_b_cnst_sel,op_mod_2_a_cnst_sel,op_mod_2_b_cnst_sel;  

//运算数与结果
wire [255:0]        op_mod_0_a,op_mod_0_b,op_mod_0_r;
wire [255:0]        op_mod_1_a,op_mod_1_b,op_mod_1_r;
wire [255:0]        op_mod_2_a,op_mod_2_b,op_mod_2_r;

//运算单元
wire                mod_0_done,mod_1_done,mod_2_done;  
wire                mod_0_start,mod_1_start,mod_2_start;  
wire[1:0]           op_sel_0,op_sel_1,op_sel_2;
wire                op_done;//运算完成信号

//取指令中的信息
wire [1:0]          ins_type_0,ins_type_1,ins_type_2;
wire [1:0]          ins_op_mod_0,ins_op_mod_1,ins_op_mod_2;
wire [7:0]          ins_op_num_ab_0,ins_op_num_ab_1,ins_op_num_ab_2;
wire [3:0]          ins_op_r_0,ins_op_r_1,ins_op_r_2;
wire [3:0]          ins_updt_reg_id;

assign              {ins_op_mod_0,ins_type_0,ins_op_num_ab_0,ins_op_r_0}   =   ins_0_i;
assign              {ins_op_mod_1,ins_type_1,ins_op_num_ab_1,ins_op_r_1}   =   ins_1_i;
assign              {ins_op_mod_2,ins_type_2,ins_op_num_ab_2,ins_op_r_2}   =   ins_2_i;

//实现状态机
always @(*) begin
    case (state)
        IDLE: begin
            if(ins_vld_i)
                if(ins_type_0 == INS_FIN)
                    nxt_state   =   FIN;
                else
                    nxt_state   =   CAL;
            else
                nxt_state   =   IDLE;
        end
        FETCH:begin
            if(ins_type_0 == INS_CAL || ins_type_1 == INS_CAL || ins_type_2 == INS_CAL)
                nxt_state   =   CAL;
            else if(ins_type_0 == INS_UPDT_REG)
                nxt_state   =   UPDT_REG;
        end
        CAL: 
            if(op_done)
                nxt_state   =   IDLE;
                // nxt_state   =   CAL;//连续计算
            else
                nxt_state   =   CAL;
        UPDT_REG:
            nxt_state   =   IDLE;
        FIN:
            nxt_state   =   IDLE;
        default: 
            nxt_state   =   IDLE;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        state   <=  IDLE;
    else begin
        state   <=  nxt_state;
    end  
end

//读取寄存器更新指令中的寄存器id
assign              ins_updt_reg_id    =   ins_op_r_0;

//将运算类型传递给计算单元
assign              op_done =   mod_0_done || mod_1_done || mod_2_done;
// assign              op_done =   mod_0_done;
//单元0
assign              mod_0_start =       state == CAL && ins_type_0 == INS_CAL;//在指令有效的情况下启动运算符
assign              mod_1_start =       state == CAL && ins_type_1 == INS_CAL;
assign              mod_2_start =       state == CAL && ins_type_2 == INS_CAL;
assign              op_sel_0    =       ins_op_mod_0;
assign              op_sel_1    =       ins_op_mod_1;
assign              op_sel_2    =       ins_op_mod_2;

//将指令数据通路信息传递给
assign              {op_mod_0_a_sel,op_mod_0_b_sel} =   ins_op_num_ab_0;
assign              {op_mod_1_a_sel,op_mod_1_b_sel} =   ins_op_num_ab_1;
assign              {op_mod_2_a_sel,op_mod_2_b_sel} =   ins_op_num_ab_2;
assign              var_x2_updt_en  =   ins_op_r_0  == OP_NUM_SEL_X2 ? 2'd1 : ins_op_r_1  == OP_NUM_SEL_X2 ? 2'd2 : ins_op_r_2  == OP_NUM_SEL_X2 ? 2'd3 : 2'd0;
assign              var_y2_updt_en  =   ins_op_r_0  == OP_NUM_SEL_Y2 ? 2'd1 : ins_op_r_1  == OP_NUM_SEL_Y2 ? 2'd2 : ins_op_r_2  == OP_NUM_SEL_Y2 ? 2'd3 : 2'd0;
assign              var_z2_updt_en  =   ins_op_r_0  == OP_NUM_SEL_Z2 ? 2'd1 : ins_op_r_1  == OP_NUM_SEL_Z2 ? 2'd2 : ins_op_r_2  == OP_NUM_SEL_Z2 ? 2'd3 : 2'd0;
assign              var_t0_updt_en  =   ins_op_r_0  == OP_NUM_SEL_T0 ? 2'd1 : ins_op_r_1  == OP_NUM_SEL_T0 ? 2'd2 : ins_op_r_2  == OP_NUM_SEL_T0 ? 2'd3 : 2'd0;
assign              var_t1_updt_en  =   ins_op_r_0  == OP_NUM_SEL_T1 ? 2'd1 : ins_op_r_1  == OP_NUM_SEL_T1 ? 2'd2 : ins_op_r_2  == OP_NUM_SEL_T1 ? 2'd3 : 2'd0;
assign              var_t2_updt_en  =   ins_op_r_0  == OP_NUM_SEL_T2 ? 2'd1 : ins_op_r_1  == OP_NUM_SEL_T2 ? 2'd2 : ins_op_r_2  == OP_NUM_SEL_T2 ? 2'd3 : 2'd0;

//常量寄存器更新初值
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        {cnst_x0,cnst_y0,cnst_z0,cnst_x1,cnst_y1,cnst_z1}              <= {Gx,Gy,256'd1,Gx,Gy,256'd1};//调试用G点
    end else if(state == UPDT_REG)begin
        cnst_x0         <=      ins_updt_reg_id == OP_NUM_CNST_X0 ? data_path_i : cnst_x0; 
        cnst_y0         <=      ins_updt_reg_id == OP_NUM_CNST_Y0 ? data_path_i : cnst_y0; 
        cnst_z0         <=      ins_updt_reg_id == OP_NUM_CNST_Z0 ? data_path_i : cnst_z0; 
        cnst_x1         <=      ins_updt_reg_id == OP_NUM_CNST_X1 ? data_path_i : cnst_x1; 
        cnst_y1         <=      ins_updt_reg_id == OP_NUM_CNST_Y1 ? data_path_i : cnst_y1; 
        cnst_z1         <=      ins_updt_reg_id == OP_NUM_CNST_Z1 ? data_path_i : cnst_z1;         
    end  else if(state == FIN)begin//收到结束指令，默认将前次运算结果装载为运算坐标
        cnst_x0         <=      var_x2; 
        cnst_y0         <=      var_y2; 
        cnst_z0         <=      var_z2; 
               
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        // cfg_prim_num              <= 256'b0;
        cfg_prim_num              <= P256;
    end else if(cfg_prim_num_updt_en && state == UPDT_REG)begin
        cfg_prim_num              <= P256;
    end
end

assign              cfg_prim_num_updt_en    =   ins_updt_reg_id == OP_NUM_CNST_P256;

//变量寄存器更新
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        // {var_x2,var_y2,var_z2,var_t0,var_t1,var_t2}              <= {256'd2,256'd3,256'd4,256'd5,256'd6,256'd7};//调试用
        {var_x2,var_y2,var_z2,var_t0,var_t1,var_t2}              <= 1536'b0;
    end else if(op_done)begin
        var_x2  <=   var_x2_updt_en == 2'd1 ?   op_mod_0_r : var_x2_updt_en == 2'd2 ? op_mod_1_r : var_x2_updt_en == 2'd3 ? op_mod_2_r :  var_x2;     
        var_y2  <=   var_y2_updt_en == 2'd1 ?   op_mod_0_r : var_y2_updt_en == 2'd2 ? op_mod_1_r : var_y2_updt_en == 2'd3 ? op_mod_2_r :  var_y2;     
        var_z2  <=   var_z2_updt_en == 2'd1 ?   op_mod_0_r : var_z2_updt_en == 2'd2 ? op_mod_1_r : var_z2_updt_en == 2'd3 ? op_mod_2_r :  var_z2;     
        var_t0  <=   var_t0_updt_en == 2'd1 ?   op_mod_0_r : var_t0_updt_en == 2'd2 ? op_mod_1_r : var_t0_updt_en == 2'd3 ? op_mod_2_r :  var_t0;     
        var_t1  <=   var_t1_updt_en == 2'd1 ?   op_mod_0_r : var_t1_updt_en == 2'd2 ? op_mod_1_r : var_t1_updt_en == 2'd3 ? op_mod_2_r :  var_t1;     
        var_t2  <=   var_t2_updt_en == 2'd1 ?   op_mod_0_r : var_t2_updt_en == 2'd2 ? op_mod_1_r : var_t2_updt_en == 2'd3 ? op_mod_2_r :  var_t2;     
    end
end

//操作数选择
assign              op_mod_0_a  =   op_mod_0_a_sel == OP_NUM_SEL_X2 ? var_x2:
                                    op_mod_0_a_sel == OP_NUM_SEL_Y2 ? var_y2:
                                    op_mod_0_a_sel == OP_NUM_SEL_Z2 ? var_z2:
                                    op_mod_0_a_sel == OP_NUM_SEL_T0 ? var_t0:
                                    op_mod_0_a_sel == OP_NUM_SEL_T1 ? var_t1:
                                    op_mod_0_a_sel == OP_NUM_SEL_T2 ? var_t2:
                                    op_mod_0_a_sel == OP_NUM_CNST_X0 ? cnst_x0:
                                    op_mod_0_a_sel == OP_NUM_CNST_Y0 ? cnst_y0:
                                    op_mod_0_a_sel == OP_NUM_CNST_Z0 ? cnst_z0:
                                    op_mod_0_a_sel == OP_NUM_CNST_X1 ? cnst_x1:
                                    op_mod_0_a_sel == OP_NUM_CNST_Y1 ? cnst_y1:
                                    op_mod_0_a_sel == OP_NUM_CNST_Z1 ? cnst_z1:
                                    256'd0
                                    ;
assign              op_mod_0_b  =   op_mod_0_b_sel == OP_NUM_SEL_X2 ? var_x2:
                                    op_mod_0_b_sel == OP_NUM_SEL_Y2 ? var_y2:
                                    op_mod_0_b_sel == OP_NUM_SEL_Z2 ? var_z2:
                                    op_mod_0_b_sel == OP_NUM_SEL_T0 ? var_t0:
                                    op_mod_0_b_sel == OP_NUM_SEL_T1 ? var_t1:
                                    op_mod_0_b_sel == OP_NUM_SEL_T2 ? var_t2:
                                    op_mod_0_b_sel == OP_NUM_CNST_X0 ? cnst_x0:
                                    op_mod_0_b_sel == OP_NUM_CNST_Y0 ? cnst_y0:
                                    op_mod_0_b_sel == OP_NUM_CNST_Z0 ? cnst_z0:
                                    op_mod_0_b_sel == OP_NUM_CNST_X1 ? cnst_x1:
                                    op_mod_0_b_sel == OP_NUM_CNST_Y1 ? cnst_y1:
                                    op_mod_0_b_sel == OP_NUM_CNST_Z1 ? cnst_z1:
                                    256'd0
                                    ;

assign              op_mod_1_a  =   op_mod_1_a_sel == OP_NUM_SEL_X2 ? var_x2:
                                    op_mod_1_a_sel == OP_NUM_SEL_Y2 ? var_y2:
                                    op_mod_1_a_sel == OP_NUM_SEL_Z2 ? var_z2:
                                    op_mod_1_a_sel == OP_NUM_SEL_T0 ? var_t0:
                                    op_mod_1_a_sel == OP_NUM_SEL_T1 ? var_t1:
                                    op_mod_1_a_sel == OP_NUM_SEL_T2 ? var_t2:
                                    op_mod_1_a_sel == OP_NUM_CNST_X0 ? cnst_x0:
                                    op_mod_1_a_sel == OP_NUM_CNST_Y0 ? cnst_y0:
                                    op_mod_1_a_sel == OP_NUM_CNST_Z0 ? cnst_z0:
                                    op_mod_1_a_sel == OP_NUM_CNST_X1 ? cnst_x1:
                                    op_mod_1_a_sel == OP_NUM_CNST_Y1 ? cnst_y1:
                                    op_mod_1_a_sel == OP_NUM_CNST_Z1 ? cnst_z1:
                                    256'd0
                                    ;
assign              op_mod_1_b  =   op_mod_1_b_sel == OP_NUM_SEL_X2 ? var_x2:
                                    op_mod_1_b_sel == OP_NUM_SEL_Y2 ? var_y2:
                                    op_mod_1_b_sel == OP_NUM_SEL_Z2 ? var_z2:
                                    op_mod_1_b_sel == OP_NUM_SEL_T0 ? var_t0:
                                    op_mod_1_b_sel == OP_NUM_SEL_T1 ? var_t1:
                                    op_mod_1_b_sel == OP_NUM_SEL_T2 ? var_t2:
                                    op_mod_1_b_sel == OP_NUM_CNST_X0 ? cnst_x0:
                                    op_mod_1_b_sel == OP_NUM_CNST_Y0 ? cnst_y0:
                                    op_mod_1_b_sel == OP_NUM_CNST_Z0 ? cnst_z0:
                                    op_mod_1_b_sel == OP_NUM_CNST_X1 ? cnst_x1:
                                    op_mod_1_b_sel == OP_NUM_CNST_Y1 ? cnst_y1:
                                    op_mod_1_b_sel == OP_NUM_CNST_Z1 ? cnst_z1:
                                    256'd0
                                    ;

assign              op_mod_2_a  =   op_mod_2_a_sel == OP_NUM_SEL_X2 ? var_x2:
                                    op_mod_2_a_sel == OP_NUM_SEL_Y2 ? var_y2:
                                    op_mod_2_a_sel == OP_NUM_SEL_Z2 ? var_z2:
                                    op_mod_2_a_sel == OP_NUM_SEL_T0 ? var_t0:
                                    op_mod_2_a_sel == OP_NUM_SEL_T1 ? var_t1:
                                    op_mod_2_a_sel == OP_NUM_SEL_T2 ? var_t2:
                                    op_mod_2_a_sel == OP_NUM_CNST_X0 ? cnst_x0:
                                    op_mod_2_a_sel == OP_NUM_CNST_Y0 ? cnst_y0:
                                    op_mod_2_a_sel == OP_NUM_CNST_Z0 ? cnst_z0:
                                    op_mod_2_a_sel == OP_NUM_CNST_X1 ? cnst_x1:
                                    op_mod_2_a_sel == OP_NUM_CNST_Y1 ? cnst_y1:
                                    op_mod_2_a_sel == OP_NUM_CNST_Z1 ? cnst_z1:
                                    256'd0
                                    ;
assign              op_mod_2_b  =   op_mod_2_b_sel == OP_NUM_SEL_X2 ? var_x2:
                                    op_mod_2_b_sel == OP_NUM_SEL_Y2 ? var_y2:
                                    op_mod_2_b_sel == OP_NUM_SEL_Z2 ? var_z2:
                                    op_mod_2_b_sel == OP_NUM_SEL_T0 ? var_t0:
                                    op_mod_2_b_sel == OP_NUM_SEL_T1 ? var_t1:
                                    op_mod_2_b_sel == OP_NUM_SEL_T2 ? var_t2:
                                    op_mod_2_b_sel == OP_NUM_CNST_X0 ? cnst_x0:
                                    op_mod_2_b_sel == OP_NUM_CNST_Y0 ? cnst_y0:
                                    op_mod_2_b_sel == OP_NUM_CNST_Z0 ? cnst_z0:
                                    op_mod_2_b_sel == OP_NUM_CNST_X1 ? cnst_x1:
                                    op_mod_2_b_sel == OP_NUM_CNST_Y1 ? cnst_y1:
                                    op_mod_2_b_sel == OP_NUM_CNST_Z1 ? cnst_z1:
                                    256'd0
                                    ;


mul_add_sub_mod_module U_cal_0 (
    .clk(clk), 
    .rst_n(rst_n), 

    .op_vld_i(mod_0_start), 
    .op_sel_i(op_sel_0), 
    .op_mod_num_i(cfg_prim_num),
    // .op_mod_num_i(P256),

    .op_a_i     (op_mod_0_a), 
    .op_b_i     (op_mod_0_b), 
    .op_done_o  (mod_0_done), 
    .op_rslt_o  (op_mod_0_r)
);

mul_add_sub_mod_module U_cal_1 (
    .clk(clk), 
    .rst_n(rst_n), 

    .op_vld_i(mod_1_start), 
    .op_sel_i(op_sel_1), 
    .op_mod_num_i(cfg_prim_num),
    // .op_mod_num_i(P256),

    .op_a_i     (op_mod_1_a), 
    .op_b_i     (op_mod_1_b), 
    .op_done_o  (mod_1_done), 
    .op_rslt_o  (op_mod_1_r)
);

mul_add_sub_mod_module U_cal_2 (
    .clk(clk), 
    .rst_n(rst_n), 

    .op_vld_i(mod_2_start), 
    .op_sel_i(op_sel_2), 
    .op_mod_num_i(cfg_prim_num),
    // .op_mod_num_i(P256),

    .op_a_i     (op_mod_2_a), 
    .op_b_i     (op_mod_2_b), 
    .op_done_o  (mod_2_done), 
    .op_rslt_o  (op_mod_2_r)
);


//输出逻辑
assign  var_x2_o            =   var_x2;
assign  var_y2_o            =   var_y2;
assign  var_z2_o            =   var_z2;
assign  intr_cal_done_o     =   mod_0_done || mod_1_done || mod_2_done;

    always@(intr_cal_done_o)begin
        $display("X2:%X,%X\n",var_x2[255-:128],var_x2[127-:128]);
        $display("Y2:%X,%X\n",var_y2[255-:128],var_y2[127-:128]);
        $display("Z2:%X,%X\n",var_z2[255-:128],var_z2[127-:128]);
        $display("T0:%X,%X\n",var_t0[255-:128],var_t0[127-:128]);
        $display("T1:%X,%X\n",var_t1[255-:128],var_t1[127-:128]);
        $display("T2:%X,%X\n",var_t2[255-:128],var_t2[127-:128]);
    end

endmodule