%%

"void"      { printf("VOID\n"); }
"main"      { printf("MAIN\n"); }
"if"        { printf("IF\n"); }
"else"      { printf("ELSE\n"); }
"while"     { printf("WHILE\n"); }
"var"       { printf("VAR\n"); }

"int"       { printf("INT\n"); }
"double"    { printf("DOUBLE\n"); }
"bool"      { printf("BOOL\n"); }
"String"    { printf("STRING_T\n"); }

"true"      { printf("TRUE\n"); }
"false"     { printf("FALSE\n"); }

"=="        { printf("EQ\n"); }
"!="        { printf("NE\n"); }
"<="        { printf("LE\n"); }
">="        { printf("GE\n"); }
"&&"        { printf("AND\n"); }
"||"        { printf("OR\n"); }

"+"         { printf("PLUS\n"); }
"-"         { printf("MINUS\n"); }
"*"         { printf("MUL\n"); }
"/"         { printf("DIV\n"); }
"<"         { printf("LT\n"); }
">"         { printf("GT\n"); }
"!"         { printf("NOT\n"); }
"="         { printf("ASSIGN\n"); }

";"         { printf("SEMI\n"); }
"("         { printf("LPAREN\n"); }
")"         { printf("RPAREN\n"); }
"{"         { printf("LBRACE\n"); }
"}"         { printf("RBRACE\n"); }

[0-9]+(\.[0-9]+)?       { printf("NUM(%s)\n", yytext); }
\"([^\"\\]|\\.)*\"|\'([^\'\\]|\\.)*\'     { printf("STRING_LITERAL(%s)\n", yytext); }
[a-zA-Z_][a-zA-Z0-9_]*  { printf("ID(%s)\n", yytext); }

[ \t\n\r]+              ;
.                       { printf("UNKNOWN(%s)\n", yytext); }


%%

int main() {
    printf("Dart lexer...\n");
    yylex();
    return 0;
}