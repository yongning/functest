/*
 * (C) Copyright 2009
 * Vipin Kumar, ST Micoelectronics, vipin.kumar@st.com.
 *
 * SPDX-License-Identifier:	GPL-2.0+
 */

#ifndef __DW_I2CLib_H_
#define __DW_I2CLib_H_
#include <stddef.h>
#include <stdint.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <sys/mman.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>

/*
 * Registers offset
 */
#define DW_IC_CON		0x0	/* i2c control register */
#define  IC_CON_SD		0x0040
#define  IC_CON_RE		0x0020
#define  IC_CON_10BITADDRMASTER	0x0010
#define  IC_CON_10BITADDR_SLAVE	0x0008
#define  IC_CON_SPD_MSK		0x0006
#define  IC_CON_SPD_SS		0x0002
#define  IC_CON_SPD_FS		0x0004
#define  IC_CON_SPD_HS		0x0006
#define  IC_CON_MM		0x0001
#define DW_IC_TAR		0x4	/* i2c target address register */
#define DW_IC_SAR		0x8	/* i2c slave address register */
#define DW_IC_DATA_CMD		0x10	/* i2c data buffer and command register */
#define  IC_CMD			0x0100
#define  IC_STOP		0x0200
#define DW_IC_SS_SCL_HCNT	0x14
#define DW_IC_SS_SCL_LCNT	0x18
#define DW_IC_FS_SCL_HCNT	0x1c
#define DW_IC_FS_SCL_LCNT	0x20
#define DW_IC_HS_SCL_HCNT	0x24
#define DW_IC_HS_SCL_LCNT	0x28
#define DW_IC_INTR_STAT		0x2c	/* i2c interrupt status register */
#define  IC_GEN_CALL		0x0800
#define  IC_START_DET		0x0400
#define  IC_STOP_DET		0x0200
#define  IC_ACTIVITY		0x0100
#define  IC_RX_DONE		0x0080
#define  IC_TX_ABRT		0x0040
#define  IC_RD_REQ		0x0020
#define  IC_TX_EMPTY		0x0010
#define  IC_TX_OVER		0x0008
#define  IC_RX_FULL		0x0004
#define  IC_RX_OVER 		0x0002
#define  IC_RX_UNDER		0x0001
#define DW_IC_INTR_MASK		0x30
#define DW_IC_RAW_INTR_STAT	0x34
#define DW_IC_RX_TL		0x38	/* fifo receive threshold register */
#define DW_IC_TX_TL		0x3c	/* fifo transmit threshold register */
#define  IC_TL0			0x00
#define  IC_TL1			0x01
#define  IC_TL2			0x02
#define  IC_TL3			0x03
#define  IC_TL4			0x04
#define  IC_TL5			0x05
#define  IC_TL6			0x06
#define  IC_TL7			0x07
#define  IC_RX_TL		IC_TL0
#define  IC_TX_TL		IC_TL0
#define DW_IC_CLR_INTR		0x40
#define DW_IC_CLR_RX_UNDER	0x44
#define DW_IC_CLR_RX_OVER	0x48
#define DW_IC_CLR_TX_OVER	0x4c
#define DW_IC_CLR_RD_REQ	0x50
#define DW_IC_CLR_TX_ABRT	0x54
#define DW_IC_CLR_RX_DONE	0x58
#define DW_IC_CLR_ACTIVITY	0x5c
#define DW_IC_CLR_STOP_DET	0x60
#define DW_IC_CLR_START_DET	0x64
#define DW_IC_CLR_GEN_CALL	0x68
#define DW_IC_ENABLE		0x6c	/* i2c enable register */
#define  IC_ENABLE_0B		0x0001
#define DW_IC_STATUS		0x70	/* i2c status register */
#define  IC_STATUS_SA		0x0040
#define  IC_STATUS_MA		0x0020
#define  IC_STATUS_RFF		0x0010
#define  IC_STATUS_RFNE		0x0008
#define  IC_STATUS_TFE		0x0004
#define  IC_STATUS_TFNF		0x0002
#define  IC_STATUS_ACT		0x0001
#define DW_IC_TXFLR		0x74
#define DW_IC_RXFLR		0x78
#define DW_IC_SDA_HOLD		0x7c
#define DW_IC_TX_ABRT_SOURCE	0x80
#define DW_IC_ENABLE_STATUS	0x9c
#define DW_IC_COMP_PARAM_1	0xf4
#define DW_IC_COMP_VERSION	0xf8
#define DW_IC_COMP_TYPE		0xfc

#if !defined(IC_CLK)
#define IC_CLK			166
#endif
#define NANO_TO_MICRO		1000

/* High and low times in different speed modes (in ns) */
#define MIN_SS_SCL_HIGHTIME	4000
#define MIN_SS_SCL_LOWTIME	4700
#define MIN_FS_SCL_HIGHTIME	600
#define MIN_FS_SCL_LOWTIME	1300
#define MIN_HS_SCL_HIGHTIME	60
#define MIN_HS_SCL_LOWTIME	160

/* Worst case timeout for 1 byte is kept as 2ms */
#define I2C_BYTE_TO		(20)
#define I2C_STOPDET_TO		(2)
#define I2C_BYTE_TO_BB		(I2C_BYTE_TO * 16)

/* Speed Selection */
#define I2C_MAX_SPEED		3400000
#define I2C_FAST_SPEED		400000
#define I2C_STANDARD_SPEED	100000

#define readb(a)		(*(volatile unsigned char *)(a))
#define readw(a)		(*(volatile unsigned short *)(a))
// #define readl(a)		(*(volatile unsigned int *)(a))

#define writeb(v,a)		(*(volatile unsigned char *)(a) = (v))
#define writew(v,a)		(*(volatile unsigned short *)(a) = (v))
// #define writel(v,a)		(*(volatile unsigned int *)(a) = (v))
#define writeq(v,a)		(*(volatile unsigned long *)(a) = (v))

int i2c_read(unsigned char chip, unsigned int addr, int alen, unsigned char *buffer, int len);
int i2c_write(unsigned char chip, unsigned int addr, int alen, unsigned char *buffer, int len);

#endif /* __DW_I2CLib_H_ */
