`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:         SHU
// Engineer:        lf
// 
// Create Date:    09:49:50 04/01/2020 
// Design Name: 
// Module Name:    mul_ko_128b 
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
//使用 64b 乘法器搭建 128b 乘法器，使用 k =2 的 KO 分治算法
//包括 2 个 256b 加法器，进行 3 次乘法，4次加减法
//使用 2 个 128 bit 中间变量寄存器，以及256bit 结果寄存器 
//计算 {A,B}x{C,D}
//cyc0:   M=B x D    P=B+D   Q=A+C
//cyc1:   N=A x C    S = {M,N} - (N << 64)
//cyc2:   S = S - (M << 64)  T = P X Q  S = S + T
//关键路径：乘法+加法
//延迟： 3clk+1clk（输出寄存器）
//////////////////////////////////////////////////////////////////////////////////
module mul_ko_128b(
    input           clk,
    input           rst_n,

    input           mul_vld_i,//运算有效信号

    input [127:0]   mul_a_i,
    input [127:0]   mul_b_i,

    output          mul_fin_o,
    output [255:0]  mul_r_o
);

//本地参数
`define  USE_192B_ADD_SUB  //使用192b加减法器 替代 256b 加减法器

//输入信号分割 {A,B}x{C,D} 与预处理
wire [63:0]         mul_A;
wire [63:0]         mul_B;
wire [63:0]         mul_C;
wire [63:0]         mul_D;
reg  [64:0]         mul_CpD;
reg  [64:0]         mul_ApB;
reg  [65:0]         mul_ApBxCpD_adj; //65位使用64位乘法器的修正

//64位 无符号数乘法 IP
wire [63 : 0]       mul_64a_a;
wire [63 : 0]       mul_64a_b;
wire [127 : 0]      mul_64a_p;

//乘法器输出寄存器
reg  [127:0]        mul_64r_BxD;
reg  [127:0]        mul_64r_AxC;
reg  [127:0]        mul_64r_ApBxCpD;

//对有效信号取上升沿，并产生运算结束信号
reg                 mul_vld_r1;
reg                 mul_vld_r2;
reg                 mul_vld_r3;
wire                mul_vld_redge;
reg                 mul_fin;

//处理cycle标志
wire                mul_cyc_0;
wire                mul_cyc_1;
wire                mul_cyc_2;

//运算中间变量
`ifdef USE_192B_ADD_SUB
reg  [191:0]       mul_r_mid;      
reg  [191:0]       mul_r_mid_1;    
`else
reg  [255:0]       mul_r_mid;      
reg  [255:0]       mul_r_mid_1;   
`endif  

//复用一个64b加法器
wire [63:0]         add_64b_a;
wire [63:0]         add_64b_b;
wire [64:0]         add_64b_r;

//输入信号分割 {A,B}x{C,D}
assign              {mul_A,mul_B}   =   mul_a_i;
assign              {mul_C,mul_D}   =   mul_b_i;

//复用一个64b加法器
assign              add_64b_r = add_64b_a + add_64b_b;
assign              add_64b_a = mul_cyc_0 ? mul_A:mul_C;
assign              add_64b_b = mul_cyc_0 ? mul_B:mul_D;

//切断路径上的加法器
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_CpD     <=   65'd0;
        mul_ApB     <=   65'd0;
    end else if(mul_cyc_0)begin //并行进行加法
        mul_ApB     <=   mul_A + mul_B; 
        mul_CpD     <=   mul_C + mul_D; 
    // end else if(mul_cyc_1)begin
    end
end

//乘法器输入控制
assign              mul_64a_a   =   mul_cyc_0 ? mul_B:
                                    mul_cyc_1 ? mul_A:
                                    mul_cyc_2 ? mul_CpD[64-:64]://直接取高位会损失精度，需要补偿
                                    64'd0
                                    ;
assign              mul_64a_b   =   mul_cyc_0 ? mul_D:
                                    mul_cyc_1 ? mul_C:
                                    mul_cyc_2 ? mul_ApB[64-:64]:
                                    64'd0
                                    ;

//对乘法进行修正
//假设 mul_CpD[0] && ~mul_ApB[0] 则代表少加了 mul_ApB，反之相同
//假设 mul_CpD[0] &&  mul_ApB[0] 则代表少加了 mul_ApB mul_CpD，多加了 1，修正之
// assign              mul_ApBxCpD_adj =   mul_cyc_2 ? (
//                                         ( mul_CpD[0] && ~mul_ApB[0])? mul_ApB :
//                                         (~mul_CpD[0] &&  mul_ApB[0])? mul_CpD :
//                                         ( mul_CpD[0] &&  mul_ApB[0])? mul_ApB + mul_CpD - 1'b1:
//                                         65'd0):
//                                         65'd0
//                                     ;

//为了使修正电路退出关键路径，改为触发器类型
always @(posedge clk or negedge rst_n) begin
    if(~rst_n | mul_cyc_0) begin
        mul_ApBxCpD_adj              <= 65'b0;
    end else if(mul_cyc_1)begin
        mul_ApBxCpD_adj              <=( mul_CpD[0] && ~mul_ApB[0])? mul_ApB :
                                    (~mul_CpD[0] &&  mul_ApB[0])? mul_CpD :
                                    ( mul_CpD[0] &&  mul_ApB[0])? mul_ApB + mul_CpD - 1'b1:
                                    65'd0;
    end
end

//乘法器输出寄存器
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_64r_BxD        <=  128'd0;
        mul_64r_AxC        <=  128'd0; //并未实际使用
        mul_64r_ApBxCpD    <=  128'd0; //并未实际使用
    end else begin
        mul_64r_BxD        <=  mul_cyc_0 ? mul_64a_p : mul_64r_BxD    ;
        mul_64r_AxC        <=  mul_cyc_1 ? mul_64a_p : mul_64r_AxC    ;
        mul_64r_ApBxCpD    <=  mul_cyc_2 ? mul_64a_p : mul_64r_ApBxCpD;
    end
end

//对有效信号取上升沿，并产生运算结束信号
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_vld_r1              <= 1'b0;
        mul_vld_r2              <= 1'b0;
        mul_vld_r3              <= 1'b0;
    end else begin
        mul_vld_r1              <= mul_vld_i;
        mul_vld_r2              <= mul_vld_r1;
        mul_vld_r3              <= mul_vld_r2;
    end
end

assign              mul_vld_redge   =   mul_vld_i && ~mul_vld_r1;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_fin              <= 1'b0;
    end else begin
        mul_fin              <= mul_cyc_2;
    end
end
//处理cycle标志
assign              mul_cyc_0       =   mul_vld_i && ~mul_vld_r1;
assign              mul_cyc_1       =   mul_vld_r1 && ~mul_vld_r2;
assign              mul_cyc_2       =   mul_vld_r2 && ~mul_vld_r3;


//运算中间变量 mul_cyc_1 运算
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_r_mid              <= 256'b0;
    end else if(mul_cyc_1)begin//mul_64a_p 此时为 mul_64r_AxC
        `ifdef USE_192B_ADD_SUB
        mul_r_mid              <= {mul_64a_p,mul_64r_BxD[127-:64]} - mul_64a_p - mul_64r_BxD; //-{mul_64r_AxC,64'd0} -{mul_64r_BxD,64'd0} 
        `else
        mul_r_mid              <= {mul_64a_p,mul_64r_BxD} - {64'd0,mul_64a_p,64'd0} - {64'd0,mul_64r_BxD,64'd0}; //-{mul_64r_AxC,64'd0} -{mul_64r_BxD,64'd0} 
        `endif
    end
end

//运算结果 mul_cyc_2 运算
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        mul_r_mid_1              <= 256'b0;
    end else if(mul_cyc_2)begin //mul_64a_p 此时为 mul_64r_ApBxCpD
        `ifdef USE_192B_ADD_SUB
        mul_r_mid_1              <= {mul_64a_p,2'b00} + mul_r_mid + mul_ApBxCpD_adj;//mul_64r_ApBxCpD 需要修正        `endif
        `else
        mul_r_mid_1              <= {mul_64a_p,2'b00,64'h0} + mul_r_mid + {mul_ApBxCpD_adj,64'h0};//mul_64r_ApBxCpD 需要修正
        `endif
    end
end

//64位 无符号数乘法 IP
mul_64b_wrapper U_mul_64_a (
  .a(mul_64a_a), // input [63 : 0] a
  .b(mul_64a_b), // input [63 : 0] b
  .p(mul_64a_p) //  output [127 : 0] p
);

//输出控制
assign              mul_fin_o       =       mul_fin;

`ifdef USE_192B_ADD_SUB
assign              mul_r_o         =       {mul_r_mid_1,mul_64r_BxD[63:0]};
`else
assign              mul_r_o         =       mul_r_mid_1;
`endif

endmodule
