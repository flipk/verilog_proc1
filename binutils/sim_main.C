
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "sim.H"

int
main()
{
    Cpu   cpu;
    Listing  listing;

    load_binary( &cpu, "memory.bin" );
    load_listing( &listing, "memory_listing.txt" );

    while (1)
    {
        listing_line * l = listing.find(cpu.pc);

        if (l)
            printf("%s\n", l->line->c_str());
        else
            printf("executing instr %04x at %04x (listing not found)\n",
                   (cpu.memory[cpu.pc] << 8) + cpu.memory[cpu.pc+1],
                   cpu.pc);

        cpu.execute_instr();
    }

    return 0;
}
