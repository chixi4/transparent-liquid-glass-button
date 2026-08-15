# 验收清单

- [x] 为拖拽点击增加移动阈值，避免轻微抖动吞掉交换
- [x] 为 Core Audio 属性增加存在性、可写性和数据长度校验
- [x] 用可运行的测试覆盖声道交换与按钮事件路径

## 历史记录

### 2026-08-16

- 只读检查 `AudioChannelSwapper`、按钮事件和打包脚本，未修改业务代码。
- 当前默认输出设备的 `kAudioDevicePropertyPreferredChannelsForStereo` 可读可写；临时写入 `[2, 1]` 后读回成功，并已恢复 `[1, 2]`。
- 复现按钮边界问题：按下后只移动 1 像素再抬起不会交换；无移动的普通点击可以交换。根因是首次 `mouseDragged` 立即将 `isDragging` 置为 `true`，没有拖动阈值。
- 设备扫描发现 5 个设备中有 1 个没有该属性，现有实现未检查属性是否存在/可写。
- `swift build` 成功；`swift test` 在本机因 SwiftPM 测试运行器找不到 `Testing.framework` 失败，现有测试本身仍是占位测试。
- 当前选定状态：未选定修复版本；系统声道已恢复为 `[1, 2]`，测试启动的应用进程已退出。

### 2026-08-16（落地修复）

- `AudioChannelSwapper` 改为返回 `Result`，增加默认设备、属性存在性/可写性、数据长度和写后读回校验，并使用显式 buffer 读写。
- 拖动增加 4 像素阈值；按钮点击显示成功 `✓` 或失败 `!`，失败会蜂鸣并把原因写入 tooltip、辅助功能值和日志。
- 用 5 个 Swift Testing 用例覆盖声道交换、非法通道数和拖动阈值；`./run_tests.sh` 实测 5/5 通过。
- `build_app.sh` 支持任意 cwd、自动构建、`CONFIGURATION=release` 和版本变量；debug 与 release 打包均实测成功。
- 运行时通过 `Swap.app` 的辅助功能点击验证交换与恢复，系统状态最终为 `[1, 2]`，应用进程已退出。
- 本机 Command Line Tools 仍会输出两条错误的 linker search path 警告，但不影响构建和测试；该路径由当前工具链生成，未硬编码进项目。
- 当前最优 = 已提交的本次修复版本。
