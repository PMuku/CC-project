# CC-project

Dart-subset compiler (CS F365 Compiler Construction) — Flex + Bison, generates three-address code (TAC).

---

## Prerequisites

The following tools must be installed:

| Tool | Purpose |
|------|---------|
| `flex` | Generates the lexer from `dart_lexer.l`  |
| `bison` | Generates the parser from `dart_parser.y` |
| `gcc` | Compiles the generated C files into the binary |

Check they are available:

```bash
flex --version
bison --version
gcc --version
```

On Linux (Ubuntu)
```bash
sudo apt update
sudo apt install flex bison gcc make
```

On macOS, all three ship with Xcode Command Line Tools:

```bash
xcode-select --install
```

`bison` MUST be Version 3.8+

---

## Building

```bash
make
```

The Makefile runs three steps in order:

1. `bison -d dart_parser.y` — produces `dart_parser.tab.c` and `dart_parser.tab.h`
2. `flex dart_lexer.l` — produces `lex.yy.c` (requires the Bison header)
3. `gcc lex.yy.c dart_parser.tab.c -o dart_compiler` — links everything into the `dart_compiler` binary

---

## Running

### On any Dart file

```bash
./dart_compiler <file.dart>
```

Three-address code is printed to **stdout**. Error messages go to **stderr**.

### Makefile shortcut targets

| Target | What it does |
|--------|-------------|
| `make` or `make all` | Build the `dart_compiler` binary |
| `make test_valid` | Build then run `./dart_compiler test_valid.dart` |
| `make test_error` | Build then run `./dart_compiler test_error.dart` |
| `make clean` | Delete the binary and all generated files (`lex.yy.c`, `dart_parser.tab.c`, `dart_parser.tab.h`, `dart_parser.output`) |

---

## Example

Input (`test_valid.dart`):

```dart
void main() {
    int x = 5;
    while (x < 20) {
        x = x + 1;
    }
}
```

Run:

```bash
./dart_compiler test_valid.dart
```

Output:

```
=== Three-Address Code ===
    x = 5
L1:
    t1 = x < 20
    if_false t1 goto L2
    t2 = x + 1
    x = t2
    goto L1
L2:

[Parse successful — no syntax errors]
```

If the file contains a syntax error the compiler prints a diagnostic and exits with a non-zero code:

```
Syntax Error (line 4): syntax error
```

---

## How TAC generation works

The parser is generated from `dart_parser.y`, which implements the **Syntax-Directed Definition** described in `SDD.md`.

Each grammar rule has a semantic action that:

- For **expressions** — allocates a fresh temporary (`t1`, `t2`, …) with `newtemp()`, emits one TAC instruction via `emit()`, and returns the temporary's name as the rule's synthesised `.place` attribute.
- For **statements** — emits TAC instructions as side-effects; no value is returned.
- For **control flow** — allocates labels (`L1`, `L2`, …) with `newlabel()`, emits conditional jumps (`if_false … goto …`), unconditional jumps (`goto …`), and label definitions.

The `|||` operator in `SDD.md` denotes TAC-sequence concatenation; in Bison this maps directly to the left-to-right ordering of `emit()` calls within and across rules.