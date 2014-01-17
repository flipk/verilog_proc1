
#include <inttypes.h>
#include <string.h>
#include <string>
#include "dll2.H"

struct Cpu {
    static const int memory_size = 65536;
    uint8_t   memory[memory_size];

    uint16_t  pc;
    uint16_t  regs[16];
    uint8_t   flag_c:1;
    uint8_t   flag_z:1;

    Cpu(void) {
        pc = 0;
        memset(regs, 0, sizeof(regs));
        flag_c = flag_z = 0;
    }

    void execute_instr(void);
};

enum {
    LISTING_LINE_LIST,
    LISTING_LINE_ADDDRHASH,
    LISTING_LINE_NUM_LISTS
};

struct listing_line {
    LListLinks <listing_line> links[LISTING_LINE_NUM_LISTS];
    uint16_t address;
    std::string * line;
};

class listingHashComparator {
public:
    static int hash_key( listing_line * item ) { return item->address/2; }
    static int hash_key( const uint16_t key ) { return key / 2; }
    static bool hash_key_compare( listing_line * item, 
                                  const uint16_t key ) {
        return (item->address == key);
    }
};

class Listing {
    LList <listing_line,LISTING_LINE_LIST>  lines;
    LListHash <listing_line,uint16_t,
               listingHashComparator,LISTING_LINE_ADDDRHASH> lineHash;
public:
    Listing(void) { }
    ~Listing(void) { 
        listing_line * l;
        while ((l = lines.dequeue_head()) != NULL)
        {
            lineHash.remove(l);
            delete l;
        }
    }
    void add(listing_line * l) {
        lines.add(l);
        lineHash.add(l);
    }
    listing_line * find( uint16_t addr ) { 
        return lineHash.find(addr);
    }
};

void  load_binary( Cpu * cpu, const char * filename );
void  load_listing( Listing * listing, const char * filename );
