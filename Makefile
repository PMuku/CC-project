CC     = gcc
BISON  = bison
FLEX   = flex
CFLAGS = -Wall -Wno-unused-function

TARGET = dart_compiler

.PHONY: all clean test_valid test_error

all: $(TARGET)

# 1. Generate parser (C source + header) from Bison grammar
dart_parser.tab.c dart_parser.tab.h: dart_parser.y
	$(BISON) -d -o dart_parser.tab.c dart_parser.y

# 2. Generate lexer from Flex spec (needs the Bison header for token codes)
lex.yy.c: dart_lexer.l dart_parser.tab.h
	$(FLEX) -o lex.yy.c dart_lexer.l

# 3. Compile both generated C files into one binary
$(TARGET): lex.yy.c dart_parser.tab.c dart_parser.tab.h
	$(CC) $(CFLAGS) -o $(TARGET) lex.yy.c dart_parser.tab.c

# Run on valid test program
test_valid: $(TARGET)
	@echo "====== Valid program ======"
	./$(TARGET) test_valid.dart

# Run on syntax-error test program
test_error: $(TARGET)
	@echo "====== Syntax-error program ======"
	./$(TARGET) test_error.dart; true

clean:
	rm -f $(TARGET) lex.yy.c dart_parser.tab.c dart_parser.tab.h dart_parser.output
