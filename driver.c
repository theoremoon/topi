#include <stdio.h>

extern int _func(void);

int main() {
    int v = _func();
    printf("%d\n", v);
    return 0;
}
