#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define READLEN 26
#define WRITELEN 26

int main(int argc, char* argv[])
{

    FILE* file = NULL;
    size_t readlen;
    size_t writelen;
    unsigned char readbuf[READLEN + 1] = {0};
    unsigned char mac[12] = {0};
    unsigned char temp[6] = {0};

    if (argc != 3) {
        printf("i211 mactool input parameter error \n");
        printf("command is mactool hexfile macaddr \n");
        return -1;
    }

    printf("hex file name is %s\n", argv[1]);
    printf("macaddr is %s\n", argv[2]);
    
    memcpy(mac, argv[2], 12);
    /*
    for (int loop = 0; loop < 12; loop++) {
       printf("temp is %02hx\n", mac[loop]);
    }
    */

    file = fopen(argv[1], "r+");
    if (file == NULL) {
        printf("Unable to open source hex file: %s\n", argv[1]);
        return -1;
    } else {
        readlen = fread(readbuf, 1, READLEN, file);
        if (readlen != READLEN) {
            printf("Read content error from hex file %zd\n", readlen);
            fclose(file);
            return -1;
        } else {
            readbuf[0]  = mac[2];
            readbuf[1]  = mac[3];
            readbuf[2]  = mac[0];
            readbuf[3]  = mac[1];
            readbuf[9]  = mac[6];
            readbuf[10] = mac[7];
            readbuf[11] = mac[4];
            readbuf[12] = mac[5];
            readbuf[18] = mac[10];
            readbuf[19] = mac[11];
            readbuf[20] = mac[8];
            readbuf[21] = mac[9];
            fseek(file, 0, 0);
            writelen = fwrite(readbuf, 1, WRITELEN, file);
            if (writelen != WRITELEN) {
                printf("Write content error to hex file \n");
                fclose(file);
                return -1;
            }
        }
    }
    fclose(file);
    return 0;
}
