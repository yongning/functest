/*
 * (C) Copyright 2009
 * Vipin Kumar, ST Micoelectronics, vipin.kumar@st.com.
 *
 * SPDX-License-Identifier:	GPL-2.0+
 */
#include <stddef.h>
#include "mem_rw.h"
#include "Dw_I2CLib.h"

void *i2c_regs_p = NULL;


/*
 * i2c_enable - Enable I2C
 */
static void i2c_enable(void)
{
	unsigned int enbl;

	/* Enable i2c */
	enbl = readl(i2c_regs_p + DW_IC_ENABLE);
	enbl |= IC_ENABLE_0B;
	writel(enbl, i2c_regs_p + DW_IC_ENABLE);
}

/*
 * i2c_disable - Disable I2C
 */
static void i2c_disable(void)
{
	unsigned int enbl;

	/* Disable i2c */
	enbl = readl(i2c_regs_p + DW_IC_ENABLE);
	enbl &= ~IC_ENABLE_0B;
	writel(enbl, i2c_regs_p + DW_IC_ENABLE);
}

/*
 * set_speed - Set the i2c speed mode (standard, high, fast)
 * @i2c_spd:	required i2c speed mode
 *
 * Set the i2c speed mode (standard, high, fast)
 */
static void set_speed(int i2c_spd)
{
	unsigned int cntl;
	unsigned int hcnt, lcnt;
	unsigned int enbl;

	/* to set speed cltr must be disabled */
	enbl = readl(i2c_regs_p + DW_IC_ENABLE);
	enbl &= ~IC_ENABLE_0B;
	writel(enbl, i2c_regs_p + DW_IC_ENABLE);

	cntl = (readl(i2c_regs_p + DW_IC_CON) & (~IC_CON_SPD_MSK));

	switch (i2c_spd) {
	case I2C_MAX_SPEED:
		cntl |= IC_CON_SPD_HS;
		hcnt = (IC_CLK * MIN_HS_SCL_HIGHTIME) / NANO_TO_MICRO;
		writel(hcnt, i2c_regs_p + DW_IC_HS_SCL_HCNT);
		lcnt = (IC_CLK * MIN_HS_SCL_LOWTIME) / NANO_TO_MICRO;
		writel(lcnt, i2c_regs_p + DW_IC_HS_SCL_LCNT);
		break;

	case I2C_STANDARD_SPEED:
		cntl |= IC_CON_SPD_SS;
		hcnt = (IC_CLK * MIN_SS_SCL_HIGHTIME) / NANO_TO_MICRO;
		writel(hcnt, i2c_regs_p + DW_IC_SS_SCL_HCNT);
		lcnt = (IC_CLK * MIN_SS_SCL_LOWTIME) / NANO_TO_MICRO;
		writel(lcnt, i2c_regs_p + DW_IC_SS_SCL_LCNT);
		break;

	case I2C_FAST_SPEED:
	default:
		cntl |= IC_CON_SPD_FS;
		hcnt = (IC_CLK * MIN_FS_SCL_HIGHTIME) / NANO_TO_MICRO;
		writel(hcnt, i2c_regs_p + DW_IC_FS_SCL_HCNT);
		lcnt = (IC_CLK * MIN_FS_SCL_LOWTIME) / NANO_TO_MICRO;
		writel(lcnt, i2c_regs_p + DW_IC_FS_SCL_LCNT);
		break;
	}

	writel(cntl, i2c_regs_p + DW_IC_CON);

	/* Enable back i2c now speed set */
	enbl |= IC_ENABLE_0B;
	writel(enbl, i2c_regs_p + DW_IC_ENABLE);
}


/*
 * i2c_setaddress - Sets the target slave address
 * @i2c_addr:	target i2c address
 *
 * Sets the target slave address.
 */
static void i2c_setaddress(unsigned int i2c_addr)
{
	writel(i2c_addr, i2c_regs_p + DW_IC_TAR);
}

/*
 * i2c_flush_rxfifo - Flushes the i2c RX FIFO
 *
 * Flushes the i2c RX FIFO
 */
static void i2c_flush_rxfifo(void)
{
	while (readl(i2c_regs_p + DW_IC_STATUS) & IC_STATUS_RFNE)
		readl(i2c_regs_p + DW_IC_DATA_CMD);
}

/*
 * i2c_wait_for_bb - Waits for bus busy
 *
 * Waits for bus busy
 */
static int i2c_wait_for_bb(void)
{
	int  timeout = I2C_BYTE_TO_BB;

	while ((readl(i2c_regs_p + DW_IC_STATUS) & IC_STATUS_MA) ||
	       !(readl(i2c_regs_p + DW_IC_STATUS) & IC_STATUS_TFE)) {

		/* Evaluate timeout */
		// MicroSecondDelay(1000);
		sleep(1);
		if (timeout-- == 0) {
			printf("Timed out. i2c i2c_wait_for_bb Failed\n");
			return 1;
		}
	}

	return 0;
}

/* check parameters for i2c_read and i2c_write */
static int check_params(unsigned int addr, int alen, unsigned char *buffer, int len)
{
	if (buffer == NULL) {
		printf("Buffer is invalid\n");
		return 1;
	}

	if (alen > 1) {
		printf("addr len %d not supported\n", alen);
		return 1;
	}

	if (addr + len > 256) {
		printf("address out of range\n");
		return 1;
	}

	return 0;
}

static int i2c_xfer_init(unsigned char chip, unsigned int addr)
{
	i2c_enable();

	if (i2c_wait_for_bb())
		return 1;

	i2c_setaddress(chip);
	writel(addr, i2c_regs_p + DW_IC_DATA_CMD);

	return 0;
}

static int i2c_xfer_finish(void)
{
	unsigned int  timeout;

	timeout = I2C_STOPDET_TO;
	while (1) {
		if ((readl(i2c_regs_p + DW_IC_RAW_INTR_STAT) & IC_STOP_DET)) {
			readl(i2c_regs_p + DW_IC_CLR_STOP_DET);
			break;
		} else {
			// MicroSecondDelay(1000);
			sleep(1);
			if (timeout-- == 0) {
				printf("Timed out. i2c i2c_xfer_finish Failed\n");
				break;
			}
		}
	}

	if (i2c_wait_for_bb()) {
		printf("Timed out waiting for bus\n");
		return 1;
	}

	i2c_flush_rxfifo();

	/* Wait for read/write operation to complete on actual memory */
	// MicroSecondDelay(10);
	usleep(10000);

	i2c_disable();

	return 0;
}

/*
 * i2c_read - Read from i2c memory
 * @chip:	target i2c address
 * @addr:	address to read from
 * @alen:
 * @buffer:	buffer for read data
 * @len:	no of bytes to be read
 *
 * Read from i2c memory.
 */
int i2c_read(unsigned char chip, unsigned int addr, int alen, unsigned char *buffer, int len)
{
	int timeout;
	if (check_params(addr, alen, buffer, len))
		return 1;

	if (i2c_xfer_init(chip, addr))
		return 1;
	timeout = I2C_BYTE_TO;
	while (len) {
		if (len == 1)
			writel(IC_CMD | IC_STOP, i2c_regs_p + DW_IC_DATA_CMD);
		else
			writel(IC_CMD, i2c_regs_p + DW_IC_DATA_CMD);

		if (readl(i2c_regs_p + DW_IC_STATUS) & IC_STATUS_RFNE) {
			*buffer++ = (unsigned char)readl(i2c_regs_p + DW_IC_DATA_CMD);
			len--;
			timeout = I2C_BYTE_TO;
		} else {
			// MicroSecondDelay(1000);
			sleep(1);
			if (timeout-- == 0) {
				printf("Timed out. i2c read Failed\n");
				return 1;
			}
		}
	}
	return i2c_xfer_finish();
}

/*
 * i2c_write - Write to i2c memory
 * @chip:	target i2c address
 * @addr:	address to read from
 * @alen:
 * @buffer:	buffer for read data
 * @len:	no of bytes to be read
 *
 * Write to i2c memory.
 */
int i2c_write(unsigned char chip, unsigned int addr, int alen, unsigned char *buffer, int len)
{
	int nb = len, timeout;

	if (check_params(addr, alen, buffer, len))
		return 1;

	if (i2c_xfer_init(chip, addr))
		return 1;

	timeout = nb * I2C_BYTE_TO;
	while (len) {
		if (readl(i2c_regs_p + DW_IC_STATUS) & IC_STATUS_TFNF) {
			if (--len == 0)
				writel(*buffer | IC_STOP, i2c_regs_p + DW_IC_DATA_CMD);
			else
				writel(*buffer, i2c_regs_p + DW_IC_DATA_CMD);
			buffer++;
			timeout = nb * I2C_BYTE_TO;
		} else {
			// MicroSecondDelay(1000);
			sleep(1);
			if (timeout-- == 0) {
				printf("Timed out. i2c write Failed\n");
				return 1;
			}
		}
	}

	return i2c_xfer_finish();
}
