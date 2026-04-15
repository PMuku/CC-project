/* A Bison parser, made by GNU Bison 2.3.  */

/* Skeleton interface for Bison's Yacc-like parsers in C

   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     ID = 258,
     NUM_INT = 259,
     NUM_DOUBLE = 260,
     STRING_LITERAL = 261,
     TRUE_LIT = 262,
     FALSE_LIT = 263,
     VOID = 264,
     MAIN = 265,
     INT_TYPE = 266,
     DOUBLE_TYPE = 267,
     BOOL_TYPE = 268,
     STRING_TYPE = 269,
     VAR = 270,
     IF = 271,
     ELSE = 272,
     WHILE = 273,
     OR = 274,
     AND = 275,
     EQ = 276,
     NEQ = 277,
     LE = 278,
     GE = 279,
     LT = 280,
     GT = 281,
     PLUS = 282,
     MINUS = 283,
     MUL = 284,
     DIV = 285,
     ASSIGN = 286,
     NOT = 287,
     SEMICOLON = 288,
     COMMA = 289,
     LPAREN = 290,
     RPAREN = 291,
     LBRACE = 292,
     RBRACE = 293,
     LOWER_THAN_ELSE = 294
   };
#endif
/* Tokens.  */
#define ID 258
#define NUM_INT 259
#define NUM_DOUBLE 260
#define STRING_LITERAL 261
#define TRUE_LIT 262
#define FALSE_LIT 263
#define VOID 264
#define MAIN 265
#define INT_TYPE 266
#define DOUBLE_TYPE 267
#define BOOL_TYPE 268
#define STRING_TYPE 269
#define VAR 270
#define IF 271
#define ELSE 272
#define WHILE 273
#define OR 274
#define AND 275
#define EQ 276
#define NEQ 277
#define LE 278
#define GE 279
#define LT 280
#define GT 281
#define PLUS 282
#define MINUS 283
#define MUL 284
#define DIV 285
#define ASSIGN 286
#define NOT 287
#define SEMICOLON 288
#define COMMA 289
#define LPAREN 290
#define RPAREN 291
#define LBRACE 292
#define RBRACE 293
#define LOWER_THAN_ELSE 294




#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
#line 40 "dart_parser.y"
{
    char *sval;
}
/* Line 1529 of yacc.c.  */
#line 131 "dart_parser.tab.h"
	YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif

extern YYSTYPE yylval;

