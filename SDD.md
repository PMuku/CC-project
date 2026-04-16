# Syntax Directed Definitions (SDD) for our Dart subset

## Attribute Scheme

Expressions have two synthesized attributes:

- `X.place`: where the result goes (identifier, literal, or temp)
- `X.code`: TAC instructions to compute `X.place`

Statements have one attribute:

- `X.code`: TAC instructions for `X`

Helpers:

- `newtemp()`: generates t1, t2, t3, ...
- `newlabel()`: generates L1, L2, L3, ...

Sequencing:

- `A ||| B`: emit A's TAC, then B's TAC

---

## Notation Guide

**Grammar vs. SDD:**

- Productions use `||`, `&&` as operators: `<Or> -> <Or> || <And> | <And>`
- SDD uses `|||` on the right side only, to show TAC ordering:
  - `Or.code = Or1.code ||| And.code ||| (Or.place = Or1.place || And.place)`
  - This means: emit Or1's TAC, then And's TAC, then emit the assignment

**Attributes:**

- Expressions: `.place` and `.code`
- Statements: `.code` only
- Pass-through rules (e.g., `Unary -> Primary`) copy attributes, no new temps

---

## 1. Program

Production:

```
<Program> -> void main() <Block>
```

SDD:

```
Program.code = Block.code
```

---

## 2. Block and Statements

Productions:

```
<Block> -> { <StatementList> }
<StatementList> -> <Statement> <StatementList> | eps
<Statement> -> <Declaration> | <Assignment> | <Conditional> | <Loop> | <Block>
```

SDD:

```
Block.code = StatementList.code

StatementList -> Statement StatementList1
    StatementList.code = Statement.code ||| StatementList1.code

StatementList -> eps
    StatementList.code = ""

Statement -> Declaration
    Statement.code = Declaration.code

Statement -> Assignment
    Statement.code = Assignment.code

Statement -> Conditional
    Statement.code = Conditional.code

Statement -> Loop
    Statement.code = Loop.code

Statement -> Block
    Statement.code = Block.code
```

---

## 3. Declaration

Productions:

```
<Declaration> -> <Type> id ;
               | <Type> id = <Expression> ;
               | var id = <Expression> ;
<Type> -> int | double | bool | String
```

SDD:

```
Declaration -> Type id ;
    Declaration.code = ""

Declaration -> Type id = Expression ;
    Declaration.code = Expression.code ||| (id = Expression.place)

Declaration -> var id = Expression ;
    Declaration.code = Expression.code ||| (id = Expression.place)
```

---

## 4. Assignment

Production:

```
<Assignment> -> id = <Expression> ;
```

SDD:

```
Assignment.code = Expression.code ||| (id = Expression.place)
```

---

## 5. Expressions

Productions:

```
<Expression> -> <Or>
<Or> -> <Or> ||| <And> | <And>
<And> -> <And> && <Equality> | <Equality>
<Equality> -> <Equality> <EquOp> <Relational> | <Relational>
<Relational> -> <Relational> <RelOp> <Additive> | <Additive>
<Additive> -> <Additive> <AddOp> <Multiplicative> | <Multiplicative>
<Multiplicative> -> <Multiplicative> <MulOp> <Unary> | <Unary>
<Unary> -> ! <Unary> | - <Unary> | <Primary>
<Primary> -> id | num | string_literal | true | false | ( <Expression> )
<RelOp> -> < | > | <= | >=
<EquOp> -> == | !=
<AddOp> -> + | -
<MulOp> -> * | /
```

SDD:

```
Expression -> Or
    Expression.place = Or.place
    Expression.code  = Or.code

Or -> Or1 ||| And
    Or.place = newtemp()
    Or.code  = Or1.code ||| And.code ||| (Or.place = Or1.place || And.place)

Or -> And
    Or.place = And.place
    Or.code  = And.code

And -> And1 && Equality
    And.place = newtemp()
    And.code  = And1.code ||| Equality.code ||| (And.place = And1.place && Equality.place)

And -> Equality
    And.place = Equality.place
    And.code  = Equality.code

Equality -> Equality1 EquOp Relational
    Equality.place = newtemp()
    Equality.code  = Equality1.code ||| Relational.code |||
                     (Equality.place = Equality1.place EquOp.lexeme Relational.place)

Equality -> Relational
    Equality.place = Relational.place
    Equality.code  = Relational.code

Relational -> Relational1 RelOp Additive
    Relational.place = newtemp()
    Relational.code  = Relational1.code ||| Additive.code |||
                       (Relational.place = Relational1.place RelOp.lexeme Additive.place)

Relational -> Additive
    Relational.place = Additive.place
    Relational.code  = Additive.code

Additive -> Additive1 AddOp Multiplicative
    Additive.place = newtemp()
    Additive.code  = Additive1.code ||| Multiplicative.code |||
                     (Additive.place = Additive1.place AddOp.lexeme Multiplicative.place)

Additive -> Multiplicative
    Additive.place = Multiplicative.place
    Additive.code  = Multiplicative.code

Multiplicative -> Multiplicative1 MulOp Unary
    Multiplicative.place = newtemp()
    Multiplicative.code  = Multiplicative1.code ||| Unary.code |||
                           (Multiplicative.place = Multiplicative1.place MulOp.lexeme Unary.place)

Multiplicative -> Unary
    Multiplicative.place = Unary.place
    Multiplicative.code  = Unary.code

Unary -> ! Unary1
    Unary.place = newtemp()
    Unary.code  = Unary1.code ||| (Unary.place = ! Unary1.place)

Unary -> - Unary1
    Unary.place = newtemp()
    Unary.code  = Unary1.code ||| (Unary.place = - Unary1.place)

Unary -> Primary
    Unary.place = Primary.place
    Unary.code  = Primary.code

Primary -> id
    Primary.place = id
    Primary.code  = ""

Primary -> num
    Primary.place = num
    Primary.code  = ""

Primary -> string_literal
    Primary.place = string_literal
    Primary.code  = ""

Primary -> true
    Primary.place = true
    Primary.code  = ""

Primary -> false
    Primary.place = false
    Primary.code  = ""

Primary -> ( Expression )
    Primary.place = Expression.place
    Primary.code  = Expression.code
```

---

## 6. Conditional (if / if-else / else-if)

Productions:

```
<Conditional> -> if ( <Expression> ) <Block>
               | if ( <Expression> ) <Block> else <Conditional>
               | if ( <Expression> ) <Block> else <Block>
```

SDD:

```
Conditional -> if ( Expression ) Block
    L1 = newlabel()
    Conditional.code = Expression.code |||
                       (if Expression.place == false goto L1) |||
                       Block.code |||
                       (L1:)

Conditional -> if ( Expression ) Block1 else Conditional2
    L1 = newlabel()
    L2 = newlabel()
    Conditional.code = Expression.code |||
                       (if Expression.place == false goto L1) |||
                       Block1.code |||
                       (goto L2) |||
                       (L1:) |||
                       Conditional2.code |||
                       (L2:)

Conditional -> if ( Expression ) Block1 else Block2
    L1 = newlabel()
    L2 = newlabel()
    Conditional.code = Expression.code |||
                       (if Expression.place == false goto L1) |||
                       Block1.code |||
                       (goto L2) |||
                       (L1:) |||
                       Block2.code |||
                       (L2:)
```

---

## 7. Loop (while)

Production:

```
<Loop> -> while ( <Expression> ) <Block>
```

SDD:

```
Loop -> while ( Expression ) Block
    L1 = newlabel()
    L2 = newlabel()
    Loop.code = (L1:) |||
                Expression.code |||
                (if Expression.place == false goto L2) |||
                Block.code |||
                (goto L1) |||
                (L2:)
```

```
