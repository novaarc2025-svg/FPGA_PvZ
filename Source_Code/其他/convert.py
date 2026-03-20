import os
from PIL import Image
import struct

# ================= 核心配置 (所有修改都在这里) =================

"""
# Sunflower_state
TARGET_FILE     = "Sunflower.png"
OUTPUT_FILENAME = "Sunflower_state.bin"

ROI_X       = 3
ROI_Y       = 52
FRAME_W     = 27
FRAME_H     = 26
GAP_X       = 1
GAP_Y       = 1

GRID_CONFIG = [
    {"start_col": 0, "count": 2},
]
"""

"""
# Sunflower
TARGET_FILE     = "Sunflower.png"
OUTPUT_FILENAME = "Sunflower.bin"

ROI_X       = 175
ROI_Y       = 120
FRAME_W     = 30
FRAME_H     = 33
GAP_X       = 1
GAP_Y       = 1

GRID_CONFIG = [
    {"start_col": 0, "count": 6},
]
"""

"""
# Sun
TARGET_FILE     = "Sun.png"
OUTPUT_FILENAME = "Sun.bin"

ROI_X       = 2
ROI_Y       = 17
FRAME_W     = 25
FRAME_H     = 25
GAP_X       = 2
GAP_Y       = 1

GRID_CONFIG = [
    {"start_col": 0, "count": 2},
]
"""

"""
# Peashooter
TARGET_FILE     = "Peashooter.png"
OUTPUT_FILENAME = "Peashooter.bin"

ROI_X       = 169
ROI_Y       = 13
FRAME_W     = 28
FRAME_H     = 32
GAP_X       = 1
GAP_Y       = 1

GRID_CONFIG = [
    {"start_col": 0, "count": 8},
]
"""

"""
# Peashooter_state
TARGET_FILE     = "Peashooter.png"
OUTPUT_FILENAME = "Peashooter_state.bin"

ROI_X       = 3
ROI_Y       = 50
FRAME_W     = 26
FRAME_H     = 24
GAP_X       = 1
GAP_Y       = 1

GRID_CONFIG = [
    {"start_col": 0, "count": 2},
]
"""


# Pea
TARGET_FILE     = "Peashooter.png"
OUTPUT_FILENAME = "Pea.bin"

ROI_X       = 327
ROI_Y       = 103
FRAME_W     = 12
FRAME_H     = 32
GAP_X       = 1
GAP_Y       = 1

GRID_CONFIG = [
    {"start_col": 0, "count": 3},
]














# =============================================================

INPUT_DIR  = "assets"
OUTPUT_DIR = "output"
TRANSPARENT_COLOR_565 = 0xF81F 

def to_rgb565(r, g, b):
    return ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3)

def process_with_gaps():
    if not os.path.exists(OUTPUT_DIR): os.makedirs(OUTPUT_DIR)
    
    img_path = os.path.join(INPUT_DIR, TARGET_FILE)
    out_path = os.path.join(OUTPUT_DIR, OUTPUT_FILENAME) # 👈 直接使用配置的名字

    if not os.path.exists(img_path):
        print(f"❌ 错误：找不到输入文件 {img_path}")
        return

    try:
        full_img = Image.open(img_path).convert("RGBA")
        bin_data = b""
        total_frames = 0

        print(f"🚀 正在处理: {TARGET_FILE} -> {OUTPUT_FILENAME}")

        for row_idx, config in enumerate(GRID_CONFIG):
            start_col = config["start_col"]
            count = config["count"]
            
            for i in range(count):
                current_col = start_col + i
                
                # 核心逻辑：起始坐标 = 初始位置 + 索引 * (宽度 + 间隔)
                left   = ROI_X + current_col * (FRAME_W + GAP_X)
                top    = ROI_Y + row_idx * (FRAME_H + GAP_Y)
                right  = left + FRAME_W
                bottom = top + FRAME_H
                
                frame = full_img.crop((left, top, right, bottom))
                
                for y in range(FRAME_H):
                    for x in range(FRAME_W):
                        r, g, b, a = frame.getpixel((x, y))
                        color = to_rgb565(r, g, b) if a > 128 else TRANSPARENT_COLOR_565
                        bin_data += struct.pack('<H', color)
                
                total_frames += 1
                print(f"  [提取成功] 第 {row_idx+1} 行, 第 {current_col+1} 列")

        with open(out_path, "wb") as f:
            f.write(bin_data)
        
        print(f"\n✅ 转换成功！")
        print(f"📂 输出路径: {out_path}")
        print(f"📏 请在 verify.py 中填入: W={FRAME_W}, H={FRAME_H}, COUNT={total_frames}")

    except Exception as e:
        print(f"💥 出错: {e}")

if __name__ == "__main__":
    process_with_gaps()