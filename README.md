# SM2_core

国密 SM2 椭圆曲线加解密算法的硬件 IP，RTL 采用 Verilog 开发。

### 算法与标准

//TODO

[SM2标准文本](http://www.gmbz.org.cn/main/viewfile/20180108015515787986.html)

### 功能

SM2 素数域点乘运算

### 特性

TODO
- 最大吞吐 
  - FPGA : 
    - //TODO
  - ASIC: 
    - //TODO

### 接口

//TODO

#### 输入

//TODO

#### 输出

//TODO

#### 波形示例

//TODO

### 实现与测试

//TODO

#### 测试

SM2_core 目前提供了一个基于 Modelsim 与 Windows 10 的测试平台，以及相应的运行脚本，其中测试平台：

- 将协议标准中的示例作为激励输入逻辑模块
- 判断输出是否与协议标准一致

#### 运行测试（How to run）

运行 run/run_sim.bat 脚本启动测试平台，该脚本

- 通过环境变量获取 Modelsim 路径（实际通过 License 的环境变量：LM_LICENSE_FILE 获取的 modelsim 路径）
- 目前已经测试的 Modelsim 版本与环境：10.5 on Win10

运行 trouble shooting：

//TODO 若运行遇到问题，欢迎提出 issue

#### 运行测试（EpicSim）

//TODO

#### 实现

- FPGA：  //TODO
  

- ASIC:  //TODO

### TODO List

- 尽快完整正式版本发布
- 完善控制模块的指令系统
- 增加模逆模块以支持硬件坐标转换
- 增加协议层模块以支持加解密与签名验签模块
- 增加与 SM3 模块的接口 
- 增加总线接口，为可配置参数添加配置寄存器

### 局限
- 目前仅支持使用伪美森素数的特定曲线
- 点乘中随机数 k 不能等于 0

### 更新

| 版本 | 更新时间  | 更新内容                            |
| ---- | --------- | ----------------------------------- |
| v0.1 | 2020.11.8 | First release，点乘软件示例代码就绪 |
| v0.2 | 2020.11.9 | 点乘运算示例以及仿真环境就绪 |

### 





