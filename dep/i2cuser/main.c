#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <getopt.h>
#include <stdlib.h>

#include "Dw_I2CLib.h"
#include "mem_rw.h"

#define     RTC_SA          0x68
#define     EEPROM_SA       0x57
#define     BIT0            0x1
#define     BIT2            0x4
#define     BIT7            0x80

#define     READ_OPS        1
#define     WRITE_OPS       2
#define     WRITE_MUL_OPS   3
int main(int argc, char **argv)
{
    int                 return_code;
    unsigned char       value;
    unsigned int        addr;
    unsigned int        cmd;  /* 0 read, 1 write */
    unsigned char       rdvalue = 0;
    unsigned char       value1;
    unsigned char       value2;
    unsigned char       value3;
    unsigned char       value4;
    unsigned char       value5;
    unsigned char       value6;
    unsigned char       chksum = 0;

    for (;;)
    {
        int option_index = 0;
        static const char* short_options = "c:a:v:d:e:f:g:h:i:";
        static const struct option long_options[] = {
            {"cmd", required_argument, 0, 'c'},
            {"addr", required_argument, 0, 'a'},
            {"val", required_argument, 0, 'v'},
            {"val1", required_argument, 0, 'd'},
            {"val2", required_argument, 0, 'e'},
            {"val3", required_argument, 0, 'f'},
            {"val4", required_argument, 0, 'g'},
            {"val5", required_argument, 0, 'h'},
            {"val6", required_argument, 0, 'i'},
            {0, 0, 0, 0},
        };
        
        int c = getopt_long(argc, argv, short_options, long_options, &option_index);
        if (c == EOF) {
            break;
        }

        switch(c) {
        case 'c':
            cmd = atoi(optarg);
            break;
        case 'a':
            addr = atoi(optarg);
            break;
        case 'v':
            sscanf(optarg, "%hhx", &value);
            break;
        case 'd':
            sscanf(optarg, "%hhx", &value1);
            break;
        case 'e':
            sscanf(optarg, "%hhx", &value2);
            break;
        case 'f':
            sscanf(optarg, "%hhx", &value3);
            break;
        case 'g':
            sscanf(optarg, "%hhx", &value4);
            break;
        case 'h':
            sscanf(optarg, "%hhx", &value5);
            break;
        case 'i':
            sscanf(optarg, "%hhx", &value6);
            break;
        }
    }

    printf("i2c1cmd_info cmd%d, addr%d \n", cmd, addr);

    lib_init(0x28007000, 0x1000);

    if (cmd == READ_OPS) {
        return_code =  i2c_read(EEPROM_SA, addr, 1, &rdvalue, 1);
        if(return_code != 0 )
        {
            printf("i2c1cmd_error addr%d \n", addr);
            goto ProcExit;
        }
        printf("i2c1cmd_info readdata is 0x%hhx\n", rdvalue);
    } else if (cmd == WRITE_OPS) {
            return_code =  i2c_write(EEPROM_SA, addr, 1, &value, 1);
            if(return_code != 0 )
            {
                printf("i2c1cmd_error write1 addr%d \n", addr);
                goto ProcExit;
            }
    } else if (cmd == WRITE_MUL_OPS) {
            return_code =  i2c_write(EEPROM_SA, addr, 1, &value1, 1);
            if(return_code != 0 )
            {
                printf("i2c1cmd_error write2 addr%d \n", addr);
                goto ProcExit;
            }
            chksum = chksum + value1;

            return_code =  i2c_write(EEPROM_SA, addr + 1, 1, &value2, 1);
            if(return_code != 0 )
            {
                printf("i2c1cmd_error write2 addr%d \n", addr + 1);
                goto ProcExit;
            }
            chksum = chksum + value2;

            return_code =  i2c_write(EEPROM_SA, addr + 2, 1, &value3, 1);
            if(return_code != 0 )
            {
                printf("i2c1cmd_error write2 addr%d \n", addr + 2);
                goto ProcExit;
            }
            chksum = chksum + value3;

            return_code =  i2c_write(EEPROM_SA, addr + 3, 1, &value4, 1);
            if(return_code != 0 )
            {
                printf("i2c1cmd_error write2 addr%d \n", addr + 3);
                goto ProcExit;
            }
            chksum = chksum + value4;
        
            return_code =  i2c_write(EEPROM_SA, addr + 4, 1, &value5, 1);
            if(return_code != 0 )
            {
                printf("i2c1cmd_error write2 addr%d \n", addr + 4);
                goto ProcExit;
            }
            chksum = chksum + value5;

            return_code =  i2c_write(EEPROM_SA, addr + 5, 1, &value6, 1);
            if(return_code != 0 )
            {
                printf("i2c1cmd_error write2 addr%d \n", addr + 5);
                goto ProcExit;
            }
            chksum = chksum + value6;

            return_code = i2c_write(EEPROM_SA, addr + 6, 1, &chksum, 1);
            if (return_code != 0) {
                printf("i2c1cmd_error write2 addr%d \n", addr + 6);
                goto ProcExit;
            }

    } else { 
         printf("i2c1cmd_error write3 add%d \n", addr);
         return_code = -3; /* no meaning */
    }

ProcExit:
    lib_deinit();
    return return_code;
}
