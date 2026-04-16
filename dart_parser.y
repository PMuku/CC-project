%{
/*
 * dart_parser.y
 * Bison parser generated directly from SDD.md.
 *
 * Attribute model (from SDD §Attribute Scheme):
 *   - Expression-like nonterminals carry a synthesised .place (char *$$)
 *     and emit their .code as side-effects via emit().
 *   - Statement-like nonterminals have no return value; they emit their
 *     .code as side-effects.
 *
 * SDD helper functions:
 *   newtemp()  -> t1, t2, t3, ...
 *   newlabel() -> L1, L2, L3, ...
 *   |||        -> TAC-sequence concatenation (ordering of emit() calls)
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int   line;
extern FILE *yyin;

/* --- SDD helper: newtemp() --- */
static int temp_count = 0;
static char *newtemp(void) {
    char *b = malloc(16);
    snprintf(b, 16, "t%d", ++temp_count);
    return b;
}

/* --- SDD helper: newlabel() --- */
static int label_count = 0;
static char *newlabel(void) {
    char *b = malloc(16);
    snprintf(b, 16, "L%d", ++label_count);
    return b;
}

/* Emit one TAC instruction (indented) */
static void emit(const char *s) {
    printf("    %s\n", s);
}

/* Emit a label definition (flush-left) */
static void emit_label(const char *lbl) {
    printf("%s:\n", lbl);
}

void yyerror(const char *s);
int  yylex(void);
%}

/* -----------------------------------------------------------------------
 * Value type: every nonterminal that carries a .place returns a char*.
 * ----------------------------------------------------------------------- */
%union { char *sval; }

/* Terminals whose lexeme is needed at semantic-action time */
%token <sval> ID NUM_INT NUM_DOUBLE STRING_LITERAL TRUE_LIT FALSE_LIT

/* Keyword terminals */
%token VOID MAIN
%token INT_TYPE DOUBLE_TYPE BOOL_TYPE STRING_TYPE VAR
%token IF ELSE WHILE

/* Operator terminals */
%token OR AND
%token EQ NEQ
%token LT GT LE GE
%token PLUS MINUS
%token MUL DIV
%token ASSIGN NOT

/* Punctuation terminals */
%token LPAREN RPAREN LBRACE RBRACE SEMICOLON COMMA

/* Nonterminals that carry a .place attribute */
%type <sval> expr or_expr and_expr equality_expr relational_expr
%type <sval> additive_expr multiplicative_expr unary_expr primary_expr
%type <sval> if_guard

/*
 * Dangling-else fix: declare LOWER_THAN_ELSE before ELSE so ELSE has
 * higher precedence.  The "if_guard block" (no-else) rule gets
 * %prec LOWER_THAN_ELSE, causing the parser to shift ELSE when present.
 */
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

/* =======================================================================
 * SDD §1 — Program
 *
 * Production:  <Program> -> void main() <Block>
 * SDD:         Program.code = Block.code
 * ======================================================================= */
program
    : VOID MAIN LPAREN RPAREN block
    ;

/* =======================================================================
 * SDD §2 — Block and Statements
 *
 * <Block>         -> { <StatementList> }
 * <StatementList> -> <Statement> <StatementList>  |  eps
 * <Statement>     -> <Declaration> | <Assignment> | <Conditional>
 *                  | <Loop> | <Block>
 *
 * Block.code         = StatementList.code
 * StatementList.code = Statement.code ||| StatementList1.code
 * StatementList.code = ""                                      (eps)
 * Statement.code     = <whichever alternative>.code
 * ======================================================================= */
block
    : LBRACE stmt_list RBRACE
    ;

stmt_list
    : stmt stmt_list
    | /* eps — StatementList.code = "" */
    ;

stmt
    : declaration
    | assignment
    | conditional
    | loop
    | block
    ;

/* =======================================================================
 * SDD §3 — Declaration
 *
 * <Declaration> -> <Type> id ;
 *     Declaration.code = ""
 *
 * <Declaration> -> <Type> id = <Expression> ;
 *     Declaration.code = Expression.code ||| (id = Expression.place)
 *
 * <Declaration> -> var id = <Expression> ;
 *     Declaration.code = Expression.code ||| (id = Expression.place)
 *
 * <Type> -> int | double | bool | String   (no attributes needed)
 * ======================================================================= */
type
    : INT_TYPE
    | DOUBLE_TYPE
    | BOOL_TYPE
    | STRING_TYPE
    ;

declaration
    : type ID SEMICOLON
        {
            /* Declaration.code = "" */
            free($2);
        }

    | type ID ASSIGN expr SEMICOLON
        {
            /* Expression.code already emitted above.
             * Emit: id = Expression.place  */
            char buf[512];
            snprintf(buf, sizeof buf, "%s = %s", $2, $4);
            emit(buf);
            free($2);
            free($4);
        }

    | VAR ID ASSIGN expr SEMICOLON
        {
            /* Expression.code already emitted above.
             * Emit: id = Expression.place  */
            char buf[512];
            snprintf(buf, sizeof buf, "%s = %s", $2, $4);
            emit(buf);
            free($2);
            free($4);
        }
    ;

/* =======================================================================
 * SDD §4 — Assignment
 *
 * <Assignment> -> id = <Expression> ;
 *     Assignment.code = Expression.code ||| (id = Expression.place)
 * ======================================================================= */
assignment
    : ID ASSIGN expr SEMICOLON
        {
            /* Expression.code already emitted above.
             * Emit: id = Expression.place  */
            char buf[512];
            snprintf(buf, sizeof buf, "%s = %s", $1, $3);
            emit(buf);
            free($1);
            free($3);
        }
    ;

/* =======================================================================
 * SDD §6 — Conditional
 *
 * (a) if ( Expression ) Block
 *     L1 = newlabel()
 *     Conditional.code = Expression.code |||
 *                        (if Expression.place == false goto L1) |||
 *                        Block.code |||
 *                        (L1:)
 *
 * (b) if ( Expression ) Block1 else Conditional2
 *     L1 = newlabel()    L2 = newlabel()
 *     Conditional.code = Expression.code |||
 *                        (if Expression.place == false goto L1) |||
 *                        Block1.code |||
 *                        (goto L2) |||
 *                        (L1:) |||
 *                        Conditional2.code |||
 *                        (L2:)
 *
 * (c) if ( Expression ) Block1 else Block2   — same shape as (b)
 *
 * Implementation note:
 *   "if_guard" is a named rule for "if ( expr )" that emits the
 *   conditional jump and returns L1.  This avoids the reduce/reduce
 *   conflict that would arise from two rules with identical anonymous
 *   mid-rule-action prefixes.
 * ======================================================================= */

/* Parses "if ( expr )" and emits: if_false expr.place goto L1
 * Returns L1 as $$.                                              */
if_guard
    : IF LPAREN expr RPAREN
        {
            char *L1 = newlabel();
            char  buf[512];
            snprintf(buf, sizeof buf, "if_false %s goto %s", $3, L1);
            emit(buf);          /* (if Expression.place == false goto L1) */
            free($3);
            $$ = L1;
        }
    ;

conditional
    /* (a) — no else */
    : if_guard block %prec LOWER_THAN_ELSE
        {
            emit_label($1);     /* (L1:) */
            free($1);
        }

    /* (b)/(c) — with else; mid-rule action emits (goto L2) and (L1:) */
    | if_guard block
        {
            /* After Block1.code has been emitted:
             *   emit (goto L2)
             *   emit (L1:)
             *   carry L2 to the closing action  */
            char *L2 = newlabel();
            char  buf[512];
            snprintf(buf, sizeof buf, "goto %s", L2);
            emit(buf);          /* (goto L2) */
            emit_label($1);     /* (L1:)     */
            free($1);
            $<sval>$ = L2;      /* becomes $3 */
        }
      ELSE else_part
        {
            emit_label($<sval>3); /* (L2:) */
            free($<sval>3);
        }
    ;

/* Covers both "else Block" and "else Conditional" */
else_part
    : block
    | conditional
    ;

/* =======================================================================
 * SDD §7 — Loop
 *
 * <Loop> -> while ( <Expression> ) <Block>
 *     L1 = newlabel()    L2 = newlabel()
 *     Loop.code = (L1:) |||
 *                 Expression.code |||
 *                 (if Expression.place == false goto L2) |||
 *                 Block.code |||
 *                 (goto L1) |||
 *                 (L2:)
 *
 * Two mid-rule actions:
 *   $2: emits (L1:) before the condition is parsed, carries L1.
 *   $6: emits the conditional jump after the condition, carries L2.
 * ======================================================================= */
loop
    : WHILE
        {
            char *L1 = newlabel();
            emit_label(L1);     /* (L1:) */
            $<sval>$ = L1;      /* carry L1 — becomes $2 */
        }
      LPAREN expr RPAREN
        {
            char *L2 = newlabel();
            char  buf[512];
            snprintf(buf, sizeof buf, "if_false %s goto %s", $4, L2);
            emit(buf);          /* (if Expression.place == false goto L2) */
            free($4);
            $<sval>$ = L2;      /* carry L2 — becomes $6 */
        }
      block
        {
            char buf[512];
            snprintf(buf, sizeof buf, "goto %s", $<sval>2);
            emit(buf);            /* (goto L1) */
            emit_label($<sval>6); /* (L2:)     */
            free($<sval>2);
            free($<sval>6);
        }
    ;

/* =======================================================================
 * SDD §5 — Expressions
 *
 * Each rule sets $$ = place (a malloc'd string).
 * The .code attribute is realised by the sequence of emit() calls, which
 * corresponds exactly to the ||| (TAC concatenation) ordering in the SDD.
 * ======================================================================= */

/* Expression -> Or */
expr : or_expr { $$ = $1; } ;

/* Or -> Or || And  |  And */
or_expr
    : or_expr OR and_expr
        {
            /* Or.place = newtemp()
             * Or.code  = Or1.code ||| And.code |||
             *             (Or.place = Or1.place || And.place)   */
            char *t = newtemp();
            char  buf[512];
            snprintf(buf, sizeof buf, "%s = %s || %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | and_expr { $$ = $1; }
    ;

/* And -> And && Equality  |  Equality */
and_expr
    : and_expr AND equality_expr
        {
            /* And.place = newtemp()
             * And.code  = And1.code ||| Equality.code |||
             *             (And.place = And1.place && Equality.place) */
            char *t = newtemp();
            char  buf[512];
            snprintf(buf, sizeof buf, "%s = %s && %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | equality_expr { $$ = $1; }
    ;

/* Equality -> Equality EquOp Relational  |  Relational
 * EquOp -> ==  |  !=                                   */
equality_expr
    : equality_expr EQ relational_expr
        {
            char *t = newtemp();
            char  buf[512];
            snprintf(buf, sizeof buf, "%s = %s == %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | equality_expr NEQ relational_expr
        {
            char *t = newtemp();
            char  buf[512];
            snprintf(buf, sizeof buf, "%s = %s != %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | relational_expr { $$ = $1; }
    ;

/* Relational -> Relational RelOp Additive  |  Additive
 * RelOp -> <  |  >  |  <=  |  >=                       */
relational_expr
    : relational_expr LT additive_expr
        {
            char *t = newtemp();
            char  buf[512];
            snprintf(buf, sizeof buf, "%s = %s < %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | relational_expr GT additive_expr
        {
            char *t = newtemp();
            char  buf[512];
            snprintf(buf, sizeof buf, "%s = %s > %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | relational_expr LE additive_expr
        {
            char *t = newtemp();
            char  buf[512];
            snprintf(buf, sizeof buf, "%s = %s <= %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | relational_expr GE additive_expr
        {
            char *t = newtemp();
            char  buf[512];
            snprintf(buf, sizeof buf, "%s = %s >= %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | additive_expr { $$ = $1; }
    ;

/* Additive -> Additive AddOp Multiplicative  |  Multiplicative
 * AddOp -> +  |  -                                             */
additive_expr
    : additive_expr PLUS multiplicative_expr
        {
            char *t = newtemp();
            char  buf[512];
            snprintf(buf, sizeof buf, "%s = %s + %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | additive_expr MINUS multiplicative_expr
        {
            char *t = newtemp();
            char  buf[512];
            snprintf(buf, sizeof buf, "%s = %s - %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | multiplicative_expr { $$ = $1; }
    ;

/* Multiplicative -> Multiplicative MulOp Unary  |  Unary
 * MulOp -> *  |  /                                       */
multiplicative_expr
    : multiplicative_expr MUL unary_expr
        {
            char *t = newtemp();
            char  buf[512];
            snprintf(buf, sizeof buf, "%s = %s * %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | multiplicative_expr DIV unary_expr
        {
            char *t = newtemp();
            char  buf[512];
            snprintf(buf, sizeof buf, "%s = %s / %s", t, $1, $3);
            emit(buf);
            free($1); free($3);
            $$ = t;
        }
    | unary_expr { $$ = $1; }
    ;

/* Unary -> ! Unary  |  - Unary  |  Primary */
unary_expr
    : NOT unary_expr
        {
            /* Unary.place = newtemp()
             * Unary.code  = Unary1.code ||| (Unary.place = ! Unary1.place) */
            char *t = newtemp();
            char  buf[512];
            snprintf(buf, sizeof buf, "%s = !%s", t, $2);
            emit(buf);
            free($2);
            $$ = t;
        }
    | MINUS unary_expr
        {
            /* Unary.place = newtemp()
             * Unary.code  = Unary1.code ||| (Unary.place = - Unary1.place) */
            char *t = newtemp();
            char  buf[512];
            snprintf(buf, sizeof buf, "%s = -%s", t, $2);
            emit(buf);
            free($2);
            $$ = t;
        }
    | primary_expr { $$ = $1; }
    ;

/* Primary -> id | num | string_literal | true | false | ( Expression )
 *
 * Primary.place = the terminal itself (or Expression.place)
 * Primary.code  = ""  (no TAC emitted for literals/identifiers)       */
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
    printf("=== Three-Address Code ===\n");
    int r = yyparse();
    if (r == 0)
        printf("\n[Parse successful — no syntax errors]\n");
    return r;
}
