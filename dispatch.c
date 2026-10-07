/*
 * multicall 分发器:st 与 dvtm 编译进同一个 ELF。
 * argv[0] 是 dvtm(或首个参数是 dvtm)→ 跑 dvtm,否则跑 st。
 * st 启动 dvtm 时通过 execv("/proc/self/exe", {"dvtm", ...}) 复用本文件,
 * 不需要任何外部二进制。
 */
#include <string.h>

int st_main(int argc, char **argv);
int dvtm_main(int argc, char **argv);

int
main(int argc, char **argv)
{
	const char *arg0 = strrchr(argv[0], '/');

	arg0 = arg0 ? arg0 + 1 : argv[0];
	if (strcmp(arg0, "dvtm") == 0)
		return dvtm_main(argc, argv);
	if (argc > 1 && strcmp(argv[1], "dvtm") == 0)
		return dvtm_main(argc - 1, argv + 1);
	return st_main(argc, argv);
}
