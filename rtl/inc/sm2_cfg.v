`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author:        ljgibbs@OpenIC SIG / lf_gibbs@163.com 
// Create Date: 2020/11/08 
// Design Name: sm2
// Module Name: sm2_cfg
// Description:
//      SM2 模块配置信息
// Dependencies: 
//      
// Revision:
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
//定义设计阶段-----------------------------
`define DESIGN_SIM
// `define DESIGN_FPGA

//定义实际 FPGA IP 的名称
`define FPAG_IP_MODULE_NAME mul_64b

//模块调试开关-----------------------------
`ifdef  DESIGN_SIM
    
`endif

//软件模型相关设置----------------------------
// `define C_MODEL_SELF_TEST

//定义仿真器 define simulator
// Modelsim_10_5(windows), default 
// EpicSim (Linux)
//`define EPICSIM
`ifndef EPICSIM
    `define MODELSIM_10_5
`endif

//定义是否使用 C 语言参考模型(DPI)
//define using C reference model or not
// `define C_MODEL_ENABLE

//定义是否 dump 波形
//define dump wave in VCD or not
//`define VCD_DUMP_ENABLE

//定义SM2寄存器地址位宽
`define SM2_REG_ADDR_W  32
`define SM2_REG_ADDR_W1 (SM2_REG_ADDR_W - 1'b1)