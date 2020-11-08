@echo off
REM ****************************************************************************
REM Vivado (TM) v2018.3 (64-bit)
REM adapt by ljgibbs / lf_gibbs@163.com for design:sm2_core
REM 
REM Filename    : run_sim.bat
REM Simulator   : Mentor Graphics ModelSim Simulator
REM Description : Script for compiling the simulation design source files
REM
REM Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
REM
REM usage: run_sim.bat
REM
REM ****************************************************************************
set bin_path=%LM_LICENSE_FILE%

call :get_root_path %bin_path%
 
:get_root_path
rem modelsim root path
set bin_path=%~dp1

set bin_path=%bin_path%/win64

REM command line mode
REM call %bin_path%/vsim -c -do "do ../script/run_sm2_point_mul_tb.do" -l run_sm2_sim.log

REM GUI mode
call %bin_path%/vsim -do "do ../script/run_sm2_point_mul_tb.do" -l run_sm2_sim.log

if "%errorlevel%"=="1" goto END
if "%errorlevel%"=="0" goto SUCCESS
:END
exit 1
:SUCCESS
exit 0