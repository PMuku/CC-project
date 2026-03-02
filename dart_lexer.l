%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int line = 1;

/* Better token printer */
void print_token(const char* type, const char* lexeme) {
    printf("Line %-3d | %-15s | %s\n", line, type, lexeme);
}

void lexical_error(const char* message) {
    printf("Lexical Error (line %d): %s\n", line, message);
}
%}

/* ---------- Start Conditions ---------- */
%x STRINGMODE
%x COMMENTMODE

/* ---------- Definitions ---------- */

DIGIT       [0-9]
LETTER      [a-zA-Z]
ID          {LETTER}({LETTER}|{DIGIT}|_)*
INT         {DIGIT}+
DOUBLE      {DIGIT}+"."{DIGIT}+
WHITESPACE  [ \t\r]+

%%
"//".*              { /* ignore */ }

"/*"                { BEGIN(COMMENTMODE); }

<COMMENTMODE>"*/"   { BEGIN(INITIAL); }

<COMMENTMODE>\n     { line++; }

<COMMENTMODE><<EOF>> {
                        lexical_error("Unclosed multi-line comment");
                        exit(1);
                    }

<COMMENTMODE>.      { /* ignore comment content */ }


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
                        lexical_error("Unclosed string at EOF");
                        exit(1);
                    }

<STRINGMODE>.       { yymore(); }


"void"      { print_token("VOID", yytext); }
"main"      { print_token("MAIN", yytext); }
"int"       { print_token("INT_TYPE", yytext); }
"double"    { print_token("DOUBLE_TYPE", yytext); }
"bool"      { print_token("BOOL_TYPE", yytext); }
"String"    { print_token("STRING_TYPE", yytext); }
"var"       { print_token("VAR", yytext); }

"if"        { print_token("IF", yytext); }
"else"      { print_token("ELSE", yytext); }
"while"     { print_token("WHILE", yytext); }

"true"      { print_token("TRUE", yytext); }
"false"     { print_token("FALSE", yytext); }


"||"        { print_token("OR", yytext); }
"&&"        { print_token("AND", yytext); }

"=="        { print_token("EQ", yytext); }
"!="        { print_token("NEQ", yytext); }

"<="        { print_token("LE", yytext); }
">="        { print_token("GE", yytext); }
"<"         { print_token("LT", yytext); }
">"         { print_token("GT", yytext); }

"+"         { print_token("PLUS", yytext); }
"-"         { print_token("MINUS", yytext); }
"*"         { print_token("MUL", yytext); }
"/"         { print_token("DIV", yytext); }

"="         { print_token("ASSIGN", yytext); }
"!"         { print_token("NOT", yytext); }


";"         { print_token("SEMICOLON", yytext); }
","         { print_token("COMMA", yytext); }

"("         { print_token("LPAREN", yytext); }
")"         { print_token("RPAREN", yytext); }
"{"         { print_token("LBRACE", yytext); }
"}"         { print_token("RBRACE", yytext); }


{DOUBLE}    { print_token("NUM_DOUBLE", yytext); }
{INT}       { print_token("NUM_INT", yytext); }


{ID}        { print_token("ID", yytext); }


{WHITESPACE}    { /* ignore */ }

\n              { line++; }


.           {
                char msg[100];
                snprintf(msg, sizeof(msg),
                         "Unexpected character '%s'", yytext);
                lexical_error(msg);
            }

%%

int main(int argc, char **argv) {
    if (argc > 1) {
        FILE *file = fopen(argv[1], "r");
        if (!file) {
            perror("File open failed");
            return 1;
        }
        yyin = file;
    }

    yylex();
    return 0;
}