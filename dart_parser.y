%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int line;
extern FILE *yyin;

/* ---- TAC generation helpers ---- */
static int temp_count  = 0;
static int label_count = 0;

static char *new_temp(void) {
    char *buf = (char *)malloc(16);
    snprintf(buf, 16, "t%d", ++temp_count);
    return buf;
}

static char *new_label(void) {
    char *buf = (char *)malloc(16);
    snprintf(buf, 16, "L%d", ++label_count);
    return buf;
}

/* Emit a TAC instruction (indented) */
static void emit(const char *code) {
    printf("    %s\n", code);
}

/* Emit a label (flush left) */
static void emit_label(const char *label) {
    printf("%s:\n", label);
}

void yyerror(const char *s);
int  yylex(void);
%}

/* ---- Value type ---- */
%union {
    char *sval;
}

/* ---- Tokens with string values ---- */
%token <sval> ID NUM_INT NUM_DOUBLE STRING_LITERAL TRUE_LIT FALSE_LIT

/* ---- Keyword tokens (no value needed) ---- */
%token VOID MAIN
%token INT_TYPE DOUBLE_TYPE BOOL_TYPE STRING_TYPE VAR
%token IF ELSE WHILE

/* ---- Operator tokens ---- */
%token OR AND
%token EQ NEQ
%token LE GE LT GT
%token PLUS MINUS MUL DIV
%token ASSIGN NOT

/* ---- Punctuation tokens ---- */
%token SEMICOLON COMMA LPAREN RPAREN LBRACE RBRACE

/* ---- Non-terminal types ---- */
%type <sval> expr or_expr and_expr equality_expr relational_expr
%type <sval> additive_expr multiplicative_expr unary_expr primary_expr
%type <sval> if_start

/* ---- Dangling-else resolution:
        LOWER_THAN_ELSE < ELSE  (declared later = higher precedence)
        Rule "if_start block" gets %prec LOWER_THAN_ELSE so the parser
        shifts ELSE rather than reducing, binding else to the nearest if. ---- */
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

/* ==================================================================
   Top-level program
   ================================================================== */
program
    : VOID MAIN LPAREN RPAREN block
    ;

/* ==================================================================
   Block and statement list
   ================================================================== */
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

/* ==================================================================
   Declarations:  type id ;
                  type id = expr ;
                  var  id = expr ;
   ================================================================== */
declaration
    : type ID SEMICOLON
        { free($2); /* no TAC for uninitialised declaration */ }

    | type ID ASSIGN expr SEMICOLON
        {
            char buf[512];
            snprintf(buf, sizeof(buf), "%s = %s", $2, $4);
            emit(buf);
            free($2); free($4);
        }

    | VAR ID ASSIGN expr SEMICOLON
        {
            char buf[512];
            snprintf(buf, sizeof(buf), "%s = %s", $2, $4);
            emit(buf);
            free($2); free($4);
        }
    ;

type
    : INT_TYPE
    | DOUBLE_TYPE
    | BOOL_TYPE
    | STRING_TYPE
    ;

/* ==================================================================
   Assignment:  id = expr ;
   ================================================================== */
assignment
    : ID ASSIGN expr SEMICOLON
        {
            char buf[512];
            snprintf(buf, sizeof(buf), "%s = %s", $1, $3);
            emit(buf);
            free($1); free($3);
        }
    ;

/* ==================================================================
   if_start helper: parses "if ( expr )" and emits the conditional
   jump.  Returns the false-label (L_false) as $$.
   ================================================================== */
if_start
    : IF LPAREN expr RPAREN
        {
            char *l_false = new_label();
            char  buf[512];
            snprintf(buf, sizeof(buf), "if_false %s goto %s", $3, l_false);
            emit(buf);
            free($3);
            $$ = l_false;     /* pass L_false up */
        }
    ;

/* ==================================================================
   Conditional:
     (a) if ( expr ) block
     (b) if ( expr ) block else block
     (c) if ( expr ) block else conditional
   TAC template for (a):
       if_false <cond> goto L_false
       <true-block>
   L_false:

   TAC template for (b)/(c):
       if_false <cond> goto L_false
       <true-block>
       goto L_end
   L_false:
       <else-block>
   L_end:
   ================================================================== */
conditional
    /* (a) no else branch */
    : if_start block %prec LOWER_THAN_ELSE
        {
            emit_label($1);
            free($1);
        }

    /* (b)/(c) with else branch — mid-rule action emits goto + L_false: */
    | if_start block
        {
            /* $1 = L_false from if_start */
            char *l_end = new_label();
            char  buf[512];
            snprintf(buf, sizeof(buf), "goto %s", l_end);
            emit(buf);
            emit_label($1);   /* L_false: */
            free($1);
            $<sval>$ = l_end; /* becomes $3 — carry L_end forward */
        }
      ELSE else_part
        {
            /* $<sval>3 = L_end */
            emit_label($<sval>3);
            free($<sval>3);
        }
    ;

/* else_part covers both "else block" and "else conditional" */
else_part
    : block
    | conditional
    ;

/* ==================================================================
   Loop:  while ( expr ) block
   TAC template:
   L_start:
       if_false <cond> goto L_end
       <body>
       goto L_start
   L_end:
   ================================================================== */
loop
    : WHILE
        {
            /* mid-rule $2: emit L_start: and save it */
            char *ls = new_label();
            emit_label(ls);
            $<sval>$ = ls;
        }
      LPAREN expr RPAREN
        {
            /* mid-rule $6: emit conditional jump and save L_end */
            char *le  = new_label();
            char  buf[512];
            snprintf(buf, sizeof(buf), "if_false %s goto %s", $4, le);
            emit(buf);
            free($4);
            $<sval>$ = le;
        }
      block
        {
            /* emit back-edge and close loop */
            char buf[512];
            snprintf(buf, sizeof(buf), "goto %s", $<sval>2);
            emit(buf);
            emit_label($<sval>6);
            free($<sval>2);
            free($<sval>6);
        }
    ;

/* ==================================================================
   Expressions  (each rule returns a TAC name/temp as char*)
   Precedence (lowest to highest):
     OR  AND  EQ_NEQ  REL  ADD  MUL  unary  primary
   ================================================================== */
expr
    : or_expr { $$ = $1; }
    ;

or_expr
    : or_expr OR and_expr
        {
            char *t = new_temp();
            char  buf[512];
            snprintf(buf, sizeof(buf), "%s = %s || %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | and_expr { $$ = $1; }
    ;

and_expr
    : and_expr AND equality_expr
        {
            char *t = new_temp();
            char  buf[512];
            snprintf(buf, sizeof(buf), "%s = %s && %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | equality_expr { $$ = $1; }
    ;

equality_expr
    : equality_expr EQ relational_expr
        {
            char *t = new_temp();
            char  buf[512];
            snprintf(buf, sizeof(buf), "%s = %s == %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | equality_expr NEQ relational_expr
        {
            char *t = new_temp();
            char  buf[512];
            snprintf(buf, sizeof(buf), "%s = %s != %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | relational_expr { $$ = $1; }
    ;

relational_expr
    : relational_expr LT additive_expr
        {
            char *t = new_temp();
            char  buf[512];
            snprintf(buf, sizeof(buf), "%s = %s < %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | relational_expr GT additive_expr
        {
            char *t = new_temp();
            char  buf[512];
            snprintf(buf, sizeof(buf), "%s = %s > %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | relational_expr LE additive_expr
        {
            char *t = new_temp();
            char  buf[512];
            snprintf(buf, sizeof(buf), "%s = %s <= %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | relational_expr GE additive_expr
        {
            char *t = new_temp();
            char  buf[512];
            snprintf(buf, sizeof(buf), "%s = %s >= %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | additive_expr { $$ = $1; }
    ;

additive_expr
    : additive_expr PLUS multiplicative_expr
        {
            char *t = new_temp();
            char  buf[512];
            snprintf(buf, sizeof(buf), "%s = %s + %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | additive_expr MINUS multiplicative_expr
        {
            char *t = new_temp();
            char  buf[512];
            snprintf(buf, sizeof(buf), "%s = %s - %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | multiplicative_expr { $$ = $1; }
    ;

multiplicative_expr
    : multiplicative_expr MUL unary_expr
        {
            char *t = new_temp();
            char  buf[512];
            snprintf(buf, sizeof(buf), "%s = %s * %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | multiplicative_expr DIV unary_expr
        {
            char *t = new_temp();
            char  buf[512];
            snprintf(buf, sizeof(buf), "%s = %s / %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | unary_expr { $$ = $1; }
    ;

unary_expr
    : NOT unary_expr
        {
            char *t = new_temp();
            char  buf[512];
            snprintf(buf, sizeof(buf), "%s = !%s", t, $2);
            emit(buf);
            free($2);
            $$ = t;
        }
    | MINUS unary_expr
        {
            char *t = new_temp();
            char  buf[512];
            snprintf(buf, sizeof(buf), "%s = -%s", t, $2);
            emit(buf);
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

/* ==================================================================
   Error handler
   ================================================================== */
void yyerror(const char *s) {
    fprintf(stderr, "Syntax Error (line %d): %s\n", line, s);
}

/* ==================================================================
   Entry point
   ================================================================== */
int main(int argc, char **argv) {
    if (argc > 1) {
        FILE *fp = fopen(argv[1], "r");
        if (!fp) {
            perror("Cannot open file");
            return 1;
        }
        yyin = fp;
    }

    printf("=== Three-Address Code ===\n");
    int result = yyparse();
    if (result == 0)
        printf("\n[Parse successful — no syntax errors]\n");
    return result;
}
