# pack.py
# Arecibo message: display and binary packing
# Compatible with Python 2.7 and Python 3

import sys

INPUT_FILE = "arecibo.txt"
BINARY_FILE = "message.bin"
IMAGE_FILE = "arecibo_image.txt"

WIDTH = 23
HEIGHT = 73
EXPECTED_BITS = WIDTH * HEIGHT


def read_bits(filename):
    try:
        with open(filename, "r") as f:
            content = f.read()
    except IOError as exc:
        print("Cannot read {}: {}".format(filename, exc))
        sys.exit(1)

    bits = "".join(content.split())

    if any(c not in "01" for c in bits):
        print("Error: input must contain only 0 and 1.")
        sys.exit(1)

    if len(bits) != EXPECTED_BITS:
        print("Expected {} bits, found {}.".format(
            EXPECTED_BITS, len(bits)))
        sys.exit(1)

    return bits


def display_image(bits):
    print("")
    print("Arecibo message: {} x {}".format(WIDTH, HEIGHT))
    print("# = 1, space = 0")
    print("-" * WIDTH)

    rows = []

    for y in range(HEIGHT):
        row_bits = bits[y * WIDTH:(y + 1) * WIDTH]
        row = "".join("#" if b == "1" else " " for b in row_bits)
        rows.append(row)
        print(row)

    print("-" * WIDTH)
    return rows


def pack_bits(bits):
    data = bytearray()

    for i in range(0, len(bits), 8):
        chunk = bits[i:i + 8]
        value = int(chunk, 2) << (8 - len(chunk))
        data.append(value)

    return data

def show_orientation(bits, reverse=False):
    print("")
    print("Reverse bit order: {}".format(reverse))

    if reverse:
        bits = bits[::-1]

    for y in range(73):
        row_bits = bits[y * 23:(y + 1) * 23]
        row = "".join("#" if b == "1" else " " for b in row_bits)
        print(row)

def main():
    bits = read_bits(INPUT_FILE)

    print("Bit count: {}".format(len(bits)))
    print("First 46 bits: {}".format(bits[:46]))

    rows = display_image(bits)

    with open(IMAGE_FILE, "w") as f:
        for row in rows:
            f.write(row + "\n")

    data = pack_bits(bits)

    with open(BINARY_FILE, "wb") as f:
        f.write(data)

    print("")
    print("Image rows: {}".format(len(rows)))
    print("Image width: {}".format(len(rows[0])))
    show_orientation(bits, False)
    show_orientation(bits, True)
    print("Done.")
    print("{} bits packed into {} bytes.".format(
        len(bits), len(data)))
    print("Binary file: {}".format(BINARY_FILE))
    print("Image file: {}".format(IMAGE_FILE))


if __name__ == "__main__":
    main()


