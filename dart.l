%%

[a-zA-Z_][a-zA-Z_0-9]+ printf("%s: IDENTIFIER\n", yytext);


%%

int main() {
    printf("Dart lexer...\n");
    yylex();
    return 0;
}