# AGENTS.md

## 项目概述

st 的个人 fork：把 dvtm（tab/分屏管理）编译进 st 同一个 ELF，multicall 单二进制，自包含（vendored dvtm + 静态链接 ncurses），部署到 `~/.LinuxTools/bin/st`。

## 架构关键点

- `dispatch.c`：multicall 分发器。`argv[0]` 或首个参数为 `dvtm` → `dvtm_main()`，否则 `st_main()`。
- `st.c` `execsh()`：默认命令是内嵌 dvtm（`defaultcmd = {"dvtm"}`）；`prog=="dvtm"` 时 `execv("/proc/self/exe", ...)` 复用自身，不经 PATH。
- **重要陷阱**：`st -e cmd` 会绕过 dvtm 直接 exec cmd，此时所有 dvtm 快捷键失效。要在 dvtm 首窗格运行程序：`st -e dvtm cmd`（dvtm 的启动命令仅支持单个词）。
- 快捷键：st 在 X 层（`x.c` `kpress`）按 `config.h` 的 `DVTMMOD`(Ctrl+Alt)/`TERMMOD`(Ctrl+Shift) 表拦截组合键，`ttysend` 发 F13+ 转义序列；dvtm 侧由 curses 解码为 `KEY_F(13+)`，动作绑定在 `deps/dvtm/config.def.h` 的 `bindings[]`。改键位需同时看这两处。
- `deps/dvtm/`：vendored dvtm 0.15 源码（dvtm.c、vt.c 等），编译为 `dvtm.o`、`vt.o`。
- `deps/ncurses/`：ncurses-6.4 tarball，Makefile 自动解包并 `--without-shared` 静态编译为 `libncursesw.a`。

## 构建与部署

```sh
make                       # 首次会自动解包+静态编译 ncurses（较慢）
cp st ~/.LinuxTools/bin/st # 部署
```

验证 multicall 是否正常：`st dvtm -v` 应打印 `dvtm-0.15-stfork ...`。

## 修改约定

- 改 `config.h` 键位时同步检查 `deps/dvtm/config.def.h` 的 F 键绑定是否对应。
- 改命令行行为时同步更新 `x.c` 的 `usage()`、`st.1` man page 和 `README` 的 fork 说明段。
- 部署侧的热键脚本在 `~/.LinuxTools/bin/core/auto.ahk`（改它需同步同目录 `auto.md`）。
