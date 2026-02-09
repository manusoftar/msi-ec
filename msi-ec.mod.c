#include <linux/module.h>
#include <linux/export-internal.h>
#include <linux/compiler.h>

MODULE_INFO(name, KBUILD_MODNAME);

__visible struct module __this_module
__section(".gnu.linkonce.this_module") = {
	.name = KBUILD_MODNAME,
	.init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
	.exit = cleanup_module,
#endif
	.arch = MODULE_ARCH_INIT,
};



static const struct modversion_info ____versions[]
__used __section("__versions") = {
	{ 0xdd6830c7, "sysfs_emit" },
	{ 0x90a48d82, "__ubsan_handle_out_of_bounds" },
	{ 0xcb594613, "device_add_groups" },
	{ 0x173ec8da, "sscanf" },
	{ 0x67b2ba98, "sysfs_emit_at" },
	{ 0x9b4b48a0, "_ctype" },
	{ 0xdd45951a, "sysfs_streq" },
	{ 0xe4de56b4, "__ubsan_handle_load_invalid_value" },
	{ 0x77edee64, "sysfs_create_group" },
	{ 0x5373d78a, "kstrtobool" },
	{ 0x71e3d3cc, "platform_device_unregister" },
	{ 0x7332f50e, "platform_driver_unregister" },
	{ 0xe8213e80, "_printk" },
	{ 0x0636df17, "led_classdev_unregister" },
	{ 0x927906af, "battery_hook_unregister" },
	{ 0x4ab9b88b, "sysfs_remove_group" },
	{ 0xfc791c16, "match_string" },
	{ 0xcd10621c, "__platform_create_bundle" },
	{ 0x9ac32e11, "led_classdev_register_ext" },
	{ 0x927906af, "battery_hook_register" },
	{ 0xc2614bbe, "param_ops_bool" },
	{ 0xc2614bbe, "param_ops_charp" },
	{ 0xd272d446, "__fentry__" },
	{ 0x361eec3f, "ec_read" },
	{ 0xd272d446, "__x86_return_thunk" },
	{ 0xd272d446, "__stack_chk_fail" },
	{ 0xf46d5bf3, "mutex_lock" },
	{ 0xf1f059ea, "ec_write" },
	{ 0xf46d5bf3, "mutex_unlock" },
	{ 0x82fd7238, "__ubsan_handle_shift_out_of_bounds" },
	{ 0x48162983, "device_remove_groups" },
	{ 0x91f966bb, "kstrtou8" },
	{ 0xba157484, "module_layout" },
};

static const u32 ____version_ext_crcs[]
__used __section("__version_ext_crcs") = {
	0xdd6830c7,
	0x90a48d82,
	0xcb594613,
	0x173ec8da,
	0x67b2ba98,
	0x9b4b48a0,
	0xdd45951a,
	0xe4de56b4,
	0x77edee64,
	0x5373d78a,
	0x71e3d3cc,
	0x7332f50e,
	0xe8213e80,
	0x0636df17,
	0x927906af,
	0x4ab9b88b,
	0xfc791c16,
	0xcd10621c,
	0x9ac32e11,
	0x927906af,
	0xc2614bbe,
	0xc2614bbe,
	0xd272d446,
	0x361eec3f,
	0xd272d446,
	0xd272d446,
	0xf46d5bf3,
	0xf1f059ea,
	0xf46d5bf3,
	0x82fd7238,
	0x48162983,
	0x91f966bb,
	0xba157484,
};
static const char ____version_ext_names[]
__used __section("__version_ext_names") =
	"sysfs_emit\0"
	"__ubsan_handle_out_of_bounds\0"
	"device_add_groups\0"
	"sscanf\0"
	"sysfs_emit_at\0"
	"_ctype\0"
	"sysfs_streq\0"
	"__ubsan_handle_load_invalid_value\0"
	"sysfs_create_group\0"
	"kstrtobool\0"
	"platform_device_unregister\0"
	"platform_driver_unregister\0"
	"_printk\0"
	"led_classdev_unregister\0"
	"battery_hook_unregister\0"
	"sysfs_remove_group\0"
	"match_string\0"
	"__platform_create_bundle\0"
	"led_classdev_register_ext\0"
	"battery_hook_register\0"
	"param_ops_bool\0"
	"param_ops_charp\0"
	"__fentry__\0"
	"ec_read\0"
	"__x86_return_thunk\0"
	"__stack_chk_fail\0"
	"mutex_lock\0"
	"ec_write\0"
	"mutex_unlock\0"
	"__ubsan_handle_shift_out_of_bounds\0"
	"device_remove_groups\0"
	"kstrtou8\0"
	"module_layout\0"
;

MODULE_INFO(depends, "");


MODULE_INFO(srcversion, "9C08614BA09F3D5B80DC2E8");
