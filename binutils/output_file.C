
#include "output_file.H"

output_file :: ~output_file(void)
{
    symbol * s;
    listing_line * l;
    while ((s = symbols.dequeue_head()) != NULL)
        delete s;
    while ((s = relocations.dequeue_head()) != NULL)
        delete s;
    while ((l = lines.dequeue_head()) != NULL)
        delete l;
}

void
output_file :: resolve_relocations( void )
{
    symbol * r, * s;
    while ((r = relocations.dequeue_head()) != NULL)
    {
        s = find_symbol(r->name);
        if (!s)
        {
            fprintf(stderr, "error relocation for '%s' not found\n",
                    r->name->c_str());
            exit(1);
        }
        else
        {
            uint16_t word = 0;

            if (r->relative)
            {
                word = s->address - (r->address + 2);
            }
            else
            {
                word = (memory[r->address] << 8) + memory[r->address];
                word += s->address;
            }

            memory[r->address+0] = (word >> 8) & 0xFF;
            memory[r->address+1] = (word >> 0) & 0xFF;
        }
        delete r;
    }
}

void
output_file :: add_space( std::string *name, uint16_t space )
{
    uint16_t name_value = 0;
    if (name)
    {
        symbol * s = find_symbol(name);
        if (!s)
        {
            fprintf(stderr, "space argument must be a constant "
                    "or defined symbol\n");
            exit(1);
        }
        name_value = s->address;
    }
    current_pos += name_value + space;
}

void
output_file :: output( std::string filename, uint16_t hex_size )
{
    symbol * s;
    uint16_t pos;

    size_t dotpos = filename.find_last_of('.');
    if (dotpos != std::string::npos)
        filename.erase(dotpos);

    std::string hexfilename = filename + ".hex";
    std::string binfilename = filename + ".bin";
    std::string listingfilename = filename + ".list";
    std::string srecfilename = filename + ".srec";
    std::string symfilename = filename + ".sym";

    printf("filename is '%s'\n", filename.c_str());
    printf("hex filename is '%s'\n", hexfilename.c_str());
    printf("bin filename is '%s'\n", binfilename.c_str());
    printf("listing filename is '%s'\n", listingfilename.c_str());
    printf("srec filename is '%s'\n", srecfilename.c_str());
    printf("syms filename is '%s'\n", symfilename.c_str());

    printf("symbols:\n");
    for (s = symbols.get_head(); s; s = symbols.get_next(s))
        printf("%04x %s\n", s->address, s->name->c_str());
    printf("relocations:\n");
    for (s = relocations.get_head(); s; s = relocations.get_next(s))
        printf("%04x %s%s\n", s->address, s->name->c_str(), 
               s->relative ? " (relative)" : "");
    printf("memory:\n");
    for (pos = 0; pos < current_pos; pos += 2)
    {
        printf("%02x%02x ", memory[pos], memory[pos+1]);
        if ((pos & 15) == 14)
            printf("\n");
    }
    printf("\n");

    // produce the HEX file for verilog code

    FILE * outf = fopen(hexfilename.c_str(), "w");
    if (!outf)
    {
        fprintf(stderr, "unable to open hex file!\n");
        exit(1);
    }

    for (pos = 0; pos < hex_size; pos += 2)
    {
        uint8_t byte1 = 0, byte2 = 0;

        if (pos < current_pos)
        {
            byte1 = memory[pos];
            byte2 = memory[pos+1];
        }

        fprintf(outf,"%02x%02x\n", byte1, byte2);
    }

    fclose(outf);

    // produce BIN file for simulator

    outf = fopen(binfilename.c_str(), "w");
    fwrite(memory, current_pos, 1, outf);
    fclose(outf);

    // produce the listing for debug

    outf = fopen(listingfilename.c_str(), "w");
    if (!outf)
    {
        fprintf(stderr, "unable to open listing file!\n");
        exit(1);
    }

    listing_line * l;
    while ((l = lines.dequeue_head()) != NULL)
    {
        if (l->length == 0)
        {
            fprintf(outf,
                    "                   %s\n", l->line->c_str());
        }
        else if (l->length == 2)
        {
            fprintf(outf,
                    "%04x : %02x%02x        %s\n", 
                    l->address,
                    memory[l->address+0], memory[l->address+1],
                    l->line->c_str());
        }
        else if (l->length == 4)
        {
            fprintf(outf,
                    "%04x : %02x%02x %02x%02x   %s\n", 
                    l->address,
                    memory[l->address+0], memory[l->address+1],
                    memory[l->address+2], memory[l->address+3],
                    l->line->c_str());
        }
        else
        {
            fprintf(outf,
                    "                   %s\n", l->line->c_str());
            fprintf(outf,
                    "%04x : ", l->address);
            for (uint16_t c = 0; c < l->length; c++)
                fprintf(outf,"%02x", memory[l->address + c]);
            fprintf(outf,"\n");
        }
    }

    fclose(outf);

    // produce S-record output

    outf = fopen(srecfilename.c_str(), "w");

    printf("org pos = %04x\n", org);
    printf("current pos = %04x\n", current_pos);

    uint32_t remaining = current_pos - org;
    uint32_t offset = org;

    while (remaining > 0)
    {
        uint32_t csum = 0;
        uint32_t sz = remaining;
        if (sz > 20)
            sz = 20;
        remaining -= sz;
        fprintf(outf, "S1%02x", sz/2); // s-records size is in words
        fprintf(outf, "%04x", offset);
        csum += offset;
        while (sz > 0)
        {
            uint16_t v = (memory[offset] << 8) + memory[offset+1];
            csum += v;
            fprintf(outf, "%04x", v);
            sz -= 2;
            offset += 2;
        }
        fprintf(outf,"%04x\r\n", csum & 0xFFFF);
    }

    // now add the S9 entry to the srec file; if 'entry' exists,
    // add that, else add 0000

    std::string entrysym = "entry";
    s = find_symbol(&entrysym);
    if (s)
        fprintf(outf,"S9%04x%04x\r\n", s->address, s->address);
    else
        fprintf(outf,"S9%04x%04x\r\n", 0, 0);

    fclose(outf);

    // now create the symbols file

    outf = fopen(symfilename.c_str(), "w");

    for (s = symbols.get_head(); s; s = symbols.get_next(s))
        if (s->global)
            fprintf(outf, "%s equ 0x%x\n",
                    s->name->c_str(), s->address);

    fclose(outf);

}
