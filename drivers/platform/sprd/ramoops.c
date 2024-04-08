#include <linux/pstore_ram.h>
#include <linux/platform_device.h>
#include <soc/sprd/board.h>

static struct ramoops_platform_data ramoops_data = {
	.mem_size = SPRD_RAM_CONSOLE_SIZE,
	.mem_address = SPRD_RAM_CONSOLE_START
};

static struct platform_device ramoops_device = {
	.name = "ramoops",
	.dev = {
		.platform_data = &ramoops_data
	}
};

static int __init ramoops_device_init(void) {
	int ret = platform_device_register(&ramoops_device);
	if(ret)
		printk(KERN_ERR "Failed to register ramoops device\n");
	return ret;
}
postcore_initcall(ramoops_device_init);
