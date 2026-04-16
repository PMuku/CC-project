%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "dart_parser.tab.h"

int line = 1;
%}

%option noinput nounput

%x STRINGMODE
%x COMMENTMODE

DIGIT       [0-9]
LETTER      [a-zA-Z]
ID          {LETTER}({LETTER}|{DIGIT}|_)*
INT         {DIGIT}+
DOUBLE      {DIGIT}+"."{DIGIT}+
WHITESPACE  [ \t\r]+

%%

"//".*              { }

"/*"                { BEGIN(COMMENTMODE); }
<COMMENTMODE>"*/"   { BEGIN(INITIAL); }
<COMMENTMODE>\n     { line++; }
<COMMENTMODE><<EOF>> {
    fprintf(stderr, "Lexical Error (line %d): Unclosed multi-line comment\n", line);
    exit(1);
}
<COMMENTMODE>.      { }

\"                  { BEGIN(STRINGMODE); yymore(); }
<STRINGMODE>\"      {
    yymore();
    yylval.sval = strdup(yytext);
    BEGIN(INITIAL);
    return STRING_LITERAL;
}
<STRINGMODE>\\[nrt\"\\] { yymore(); }
<STRINGMODE>\n      {
    fprintf(stderr, "Lexical Error (line %d): Unclosed string literal\n", line);
    line++;
    BEGIN(INITIAL);
}
<STRINGMODE><<EOF>> {
    fprintf(stderr, "Lexical Error (line %d): Unclosed string at EOF\n", line);
    exit(1);
}
<STRINGMODE>.       { yymore(); }

"void"      { return VOID; }
"main"      { return MAIN; }
"int"       { return INT_TYPE; }
"double"    { return DOUBLE_TYPE; }
"bool"      { return BOOL_TYPE; }
"String"    { return STRING_TYPE; }
"var"       { return VAR; }
"if"        { return IF; }
"else"      { return ELSE; }
"while"     { return WHILE; }
"true"      { yylval.sval = strdup(yytext); return TRUE_LIT; }
"false"     { yylval.sval = strdup(yytext); return FALSE_LIT; }

"||"        { return OR; }
"&&"        { return AND; }
"=="        { return EQ; }
"!="        { return NEQ; }
"<="        { return LE; }
">="        { return GE; }
"<"         { return LT; }
">"         { return GT; }
"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return MUL; }
"/"         { return DIV; }
"="         { return ASSIGN; }
"!"         { return NOT; }
";"         { return SEMICOLON; }
","         { return COMMA; }
"("         { return LPAREN; }
")"         { return RPAREN; }
"{"         { return LBRACE; }
"}"         { return RBRACE; }

{DOUBLE}    { yylval.sval = strdup(yytext); return NUM_DOUBLE; }
{INT}       { yylval.sval = strdup(yytext); return NUM_INT; }
{ID}        { yylval.sval = strdup(yytext); return ID; }

{WHITESPACE}    { }
\n              { line++; }

.           {
    fprintf(stderr, "Lexical Error (line %d): Unexpected character '%s'\n", line, yytext);
}

%%

int yywrap(void) { return 1; }
