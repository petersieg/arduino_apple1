# Apple I 4x4 Tic-Tac-Toe — ca65

## Build
Run `make` with cc65 installed. This creates `4xttt.bin`, linked to load at `$1000`. Needs more than 8k ram!

## Run
Load the raw binary at `$1000` with the emulator's binary loader, then run `1000R` in the Woz Monitor.

This version uses the Woz Monitor `ECHO` routine at `$FFEF` for output. `putchar` preserves A around `ECHO`, which is important because the input character must still be present for hexadecimal parsing.

Keyboard: `0`..`9`, `A`..`F`. Free cells show their index. Player is `X`; computer is `#`. Four in a row wins. Computer first searches for an immediate win, then blocks the player's immediate win, then chooses center cells/corners/other cells.

