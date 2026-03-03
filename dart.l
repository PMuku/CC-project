%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int line = 1;
int errors = 0;

// print tokens to file
void print_token(const char* type, const char* lexeme) {
    fprintf(yyout, "Line %-3d | %-35s | %s\n", line, type, lexeme);
}

// print error to stdout
void lexical_error(const char* message) {
    printf("Lexical Error (line %d): %s\n", line, message);
    errors++;
}

%}

%x STRINGMODE
%x COMMENTMODE

KEYWORD   (void|main|if|else|while|var|int|double|bool|String|true|false)
NUM       [0-9]+(\.[0-9]+)?
ID        [a-zA-Z_][a-zA-Z0-9_]*
STRING    (\"([^\"\\]|\\.)*\"|\'([^\'\\]|\\.)*\')

SINGLE_COMMENT "//"[^\n]*
MULTI_COMMENT \/\*([^*]|\*+[^*/])*\*+\/
WHITESPACE [ \t\n\r]+

%%

{SINGLE_COMMENT}        ;

"/*"  { BEGIN(COMMENTMODE); }
<COMMENTMODE>"*/"   { BEGIN(INITIAL); }
<COMMENTMODE>\n     { line++; }
<COMMENTMODE><<EOF>> {
                        lexical_error("Unclosed multi-line comment");
                        exit(1);
                    }
<COMMENTMODE>.      ;

\"                  { BEGIN(STRINGMODE); yymore(); }
<STRINGMODE>\"      {
                        yymore();
                        print_token("STRING_LITERAL", yytext);
                        BEGIN(INITIAL);
                    }
                    
<STRINGMODE>\\[nrt\"\\]   { yymore(); }

<STRINGMODE>\n      {
                        lexical_error("Unclosed string literal");
                        line++;
                        BEGIN(INITIAL);
                    }

<STRINGMODE><<EOF>> {
                        lexical_error("Unclosed string literal at EOF");
                        exit(1);
                    }

<STRINGMODE>.     { yymore(); }

{WHITESPACE}      { if (strchr(yytext, '\n')) line++; }

{KEYWORD}   { print_token("KEYWORD", yytext); }


"=="        { print_token("EQ", yytext); }
"!="        { print_token("NE", yytext); }
"<="        { print_token("LE", yytext); }
">="        { print_token("GE", yytext); }
"&&"        { print_token("AND", yytext); }
"||"        { print_token("OR", yytext); }

"+"         { print_token("PLUS", yytext); }
"-"         { print_token("MINUS", yytext); }
"*"         { print_token("MUL", yytext); }
"/"         { print_token("DIV", yytext); }
"<"         { print_token("LT", yytext); }
">"         { print_token("GT", yytext); }
"!"         { print_token("NOT", yytext); }
"="         { print_token("ASSIGN", yytext); }

";"         { print_token("SEMI", yytext); }
"("         { print_token("LPAREN", yytext); }
")"         { print_token("RPAREN", yytext); }
"{"         { print_token("LBRACE", yytext); }
"}"         { print_token("RBRACE", yytext); }

[0-9]+(\.[0-9]+){2,}  { lexical_error("Malformed number"); }

{NUM}       { print_token("NUM", yytext); }
{ID}        { print_token("ID", yytext); }

.           { print_token("UNKNOWN", yytext); }


%%

int main(int argc, char **argv) {

    if (argc < 2) {
        fprintf(stderr, "Usage: %s <input_file(s)>\n", argv[0]);
        return 1;
    }

    printf("Dart lexer...\n");

    for (int i = 1; i < argc; i++) {
        const char *in_file = argv[i];
        FILE *in = fopen(in_file, "r");
        if (!in) {
            fprintf(stderr, "Could not open file: %s\n", in_file);
            continue;
        }
        yyin = in;
        yyrestart(yyin);

        char out_file[256];
        snprintf(out_file, sizeof(out_file), "output_tokens_%d.txt", i);

        yyout = fopen(out_file, "w");
        if (!yyout) {
            fprintf(stderr, "Could not create output file: %s\n", out_file);
            fclose(in);
            continue;
        }

        printf("Processing file: %s\n", in_file);
        errors = 0; // reset error count for each file
        line = 1;  // reset line count for each file
        yylex();

        if (errors == 0) {
            printf("No lexical errors.\n");
        } else {
            printf("Lexical errors found: %d\n", errors);
        }

        fclose(in);
        fclose(yyout);
    }

    return 0;
}
