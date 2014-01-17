
#include <stdio.h>
#include "tokenizer.H"
#include "output_file.H"

void print_tokenized_file(void);
void yyparse(void);
output_file  of;

#define HEX_SIZE 8192

int
main(int argc, char ** argv)
{
    if (argc != 2)
    {
        printf("usage:  as file.s\n");
        exit(1);
    }

    std::string filename = argv[1];
    FILE * infile = fopen(argv[1], "r");
    if (!infile)
    {
        printf("unable to open file '%s'\n", 
               filename.c_str());
        exit(2);
    }

    tokenizer_init(infile);
#if 0
    print_tokenized_file();
#else
    yyparse();
    of.resolve_relocations();
    of.output(filename, HEX_SIZE);
#endif
    return 0;
}
