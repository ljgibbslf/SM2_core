`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         SHU
// Engineer:        lf
// 
// Create Date:    20:41:49 04/13/2020 
// Design Name: 
// Module Name:    spd_mod_sub_stgb  (stage B,阶段B是目前正在使用的模块，替代spd_mod_sub(stage A)) 
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
//  使用快速模约减 b = a mod p256, 0<a<p^2
//  使用 SPD_MOD_PIPE_STAGE 个周期
//  输出端的模约减逻辑在不乘法有效信号无效的情况
//////////////////////////////////////////////////////////////////////////////////
module spd_mod_sub_stgb(
    input           clk,
    input           rst_n,

    input           mod_vld_i,
    input [1:0]     op_sel_i,
    input [255:0]   op_mod_num_i,

    input [511:0]   p512_a,
    
    output[255:0]   op_add_sub_res,

    output          mod_fin_o,
    output reg [255:0]   p256_b
);

`define     SPD_MOD_PIPE_STAGE 3

localparam      OP_MUL = 2'b00;
localparam      OP_ADD = 2'b01;
localparam      OP_SUB = 2'b10;

//模加减相关逻辑
wire [255:0]    op_a;
wire [255:0]    op_b;

wire [255:0]    mod_num_p_cmp; //模减运算时为-p的补码
wire [255:0]    op_b_cmp;//模减运算时为-b的补码
wire            op_is_add;
wire            op_is_sub;

//16个 32bit 字表示 A
reg  [31:0]     m [15:0];

//14个中间变量
wire [255:0]    s [14:0];

//290bit 中间变量
wire [289:0]    a_mid_290;
reg  [289:0]    a_mid_290_tmp;
reg  [289:0]    a_mid_290_tmp_1;

//9个 a_mid_290 的中间变量
reg  [31:0]     mm [8:0]; 

//34bit变量用于累加 s11-s14
reg  [33:0]     s_tmp_11_14;

//输出中间变量
wire [255:0]    t1;
wire [255:0]    t2;
wire [255:0]    t3;
wire [256:0]    out_m;
wire [256:0]    out_m_mod;
wire            out_m_c;//输出==-大于p，需要减去p
wire            out_m_mod_c;//输出==-大于p，需要减去p

//对有效信号取上升沿，并产生运算结束信号
reg                 mod_vld_r1;
wire                mod_vld_redge;

//处理cycle标志
wire                mul_cyc_0;
reg                 mul_cyc_1,mul_cyc_2,mul_cyc_3;

//模数
wire [256:0]        op_mod_num;
wire [256:0]        op_mod_num_cmp;

//常量 p256
wire [255:0]    P256 = {
    8'hFF, 8'hFF, 8'hFF, 8'hFE, 8'hFF, 8'hFF, 8'hFF, 8'hFF, /* p */
    8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF,
    8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h00, 8'h00, 8'h00, 8'h00,
    8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF 
    } ;
//wire [255:0]    P256;
//assign            P256 = op_mod_num_i;

integer i;

//模加减相关逻辑
assign          {op_a,op_b}     =   p512_a;

//模减运算时为-p的补码
assign          mod_num_p_cmp   =   op_is_add ? op_mod_num_i : ( ~op_mod_num_i ) + 1'b1; 
//模减运算时为-b的补码
assign          op_b_cmp        =   op_is_add ? op_b : ( ~op_b ) + 1'b1; 

assign          op_is_add       =   op_sel_i == OP_ADD;
assign          op_is_sub       =   op_sel_i == OP_SUB;
assign          op_is_mul       =   op_sel_i == OP_MUL;

//对有效信号取上升沿，并产生运算结束信号
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mod_vld_r1              <= 1'b0;
    end else begin
        mod_vld_r1              <= mod_vld_i;
    end
end

assign              mod_vld_redge   =   mod_vld_i && ~mod_vld_r1;
//处理cycle标志
assign              mul_cyc_0       =   mod_vld_redge;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        {mul_cyc_1,mul_cyc_2,mul_cyc_3}   <= 3'b0;
    end else if(op_is_mul)begin
        {mul_cyc_1,mul_cyc_2,mul_cyc_3}   <= {mul_cyc_0,mul_cyc_1,mul_cyc_2};
    end
end


always@(*)begin
    for (i = 0; i<=15 ; i = i + 1 ) begin
        m[i] = p512_a[32*(i + 1) - 1 -:32];
    end
end

always@(*)begin
    for (i = 0; i<=8 ; i = i + 1 ) begin
        mm[i] = a_mid_290[32*(i + 1) - 1 -:32];
    end
end

assign      s[0] =    {32'h0	,32'h0	,32'h0	,32'h0	,32'h0	,32'h0	, 32'h0	,32'h0};
assign      s[1] =    {m[7] 	,m[6]	,m[5]	,m[4]	,m[3]	,m[2]	,m[1]	,m[0]};
assign      s[2] =    {m[15]	,m[14]	,m[13]	,m[12]	,m[11]	,32'h0	,m[9]	,m[8]};
assign      s[3] =    {m[14]	,32'h0	,m[15]	,m[14]	,m[13]	,32'h0	,m[14]	,m[13]};
assign      s[4] =    {m[13]	,32'h0	,32'h0	,32'h0	,32'h0	,32'h0	,m[15]	,m[14]};
assign      s[5] =    {m[12]	,32'h0	,32'h0	,32'h0	,32'h0	,32'h0	,32'h0	,m[15]};
assign      s[6] =    {m[11]	,m[11]	,m[10]	,m[15]	,m[14]	,32'h0	,m[13]	,m[12]};
assign      s[7] =    {m[10]	,m[15]	,m[14]	,m[13]	,m[12]	,32'h0	,m[11]	,m[10]};
assign      s[8] =    {m[9] 	,32'h0	,32'h0	,m[9]	,m[8]	,32'h0	,m[10]	,m[9]};
assign      s[9] =    {m[8] 	,32'h0	,32'h0	,32'h0	,m[15]	,32'h0	,m[12]	,m[11]};
assign      s[10] =   {m[15]	,32'h0	,32'h0	,32'h0	,32'h0	,32'h0	,32'h0	,32'h0};
assign      s[11] =   {32'h0	,32'h0	,32'h0	,32'h0	,32'h0	, m[14]	, 32'h0	,32'h0};
assign      s[12] =   {32'h0	,32'h0	,32'h0	,32'h0	,32'h0	, m[13]	, 32'h0	,32'h0};
assign      s[13] =   {32'h0	,32'h0	,32'h0	,32'h0	,32'h0	, m[9]	, 32'h0	,32'h0};
assign      s[14] =   {32'h0	,32'h0	,32'h0	,32'h0	,32'h0	, m[8]	, 32'h0	,32'h0};
// assign      a_mid_290 = s[1]+s[2]+2*(s[3]+s[4]+s[5]+s[10])+s[6]+s[7]+s[8]+s[9]-(s[11]+s[12]+s[13]+s[14]);
assign      a_mid_290 = a_mid_290_tmp_1;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        s_tmp_11_14                <= 34'd0;
        a_mid_290_tmp              <= 290'b0;
        a_mid_290_tmp_1            <= 290'b0;
    end else if(mul_cyc_0)begin
        s_tmp_11_14                <= m[14]+m[13]+m[9]+m[8];
        a_mid_290_tmp              <= s[1]+s[2]+2*(s[3]+s[4]+s[5]+s[10])+s[6]+s[7] ;
    end else if(mul_cyc_1)begin
        a_mid_290_tmp_1            <= a_mid_290_tmp-{s_tmp_11_14,64'h0}+s[8]+s[9];
    end
end

//通过选择模约减加减法器，复用为模加减运算
assign      t1  =   op_is_mul ? {mm[7],mm[6],mm[5],mm[4],mm[3],mm[2],mm[1],mm[0]}
                    :   op_a;
assign      t2  =   op_is_mul ? {mm[8], 32'h0,32'h0,32'h0,mm[8],32'h0,32'h0,mm[8]}
                    :   op_b_cmp;
assign      t3  =   op_is_mul ? {32'h0,32'h0,32'h0,32'h0,32'h0, mm[8], 32'h0,32'h0}
                    :   256'd0;
assign      op_mod_num = (op_is_mul || op_is_add) ? op_mod_num_cmp : op_mod_num_i;
assign      op_mod_num_cmp  =   {1'b1,{~op_mod_num_i + 1'b1}};
//输出
assign          out_m           = t1 + t2 - t3;         //第一阶段运算数 加/减
assign          out_m_mod       = out_m + op_mod_num; //模约减时减去P  //第二阶段 运算结果与模数减/加
// assign          out_m_mod       = out_m - op_mod_num_i;   //第二阶段 运算结果与模数减/加

assign          out_m_c         =   out_m[256];    //第一阶段加减法进位
assign          out_m_mod_c     =   out_m_mod[256];//第二阶段取模加减法进位

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        p256_b              <= 256'b0;
    end else if(mul_cyc_2)begin
        p256_b <= out_m_mod_c ? out_m[255:0] : out_m_mod[255:0];
    end
end

//输出控制
assign              mod_fin_o       =       op_is_sub || op_is_add ? mul_cyc_0 : mul_cyc_3;

//复用模加模减逻辑输出
assign              op_add_sub_res  =       ( (out_m_mod_c && op_is_add) || (out_m_c && op_is_sub))?  //加法：第二阶段减法进位(结果为负)，减法：第一阶段加法进位(结果为正)，取第一阶段结果
                                            out_m[255:0]
                                        :   out_m_mod[255:0]
                                        ;
endmodule
