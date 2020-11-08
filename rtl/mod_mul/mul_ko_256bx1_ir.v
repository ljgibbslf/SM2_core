`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         SHU
// Engineer:        lf
// 
// Create Date:    10:24:31 04/10/2020 
// Design Name: 
// Module Name:    mul_ko_256bx1_ir 
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
// 使用 128b 乘法器搭建 256b 乘法器，使用 k =2 的 KO 分治算法
// 其中使用的 128b 乘法器本身基于分治算法，运算周期 4，寄存器输出
// 串行版本，使用 1 个128b乘法器
// 输入打拍，直接输出
//////////////////////////////////////////////////////////////////////////////////
module mul_ko_256bx1_ir(
    input           clk,
    input           rst_n,

    input           mul_vld_i,//运算有效信号

    input [255:0]   mul_a_i,
    input [255:0]   mul_b_i,

    output          mul_fin_o,
    output  [511:0] mul_r_o
);

//输入信号分割 {A,B}x{C,D} 与预处理
reg [127:0]         mul_A;
reg [127:0]         mul_B;
reg [127:0]         mul_C;
reg [127:0]         mul_D;
reg [128:0]         mul_CpD;
reg [128:0]         mul_ApB;
reg [129:0]         mul_ApBxCpD_adj; //129位使用128位乘法器的修正

wire                mul_inpt_lat;

//128位 无符号数乘法 IP
wire [127: 0]       mul_128a_a;
wire [127: 0]       mul_128a_b;
wire [255 : 0]      mul_128a_p;

//乘法器启动信号
wire                mul_128a_ena;
wire                mul_128a_fin;

//乘法器运算结果缓存
reg  [255:0]        mul_AXC_reg;
reg  [255:0]        mul_BXD_reg;

wire                mul_AXC_lat;
wire                mul_BXD_lat;

//运算中间变量
reg  [383:0]        mul_r_mid;   
wire [383:0]        mul_r_mid_1;

//乘法阶段信号
wire                mul_a_inpt_sel;
wire                mul_b_inpt_sel;
wire                mul_c_inpt_sel;

//运行状态机
`define STT_W   11
`define STT_W1 `STT_W - 1

reg [`STT_W1:0]   state;
reg [`STT_W1:0]   nxt_state;

localparam IDLE                     = `STT_W'h1;
localparam INPT_REG                 = `STT_W'h2;
localparam MULA_0                   = `STT_W'h4;
localparam MULA_1                   = `STT_W'h8;
localparam MULA_2                   = `STT_W'h10;
localparam MULB_0                   = `STT_W'h20;
localparam MULB_1                   = `STT_W'h40;
localparam MULB_2                   = `STT_W'h80;
localparam MULC_0                   = `STT_W'h100;
localparam MULC_1                   = `STT_W'h200;
localparam FIN_ADD                  = `STT_W'h400;

//缓存乘法器运算结果
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_AXC_reg              <= 256'b0;
        mul_BXD_reg              <= 256'b0;
    end else if(mul_AXC_lat) begin
        mul_AXC_reg              <= mul_128a_p;
    end else if(mul_BXD_lat) begin
        mul_BXD_reg              <= mul_128a_p;
    end
end

assign              mul_AXC_lat =   state == MULA_2;
assign              mul_BXD_lat =   state == MULB_2;


//输入信号分割 {A,B}x{C,D}并寄存
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        {mul_A,mul_B}   <=   256'd0;
        {mul_C,mul_D}   <=   256'd0;
    end else if(mul_inpt_lat)begin
        {mul_A,mul_B}   <=   mul_a_i;
        {mul_C,mul_D}   <=   mul_b_i;
    end
end

assign              mul_inpt_lat    =   (state == IDLE) && mul_vld_i;

//使用寄存器进行 mul_ApBxCpD_adj 的累加，减少关键路径
always @(posedge clk or negedge rst_n) begin
    if(~rst_n | state == IDLE) begin
        mul_ApBxCpD_adj              <= 129'b0;
    end else if(state == MULA_0 && mul_CpD[0])begin
        mul_ApBxCpD_adj              <= mul_ApBxCpD_adj + mul_ApB;
    end else if(state == MULA_1 && mul_ApB[0])begin
        mul_ApBxCpD_adj              <= mul_ApBxCpD_adj + mul_CpD;
    end else if(state == MULA_2 && mul_ApB[0] && mul_CpD[0])begin
        mul_ApBxCpD_adj              <= mul_ApBxCpD_adj - 1'b1;
    end
end

//切断路径上的加法器
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_CpD     <=   129'd0;
        mul_ApB     <=   129'd0;
    end else if(state == INPT_REG)begin
        mul_CpD     <=   mul_D + mul_C; 
        mul_ApB     <=   mul_B + mul_A;
    end
end

//控制乘法器的输入 
assign              mul_128a_a  =   mul_a_inpt_sel ? mul_A :
                                    mul_b_inpt_sel ? mul_B :
                                    mul_c_inpt_sel ? mul_CpD[128-:128] :
                                    128'd0;
assign              mul_128a_b  =   mul_a_inpt_sel ? mul_C :
                                    mul_b_inpt_sel ? mul_D :
                                    mul_c_inpt_sel ? mul_ApB[128-:128] :
                                    128'd0;

assign              mul_a_inpt_sel   =   state == INPT_REG   || state == MULA_0  || state == MULA_1  ;
assign              mul_b_inpt_sel   =   state == MULA_2 || state == MULB_0  || state == MULB_1;
assign              mul_c_inpt_sel   =   state == MULB_2  || state == MULC_0 || state == MULC_1;//|| state == MULC_0;

//乘法器启动信号,分为三次运算
assign              mul_128a_ena     =  state == INPT_REG || state == MULA_2 || state == MULB_2;

//运算中间变量 mul_cyc_3 运算 此处保留左移128bit，以减少运算位
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_r_mid              <= 384'b0;
    end else if(state == MULC_0)begin//{AC,BD}
        mul_r_mid              <= {mul_AXC_reg,mul_BXD_reg[255-:128]} - {128'd0,mul_AXC_reg} - {128'd0,mul_BXD_reg}; 
    end
end

//运算结果 mul_cyc_4 运算 此处保留左移128bit，以减少运算位
// always @(posedge clk or negedge rst_n) begin
//     if(~rst_n) begin
//         mul_r_mid_1              <= 384'b0;
//     end else if(state == MULC_0)begin //mul_64r_ApBxCpD
//         mul_r_mid_1              <= {mul_128a_p,2'b00} + mul_r_mid + {mul_ApBxCpD_adj};//mul_64r_ApBxCpD 需要修正
//     end
// end
assign              mul_r_mid_1 =   {mul_128a_p,2'b00} + mul_r_mid + {mul_ApBxCpD_adj};

//实现状态机
always @(*) begin
    case (state)
        IDLE: begin
            if(mul_vld_i)
                nxt_state   =   INPT_REG;
            else
                nxt_state   =   IDLE;
        end
        INPT_REG: 
            nxt_state   =   MULA_0;
        MULA_0: 
            nxt_state   =   MULA_1;
        MULA_1: 
            nxt_state   =   MULA_2;
        MULA_2: 
            nxt_state   =   MULB_0;
        MULB_0: 
            nxt_state   =   MULB_1;
        MULB_1: 
            nxt_state   =   MULB_2;
        MULB_2: 
            nxt_state   =   MULC_0;
        MULC_0: 
            nxt_state   =   MULC_1;
        MULC_1: 
            nxt_state   =   FIN_ADD;
        FIN_ADD: 
            nxt_state   =   IDLE;
        default: 
            nxt_state   =   IDLE;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        state   <=  `STT_W'b1;
    else begin
        state   <=  nxt_state;
    end  
end

//128位分治算法乘法器，运算周期 4，寄存器输出
mul_ko_128b U_mul_128_a (
    .clk(clk), 
    .rst_n(rst_n), 
    .mul_vld_i(mul_128a_ena), 
    .mul_a_i(mul_128a_a), 
    .mul_b_i(mul_128a_b), 
    .mul_r_o(mul_128a_p),
    .mul_fin_o(mul_128a_fin)
    );

assign                  mul_fin_o   =   state == FIN_ADD;
assign                  mul_r_o     =   {mul_r_mid_1,mul_BXD_reg[127:0]};

endmodule
