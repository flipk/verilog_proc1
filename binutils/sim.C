
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
        
#include "sim.H"

void
load_binary( Cpu * cpu, const char * filename )
{
    FILE * f = fopen(filename, "r");
    if (!f)
    {
        printf("can't open binary\n");
        exit(1);
    }
    size_t  rd = fread(cpu->memory, 1, Cpu::memory_size, f);
    printf("read %d bytes from binary file\n", (int)rd);
    fclose(f);
}

uint16_t
parse_addr( char * line )
{
    if (isxdigit(line[0]) && isxdigit(line[1]) &&
        isxdigit(line[2]) && isxdigit(line[3]) )
    {
        line[4] = 0;
        uint16_t val = strtoul(line, NULL, 16);
        line[4] = ' ';
        return val;
    }
    return 0xffff;
}

void
load_listing( Listing * listing, const char * filename )
{
    FILE * f = fopen(filename, "r");
    if (!f)
    {
        printf("can't open listing\n");
        exit(1);
    }

    char line[512];
    char * c;
    int linecount = 0;

    while (1)
    {
        if (fgets(line,sizeof(line),f) == NULL)
            break;
        for (c = line; *c; c++)
            if (*c == 10 || *c == 130)
                *c = 0;
        uint16_t addr = parse_addr(line);
        if (addr != 0xffff)
        {
            listing_line * l = new listing_line;
            l->address = addr;
            l->line = new std::string;
            l->line->assign(line);
            listing->add(l);
            linecount++;
        }
    }

    printf("read %d lines of listing\n", linecount);

    fclose(f);
}

void
Cpu::execute_instr(void)
{
    uint16_t opcode, operand;

    opcode = (memory[pc] << 8) + memory[pc+1];
    pc += 2;
    if (opcode & 0x0800)
    {
        operand = (memory[pc] << 8) + memory[pc+1];
        pc += 2;
    }

    int x =  opcode & 0x000F;
    int y = (opcode & 0x00F0) >> 4;
    uint16_t temp;

    switch ((opcode >> 8) & 0xFC)
    {
    case 0x00: // or
        regs[x] = regs[x] | regs[y];
        flag_c = 0;
        flag_z = (regs[x] == 0);
        break;
    case 0x04: // mr
        regs[x] = regs[y];
        break;
    case 0x08: // ori
        regs[x] = regs[x] | operand;
        flag_c = 0;
        flag_z = (regs[x] == 0);
        break;
    case 0x10: // and
        regs[x] = regs[x] & regs[y];
        flag_c = 0;
        flag_z = (regs[x] == 0);
        break;
    case 0x18: // andi
        regs[x] = regs[x] & operand;
        flag_c = 0;
        flag_z = (regs[x] == 0);
        break;
    case 0x20: // xor
        regs[x] = regs[x] ^ regs[y];
        flag_c = 0;
        flag_z = (regs[x] == 0);
        break;
    case 0x28: // xori
        regs[x] = regs[x] ^ operand;
        flag_c = 0;
        flag_z = (regs[x] == 0);
        break;
    case 0x30: // add
        regs[x] = regs[x] + regs[y];
        flag_c = ((regs[x] & 0x8000) != 0);
        flag_z = (regs[x] == 0);
        break;
    case 0x34: // addb
        regs[x] = (uint16_t)((int16_t)(regs[x] & 0xFF) +
                             (int16_t)(regs[y] & 0xFF));
        flag_c = ((regs[x] & 0x80) != 0);
        flag_z = (regs[x] == 0);
        break;
    case 0x38: // addi
        regs[x] = regs[x] + operand;
        flag_c = (((uint32_t)regs[x] + (uint32_t)operand) > 0x1000);
        flag_z = (regs[x] == 0);
        break;
    case 0x3c: // addbi
        regs[x] = (uint16_t)((int16_t)(regs[x] & 0xFF) +
                             (int16_t)(operand & 0xFF));
        flag_c = ((regs[x] & 0x80) != 0);
        flag_z = (regs[x] == 0);
        break;
    case 0x40: // sub
        regs[x] = regs[x] - regs[y];
        flag_c = ((regs[x] & 0x8000) != 0);
        flag_z = (regs[x] == 0);
        break;
    case 0x44: // subb
        regs[x] = (uint16_t)((int16_t)(regs[x] & 0xFF) -
                             (int16_t)(regs[y] & 0xFF));
        flag_c = ((regs[x] & 0x80) != 0);
        flag_z = (regs[x] == 0);
        break;
    case 0x48: // subi
        regs[x] = regs[x] - operand;
        flag_c = ((regs[x] & 0x8000) != 0);
        flag_z = (regs[x] == 0);
        break;
    case 0x4c: // subbi
        regs[x] = (uint16_t)((int16_t)(regs[x] & 0xFF) -
                             (int16_t)(operand & 0xFF));
        flag_c = ((regs[x] & 0x80) != 0);
        flag_z = (regs[x] == 0);
        break;
    case 0x50: // rol
        temp = regs[y] & 15;
        regs[x] = (regs[x] << temp) | (regs[x] >> (16-temp));
        break;
    case 0x54: // rolb
        temp = regs[y] & 7;
        regs[x] = ((regs[x] << temp) | (regs[x] >> (16-temp))) & 0xFF;
        break;
    case 0x58: // roli
        temp = operand & 15;
        regs[x] = (regs[x] << temp) | (regs[x] >> (16-temp));
        break;
    case 0x5c: // rolbi
        temp = operand & 7;
        regs[x] = ((regs[x] << temp) | (regs[x] >> (16-temp))) & 0xFF;
        break;
    case 0x60: // cmp
        temp = regs[x] - regs[y];
        flag_c = ((temp & 0x8000) != 0);
        flag_z = (temp == 0);
        break;
    case 0x64: // cmpb
        temp = (uint16_t)((int16_t)(regs[x] & 0xFF) -
                             (int16_t)(regs[y] & 0xFF));
        flag_c = ((temp & 0x80) != 0);
        flag_z = (temp == 0);
        break;
    case 0x68: // cmpi
        temp = regs[x] - operand;
        flag_c = ((temp & 0x8000) != 0);
        flag_z = (temp == 0);
        break;
    case 0x6c: // cmpbi
        temp = (uint16_t)((int16_t)(regs[x] & 0xFF) -
                             (int16_t)(operand & 0xFF));
        flag_c = ((temp & 0x80) != 0);
        flag_z = (temp == 0);
        break;
    case 0x70: // neg
        regs[x] = -regs[x];
        break;
    case 0x74: // negb
        regs[x] = (uint16_t)(-(uint8_t)(regs[x] & 0xFF));
        break;
    case 0x88: // li
        regs[x] = operand;
        flag_c = 0;
        flag_z = (regs[x] == 0);
        break;
    case 0x8c: // lib
        regs[x] = operand & 0xFF;
        flag_c = 0;
        flag_z = (regs[x] == 0);
        break;
    case 0x98: // ld
        temp = operand + regs[y];
        regs[x] = (memory[temp] << 8) + memory[temp+1];
        break;
    case 0x9c: // ldb
        temp = operand + regs[y];
        regs[x] = memory[temp];
        break;
    case 0xa8: // st
        temp = operand + regs[y];
        memory[temp] = regs[x] >> 8;
        memory[temp+1] = regs[x] & 0xFF;
        break;
    case 0xac: // stb
        temp = operand + regs[y];
        memory[temp] = regs[x] & 0xFF;
        break;
    case 0xb8: // in
    {
        char line[20];
    again:
        printf(" ** enter hex value read for IN port %02x : ", 
               operand + regs[y]);
        fflush(stdout);
        fgets(line,sizeof(line),stdin);
        if (isxdigit(line[0]) && isxdigit(line[1]))
        {
            line[2] = 0;
            temp = strtoul(line,NULL,16);
        }
        else
            goto again;
        regs[x] = temp;
        break;
    }
    case 0xc8: // out
        printf(" ** OUT value %02x to port %02x\n",
               regs[x], regs[y] + operand);
        break;
    case 0xd0: // br
        pc = regs[x];
        break;
    case 0xd4: // brl
        temp = pc;
        pc = regs[x];
        regs[x] = temp;
        break;
    case 0xe8: // b a,eq,ne,lt,gt,le,ge
        switch (opcode & 7)
        {
        case 0: // ba
            pc += operand;
            break;
        case 1: // beq
            if (flag_z)
                pc += operand;
            break;
        case 2: // bne
            if (!flag_z)
                pc += operand;
            break;
        case 3: // blt
            if (flag_c)
                pc += operand;
            break;
        case 4: // bgt
            if (!flag_z && !flag_c)
                pc += operand;
            break;
        case 5: // ble
            if (flag_z || flag_c)
                pc += operand;
            break;
        case 6: // bge
            if (!flag_z)
                pc += operand;
            break;
        case 7:
            printf("unknown opcode %04x\n", opcode);
            exit(1);
        }
        break;
    case 0xf8: // jmp abs
        pc = operand;
        break;
    case 0xfc: // jmpl
        regs[x] = pc;
        pc = operand;
        break;
    default:
        printf("unknown opcode %04x\n", opcode);
        exit(1);
    }

    if (flag_c)
        printf("C ");
    else
        printf("c ");

    int i;

    for (i=0; i < 8; i++)
        printf("%2d:%04x ", i, regs[i]);
    printf("\n");

    if (flag_z)
        printf("Z ");
    else
        printf("z ");

    for (i=8; i < 16; i++)
        printf("%2d:%04x ", i, regs[i]);
    printf("\n");
}
