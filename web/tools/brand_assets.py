#!/usr/bin/env python3
"""品牌圖：把同學提供的原圖轉成網頁用的檔案。只做裁切、縮放、轉檔，不改圖的內容。

用法：python3 web/tools/brand_assets.py <原圖資料夾> [輸出資料夾]
      輸出資料夾預設是 web/src/assets/brand
原圖：banner-teammates.webp、banner-events.webp、squirrel.png、fomo-agent-ip.png
      （同一包裡的 banner-hangout.webp 講的是揪團，3.1 沒有這個功能，沒有用到）
需要 Pillow（含 WebP）。輸出的檔案不帶 EXIF 等附加資訊。
"""
import os
import shutil
import sys

from PIL import Image, ImageDraw

INK, YELLOW = (38, 33, 30, 255), (255, 212, 71, 255)

# 從哪張原圖、裁哪一塊（左, 上, 右, 下；None＝整張）、輸出邊長（None＝不縮放）
CROPS = {
    # 去背的松鼠：裁掉四周的透明留白
    'squirrel-stand.webp': ('squirrel.png', (22, 10, 367, 474), None),        # 站姿，345×464（右下角有一小塊去背殘留，裁在外面）
    'squirrel-wink.webp': ('fomo-agent-ip.png', (9, 18, 305, 289), None),     # 眨眼，296×271
    'squirrel-head.webp': ('squirrel.png', (82, 0, 382, 300), 192),           # 頭像，頁首標誌用
    # 從橫幅裁下來的方形，畫面上用圓框顯示
    'sticker-phone.webp': ('banner-teammates.webp', (730, 40, 1250, 560), 360),   # 拿手機：訊息
    'sticker-cheer.webp': ('banner-events.webp', (112, 37, 596, 521), 360),       # 歡呼：比賽、已報名
}


def save_webp(im, path, quality):
    im.save(path, 'WEBP', quality=quality, method=6)


def icon(head, size, round_bg):
    """網站圖示：黃底加松鼠頭，頭像貼齊底邊（原圖在脖子的位置是平的）。
    round_bg＝圓形加深色框（瀏覽器分頁）；否則整塊方形（手機主畫面會自己裁圓角）"""
    big = size * 4
    canvas = Image.new('RGBA', (big, big), (0, 0, 0, 0) if round_bg else YELLOW)
    if round_bg:
        ImageDraw.Draw(canvas).ellipse((0, 0, big - 1, big - 1), fill=YELLOW)
    side = int(big * (0.96 if round_bg else 0.88))
    layer = Image.new('RGBA', (big, big), (0, 0, 0, 0))
    layer.alpha_composite(head.resize((side, side), Image.LANCZOS), ((big - side) // 2, big - side))
    if round_bg:
        mask = Image.new('L', (big, big), 0)
        ImageDraw.Draw(mask).ellipse((0, 0, big - 1, big - 1), fill=255)
        layer.putalpha(Image.composite(layer.getchannel('A'), Image.new('L', (big, big), 0), mask))
    canvas.alpha_composite(layer)
    if round_bg:
        ImageDraw.Draw(canvas).ellipse((0, 0, big - 1, big - 1), outline=INK, width=int(big * 0.05))
    return canvas.resize((size, size), Image.LANCZOS)


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    src = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'src', 'assets', 'brand')
    os.makedirs(out, exist_ok=True)

    # 橫幅：原檔直接複製；另外做一張一半寬的給窄螢幕
    shutil.copyfile(os.path.join(src, 'banner-teammates.webp'), os.path.join(out, 'banner-teammates.webp'))
    banner = Image.open(os.path.join(src, 'banner-teammates.webp')).convert('RGB')
    save_webp(banner.resize((1024, 341), Image.LANCZOS), os.path.join(out, 'banner-teammates-1024.webp'), 84)

    for name, (source, box, size) in CROPS.items():
        im = Image.open(os.path.join(src, source))
        im = im.convert('RGBA' if source.endswith('.png') else 'RGB')
        if box:
            im = im.crop(box)
        if size:
            im = im.resize((size, size), Image.LANCZOS)
        save_webp(im, os.path.join(out, name), 90 if im.mode == 'RGBA' else 86)

    head = Image.open(os.path.join(src, 'squirrel.png')).convert('RGBA').crop(CROPS['squirrel-head.webp'][1])
    icon(head, 64, True).save(os.path.join(out, 'favicon.png'), 'PNG', optimize=True)
    icon(head, 180, False).convert('RGB').save(os.path.join(out, 'apple-touch-icon.png'), 'PNG', optimize=True)

    for f in sorted(os.listdir(out)):
        p = os.path.join(out, f)
        with Image.open(p) as im:
            print(f'{f:32s} {im.size[0]:>4}×{im.size[1]:<4} {os.path.getsize(p):>7,} bytes')


if __name__ == '__main__':
    main()
