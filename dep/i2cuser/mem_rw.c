#include <stdio.h>
#include <stdlib.h>
#include "mmio.h"

static mmio_t *mm_mmio=NULL;

//#define SPI_DEBUG

int lib_init(uintptr_t base, size_t size)
{
	mm_mmio = mmio_new();
    /* Open control module */
    if (mmio_open(mm_mmio, base, size) < 0) {
        fprintf(stderr, "mmio_open(): %s\n", mmio_errmsg(mm_mmio));
        exit(1);
    }

}

int lib_deinit()
{
	if(mm_mmio != NULL)
	{
    	mmio_close(mm_mmio);
    	mmio_free(mm_mmio);
    }
}


unsigned int readl(uintptr_t offset)
{
    uint32_t       value;
    if(mm_mmio == NULL)
    {
        printf("readl: please initialize mmio first!, address: %lx \n", offset);
        return -1;
    }
    if(mmio_read32(mm_mmio, offset, &value) == 0)
    {
        return value;
    }else
    {
        printf("readl: read error, address: %lx \n", offset);
        return -1;        
    }

}

unsigned int writel(uint32_t value, uintptr_t offset)
{
    int  returnvalue = 0;

    if(mm_mmio == NULL)
    {
        printf("writel: please initialize mmio first!, address: %lx \n", offset);
        return -1;
    }

    returnvalue = mmio_write32(mm_mmio, offset, value);
    if(returnvalue!=0)
    {
        printf("readl: read error, address: %lx \n", offset);        
    }
    
    return returnvalue;
}