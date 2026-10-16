/* ChatGPT 2026-10-16 P.Sieg

Hier ist ein kompaktes C-Programm, das eine Binärdatei einliest und direkt in 
das passende Textformat für den Wozmon (Apple 1) konvertiert.
Das Programm liest die Startadresse als optionalen Kommandozeilenparameter 
(entweder als Hexadezimalzahl mit 0x bzw. $, oder als Dezimalzahl). Wird kein 
Parameter übergeben, fragt das Programm die Adresse interaktiv ab. Es gibt 
standardmäßig 16 Bytes pro Zeile aus, was dem klassischen Wozmon-Eingabeformat 
entspricht.

Kompilieren und Nutzen

1. Kompilieren (z. B. mit gcc)
gcc bin2woz.c -o bin2woz

2. Ausführen über Parameter (Empfohlen):
Ganz klassisch für den Apple 1 im Hex-Format ab Adresse $0300 (768 dezimal):
./bin2woz meine_datei.bin 0x0300

Alternativ mit dem 6502-Dollarzeichen: ./bin2woz meine_datei.bin $0300

3. Ausgabe-Beispiel:
Das Programm erzeugt genau den Text, den du kopieren und in deinen Apple 1 
Emulator oder das serielle Terminal des echten Boards jagen kannst
0300: A9 00 8D 12 D0 60 A2 00 BD 00 04 20 F2 FF E8
0310: E0 05 D0 F5 60
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BYTES_PER_LINE 16

int main(int argc, char *argv[]) {
    FILE *file;
    unsigned int address = 0;
    int ch;
    int byte_count = 0;
    char *filename = NULL;

    // Argumente auswerten
    if (argc < 2) {
        printf("Nutzung: %s <binärdatei> [start_adresse]\n", argv[0]);
        printf("Beispiel: %s program.bin 0x0300\n\n", argv[0]);
        
        // Interaktive Abfrage, falls keine Datei angegeben wurde
        static char input_file[256];
        printf("Bitte Pfad zur Binärdatei eingeben: ");
        if (scanf("%255s", input_file) != 1) return 1;
        filename = input_file;
    } else {
        filename = argv[1];
    }

    // Datei öffnen
    file = fopen(filename, "rb");
    if (!file) {
        perror("Fehler beim Öffnen der Datei");
        return 1;
    }

    // Startadresse ermitteln
    if (argc >= 3) {
        char *addr_str = argv[2];
        // Unterstützung für Wozmon/6502-typisches '$' Präfix für Hexadezimal
        if (addr_str[0] == '$') {
            address = (unsigned int)strtol(&addr_str[1], NULL, 16);
        } else {
            address = (unsigned int)strtol(addr_str, NULL, 0); // Erkennt automatisch 0x für Hex oder Basis 10
        }
    } else {
        char addr_input[32];
        printf("Bitte Startadresse eingeben (z.B. 0x0300 oder 768): ");
        if (scanf("%31s", addr_input) != 1) {
            fclose(file);
            return 1;
        }
        if (addr_input[0] == '$') {
            address = (unsigned int)strtol(&addr_input[1], NULL, 16);
        } else {
            address = (unsigned int)strtol(addr_input, NULL, 0);
        }
    }

    // Konvertierung und Ausgabe im Wozmon-Format
    while ((ch = fgetc(file)) != EOF) {
        if (byte_count % BYTES_PER_LINE == 0) {
            // Neue Zeile mit aktueller Adresse und dem Wozmon-Doppelpunkt
            if (byte_count > 0) {
                printf("\n");
            }
            printf("%04X:", address + byte_count);
        }
        
        printf(" %02X", ch);
        byte_count++;
    }

    if (byte_count > 0) {
        printf("\n");
    }

    fclose(file);
    return 0;
}

