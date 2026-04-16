%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int line;
extern FILE *yyin;
static FILE *tac_out = NULL;

static int temp_count = 0;
static char *newtemp(void) {
    char *b = malloc(16);
    snprintf(b, 16, "t%d", ++temp_count);
    return b;
}

static int label_count = 0;
static char *newlabel(void) {
    char *b = malloc(16);
    snprintf(b, 16, "L%d", ++label_count);
    return b;
}

static void emit(const char *s) {
    fprintf(tac_out, "    %s\n", s);
}

static void emit_label(const char *lbl) {
    fprintf(tac_out, "%s:\n", lbl);
}

static void emit_binop(char* res, char* a, const char* op, char* b) {
    char buf[256];
    snprintf(buf, sizeof buf, "%s = %s %s %s", res, a, op, b);
    emit(buf);
}

static void emit_unary(char* res, const char* op, char* val) {
    char buf[256];
    snprintf(buf, sizeof buf, "%s = %s%s", res, op, val);
    emit(buf);
}

void yyerror(const char *s);
int yylex(void);
%}

%union { char *sval; }

%token <sval> ID NUM_INT NUM_DOUBLE STRING_LITERAL TRUE_LIT FALSE_LIT

%token VOID MAIN
%token INT_TYPE DOUBLE_TYPE BOOL_TYPE STRING_TYPE VAR
%token IF ELSE WHILE

%token OR AND
%token EQ NEQ
%token LT GT LE GE
%token PLUS MINUS
%token MUL DIV
%token ASSIGN NOT

// these two are for better syntax error handling
%define parse.error detailed
%define parse.lac none

/* Punctuation terminals */
%token LPAREN RPAREN LBRACE RBRACE SEMICOLON COMMA

/* Nonterminals that carry a .place attribute */
%type <sval> expr or_expr and_expr equality_expr relational_expr
%type <sval> additive_expr multiplicative_expr unary_expr primary_expr
%type <sval> if_guard

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

program
    : VOID MAIN LPAREN RPAREN block
    ;

block
    : LBRACE stmt_list RBRACE
    ;

stmt_list
    : stmt stmt_list
    | /* empty */
    ;

stmt
    : declaration
    | assignment
    | conditional
    | loop
    | block
    ;

type
    : INT_TYPE
    | DOUBLE_TYPE
    | BOOL_TYPE
    | STRING_TYPE
    ;

declaration
    : type ID SEMICOLON
        { free($2); }

    | type ID ASSIGN expr SEMICOLON
        {
            char buf[256];
            snprintf(buf, sizeof buf, "%s = %s", $2, $4);
            emit(buf);
            free($2); free($4);
        }

    | VAR ID ASSIGN expr SEMICOLON
        {
            char buf[256];
            snprintf(buf, sizeof buf, "%s = %s", $2, $4);
            emit(buf);
            free($2); free($4);
        }
    ;

assignment
    : ID ASSIGN expr SEMICOLON
        {
            char buf[256];
            snprintf(buf, sizeof buf, "%s = %s", $1, $3);
            emit(buf);
            free($1); free($3);
        }
    ;

if_guard
    : IF LPAREN expr RPAREN
        {
            char *L1 = newlabel();
            char buf[256];
            snprintf(buf, sizeof buf, "if_false %s goto %s", $3, L1);
            emit(buf);
            free($3);
            $$ = L1;
        }
    ;

conditional
    : if_guard block %prec LOWER_THAN_ELSE
        {
            emit_label($1);
            free($1);
        }

    | if_guard block
        {
            char *L2 = newlabel();
            char buf[256];
            snprintf(buf, sizeof buf, "goto %s", L2);
            emit(buf);
            emit_label($1);
            free($1);
            $<sval>$ = L2;
        }
      ELSE else_part
        {
            emit_label($<sval>3);
            free($<sval>3);
        }
    ;

else_part
    : block
    | conditional
    ;

loop
    : WHILE
        {
            char *L1 = newlabel();
            emit_label(L1);
            $<sval>$ = L1;
        }
      LPAREN expr RPAREN
        {
            char *L2 = newlabel();
            char buf[256];
            snprintf(buf, sizeof buf, "if_false %s goto %s", $4, L2);
            emit(buf);
            free($4);
            $<sval>$ = L2;
        }
      block
        {
            char buf[256];
            snprintf(buf, sizeof buf, "goto %s", $<sval>2);
            emit(buf);
            emit_label($<sval>6);
            free($<sval>2);
            free($<sval>6);
        }
    ;

expr : or_expr { $$ = $1; };

or_expr
    : or_expr OR and_expr
        {
            char *t = newtemp();
            emit_binop(t, $1, "||", $3);
            free($1); free($3);
            $$ = t;
        }
    | and_expr { $$ = $1; }
    ;

and_expr
    : and_expr AND equality_expr
        {
            char *t = newtemp();
            emit_binop(t, $1, "&&", $3);
            free($1); free($3);
            $$ = t;
        }
    | equality_expr { $$ = $1; }
    ;

equality_expr
    : equality_expr EQ relational_expr
        {
            char *t = newtemp();
            emit_binop(t, $1, "==", $3);
            free($1); free($3);
            $$ = t;
        }
    | equality_expr NEQ relational_expr
        {
            char *t = newtemp();
            emit_binop(t, $1, "!=", $3);
            free($1); free($3);
            $$ = t;
        }
    | relational_expr { $$ = $1; }
    ;

relational_expr
    : relational_expr LT additive_expr
        {
            char *t = newtemp();
            emit_binop(t, $1, "<", $3);
            free($1); free($3);
            $$ = t;
        }
    | relational_expr GT additive_expr
        {
            char *t = newtemp();
            emit_binop(t, $1, ">", $3);
            free($1); free($3);
            $$ = t;
        }
    | relational_expr LE additive_expr
        {
            char *t = newtemp();
            emit_binop(t, $1, "<=", $3);
            free($1); free($3);
            $$ = t;
        }
    | relational_expr GE additive_expr
        {
            char *t = newtemp();
            emit_binop(t, $1, ">=", $3);
            free($1); free($3);
            $$ = t;
        }
    | additive_expr { $$ = $1; }
    ;

additive_expr
    : additive_expr PLUS multiplicative_expr
        {
            char *t = newtemp();
            emit_binop(t, $1, "+", $3);
            free($1); free($3);
            $$ = t;
        }
    | additive_expr MINUS multiplicative_expr
        {
            char *t = newtemp();
            emit_binop(t, $1, "-", $3);
            free($1); free($3);
            $$ = t;
        }
    | multiplicative_expr { $$ = $1; }
    ;

multiplicative_expr
    : multiplicative_expr MUL unary_expr
        {
            char *t = newtemp();
            emit_binop(t, $1, "*", $3);
            free($1); free($3);
            $$ = t;
        }
    | multiplicative_expr DIV unary_expr
        {
            char *t = newtemp();
            emit_binop(t, $1, "/", $3);
            free($1); free($3);
            $$ = t;
        }
    | unary_expr { $$ = $1; }
    ;

unary_expr
    : NOT unary_expr
        {
            char *t = newtemp();
            emit_unary(t, "!", $2);
            free($2);
            $$ = t;
        }
    | MINUS unary_expr
        {
            char *t = newtemp();
            emit_unary(t, "-", $2);
            free($2);
            $$ = t;
        }
    | primary_expr { $$ = $1; }
    ;

primary_expr
    : ID             { $$ = $1; }
    | NUM_INT        { $$ = $1; }
    | NUM_DOUBLE     { $$ = $1; }
    | STRING_LITERAL { $$ = $1; }
    | TRUE_LIT       { $$ = $1; }
    | FALSE_LIT      { $$ = $1; }
    | LPAREN expr RPAREN { $$ = $2; }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Syntax Error (line %d): %s\n", line, s);
}

int main(int argc, char **argv) {
    if (argc > 1) {
        FILE *fp = fopen(argv[1], "r");
        if (!fp) { perror("Cannot open file"); return 1; }
        yyin = fp;
    }

    {
        const char *out_path = (argc > 2) ? argv[2] : "tac_output.txt";
        tac_out = fopen(out_path, "w");
        if (!tac_out) {
            perror("Cannot open output file");
            return 1;
        }
    }

    fprintf(tac_out, "=== Three-Address Code ===\n");
    {
        int ret = yyparse();
        fclose(tac_out);
        tac_out = NULL;
        return ret;
    }
}
