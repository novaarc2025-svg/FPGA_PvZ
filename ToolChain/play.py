import time
from PIL import Image, ImageTk
import tkinter as tk
import struct

# ================= 配置区 =================

BIN_FILE = "output/Zombie.bin" 
FRAME_W, FRAME_H = 41, 54
FRAME_COUNT = 21
FPS = 2

# ==========================================

# 💡 核心开关：动画模式
# "LINEAR"   : 0->1->2->3->4->5->0 (适合僵尸、子弹)
# "PINGPONG" : 0->1->2->3->4->5->4->3->2->1->0 (适合植物摇摆)
ANIMATION_MODE = "LINEAR" 

# ==========================================

def rgb565_to_rgb888(rgb565):
    r = (rgb565 >> 11) & 0x1F
    g = (rgb565 >> 5) & 0x3F
    b = rgb565 & 0x1F
    return (r << 3, g << 2, b << 3)

class BinPlayer:
    def __init__(self, root):
        self.root = root
        self.root.title(f"FPGA 动画预览 - {ANIMATION_MODE} 模式")
        
        with open(BIN_FILE, "rb") as f:
            self.data = f.read()
            
        self.label = tk.Label(root)
        self.label.pack(padx=20, pady=20)
        
        # 💡 生成播放序列
        if ANIMATION_MODE == "PINGPONG":
            # 如果是 6 帧，生成 [0, 1, 2, 3, 4, 5, 4, 3, 2, 1]
            self.sequence = list(range(FRAME_COUNT)) + list(range(FRAME_COUNT - 2, 0, -1))
        else:
            # 如果是 6 帧，生成 [0, 1, 2, 3, 4, 5]
            self.sequence = list(range(FRAME_COUNT))
            
        self.seq_index = 0
        self.update_frame()

    def update_frame(self):
        # 💡 从序列中获取当前应该显示的“真·帧索引”
        display_frame = self.sequence[self.seq_index]
        
        # 计算该帧在二进制文件中的偏移量
        offset = display_frame * FRAME_W * FRAME_H * 2
        img = Image.new("RGB", (FRAME_W, FRAME_H))
        
        for y in range(FRAME_H):
            for x in range(FRAME_W):
                idx = offset + (y * FRAME_W + x) * 2
                # 防止超出文件末尾的简单保护
                if idx + 2 <= len(self.data):
                    pixel = struct.unpack("<H", self.data[idx:idx+2])[0]
                    img.putpixel((x, y), rgb565_to_rgb888(pixel))
        
        # 放大显示并绘制到窗口
        img = img.resize((200, 200), Image.NEAREST)
        self.tk_img = ImageTk.PhotoImage(img)
        self.label.config(image=self.tk_img)
        
        # 💡 更新序列索引（在 0 到序列总长度之间循环）
        self.seq_index = (self.seq_index + 1) % len(self.sequence)
        
        self.root.after(int(1000/FPS), self.update_frame)

if __name__ == "__main__":
    root = tk.Tk()
    player = BinPlayer(root)
    root.mainloop()