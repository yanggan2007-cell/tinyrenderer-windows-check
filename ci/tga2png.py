# Minimal TGA reader (uncompressed + RLE, 8/24/32 bpp) -> PNG. Pillow is used only to write PNG.
import struct, sys
from PIL import Image

def read_tga(path):
    b = open(path, 'rb').read()
    idlen, dtype = b[0], b[2]
    w, h = struct.unpack('<HH', b[12:16]); bpp = b[16]; desc = b[17]
    B = bpp // 8; p = 18 + idlen; n = w * h; px = bytearray()
    if dtype in (2, 3):
        px = b[p:p + n * B]
    elif dtype in (10, 11):
        while len(px) < n * B:
            c = b[p]; p += 1
            if c < 128:
                cnt = c + 1; px += b[p:p + cnt * B]; p += cnt * B
            else:
                cnt = c - 127; px += b[p:p + B] * cnt; p += B
        px = px[:n * B]
    else:
        raise ValueError('unsupported TGA type %d' % dtype)
    if B == 1: im = Image.frombytes('L', (w, h), bytes(px))
    elif B == 3: im = Image.frombytes('RGB', (w, h), bytes(px), 'raw', 'BGR')
    else: im = Image.frombytes('RGBA', (w, h), bytes(px), 'raw', 'BGRA')
    if not (desc & 0x20): im = im.transpose(Image.FLIP_TOP_BOTTOM)
    return im.convert('RGB')

if __name__ == '__main__':
    im = read_tga(sys.argv[1])
    if max(im.size) > 2048: im = im.resize((1024, 1024))
    im.save(sys.argv[2])
