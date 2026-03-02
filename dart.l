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

{SINGLE_COMMENT}        { fprintf(yyout, "Single line comment\n"); }
{MULTI_COMMENT}         { fprintf(yyout, "Multi line comment\n"); }
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

.                       { fprintf(yyout, "UNKNOWN(%s)\n", yytext); }


%%

int main() {
    printf("Dart lexer...\n");
    // yyin = fopen("test_correct.dart", "r");
    // yyin = fopen("test_error.dart", "r");
    // yyout = fopen("output_correct.txt", "w");
    // yyout = fopen("output_error.txt", "w");
    yylex();
    return 0;
}