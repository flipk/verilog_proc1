
#include "parser.h"

struct expr {
    std::string * name;
    uint16_t value;
    struct expr * next;

    expr(void) { next = NULL ; name = NULL; }
};

void emit_2r   (uint16_t opcode, uint16_t reg_x, uint16_t reg_y);
void emit_2ri  (uint16_t opcode, uint16_t reg_x,  expr * expression);
void emit_1r   (uint16_t opcode, uint16_t reg_x);
void emit_rel  (uint16_t opcode, expr * expression);
void emit_abs  (uint16_t opcode, expr * expression);
void emit_2ro  (uint16_t opcode, uint16_t reg_x,
                expr * expression, uint16_t reg_y);
void add_symbol(std::string *name, uint16_t value);
void add_label (std::string *name, bool global);
void add_string(std::string *bytes, bool append_z);
void add_bytes (expr * expression);
void add_words (expr * expression);
void add_space (expr * expression);
void add_org   (uint16_t value);
