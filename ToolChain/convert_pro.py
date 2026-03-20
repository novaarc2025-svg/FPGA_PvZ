import os
from PIL import Image
import struct

# ======================= 核心配置区 =======================


# Zombie

TARGET_FILE     = "Zombie.png"
OUTPUT_FILENAME = "Zombie.bin"

# 1. 【标准盒子】
TARGET_W    = 41
TARGET_H    = 54

# 2. 【多行配置】增加 offset_x 进行手动对齐
ROWS_CONFIG = [
    {
        "start_x": 0, "start_y": 59, "gap_x": 9, "offset_x": 0,  # 居中不动
        "frames": [(41, 54)] * 7
    },
    {
        "start_x": 0, "start_y": 122, "gap_x": 9, "offset_x": -2, # 💡 同理
        "frames": [(36, 53)] * 7
    },
    {
        "start_x": 0, "start_y": 183, "gap_x": 9, "offset_x": 2,
        "frames": [(25, 33)] * 7
    }
]


"""
# Zombie_eat
TARGET_FILE     = "Zombie.png"
OUTPUT_FILENAME = "Zombie_eat.bin"

# 1. 【标准盒子】
TARGET_W    = 45
TARGET_H    = 51

# 2. 【多行配置】增加 offset_x 进行手动对齐
ROWS_CONFIG = [
    {
        "start_x": 0, "start_y": 224, "gap_x": 9, "offset_x": 5,
        "frames": [(36, 51)] * 7
    },
    {
        "start_x": 0, "start_y": 283, "gap_x": 9, "offset_x": 5,
        "frames": [(36, 51)] * 7
    },
    {
        "start_x": 0, "start_y": 342, "gap_x": 9, "offset_x": 7,
        "frames": [(32, 35)] * 5
    },
    {
        "start_x": 0, "start_y": 385, "gap_x": 9, "offset_x": 0,
        "frames": [(43, 31)] * 9
    }
]
"""

"""
# zombie_components
TARGET_FILE     = "Zombie.png"
OUTPUT_FILENAME = "Zombie.bin"

# 1. 【标准盒子】
TARGET_W    = 45
TARGET_H    = 51

# 2. 【多行配置】增加 offset_x 进行手动对齐
ROWS_CONFIG = [
    {
        "start_x": 0, "start_y": 224, "gap_x": 9, "offset_x": 5,
        "frames": [(36, 51)] * 7
    },
    {
        "start_x": 0, "start_y": 283, "gap_x": 9, "offset_x": 5,
        "frames": [(36, 51)] * 7
    },
    {
        "start_x": 0, "start_y": 342, "gap_x": 9, "offset_x": 7,
        "frames": [(32, 35)] * 5
    },
    {
        "start_x": 0, "start_y": 385, "gap_x": 9, "offset_x": 0,
        "frames": [(43, 31)] * 9
    }
]
"""









# =========================================================

INPUT_DIR  = "assets"
OUTPUT_DIR = "output"
TRANSPARENT_565 = 0xFCCF # 使用你发现的僵尸背景粉

def to_rgb565(r, g, b):
    return ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3)

def process_multi_rows_with_offset():
    if not os.path.exists(OUTPUT_DIR): os.makedirs(OUTPUT_DIR)
    img_path = os.path.join(INPUT_DIR, TARGET_FILE)
    
    try:
        full_img = Image.open(img_path).convert("RGBA")
        bin_data = b""
        total_frames = 0

        print(f"🚀 启动对齐修正处理: {TARGET_FILE}")

        for row_idx, row in enumerate(ROWS_CONFIG):
            current_left = row["start_x"]
            y_top = row["start_y"]
            gap = row["gap_x"]
            off_x = row.get("offset_x", 0) # 💡 获取偏移量
            
            print(f"  📂 处理第 {row_idx+1} 行 (偏移: {off_x})")

            for i, (actual_w, actual_h) in enumerate(row["frames"]):
                crop_frame = full_img.crop((current_left, y_top, current_left + actual_w, y_top + actual_h))
                
                # 统一底色为背景粉
                canvas = Image.new("RGBA", (TARGET_W, TARGET_H), (248, 152, 248, 255))
                
                # 💡 核心逻辑修改：居中值 + 手动偏移量
                paste_x = (TARGET_W - actual_w) // 2 + off_x
                paste_y = TARGET_H - actual_h
                
                # 防呆：防止偏移过大导致贴图超出画布边界
                paste_x = max(0, min(paste_x, TARGET_W - actual_w))
                
                canvas.paste(crop_frame, (paste_x, paste_y))
                
                for y in range(TARGET_H):
                    for x in range(TARGET_W):
                        r, g, b, a = canvas.getpixel((x, y))
                        color = to_rgb565(r, g, b) if a > 128 else TRANSPARENT_565
                        bin_data += struct.pack('<H', color)
                
                total_frames += 1
                current_left += (actual_w + gap)

        with open(os.path.join(OUTPUT_DIR, OUTPUT_FILENAME), "wb") as f:
            f.write(bin_data)
        
        print(f"\n✅ 修正完成！已通过 offset_x 调整水平落脚点。")

    except Exception as e:
        print(f"💥 错误: {e}")

if __name__ == "__main__":
    process_multi_rows_with_offset()