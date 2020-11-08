`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         SHU
// Engineer:        lf
// 
// Create Date:    11:24:31 04/10/2020 
// Design Name: 
// Module Name:    mul_ko_256bx3_ir 
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
// 并行版本，使用 3 个128b乘法器
// 输入打拍，直接输出:5clk
//////////////////////////////////////////////////////////////////////////////////
module mul_ko_256bx3_ir(
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

//128位 无符号数乘法 IP
wire [127: 0]       mul_128a_a;
wire [127: 0]       mul_128a_b;
wire [255 : 0]      mul_128a_p;

wire [127: 0]       mul_128b_a;
wire [127: 0]       mul_128b_b;
wire [255 : 0]      mul_128b_p;

wire [127: 0]       mul_128c_a;
wire [127: 0]       mul_128c_b;
wire [255 : 0]      mul_128c_p;

//对有效信号取上升沿，并产生运算结束信号
reg                 mul_vld_r1;
wire                mul_vld_redge;
reg                 mul_fin;

//处理cycle标志
wire                mul_cyc_0;
reg                 mul_cyc_1,mul_cyc_2,mul_cyc_3,mul_cyc_4,mul_cyc_5,mul_cyc_6;

//运算中间变量
reg  [383:0]        mul_r_mid;   
reg  [383:0]        mul_r_mid_1;
wire [383:0]        mul_w_mid_1;

//输入信号分割 {A,B}x{C,D}并寄存
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        {mul_A,mul_B}   <=   256'd0;
        {mul_C,mul_D}   <=   256'd0;
    end else begin
        {mul_A,mul_B}   <=   mul_a_i;
        {mul_C,mul_D}   <=   mul_b_i;
    end
end

//切断路径上的加法器
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_CpD     <=   65'd0;
        mul_ApB     <=   65'd0;
    end else if(mul_cyc_1)begin
        mul_CpD     <=   mul_D + mul_C; 
        mul_ApB     <=   mul_B + mul_A;
    end
end

//使用寄存器进行 mul_ApBxCpD_adj 的累加，减少关键路径
always @(posedge clk or negedge rst_n) begin
    if(~rst_n | mul_cyc_0) begin
        mul_ApBxCpD_adj              <= 129'b0;
    end else if(mul_cyc_2 && mul_CpD[0])begin
        mul_ApBxCpD_adj              <= mul_ApBxCpD_adj + mul_ApB;
    end else if(mul_cyc_3 && mul_ApB[0])begin
        mul_ApBxCpD_adj              <= mul_ApBxCpD_adj + mul_CpD;
    end else if(mul_cyc_4 && mul_ApB[0] && mul_CpD[0])begin
        mul_ApBxCpD_adj              <= mul_ApBxCpD_adj - 1'b1;
    end
end


//分配乘法器的输入 乘法器A分配 AxC B分配 BxD C分配（A+B）x（C+D）
assign              mul_128a_a  =   mul_A;
assign              mul_128a_b  =   mul_C;
assign              mul_128b_a  =   mul_B;
assign              mul_128b_b  =   mul_D;
assign              mul_128c_a  =   mul_CpD[128-:128];//129位使用128位乘法器
assign              mul_128c_b  =   mul_ApB[128-:128];//129位使用128位乘法器

//对有效信号取上升沿，并产生运算结束信号
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_vld_r1              <= 1'b0;
    end else begin
        mul_vld_r1              <= mul_vld_i;
    end
end

assign              mul_vld_redge   =   mul_vld_i && ~mul_vld_r1;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_fin              <= 1'b0;
    end else begin
        mul_fin              <= mul_cyc_4;
    end
end

//处理cycle标志
assign              mul_cyc_0       =   mul_vld_redge;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        {mul_cyc_1,mul_cyc_2,mul_cyc_3,mul_cyc_4,mul_cyc_5,mul_cyc_6}<= 6'b0;
    end else begin
        {mul_cyc_1,mul_cyc_2,mul_cyc_3,mul_cyc_4,mul_cyc_5,mul_cyc_6}<= 
        {mul_cyc_0,mul_cyc_1,mul_cyc_2,mul_cyc_3,mul_cyc_4,mul_cyc_5};
    end
end

//运算中间变量 mul_cyc_3 运算 此处保留左移128bit，以减少运算位
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_r_mid              <= 384'b0;
    end else if(mul_cyc_4)begin//{AC,BD}
        mul_r_mid              <= {mul_128a_p,mul_128b_p[255-:128]} - {128'd0,mul_128a_p} - {128'd0,mul_128b_p}; 
    end
end

//运算结果 mul_cyc_4 运算 此处保留左移128bit，以减少运算位
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_r_mid_1              <= 384'b0;
    end else if(mul_cyc_5)begin //mul_64r_ApBxCpD
        mul_r_mid_1              <= {mul_128c_p,2'b00} + mul_r_mid + {mul_ApBxCpD_adj};//mul_64r_ApBxCpD 需要修正
    end
end

assign  mul_w_mid_1 =   {mul_128c_p,2'b00} + mul_r_mid + {mul_ApBxCpD_adj};

//128位分治算法乘法器，运算周期 4，寄存器输出
mul_ko_128b U_mul_128_a (
    .clk(clk), 
    .rst_n(rst_n), 
    .mul_vld_i(mul_vld_i), 
    .mul_a_i(mul_128a_a), 
    .mul_b_i(mul_128a_b), 
    .mul_r_o(mul_128a_p),
    .mul_fin_o()
    );

mul_ko_128b U_mul_128_b (
    .clk(clk), 
    .rst_n(rst_n), 
    .mul_vld_i(mul_vld_i), 
    .mul_a_i(mul_128b_a), 
    .mul_b_i(mul_128b_b), 
    .mul_r_o(mul_128b_p),
    .mul_fin_o()
    );

mul_ko_128b U_mul_128_c (
    .clk(clk), 
    .rst_n(rst_n), 
    .mul_vld_i(mul_vld_r1), //等待加法结束后的一周期开始
    .mul_a_i(mul_128c_a), 
    .mul_b_i(mul_128c_b), 
    .mul_r_o(mul_128c_p),
    .mul_fin_o()
    );

//输出控制
assign              mul_fin_o       =       mul_fin;
//此处恢复低128bit
assign              mul_r_o         =       {mul_w_mid_1,mul_128b_p[127:0]};

endmodule