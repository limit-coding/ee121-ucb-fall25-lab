# EE121 Lab 3: WebSDR 信号扫描实验报告

姓名：  
日期：2026-04-24  
实验主题：通过 WebSDR / OpenWebRX 观察无线电频谱、瀑布图、调制方式与数字解码标签

## 1. 实验目的

本实验参考 EE121 Digital Communications Systems Lab 3 的要求，使用在线 SDR 接收机观察不同频段中的无线电信号。重点目标包括：

- 在频谱图和瀑布图上识别 AM、SSB、数字信号、CW 摩尔斯码以及“特殊/异常”信号。
- 记录每个信号的频率、调制方式、可能来源和采集时间。
- 根据接收机界面标签、频段分配和信号形态对截图进行分类标注。

## 2. 截图分类总览

| 类别 | 截图 | 频率 | 调制/协议 | 可能来源 | 采集时间 |
|---|---|---:|---|---|---|
| 数字广播 | `dab_178.352mhz_dr-deutschland.png` | 178.352 MHz 附近 | DAB | DR Deutschland / Schwarzwaldradio，德国 | 2026-04-24 17:26:30 |
| 航空通信 | `airband_am_131.350mhz_scotland.jpeg` | 131.350 MHz | AM | Central Scotland OpenWebRX，航空频段 | 09:15 UTC |
| 航空通信 | `airband_am_126.303mhz_scotland.jpg` | 126.3028 MHz | AM | Central Scotland OpenWebRX，航空频段 | 09:16 UTC |
| 海事数字 | `ais_161.975mhz_scotland.jpeg` | 161.975 MHz | AIS | 船舶自动识别系统，苏格兰附近海事信号 | 09:17 UTC |
| 海事数字 | `ais_162.025mhz_scotland.jpg` | 162.025 MHz | AIS | 船舶自动识别系统，苏格兰附近海事信号 | 09:30 UTC |
| 业余无线电数字 | `ham_digital_145.725mhz_munich.jpeg` | 145.725 MHz | FM / 数字标签区 | Munich, Germany 2m 业余频段 | 文件时间 17:35 |
| 摩尔斯码 | `cw_7.025mhz_40m.jpg` | 7.025 MHz | CW | 40 m 业余无线电 CW 段 | 文件时间 17:35 |
| 数字窄带 | `ft8_7.074mhz_40m.jpg` | 7.074 MHz | FT8 等弱信号数字通信 | 40 m 业余无线电数字段 | 文件时间 17:36 |
| 短波 AM | `shortwave_am_9.620mhz_guangdong.jpeg` | 9.620 MHz | AM | 31 m 短波广播，广东/中国相关广播标签 | 文件时间 17:55 |
| 短波 AM 补充 | `shortwave_am_13.80087mhz.jpg` | 13.80087 MHz | AM | 短波广播/实用台标签区，含 TWR、CNR1、NHK Japan Meteo Fax 等标签 | 文件时间 17:40 |
| USB/SSB 补充 | `usb_ssb_17.26985mhz.jpg` | 17.26985 MHz | USB | 短波实用通信/SSB 接收示例 | 文件时间 17:41 |
| AM 广播补充 | `am_broadcast_908khz.jpeg` | 908 kHz | AM | 中波广播示例 | 文件时间 17:25 |
| AM 广播补充 | `am_broadcast_198khz_lw.jpg` | 198 kHz | AM | 长波广播示例，可能为 BBC Radio 4 LW | 文件时间 17:36 |
| 特殊/时钟信号 | `time_signal_10.000mhz.jpg` | 10.000 MHz | AM / 标准频率时间信号 | 标准时间/频率台，如 WWV/WWVH/类似台站 | 文件时间 17:36 |
| 接收机菜单 | `openwebrx_band_menu_airband.png` | N/A | N/A | OpenWebRX 频段选择菜单 | 文件时间 17:24 |
| 接收机菜单 | `openwebrx_band_menu_airband_compact.png` | N/A | N/A | OpenWebRX 频段选择菜单 | 文件时间 17:37 |

说明：文件时间来自本地文件修改时间；部分截图本身显示 UTC 时间，表格中优先使用截图可见时间。中国标准时间 CST = UTC + 8，因此 09:15 UTC 约为 17:15 CST。

## 3. 按实验要求整理的信号样例

### 3.1 AM 信号

实验要求寻找 9 MHz 到 10 MHz 之间的 AM 短波广播。新增截图中有一张 9.620 MHz 的 AM 短波广播样例，位于 31 m Broadcast 频段，满足该项要求。另有 13.80087 MHz、908 kHz 和 198 kHz 的 AM 截图，可作为补充观察材料。

![9.620 MHz 广东/中国相关短波 AM 广播](<shortwave_am_9.620mhz_guangdong.jpeg>)

标注：该截图显示频率为 9620.00 kHz，即 9.620 MHz，模式选择为 AM，位于 9-10 MHz 范围内。界面上方标注为 31m Broadcast，并出现 China、Sound of Hope 等广播标签，符合短波 AM 广播信号的实验要求。

![13.80087 MHz 短波 AM 补充](<shortwave_am_13.80087mhz.jpg>)

标注：该截图显示频率约为 13800.87 kHz，即 13.80087 MHz，模式选择为 AM。频谱下方可见多个短波台站/业务标签，例如 TWR、CNR1、VMC、NHK Japan Meteo Fax 等，说明该段附近存在短波广播或实用通信信号。虽然它不在 9-10 MHz，但可作为短波 AM 观察样例。

![908 kHz AM 中波广播](<am_broadcast_908khz.jpeg>)

标注：该截图中接收机显示频率约为 908.00 kHz，模式选择为 AM。瀑布图中可以看到多个较窄的垂直信号线，符合 AM 广播或中波频段台站的连续载波特征。

![198 kHz AM 长波广播](<am_broadcast_198khz_lw.jpg>)

标注：该截图显示频率约为 198.00 kHz，模式为 AM。198 kHz 是典型长波广播频率，可能对应英国 BBC Radio 4 Long Wave 一类的长波广播信号。

### 3.2 Upper Sideband SSB 信号

实验要求寻找上边带 SSB 信号，建议位置为 14 MHz 业余无线电频段。新增截图中有一张选择 USB 模式、频率约 17.26985 MHz 的短波信号，可作为 USB/SSB 接收补充样例；不过它不在 14 MHz 业余无线电频段，因此如果要完全贴合作业建议，仍可后续补采 14 MHz USB 业余语音。

![17.26985 MHz USB/SSB 补充](<usb_ssb_17.26985mhz.jpg>)

标注：该截图显示频率约为 17269.85 kHz，即 17.26985 MHz，接收模式选择为 USB。瀑布图中有窄带信号线和短波业务标签，可作为上边带解调设置和短波 SSB/实用通信观察的补充材料。

建议补采方法：进入 20 m 业余无线电频段，调到 14.150-14.350 MHz 附近，选择 USB 模式，寻找语音信号。SSB 语音在瀑布图上通常表现为约 2-3 kHz 宽的非对称带状能量，没有完整 AM 载波。

### 3.3 数字信号

![DAB 数字广播](<dab_178.352mhz_dr-deutschland.png>)

标注：该截图显示 OpenWebRX 的 DAB 解码界面，频率约为 178.352 MHz，解码信息中出现 `Ensemble: DR Deutschland` 和 `Schwarzwaldradio`。DAB 是数字音频广播，瀑布图上表现为较宽、持续、近似块状的宽带数字信号。

![40 m FT8 数字弱信号](<ft8_7.074mhz_40m.jpg>)

标注：该截图显示频率约为 7074.00 kHz，即 7.074 MHz。该频点是 40 m 业余无线电常见 FT8 活动频率。瀑布图上可见较窄、周期性出现的垂直数字信号，符合 FT8 弱信号数字通信的形态。

![2 m 业余数字/分组信号区域](<ham_digital_145.725mhz_munich.jpeg>)

标注：该截图来自德国慕尼黑 OpenWebRX，频率约为 145.725 MHz，处于 2 m 业余无线电频段。界面上方标注了 FT8、MSK144、WSPR、PACKET 等数字通信活动区，瀑布图上可以看到规则的窄带数字信号结构。

### 3.4 Morse Code / CW 信号

![7.025 MHz CW 摩尔斯码](<cw_7.025mhz_40m.jpg>)

标注：该截图显示频率约为 7025.00 kHz，即 7.025 MHz，接收模式选择为 CW。该频率位于 40 m 业余无线电 CW 活动段，瀑布图中细窄、断续的垂直线条符合摩尔斯电码“点”和“划”的时域开关键控特征。

### 3.5 Something Weird / 特殊信号

![10 MHz 标准频率时间信号](<time_signal_10.000mhz.jpg>)

标注：该截图显示频率为 10000.00 kHz，即 10.000 MHz。10 MHz 是常见标准频率和时间信号频点，可能来自 WWV、WWVH 或类似标准时间台。此类信号通常用于频率校准和时间同步，属于实验要求中“clocks / beacons”类型的特殊信号。

![AIS 161.975 MHz 海事数字信号](<ais_161.975mhz_scotland.jpeg>)

标注：该截图显示频率 161.975 MHz，OpenWebRX 已选择 AIS 解码器，并输出船舶 MMSI/callsign 类数字信息。AIS 是船舶自动识别系统，用于广播船舶位置、航向、速度和身份信息。

![AIS 162.025 MHz 海事数字信号](<ais_162.025mhz_scotland.jpg>)

标注：该截图显示频率 162.025 MHz，同样是 AIS 通道。瀑布图中可见短促、重复出现的数字突发信号，与 AIS 的时隙突发传输特征一致。

## 4. 其他观测截图

![131.350 MHz 航空 AM](<airband_am_131.350mhz_scotland.jpeg>)

标注：频率 131.350 MHz，接收机选择 Airband 131-137，模式为 AM。航空通信一般使用 AM 调制，这一点与截图中的模式选择一致。

![126.3028 MHz 航空 AM](<airband_am_126.303mhz_scotland.jpg>)

标注：频率约 126.3028 MHz，位于航空 VHF 频段，模式为 AM。该截图可作为航空语音通信的补充观察。

![OpenWebRX 频段菜单](<openwebrx_band_menu_airband.png>)

![OpenWebRX 频段菜单重复截图](<openwebrx_band_menu_airband_compact.png>)

标注：这两张截图显示 OpenWebRX 接收机的频段选择菜单，包括 2m、Marine、Airband、70cm、PMR446、AIS 等选项。它们不作为信号样例，但说明了实验中使用的接收机配置来源。

## 5. 结论

本次采集覆盖了多种无线电信号：DAB 数字广播、FT8 弱信号数字通信、CW 摩尔斯码、AIS 海事数字突发信号、航空 AM 语音信道，以及长波/中波 AM 广播。通过频率、调制模式按钮、瀑布图形态和 OpenWebRX 的标签/解码器输出，可以较可靠地完成分类。

当前素材中最符合 EE121 Lab 3 要求的是 AM 短波广播、数字信号、CW 摩尔斯码和特殊信号四类；新增的 9.620 MHz AM 截图已经补上了 9-10 MHz 短波广播要求。USB/SSB 目前使用 17.26985 MHz 的短波 USB 截图作为补充样例，虽然不在建议的 14 MHz 业余频段，但已经能体现上边带接收设置和 SSB 类信号观察。
