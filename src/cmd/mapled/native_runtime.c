#include <stdlib.h>

void maple_moon_fill_secure_random(unsigned char *buffer, int length) {
  arc4random_buf(buffer, (size_t)length);
}
