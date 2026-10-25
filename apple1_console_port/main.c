/*
 * ChatGPT 2026-10-25 P.Sieg
 * Apple-1 console frontend for Peter Sieg's arduino_apple1_rp2040 cpu.c
 * POSIX terminal frontend (macOS / Linux), ISO C with POSIX terminal APIs.
 */
#define _POSIX_C_SOURCE 200809L
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>

extern void exec6502(int32_t tickcount);
extern void reset6502(void);
extern void serout(uint8_t value);
extern uint8_t isakey(void);
extern uint8_t getkey(void);
extern void clearkey(void);
extern void printhex(uint16_t value);
extern uint8_t RAM[];

static struct termios saved_termios;
static int terminal_saved;
static volatile sig_atomic_t stop_requested;

static void restore_terminal(void)
{
    if (terminal_saved) {
        (void)tcsetattr(STDIN_FILENO, TCSAFLUSH, &saved_termios);
        terminal_saved = 0;
    }
}

static void on_signal(int sig)
{
    (void)sig;
    stop_requested = 1;
}

static int setup_terminal(void)
{
    struct termios t;
    if (!isatty(STDIN_FILENO))
        return 0;
    if (tcgetattr(STDIN_FILENO, &saved_termios) != 0)
        return -1;
    t = saved_termios;
    t.c_lflag &= (tcflag_t)~(ICANON | ECHO);
    t.c_iflag &= (tcflag_t)~(IXON | ICRNL);
    t.c_oflag |= OPOST;
    t.c_cc[VMIN] = 0;
    t.c_cc[VTIME] = 0;
    if (tcsetattr(STDIN_FILENO, TCSAFLUSH, &t) != 0)
        return -1;
    terminal_saved = 1;
    return 0;
}

static int load_binary(const char *path, unsigned long address)
{
    FILE *f = fopen(path, "rb");
    size_t n, maxlen;
    if (!f) {
        fprintf(stderr, "Kann '%s' nicht öffnen: %s\n", path, strerror(errno));
        return -1;
    }
    if (address > 0xffffUL) {
        fprintf(stderr, "Ladeadresse muss zwischen 0000 und FFFF liegen.\n");
        fclose(f);
        return -1;
    }
    maxlen = 0x10000u - (size_t)address;
    n = fread(RAM + address, 1, maxlen, f);
    if (ferror(f)) {
        fprintf(stderr, "Fehler beim Lesen von '%s'.\n", path);
        fclose(f);
        return -1;
    }
    if (!feof(f)) {
        fprintf(stderr, "Datei passt ab $%04lX nicht in den 64-KiB-Adressraum.\n", address);
        fclose(f);
        return -1;
    }
    fclose(f);
    fprintf(stderr, "Geladen: %lu Bytes nach $%04lX\n", (unsigned long)n, address);
    return 0;
}

/* The original Apple-1 ROM calls these hooks for its memory-mapped terminal. */
void serout(uint8_t value)
{
    if (value == 13) {
        putchar('\n');
        fflush(stdout);
    } else if (value == 10) {
        /* CR is emitted as a newline; ignore a following LF if a ROM emits one. */
    } else {
        putchar((int)(value & 0x7f));
        fflush(stdout);
    }
}

uint8_t isakey(void)
{
    unsigned char c;
    ssize_t n = read(STDIN_FILENO, &c, 1);
    if (n == 1) {
        if (c == 0x11) { /* Ctrl-Q */
            stop_requested = 1;
            return 0;
        }
        /* Keep this byte for getkey(), which the emulated PIA calls next. */
        extern void console_key_pending_set(unsigned char);
        console_key_pending_set(c);
        return 0x80;
    }
    return 0;
}

static unsigned char pending_key;
static int pending_valid;

void console_key_pending_set(unsigned char c)
{
    pending_key = c;
    pending_valid = 1;
}

uint8_t getkey(void)
{
    unsigned char c;
    if (pending_valid) {
        c = pending_key;
        pending_valid = 0;
    } else {
        ssize_t n = read(STDIN_FILENO, &c, 1);
        if (n != 1)
            return 0;
        if (c == 0x11) {
            stop_requested = 1;
            return 0;
        }
    }
    c &= 0x7f;
    if (c >= 'a' && c <= 'z')
        c = (unsigned char)(c - ('a' - 'A'));
    if (c == '\n')
        c = '\r';
    return c;
}

void clearkey(void)
{
    pending_valid = 0;
}

void printhex(uint16_t value)
{
    printf("%X\n", (unsigned)value);
    fflush(stdout);
}

int main(int argc, char **argv)
{
    unsigned long load_address = 0;
    char *end = NULL;

    if (argc != 1 && argc != 3) {
        fprintf(stderr, "Aufruf: %s [programm.bin HEX-Ladeadresse]\n", argv[0]);
        fprintf(stderr, "Beispiel: %s demo.bin 0280\n", argv[0]);
        return EXIT_FAILURE;
    }
    if (argc == 3) {
        errno = 0;
        load_address = strtoul(argv[2], &end, 16);
        if (errno || end == argv[2] || *end != '\0' || load_address > 0xffffUL) {
            fprintf(stderr, "Ungültige HEX-Ladeadresse: '%s'\n", argv[2]);
            return EXIT_FAILURE;
        }
    }

    if (argc == 3 && load_binary(argv[1], load_address) != 0)
        return EXIT_FAILURE;

    if (setup_terminal() != 0) {
        perror("Terminalmodus");
        return EXIT_FAILURE;
    }
    (void)atexit(restore_terminal);
    (void)signal(SIGINT, on_signal);
    (void)signal(SIGTERM, on_signal);

    puts("Apple-1 Konsolenemulator — Ctrl-Q beendet.");
    fflush(stdout);
    reset6502();

    while (!stop_requested) {
        exec6502(100);
        /* Give the terminal and signal handler regular opportunities to run. */
        if (stop_requested)
            break;
    }

    restore_terminal();
    puts("\nEmulator beendet.");
    return EXIT_SUCCESS;
}
