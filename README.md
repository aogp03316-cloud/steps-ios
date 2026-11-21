# iOS 改步数 App（HealthKit）— 含云端自动编译

> 微信运动读的是 HealthKit。本 App 往 HealthKit 写「非手动」步数样本，微信同步后就变了。
> 不需要 Zepp 账号、不需要越狱、不需要绑数据源。

## 为什么不能在你电脑上直接编译

iOS App 只能用 **macOS + Xcode** 编译。你这台是 Windows（已确认：iPhone 已连接、爱思助手 9.21 已装、但没有 Xcode / git），所以有两条路：

| 路线 | 耗时 | 成本 |
|---|---|---|
| **A. GitHub 云端编译**（推荐，下面详述） | 约 20 分钟 | 0 |
| B. 借一台 Mac，Xcode 打开直接 Run | 5 分钟 | 0 |

## A. GitHub 云端编译（不用装 git）

1. 注册/登录 GitHub → 右上角 **+ → New repository** → 名字随便（如 `steps`）→ **Private** → Create
2. 进仓库 → **Add file → Upload files** → 把本文件夹里的这些拖进去：
   ```
   project.yml
   Sources/（三个 .swift）
   .github/workflows/build.yml
   ```
   > 网页上传支持拖文件夹，`.github` 目录也能一起传上去。
3. 上传后自动开始构建（仓库顶部 **Actions** 标签能看到进度），约 3–5 分钟
4. 构建完成 → 点进那次运行 → 页面底部 **Artifacts → Steps-unsigned-ipa** 下载
5. 解压得到 `Steps-unsigned.ipa`

## B. 签名 + 装到手机（爱思助手）

你已经装了爱思助手 9.21，直接用它：

1. 手机连电脑，爱思助手识别到设备
2. 顶部 **工具箱 → IPA 签名**
3. 选 `Steps-unsigned.ipa` → 填你的 **Apple ID 和密码**（或导入证书）
4. 签名完成后点 **安装到设备**

> 装完第一次打开会提示「不受信任的开发者」→ 设置 → 通用 → VPN与设备管理 → 信任

## ⚠️ 一个硬门槛：HealthKit 需要付费开发者账号

免费 Apple ID 签出来的 App，**启用不了 HealthKit 权限**，装上会闪退或写入失败。三条出路：

| 方式 | 成本 | 说明 |
|---|---|---|
| Apple 开发者账号 | $99/年 | 最稳，自己签，一年有效 |
| 第三方企业签名 | ¥100–300/年 | 淘宝/闲鱼买，装完能用，但可能被吊销 |
| 越狱设备 | 0 | 用 ldid 伪签名 + 越狱环境，绕开校验 |

**没有这三样之一，App 能装上但写不了步数**——这是 Apple 的机制，不是代码问题。

## C. 用起来（装好之后）

1. 打开 App → 弹窗允许「写入步数」
2. 输入目标（如 23800）→ 点「写入今天」
3. 打开微信 → 微信运动 → 下拉刷新 → 等 1–3 分钟 → 排行榜变了

## D. 三个坑

1. **HealthKit 是累加的**：代码已做「读当天总和 → 只写差值」，不会叠成 4 万
2. **微信不是实时读**：写完要下拉刷新，1–3 分钟，最长几小时
3. **别写太夸张**：2–3.5 万最自然，10 万会被标异常

## E. 文件说明

```
ios-step-app/
├── project.yml                  XcodeGen 工程定义（含 HealthKit entitlement）
├── Sources/
│   ├── StepApp.swift            入口
│   ├── ContentView.swift        UI
│   └── StepWriter.swift         HealthKit 写入逻辑（差值算法）
├── .github/workflows/build.yml  云端自动编译 + 打包 IPA
└── README.md
```
