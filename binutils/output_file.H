
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include "dll2.H"
#include "tokenizer.H"

enum { 
    SYMBOL_LIST,
//    SYMBOL_HASH,
    NUM_SYMBOL_LINKS
};

struct symbol {
    LListLinks <symbol> links[NUM_SYMBOL_LINKS];
    std::string * name;
    uint16_t address;
    bool relative; // only used in relocation entries
    bool global;
    symbol(void) { global = false; relative = false; name = NULL; }
};

struct listing_line {
    LListLinks <listing_line> links[1];
    uint16_t address;
    uint16_t length; // in bytes
    std::string * line;
};

typedef LList<symbol,SYMBOL_LIST> SymbolList;
typedef LList<listing_line,0>  Listing;

#define MEMORY_SIZE 65536

struct output_file {
    SymbolList  symbols;
    SymbolList  relocations;
    Listing     lines;
    uint8_t     memory[MEMORY_SIZE];
    uint16_t    word_buffer;
    bool        has_odd_buffer;
    uint16_t    org;
    uint16_t    current_pos;

    output_file(void) {
        memset(memory, 0, sizeof(memory));
        current_pos = 0;
        org = 0;
        has_odd_buffer = false;
    }
    ~output_file(void);
    uint16_t get_current_pos(void) {
        return current_pos + (has_odd_buffer ? 1 : 0);
    }
    void define_symbol(std::string *name, uint16_t address, bool global) {
        if (find_symbol(name) != NULL)
        {
            fprintf(stderr, "duplicate defn of symbol '%s'\n",
                    name->c_str());
            exit(1);
        }
        symbol * s = new symbol;
        s->name = name;
        s->address = address;
        s->global = global;
        symbols.add(s);
    }
    void define_symbol(std::string *name, bool global) {
        define_symbol(name, get_current_pos(), global);
    }
    symbol * find_symbol(std::string *name) {
        symbol * s;
        for (s = symbols.get_head(); s; s = symbols.get_next(s))
            if (*(s->name) == *(name))
                break;
        return s;
    }
    void add_line(uint16_t length) {
        add_line(get_current_pos(), length);
    }
    void add_line(uint16_t address, uint16_t length) {
        listing_line * l = new listing_line;
        l->address = address;
        l->length = length;
        l->line = new std::string;
        l->line->assign(input_line);
        lines.add(l);
    }
    void _add_word(uint16_t word) {
        memory[current_pos] = (word >> 8) & 0xFF;
        current_pos++;
        memory[current_pos] = (word >> 0) & 0xFF;
        current_pos++;
    }
    void add_word(uint16_t word) {
        if (has_odd_buffer)
        {
            _add_word(word_buffer);
            has_odd_buffer = false;
        }
        _add_word(word);
    }
    void add_byte(uint8_t byte) {
        if (has_odd_buffer)
        {
            word_buffer |= byte;
            has_odd_buffer = false;
            add_word(word_buffer);
        }
        else
        {
            word_buffer = byte << 8;
            has_odd_buffer = true;
        }
    }
    void add_space(std::string *name, uint16_t space);
    void add_relocation(std::string *name, bool relative=false) {
        symbol * s = new symbol;
        s->name = name;
        s->address = get_current_pos();
        s->relative = relative;
        relocations.add(s);
    }
    void resolve_relocations(void);
    void output(std::string filename, uint16_t hex_size);
};

extern output_file  of;
