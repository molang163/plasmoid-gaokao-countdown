# Gaokao Countdown Widget for KDE Plasma 6

适用于 KDE Plasma 6 的高考倒计时小组件。默认目标时间为每年 6 月 7 日 09:00，可在小组件设置中修改标题、日期、时间和是否显示秒数。

## 功能

- 支持 Plasma 6 桌面和面板显示
- 面板中显示紧凑倒计时，点击后打开完整视图
- 高考当天显示“今天”，不会在 6 月 7 日凌晨误跳到下一年
- 支持配置目标月份、日期、小时、分钟和标题
- 遵循 Plasma 6 `metadata.json` 和 `PlasmoidItem` 结构

## 安装源码版

```bash
chmod +x install.sh
./install.sh
```

安装完成后，在桌面右键菜单中选择“添加或管理挂件...”，搜索并添加“高考倒计时”。

## 打包 release

```bash
chmod +x package.sh
./package.sh
```

打包产物会生成在 `dist/gaokao-countdown.plasmoid`，用户可以通过下面的命令安装：

```bash
kpackagetool6 -t Plasma/Applet -i dist/gaokao-countdown.plasmoid
```

## 开发测试

```bash
kpackagetool6 --appstream-metainfo .
./install.sh
plasmawindowed com.github.plasmoid-gaokao-countdown
```
