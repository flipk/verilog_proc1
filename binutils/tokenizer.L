/* -*- mode: c++; -*- */

%option noyywrap
%option yylineno
%option outfile="lex.yy.c"
 /* header-file="lex.yy.h" */

%{

#include <stdio.h>
#include <inttypes.h>
#include <iostream>
#include <string>
#include "tokenizer.H"
#include "parser.h"

using namespace std;

static string * strvec(const char * w, int len);
static int myinput( char *buf, int len );

char input_line[256];

#define YY_NO_INPUT 1
#define YY_INPUT(buf,result,max_size) result = myinput(buf, max_size)

%}

%%

ori   { return ORI; }
or    { return OR; }
andi  { return ANDI; }
and   { return AND; }
xori  { return XORI; }
xor   { return XOR; }
addbi { return ADDBI; }
addi  { return ADDI; }
addb  { return ADDB; }
add   { return ADD; }
subbi { return SUBBI; }
subi  { return SUBI; }
subb  { return SUBB; }
sub   { return SUB; }
rolbi { return ROLBI; }
roli  { return ROLI; }
rolb  { return ROLB; }
rol   { return ROL; }
cmpbi { return CMPBI; }
cmpi  { return CMPI; }
cmpb  { return CMPB; }
cmp   { return CMP; }
negb  { return NEGB; }
neg   { return NEG; }
lib   { return LIB; }
li    { return LI; }
ldbu  { return LDBU; }
ldu   { return LDU; }
ldb   { return LDB; }
ld    { return LD; }
stbu  { return STBU; }
stu   { return STU; }
stb   { return STB; }
st    { return ST; }
in    { return IN; }
out   { return OUT; }
brl   { return BRL; }
br    { return BR; }
ba    { return BA; }
beq   { return BEQ; }
bne   { return BNE; }
blt   { return BLT; }
bgt   { return BGT; }
ble   { return BLE; }
bge   { return BGE; }
jmpl  { return JMPL; }
jmp   { return JMP; }
mr    { return MR; }
org   { return ORG; }
equ   { return EQU; }
globl { return GLOBAL; }

\+    { return PLUS; }

r[0-9]+   { yylval.value = atoi(yytext+1); return REG; }

0x[0-9a-fA-F]+ { yylval.value = strtoul(yytext+2,NULL,16); return CONST; }
0b[0-1]+       { yylval.value = strtoul(yytext+2,NULL,2);  return CONST; }

-[0-9]+  { yylval.value = 0x10000-strtoul(yytext+1,NULL,10); return CONST; }
[0-9]+  { yylval.value = strtoul(yytext,NULL,10); return CONST; }

,       { return COMMA; }
\(      { return LP; }
\)      { return RP; }
#.*/(\r|\n)   { }
[ \t]+  { }
[\r\n]  { return NL; }

\".*\"   { 
    yylval.bytes = strvec(yytext+1,yyleng-2);
    return STRING;
}
asciiz  { return ASCIIZ; }
ascii   { return ASCII; }
byte    { return BYTE; }
word    { return WORD; }
space   { return SPACE; }

[a-zA-Z_][a-zA-Z0-9_]*:  {
    yylval.name = strvec(yytext,yyleng-1);
    return LABEL;
}
[a-zA-Z_][a-zA-Z0-9_]*   {
    yylval.name = strvec(yytext,yyleng);
    return SYMBOL;
}

%%

void
tokenizer_dummy_function(void)
{
    // with this, you can build with -Wall silently
    yyunput(0,0);
//    yyinput();
}

/* the return from this function needs to be deleted
   when it is no longer needed. */

static string *
strvec( const char * w, int len )
{
    string * ret = new string;

    ret->append(w, len);
    return ret;
}

static FILE * my_fin = NULL;

void
tokenizer_init(FILE *in)
{
    my_fin = in;
}

static int
myinput( char *buf, int len )
{
    char * ret = fgets(input_line, sizeof(input_line), my_fin);
    if (ret == NULL)
        return 0;

    int slen = strlen(input_line);
    if (slen > len)
        memcpy(buf, input_line, len);
    else
        memcpy(buf, input_line, slen);

    for (char *c = ret; *c; c++)
        if (*c == 10 || *c == 13)
            *c = 0;

    return slen;
}
