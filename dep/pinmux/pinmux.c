#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <fcntl.h>
#include <errno.h>

#define PINMUX_CONFIG 0x28180000
#define MAPSIZE 4096

/* usage: offset 0xoffset, configbit only config bit set to 1, hex format, configdata only config bit data is validate, hex format */
int main(int argc, char** argv)
{
    int fd;
    void* map_base, *virt_addr;
    unsigned int rdconf, wrconf;
    unsigned long offset;
    unsigned int configdata, configbit;

    if (argc < 4) {
        printf("input parameter error format is \"pinmux offset configbit configdata\"\n");
        return -1;
    }

    offset = strtoul(argv[1], NULL, 16); 

    configdata = strtol(argv[3], NULL, 16);

    configbit = strtol(argv[2], NULL, 16);

    fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd == -1) {
        printf("open /dev/mem error\n");
        return -1;
    }
    
    map_base = mmap(0, MAPSIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, PINMUX_CONFIG);
    if (map_base == (void *)-1) {
        printf("memory map error\n");
        return -1;
    }
    
    virt_addr = map_base + offset;
    rdconf = *(unsigned int *)virt_addr;
    printf("source config data is 0x%x at offset 0x%lx \n", rdconf, offset);

    wrconf = rdconf & ~configbit;
    wrconf = wrconf | configdata;
    
    *(unsigned int *)virt_addr = wrconf;

    rdconf = *(unsigned int *)virt_addr;
    printf("dest config data is 0x%x \n", rdconf);

    if (munmap(map_base, MAPSIZE) == -1) {
        printf(" /dev/mem unmap error \n");
        return -1;
    }

    return 0;

}
