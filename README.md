# CC-project

Dart language compiler (CS F365 Compiler Construction Assignment) — Flex + Bison, generates three-address code.

---

## Prerequisites

Make sure the following tools are installed:

```bash
flex --version
bison --version
gcc --version
```

On macOS they ship with Xcode Command Line Tools:
```bash
xcode-select --install
```

---

## Phase 1 — Lexer only

Build and run the standalone lexer (prints token stream):

```bash
# Compile
flex dart_lexer.l
gcc -o dart_lexer lex.yy.c

# Run on a valid program
./dart_lexer test_correct.dart

# Run on a program with lexical errors
./dart_lexer test_error.dart
```

---

## Phase 2 — Parser + Three-Address Code Generator

### Build

```bash
make
```

This runs:
1. `bison -d` on `dart_parser.y` → generates `dart_parser.tab.c` / `dart_parser.tab.h`
2. `flex` on `dart_lexer_p2.l` → generates `lex.yy.c`
3. `gcc` links both into the `dart_compiler` binary

### Run on the valid test program

```bash
./dart_compiler test_valid_p2.dart
```

Expected output: three-address code followed by `[Parse successful — no syntax errors]`

### Run on the syntax-error test program

```bash
./dart_compiler test_syntax_error_p2.dart
```

Expected output: `Syntax Error (line N): ...`

### Shortcut targets

```bash
make test_valid   # build + run test_valid_p2.dart
make test_error   # build + run test_syntax_error_p2.dart
make clean        # remove all generated files and the binary
```

### Run on any Dart file

```bash
./dart_compiler <your_file.dart>
```

---

## Project structure

```
dart_lexer.l          Phase 1 — standalone Flex lexer
dart_lexer_p2.l       Phase 2 — Flex lexer (returns tokens to Bison)
dart_parser.y         Phase 2 — Bison parser + TAC generation
cfg.txt               Context-free grammar specification
terminals.txt         Terminal/token definitions
regex.txt             Regular expressions for each terminal
test_correct.dart     Phase 1 valid test input
test_error.dart       Phase 1 lexical-error test input
test_valid_p2.dart    Phase 2 valid test input
test_syntax_error_p2.dart  Phase 2 syntax-error test input
Makefile              Build rules for Phase 2
```