# 智能照明系统架构文档
# Smart Lighting System Architecture

## 概述 Overview

本文档描述了基于HarmonyOS的智能照明系统的技术架构和设计决策。
This document describes the technical architecture and design decisions of the HarmonyOS-based Smart Lighting System.

## 技术栈 Technology Stack

- **开发语言 Language**: ArkTS (TypeScript-based)
- **框架 Framework**: HarmonyOS SDK API 9
- **UI范式 UI Paradigm**: ArkUI Declarative Development
- **架构模式 Architecture**: MVVM (Model-View-ViewModel)

## 项目结构 Project Structure

```
smart_LightAPP/
├── entry/                                      # 应用入口模块 Entry Module
│   ├── src/main/
│   │   ├── ets/
│   │   │   ├── entryability/
│   │   │   │   └── EntryAbility.ts           # 应用能力 Application Ability
│   │   │   ├── pages/
│   │   │   │   └── Index.ets                  # 主界面 Main Page
│   │   │   └── model/
│   │   │       └── LightModel.ts              # 数据模型 Data Model
│   │   ├── resources/
│   │   │   ├── base/                          # 默认资源 Default Resources
│   │   │   │   ├── element/
│   │   │   │   │   ├── string.json           # 英文字符串 English Strings
│   │   │   │   │   └── color.json            # 颜色资源 Color Resources
│   │   │   │   ├── media/
│   │   │   │   │   └── icon.png              # 应用图标 App Icon
│   │   │   │   └── profile/
│   │   │   │       └── main_pages.json       # 页面配置 Page Config
│   │   │   └── zh_CN/                         # 中文资源 Chinese Resources
│   │   │       └── element/
│   │   │           └── string.json           # 中文字符串 Chinese Strings
│   │   └── module.json5                       # 模块配置 Module Config
│   ├── build-profile.json5                    # 构建配置 Build Profile
│   └── oh-package.json5                       # 包配置 Package Config
├── build-profile.json5                        # 全局构建配置 Global Build Profile
├── oh-package.json5                           # 项目配置 Project Config
├── hvigorfile.ts                             # 构建脚本 Build Script
├── .gitignore                                 # Git忽略文件 Git Ignore
└── README.md                                  # 项目说明 Project Documentation
```

## 架构设计 Architecture Design

### 三层架构 Three-Layer Architecture

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│         (Index.ets)                     │
│  - UI Components                        │
│  - State Management (@State)            │
│  - User Interaction                     │
└─────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────┐
│         Business Logic Layer            │
│         (LightModel.ts)                 │
│  - LightDevice Class                    │
│  - LightingManager (Singleton)          │
│  - Business Rules                       │
└─────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────┐
│         Application Layer               │
│         (EntryAbility.ts)               │
│  - Lifecycle Management                 │
│  - Window Management                    │
│  - Application Initialization           │
└─────────────────────────────────────────┘
```

## 核心组件 Core Components

### 1. LightDevice 类

**职责 Responsibility**: 表示单个智能灯光设备
Represents a single smart lighting device

**属性 Properties**:
- `id`: 设备唯一标识符 (Device unique identifier)
- `name`: 设备名称 (Device name)
- `isOn`: 开关状态 (Power state)
- `brightness`: 亮度 (0-100%) (Brightness)
- `colorTemperature`: 色温 (2700-6500K) (Color temperature)

**方法 Methods**:
- `togglePower()`: 切换开关状态 (Toggle power state)
- `setBrightness(value)`: 设置亮度 (Set brightness)
- `setColorTemperature(value)`: 设置色温 (Set color temperature)
- `getStatus()`: 获取状态 (Get status)

### 2. LightingManager 类

**设计模式 Design Pattern**: 单例模式 (Singleton Pattern)

**职责 Responsibility**: 管理所有灯光设备
Manages all lighting devices

**方法 Methods**:
- `getInstance()`: 获取单例实例 (Get singleton instance)
- `getDevice(id)`: 获取指定设备 (Get device by ID)
- `getAllDevices()`: 获取所有设备 (Get all devices)
- `addDevice(device)`: 添加设备 (Add device)

### 3. Index 页面组件

**职责 Responsibility**: 用户界面和交互
User interface and interaction

**状态管理 State Management**:
- `@State currentLight`: 当前灯光设备 (Current light device)
- `@State isLightOn`: 灯光开关状态 (Light power state)
- `@State brightness`: 亮度值 (Brightness value)
- `@State colorTemperature`: 色温值 (Color temperature value)

**UI组件 UI Components**:
- 标题栏 (Title bar)
- 灯光状态卡片 (Light status card)
- 开关按钮 (Power button)
- 亮度滑块 (Brightness slider)
- 色温滑块 (Color temperature slider)

## 数据流 Data Flow

```
User Action → UI Component → Update @State → Model Update → UI Re-render
用户操作 → UI组件 → 更新状态 → 模型更新 → UI重新渲染
```

### 示例流程 Example Flow

1. 用户点击开关按钮 (User clicks power button)
2. onClick事件触发 (onClick event triggers)
3. 调用 `currentLight.togglePower()` (Call togglePower method)
4. 更新 `@State isLightOn` (Update @State)
5. UI自动重新渲染 (UI automatically re-renders)

## 国际化支持 Internationalization Support

### 资源管理 Resource Management

使用HarmonyOS资源管理系统实现国际化：
Using HarmonyOS resource management system for i18n:

- **默认语言 Default**: English (base/element/string.json)
- **中文 Chinese**: Simplified Chinese (zh_CN/element/string.json)

### 资源引用方式 Resource Reference

```typescript
// 在UI中使用 (In UI)
Text($r('app.string.light_control'))

// 自动根据系统语言选择对应资源
// Automatically selects appropriate resource based on system language
```

## 设计原则 Design Principles

### 1. 单一职责原则 (Single Responsibility Principle)
- 每个类只负责一个功能领域
- Each class is responsible for a single functional area

### 2. 开闭原则 (Open-Closed Principle)
- 对扩展开放，对修改封闭
- Open for extension, closed for modification
- 可以轻松添加新的设备类型
- Easy to add new device types

### 3. 依赖倒置原则 (Dependency Inversion Principle)
- UI层依赖于抽象的模型接口
- UI layer depends on abstract model interfaces

### 4. 单例模式 (Singleton Pattern)
- LightingManager使用单例确保数据一致性
- LightingManager uses singleton to ensure data consistency

## 扩展性 Extensibility

### 添加新设备类型 Adding New Device Types

1. 在 `LightModel.ts` 中添加新的设备常量
2. 创建新的设备实例
3. 在UI中添加对应的控制界面

### 添加新功能 Adding New Features

可以轻松添加：
Can easily add:
- 定时功能 (Timer function)
- 场景模式 (Scene modes)
- 设备分组 (Device grouping)
- 远程控制 (Remote control)
- 数据统计 (Data statistics)

## 性能考虑 Performance Considerations

1. **状态管理优化**
   - 使用 @State 装饰器实现精确的UI更新
   - Only update necessary UI components

2. **单例模式**
   - 避免重复创建管理器实例
   - Avoid creating multiple manager instances

3. **资源懒加载**
   - 资源按需加载
   - Load resources on demand

## 安全性 Security

1. **输入验证**
   - 亮度和色温值范围检查
   - Range validation for brightness and color temperature

2. **空值检查**
   - 安全的设备初始化逻辑
   - Safe device initialization logic

3. **代码扫描**
   - 通过CodeQL安全扫描
   - Passed CodeQL security scan

## 最佳实践 Best Practices

1. **代码组织**
   - 清晰的目录结构
   - 功能模块分离

2. **命名规范**
   - 使用描述性的变量名
   - 类名使用PascalCase
   - 方法名使用camelCase

3. **注释**
   - 中英文双语注释
   - 关键逻辑添加详细说明

4. **错误处理**
   - 适当的错误检查
   - 用户友好的错误提示

## 构建和部署 Build and Deployment

### 开发环境要求 Development Requirements
- DevEco Studio 3.1+
- HarmonyOS SDK API 9+

### 构建命令 Build Commands
```bash
# 使用DevEco Studio构建
# Build using DevEco Studio
- File → Project Structure → Verify SDK
- Build → Build Hap(s)
```

### 部署步骤 Deployment Steps
1. 连接HarmonyOS设备或启动模拟器
2. 点击运行按钮
3. 选择目标设备
4. 应用自动安装和启动

## 版本历史 Version History

### v1.0.0 (2025-11-04)
- ✅ 初始版本发布
- ✅ 基本照明控制功能
- ✅ 亮度和色温调节
- ✅ 中英文国际化支持
- ✅ 完整的文档

## 贡献指南 Contributing

欢迎贡献代码！请遵循以下准则：
Contributions are welcome! Please follow these guidelines:

1. Fork项目 (Fork the project)
2. 创建特性分支 (Create feature branch)
3. 提交变更 (Commit changes)
4. 推送到分支 (Push to branch)
5. 创建Pull Request (Create Pull Request)

## 许可证 License

Apache-2.0 License
