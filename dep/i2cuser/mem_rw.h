#ifndef MEM_RW_H
#define MEM_RW_H

#include <stddef.h>
#include <stdint.h>

int lib_init();

int lib_deinit();

unsigned int readl(void *offset);

unsigned int writel(uint32_t value, void *offset);
#endif