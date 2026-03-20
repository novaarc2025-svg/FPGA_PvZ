# 🎓 嵌入式系统与 AI 机器人工程实践 (SCUT Portfolio)

本项目展示了作为华南理工大学（SCUT）信息工程专业大三学生的两项核心开发实践：基于 **FPGA** 的复古游戏实现与基于 **ESP32-S3** 的智能交互机器人。

---

## 🚀 项目一：基于 Altera Cyclone IV 的《植物大战僵尸》复刻

### 核心背景
本项实践旨在探索硬件描述语言（VHDL/Verilog）在复杂图像处理与实时逻辑控制中的应用。

* **硬件平台**: Altera Cyclone IV (EP4CE10)。
* **显示技术**: 自研 LCD 驱动逻辑，实现了向日葵、豌豆射手及僵尸的位图渲染。
* **资源优化**: 针对僵尸等大型素材导致的内存溢出（Memory Overflow）问题，设计了专用的 Python 自动化工具链进行位图压缩与地址映射转换。

### 🛠️ 工具链与资源
* **Quartus II**: 底层逻辑综合与烧录。
* **Python Scripts**: 包含 `bin2mif.py` 与 `convert.py`，用于将 `.png` 素材转换为 FPGA 内部存储器（MIF）可识别的数据格式。

---

## 🤖 项目二：ESP32-S3 AI 智能交互机器人

### 核心背景
结合 AI 大模型与嵌入式开发，构建了一个具备“感知-思考-执行”闭环的微型智能体。

* **硬件平台**: ESP32-S3 开发板，集成两路 PWM 电机驱动与电压实时监测（如 4.06V 动态监测）。
* **AI 交互**: 接入大语言模型（LLM），支持语音指令解析与多轮对话交互。
* **功能演示**: 视频展示了机器人根据语音指令完成“前进”、“后退”及“转向”等精准控制逻辑。

---

## 📂 仓库目录说明

| 文件夹 | 功能描述 |
| :--- | :--- |
| **`Source_Code`** | 包含 FPGA 的 VHDL 逻辑源码与 ESP32 的 C/C++ (ESP-IDF) 代码。 |
| **`ToolChain`** | 自研的素材转换工具集（Python）及生成的内存初始化文件（MIF）。 |
| **`DeveloperGuide`** | 详尽的开发文档与硬件接线定义。 |
| **`demo`** | GitHub Pages 静态展示页及演示视频（index.html & mp4）。 |

---

## 🎬 在线演示 (Demo)

点击下方链接即可直接在浏览器中查看项目的实时演示视频（建议使用 Edge 或 Chrome 浏览器）：

🔗 **[立即查看 Demo 演示页](https://novaarc2025-svg.github.io/FPGA_PvZ/demo/index.html)** *(注：由于包含高码率视频，初次加载可能需要 2-5 秒)*

---

## 🛠️ 本地开发环境

本项目推荐使用 **Scoop** 软件包管理器进行环境搭建：

```powershell
# 快速安装开发工具
scoop install git ffmpeg
scoop install extras/calibre # 用于查阅相关技术手册
```
