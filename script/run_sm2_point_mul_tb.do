#////////////////////////////////////////////////////////////////////////////////
# Author:        ljgibbs / lf_gibbs@163.com
# Create Date: 2020/07/28 
# Design Name: sm2
# Module Name: run_sm2_point_mul_tb
# Description:
#      运行 sm2 点乘模块 tb 的 Modelsim 脚本
#          - 使用相对路径
#          - 使用库 sm2_core
# Revision:
# Revision 0.01 - File Created
#////////////////////////////////////////////////////////////////////////////////

vlib sm2_core

vlog  -work sm2_core "../rtl/ip_wrapper/mul_64b_sim_model.v"
vlog  -work sm2_core "../rtl/ip_wrapper/mul_64b_wrapper.v"
vlog  -work sm2_core "../rtl/mod_mul/mul_ko_128b.v"
vlog  -work sm2_core "../rtl/spd_mod_sub/spd_mod_sub_stgb.v"
vlog  -work sm2_core "../rtl/mod_mul/mul_ko_256b.v"
vlog  -work sm2_core "../rtl/point_mul/mul_add_sub_mod_module.v"
vlog  -work sm2_core "../rtl/point_mul/point_cal_top.v"
vlog  -work sm2_core "../tb/point_mul/tb_point_cal_top.v"

vsim -voptargs="+acc" -t 1ps   -L unisims_ver -L unimacro_ver -L secureip -lib sm2_core sm2_core.tb_point_cal_top;

add wave *

view wave
view structure
view signals
log -r /*

restart -f;run 300us
