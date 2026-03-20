import os

# ================= 核心配置区 =================
# 格式: {"name": "宏定义名称", "path": ".bin路径", "w": 宽, "h": 高, "f": 帧数}
ASSETS_CONFIG = [
    {"name": "SUNFLOWER",      "path": "output/Sunflower.bin",      "w": 30, "h": 33, "f": 6},
    {"name": "SUN", "path": "output/Sun.bin",       "w": 25, "h": 25, "f": 2},
    {"name": "SUNFLOWER_STATE",      "path": "output/Sunflower_state.bin", "w": 27, "h": 26, "f": 2},
    {"name": "PEASHOOTER",      "path": "output/Peashooter.bin",      "w": 28, "h": 32, "f": 8},
    {"name": "PEASHOOTER_STATE",      "path": "output/Peashooter_state.bin",      "w": 26, "h": 24, "f": 2},
    {"name": "PEA",      "path": "output/Pea.bin",      "w": 12, "h": 32, "f": 3},
    {"name": "ZOMBIE",      "path": "output/Zombie.bin",      "w": 41, "h": 54, "f": 21},
    {"name": "ZOMBIE_EAT",      "path": "output/Zombie_eat.bin",      "w": 45, "h": 51, "f": 28},
]

ALIGN_SIZE = 512  # 对齐粒度
OUTPUT_BIN = "output/game_data.bin"
OUTPUT_V   = "output/assets_map.v"
# ==============================================

def smart_link_pro():
    master_data = b""
    verilog_content = "// ===========================================\n"
    verilog_content += "//  PvZ FPGA Asset Map - Auto Generated\n"
    verilog_content += "// ===========================================\n\n"
    
    current_addr = 0

    print(f"🚀 开始高级对齐合并...")

    for asset in ASSETS_CONFIG:
        path = asset["path"]
        if not os.path.exists(path):
            print(f"⚠️ 跳过缺失文件: {path}")
            continue

        with open(path, "rb") as f:
            data = f.read()
        
        # 1. 生成 Verilog 宏定义 (地址、宽、高、帧数)
        name = asset["name"]
        verilog_content += f"// --- Asset: {name} ---\n"
        verilog_content += f"`define ADDR_{name:<15} 32'h{current_addr:08x}\n"
        verilog_content += f"`define W_{name:<18} 8'd{asset['w']}\n"
        verilog_content += f"`define H_{name:<18} 8'd{asset['h']}\n"
        verilog_content += f"`define FRM_{name:<16} 8'd{asset['f']}\n\n"
        
        # 2. 计算并填充对齐字节
        padding_size = (ALIGN_SIZE - (len(data) % ALIGN_SIZE)) % ALIGN_SIZE
        master_data += data
        master_data += b'\x00' * padding_size
        
        print(f"  [+] {name:<12} | Addr: 0x{current_addr:08x} | Size: {len(data):>6} | Align: +{padding_size}")
        
        current_addr += (len(data) + padding_size)

    # 保存结果
    with open(OUTPUT_BIN, "wb") as f:
        f.write(master_data)
    with open(OUTPUT_V, "w") as f:
        f.write(verilog_content)

    print(f"\n✅ 合并成功！总包大小: {len(master_data)/1024:.2f} KB")
    print(f"📂 头文件已生成: {OUTPUT_V}")

if __name__ == "__main__":
    smart_link_pro()