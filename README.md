GrowingIO SaaS SDK
======
![GrowingIO](https://www.growingio.com/vassets/images/home_v3/gio-logo-primary.svg)  

## GrowingIO简介
创立于 2015 年，GrowingIO 是国内领先的一站式数据增长引擎方案服务商，属 StartDT 奇点云集团旗下品牌。**以数据智能分析为核心，GrowingIO 通过构建客户数据平台，打造增长营销闭环**，帮助企业提升数据驱动能力，赋能商业决策、实现业务增长。   
GrowingIO 专注于零售、电商、保险、酒旅航司、教育、内容社区等行业，成立以来，累计服务超过 1500 家企业级客户，获得 LVMH 集团、百事、达能、老佛爷百货、戴尔、lululemon、美素佳儿、宜家、乐高、美的、海尔、安踏、汉光百货、中原地产、上汽集团、广汽蔚来、理想汽车、招商仁和人寿、飞鹤、红星美凯龙、东方航空、滴滴、新东方、喜茶、每日优鲜、奈雪的茶、永辉超市等客户的青睐。

## SDK 简介
**GrowingIO SaaS SDK** 具备自动采集基本的用户行为事件，比如访问和行为数据等。目前支持代码埋点、无埋点、可视化圈选等功能。

## 如何编译

### 修改签名命令

请在 build.sh 中修改 codesign 相关签名参数为您的证书

### 开始编译

```shell
// 生成 GrowingCoreKit
sh build.sh -cv 3.2.0

// 生成 GrowingPublicHeader、GrowingAutoTrackKit、GrowingReactNativeKit 等等
sh build.sh -pv 3.2.0 -av 3.2.0 -rv 3.2.0
```

## License

```
Copyright (C) 2025 Beijing Yishu Technology Co., Ltd.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

### Third-Party Libraries

This project includes the following third-party libraries:

- **CocoaLumberjack** - BSD 3-Clause License (Deusty, LLC)
- **Masonry** - MIT License (Masonry Team)  
- **FMDB** - License varies by version (Gus Mueller, Flying Meat Inc.)
- **SocketRocket** - BSD License (Facebook, Inc.)
- **LZ4** - BSD 2-Clause License (Yann Collet)
- **fishhook** - BSD 3-Clause License (Facebook, Inc.)

The third-party libraries listed above have been integrated and modified within this project. All third-party libraries used in this project are compatible with the Apache License 2.0.
