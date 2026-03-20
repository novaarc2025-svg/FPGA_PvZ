import os

# ================= 配置区 =================
INPUT_BIN = "output/game_data.bin"
# 修改这里为你想要的路径，比如 "mif_files"
OUTPUT_DIR = "mif_results"  
OUTPUT_MIF = os.path.join(OUTPUT_DIR, "game_data.mif")
WIDTH = 16 
# ==========================================

def convert_bin_to_mif():
    if not os.path.exists(INPUT_BIN):
        print(f"❌ 错误：找不到文件 {INPUT_BIN}")
        return

    # 自动创建输出目录
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        print(f"📁 已创建输出目录: {OUTPUT_DIR}")

    # 读取二进制数据
    with open(INPUT_BIN, "rb") as f:
        bin_data = f.read()

    # 计算总字数
    total_bytes = len(bin_data)
    depth = (total_bytes + 1) // 2 

    print(f"🚀 正在转换: {INPUT_BIN} -> {OUTPUT_MIF}")
    print(f"📏 检测到大小: {total_bytes} 字节, 深度: {depth} words")

    with open(OUTPUT_MIF, "w") as f:
        # 1. 写入 MIF 文件头
        f.write(f"WIDTH={WIDTH};\n")
        f.write(f"DEPTH={depth};\n\n")
        f.write("ADDRESS_RADIX=UNS;\n")
        f.write("DATA_RADIX=HEX;\n\n")
        f.write("CONTENT BEGIN\n")

        # 2. 写入数据
        for i in range(depth):
            byte_idx = i * 2
            if byte_idx + 1 < total_bytes:
                low_byte = bin_data[byte_idx]
                high_byte = bin_data[byte_idx + 1]
                value = (high_byte << 8) | low_byte
            else:
                value = bin_data[byte_idx]

            f.write(f"    {i} : {value:04X};\n")

        f.write("END;\n")

    print(f"✅ 转换成功！生成的 MIF 文件：{OUTPUT_MIF}")
    print(f"⚠️  请在 Quartus 中将 ROM 深度设置为: {depth}")

if __name__ == "__main__":
    convert_bin_to_mif()