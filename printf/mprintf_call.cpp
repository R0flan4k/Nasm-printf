#include <stdio.h>

extern "C" void _printfept(const char * str, ...);

int main(void)
{
    char aboba[24] = "otshit, chushpan";
    _printfept("Lol %d %s %%\n", 24, aboba);

    return 0;
}
