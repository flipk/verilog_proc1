
#include <stdio.h>
#include <inttypes.h>
#include <string>
#include "tokenizer.H"
#include "parse_actions.H"
#include "output_file.H"

using namespace std;

#define OP1REG(op,x) ((op) | (x))
#define OP2REG(op,x,y) ((op) | (x) | ((y) << 4))

void
emit_2r(uint16_t opcode, uint16_t reg_x, uint16_t reg_y)
{
    of.add_line(2);
    of.add_word(OP2REG(opcode,reg_x,reg_y));
}

void
emit_2ri(uint16_t opcode, uint16_t reg_x,  expr * expression)
{
    of.add_line(4);
    of.add_word(OP1REG(opcode,reg_x));
    if (expression->name)
        of.add_relocation(expression->name);
    of.add_word(expression->value);
}

void
emit_1r(uint16_t opcode, uint16_t reg_x)
{
    of.add_line(2);
    of.add_word(OP1REG(opcode,reg_x));
}

void
emit_rel(uint16_t opcode, expr * expression)
{
    of.add_line(4);
    of.add_word(opcode);
    if (expression->name)
        of.add_relocation(expression->name,true);
    of.add_word(expression->value);
}

void
emit_abs(uint16_t opcode, expr * expression)
{
    of.add_line(4);
    of.add_word(opcode);
    if (expression->name)
        of.add_relocation(expression->name);
    of.add_word(expression->value);
}

void
emit_2ro(uint16_t opcode, uint16_t reg_x, expr * expression,
              uint16_t reg_y)
{
    of.add_line(4);
    of.add_word(OP2REG(opcode,reg_x,reg_y));
    if (expression->name)
        of.add_relocation(expression->name);
    of.add_word(expression->value);
}

void
add_symbol(std::string *name, uint16_t value)
{
    of.add_line(0);
    of.define_symbol(name, value, true);
}

void
add_label(std::string *name, bool global)
{
    of.add_line(0);
    of.define_symbol(name, global);
}

void
add_string(std::string *bytes, bool append_z)
{
    size_t i;
    uint16_t start_pos = of.get_current_pos();
    uint16_t final_length = 0;

    for (i = 0; i < bytes->length(); i++)
    {
        uint8_t c = (uint8_t) bytes->at(i);

        if (c == '\\')
        {
            bytes->erase(i,1);
            switch (bytes->at(i))
            {
            case 'r':  c = 0x0d; break;
            case 'n':  c = 0x0a; break;
            case 't':  c = 0x09; break;
            case '0':  c = 0x00; break;
            case 'b':  c = 0x08; break;
            case '\\': c = '\\'; break;
            default:
                fprintf(stderr, "unknown string escape char 0x%02x\n",
                        bytes->at(i));
            }
        }

        of.add_byte(c);
        final_length += 1;
    }

    if (append_z)
    {
        of.add_byte(0);
        final_length += 1;
    }

    of.add_line(start_pos, final_length);
}

void
add_bytes( expr * expression )
{
    uint16_t start_pos = of.get_current_pos();
    uint16_t final_length = 0;

    while (expression)
    {
        uint8_t b = (uint8_t) expression->value;
        if (expression->name)
            fprintf(stderr, "NOTE : symbols in 'byte' not supported\n");

        of.add_byte(b);
        final_length += 1;

        expression = expression->next;
    }

    of.add_line(start_pos, final_length);
}

void
add_words( expr * expression )
{
    uint16_t start_pos = of.get_current_pos();
    uint16_t final_length = 0;

    while (expression)
    {
        if (expression->name)
            of.add_relocation(expression->name);
        of.add_word(expression->value);
        final_length += 2;
        expression = expression->next;
    }

    of.add_line(start_pos, final_length);
}

void
add_space( expr * expression )
{
    of.add_space(expression->name, expression->value);
}

void
add_org   (uint16_t value)
{
    of.org = value;
    of.current_pos = value;
}
