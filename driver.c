#include <stdio.h>

extern int _func(void);

void print_real(double v) {
    printf("%.6lf\n", v);
    return;
}
void print_int(long v) {
    printf("%ld\n", v);
    return;
}

int main() {
    _func();
    return 0;
}
