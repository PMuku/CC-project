%{
#include <stdio.h>
%}

KEYWORD   (void|main|if|else|while|var|int|double|bool|String|true|false)
NUM       [0-9]+(\.[0-9]+)?
ID        [a-zA-Z_][a-zA-Z0-9_]*
STRING    (\"([^\"\\]|\\.)*\"|\'([^\'\\]|\\.)*\')

SINGLE_COMMENT "//"[^\n]*
MULTI_COMMENT \/\*([^*]|\*+[^*/])*\*+\/
WHITESPACE [ \t\n\r]+

%%

{SINGLE_COMMENT}        ;
{MULTI_COMMENT}         ;
{WHITESPACE}            ;

{KEYWORD}   { fprintf(yyout, "KEYWORD(%s)\n", yytext); }


"=="        { fprintf(yyout, "EQ\n"); }
"!="        { fprintf(yyout, "NE\n"); }
"<="        { fprintf(yyout, "LE\n"); }
">="        { fprintf(yyout, "GE\n"); }
"&&"        { fprintf(yyout, "AND\n"); }
"||"        { fprintf(yyout, "OR\n"); }

"+"         { fprintf(yyout, "PLUS\n"); }
"-"         { fprintf(yyout, "MINUS\n"); }
"*"         { fprintf(yyout, "MUL\n"); }
"/"         { fprintf(yyout, "DIV\n"); }
"<"         { fprintf(yyout, "LT\n"); }
">"         { fprintf(yyout, "GT\n"); }
"!"         { fprintf(yyout, "NOT\n"); }
"="         { fprintf(yyout, "ASSIGN\n"); }

";"         { fprintf(yyout, "SEMI\n"); }
"("         { fprintf(yyout, "LPAREN\n"); }
")"         { fprintf(yyout, "RPAREN\n"); }
"{"         { fprintf(yyout, "LBRACE\n"); }
"}"         { fprintf(yyout, "RBRACE\n"); }

{NUM}       { fprintf(yyout, "NUM(%s)\n", yytext); }
{STRING}    { fprintf(yyout, "STRING_LITERAL(%s)\n", yytext); }
{ID}        { fprintf(yyout, "ID(%s)\n", yytext); }

.           { fprintf(yyout, "UNKNOWN(%s)\n", yytext); }


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
        yylex();

        fclose(in);
        fclose(yyout);
    }

    return 0;
}