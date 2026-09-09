#!/usr/bin/env python3
"""launcher_icon.svg 와 같은 도형을 임의 크기 PNG 로 그린다.

사용법: python3 tools/render_icon.py <출력.png> [크기]

Store 등록에는 고해상도 PNG 아이콘이 따로 필요한데, 시계에 들어가는 SVG 를
그대로 못 올린다. 도형이 단순해서(둥근 사각형 3개) 외부 라이브러리 없이 그린다.
SVG 를 고치면 아래 BARS 도 같이 고쳐야 한다.
"""
import sys, zlib, struct

# (x, y, w, h, color) — 24x24 좌표계. launcher_icon.svg 와 같은 값.
BARS = [
    (3, 3,    15, 4.5, (244, 244, 244)),
    (3, 9.75, 18, 5.0, (0, 255, 0)),
    (3, 16.5, 11, 4.5, (244, 244, 244)),
]
BG = (0, 0, 0)

def render(path, size):
    s = size / 24.0
    px = [[BG for _ in range(size)] for _ in range(size)]

    for bx, by, bw, bh, col in BARS:
        x0, y0 = bx * s, by * s
        x1, y1 = (bx + bw) * s, (by + bh) * s
        r = (y1 - y0) / 2.0                      # 완전한 둥근 끝(rx = 높이/2)
        for y in range(max(0, int(y0)), min(size, int(y1) + 1)):
            for x in range(max(0, int(x0)), min(size, int(x1) + 1)):
                cx, cy = x + 0.5, y + 0.5
                if cx < x0 or cx > x1 or cy < y0 or cy > y1:
                    continue
                # 좌우 끝의 둥근 부분만 원으로 자른다
                if cx < x0 + r:
                    if (cx - (x0 + r)) ** 2 + (cy - (y0 + r)) ** 2 > r * r: continue
                elif cx > x1 - r:
                    if (cx - (x1 - r)) ** 2 + (cy - (y0 + r)) ** 2 > r * r: continue
                px[y][x] = col

    raw = b''.join(b'\x00' + b''.join(struct.pack('3B', *px[y][x]) for x in range(size))
                   for y in range(size))
    def chunk(t, d):
        c = t + d
        return struct.pack('>I', len(d)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    data = (b'\x89PNG\r\n\x1a\n'
            + chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(raw, 9))
            + chunk(b'IEND', b''))
    open(path, 'wb').write(data)
    return len(data)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(__doc__); sys.exit(1)
    out = sys.argv[1]
    size = int(sys.argv[2]) if len(sys.argv) > 2 else 512
    print("%s (%dx%d) - %d bytes" % (out, size, size, render(out, size)))
