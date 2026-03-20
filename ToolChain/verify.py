import os
from PIL import Image
import struct

# =========================== 验证配置 =============================

BIN_FILE = "output/Zombie.bin"
FRAME_W, FRAME_H = 41, 54
FRAME_COUNT = 20

# =================================================================

def rgb565_to_rgb888(rgb565):
    # 将 16位 RGB565 还原为 24位 RGB888
    r = (rgb565 >> 11) & 0x1F
    g = (rgb565 >> 5) & 0x3F
    b = rgb565 & 0x1F
    return (r << 3, g << 2, b << 3)

def verify_bin():
    if not os.path.exists(BIN_FILE):
        print(f"找不到文件: {BIN_FILE}")
        return

    with open(BIN_FILE, "rb") as f:
        data = f.read()

    # 检查字节数是否匹配
    expected_size = FRAME_W * FRAME_H * 2 * FRAME_COUNT
    if len(data) != expected_size:
        print(f"警告：文件大小({len(data)})与预期({expected_size})不符！")

    # 创建验证文件夹
    if not os.path.exists("verify_result"): os.makedirs("verify_result")

    for i in range(FRAME_COUNT):
        img = Image.new("RGB", (FRAME_W, FRAME_H))
        
        # 计算当前帧在 data 中的起始位置
        frame_offset = i * FRAME_W * FRAME_H * 2
        
        for y in range(FRAME_H):
            for x in range(FRAME_W):
                pixel_offset = frame_offset + (y * FRAME_W + x) * 2
                # 读取 2 字节小端序
                pixel_data = struct.unpack("<H", data[pixel_offset:pixel_offset+2])[0]
                img.putpixel((x, y), rgb565_to_rgb888(pixel_data))
        
        img.save(f"verify_result/frame_{i}.png")
        print(f"已还原第 {i} 帧：verify_result/frame_{i}.png")

    print("\n✅ 验证完毕！请去 verify_result 文件夹查看图片是否正常。")

if __name__ == "__main__":
    verify_bin()