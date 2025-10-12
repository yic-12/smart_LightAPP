/**
 * 智能照明管理APP - 数据接口定义 (Interface1.ets)
 * 
 * 功能说明：
 * 1. 定义项目中使用的所有数据接口和类型
 * 2. 提供API请求和响应的数据结构
 * 3. 定义设备控制相关的数据结构
 * 4. 定义场景和定时任务的数据结构
 * 5. 定义颜色和命令相关的数据结构
 * 
 * 技术特点：
 * - TypeScript接口定义
 * - 可选参数支持
 * - 类型安全保证
 * - 便于代码维护和扩展
 */

// ==================== 基础数据接口 ====================

/**
 * Data1 - 基础请求数据接口
 * 
 * 功能说明：
 * - 定义基础的项目请求数据结构
 * - 包含项目ID和时间戳
 * - 用于简单的API请求
 * 
 * 字段说明：
 * - project_id: 项目唯一标识符
 * - timestamp: 请求时间戳，用于认证和防重放
 */
export interface Data1 {
  project_id: string,    // 项目唯一标识符
  timestamp: string      // 请求时间戳，用于认证和防重放
}

/**
 * Data2 - 设备控制请求数据接口
 * 
 * 功能说明：
 * - 定义设备控制的完整请求数据结构
 * - 支持RGB颜色控制和亮度控制
 * - 包含认证令牌和设备状态
 * - 用于单个设备的精确控制
 * 
 * 字段说明：
 * - timestamp: 请求时间戳，用于认证和防重放
 * - token: 认证令牌，基于时间戳和密钥生成
 * - control_sub_id: 控制的子设备ID（目标灯光设备ID）
 * - control_sub_state: 设备控制状态（'0'=打开，'1'=关闭）
 * - r_channel: 红色通道值，可选参数
 * - g_channel: 绿色通道值，可选参数
 * - b_channel: 蓝色通道值，可选参数
 * - w_channel: 白光通道值（亮度控制），可选参数
 * - y_channel: 黄光通道值（色温控制），可选参数
 * - control_state: 控制状态，可选参数
 * - type_uuid: 设备类型UUID
 * - lightness: 亮度值，可选参数（与w_channel可能重复，取决于API设计）
 */
export interface Data2 {
  timestamp: string;        // 请求时间戳，用于认证和防重放
  token: string;           // 认证令牌，基于时间戳和密钥生成
  control_sub_id: string;  // 控制的子设备ID（目标灯光设备ID）
  control_sub_state: string; // 设备控制状态：'0'=打开，'1'=关闭
  r_channel?: number;      // 红色通道值，可选参数
  g_channel?: number;      // 绿色通道值，可选参数
  b_channel?: number;      // 蓝色通道值，可选参数
  w_channel?: number;      // 白光通道值（亮度控制），可选参数
  y_channel?: number;      // 黄光通道值（色温控制），可选参数
  control_state?: string;  // 控制状态，可选参数
  type_uuid: string;       // 设备类型UUID
  lightness?: number;      // 亮度值，可选参数（与w_channel可能重复，取决于API设计）
}

// ==================== 场景和UI相关接口 ====================

/**
 * SceneClass - 场景类接口
 * 
 * 功能说明：
 * - 定义场景的基本信息结构
 * - 用于场景列表的显示和控制
 * - 支持图标和文本描述
 * 
 * 字段说明：
 * - text: 场景名称或描述文本
 * - icon: 场景图标资源，可选参数
 */
export interface SceneClass {
  text: string,           // 场景名称或描述文本
  icon?: ResourceStr      // 场景图标资源，可选参数
}

/**
 * ApiRequestData - API请求数据接口
 * 
 * 功能说明：
 * - 定义通用的API请求数据结构
 * - 支持场景、设备、动作等参数
 * - 用于各种API调用场景
 * 
 * 字段说明：
 * - scene: 场景名称，可选参数
 * - device: 设备名称，可选参数
 * - action: 动作类型，可选参数
 * - timestamp: 请求时间戳
 */
export interface ApiRequestData {
  scene?: string;         // 场景名称，可选参数
  device?: string;        // 设备名称，可选参数
  action?: string;        // 动作类型，可选参数
  timestamp: number;      // 请求时间戳
}

// ==================== 定时任务相关接口 ====================

/**
 * TimerItem - 定时任务项接口
 * 
 * 功能说明：
 * - 定义单个定时任务的完整信息
 * - 支持重复周期设置
 * - 支持开灯和关灯动作
 * - 用于定时功能的实现
 * 
 * 字段说明：
 * - id: 定时任务唯一标识符
 * - name: 定时任务名称（如：早晨起床、晚上休息）
 * - time: 执行时间，格式：HH:mm（如：07:00、23:00）
 * - enabled: 是否启用该定时任务
 * - repeat: 重复周期数组，数字1-7代表周一到周日
 * - deviceId: 关联的设备ID
 * - action: 定时动作（'0'=开灯，'1'=关灯）
 */
export interface TimerItem {
  id: string;                    // 定时任务唯一标识符
  name: string;                  // 定时任务名称（如：早晨起床、晚上休息）
  time: string;                  // 执行时间，格式：HH:mm（如：07:00、23:00）
  enabled: boolean;              // 是否启用该定时任务
  repeat: number[];              // 重复周期数组，数字1-7代表周一到周日
  deviceId: string;              // 关联的设备ID
  action: '0' | '1';  // 定时动作：开灯或关灯
}

// ==================== 颜色相关接口 ====================

/**
 * colorRgb - RGB颜色接口
 * 
 * 功能说明：
 * - 定义RGB三原色的颜色结构
 * - 用于颜色控制和显示
 * - 支持0-255的颜色值范围
 * 
 * 字段说明：
 * - r: 红色通道值（0-255）
 * - g: 绿色通道值（0-255）
 * - b: 蓝色通道值（0-255）
 */
export interface colorRgb {
  r: number,    // 红色通道值（0-255）
  g: number,    // 绿色通道值（0-255）
  b: number     // 蓝色通道值（0-255）
}

/**
 * scenceRgb - 场景RGB接口
 * 
 * 功能说明：
 * - 定义场景与设备控制项的关联结构
 * - 用于场景模式的颜色控制
 * - 支持一个场景控制多个设备
 * 
 * 字段说明：
 * - scence: 场景名称
 * - device: 该场景下的设备控制项列表
 */
export interface scenceRgb {
  scence: string,                    // 场景名称
  device: DeviceControlItem[]         // 该场景下的设备控制项列表
}

// ==================== 命令相关接口 ====================

/**
 * commands - 命令接口
 * 
 * 功能说明：
 * - 定义语音命令的数据结构
 * - 支持命令名称、模式和动作
 * - 用于语音控制功能
 * 
 * 字段说明：
 * - name: 命令名称
 * - patter: 命令模式数组，支持多种语音模式
 * - action: 命令对应的动作
 */
export interface commands {
  name: string,        // 命令名称
  patter: string[],    // 命令模式数组，支持多种语音模式
  action: string       // 命令对应的动作
}

// ==================== 多设备控制相关接口 ====================

/**
 * MultiDeviceControlData - 多设备控制请求数据结构
 * 
 * 功能说明：
 * - 定义多设备批量控制的数据结构
 * - 支持一次性控制多个设备
 * - 包含认证和防重放机制
 * 
 * 字段说明：
 * - timestamp: 请求时间戳，用于认证和防重放
 * - token: 认证令牌，基于时间戳和密钥生成
 * - devices: 需要控制的设备列表
 */
export interface MultiDeviceControlData {
  timestamp: string;        // 请求时间戳，用于认证和防重放
  token: string;           // 认证令牌，基于时间戳和密钥生成
  devices: DeviceControlItem[];  // 需要控制的设备列表
}

/**
 * DeviceControlItem - 单个设备控制项接口
 * 
 * 功能说明：
 * - 定义单个设备的控制参数
 * - 支持RGB颜色控制和亮度控制
 * - 包含设备状态和类型信息
 * - 用于设备列表和批量控制
 * 
 * 字段说明：
 * - control_sub_id: 控制的子设备ID
 * - control_sub_state: 设备控制状态（'0'=打开，'1'=关闭）
 * - name: 设备名称（来自 device.ets 注释）
 * - r_channel: 红色通道值
 * - g_channel: 绿色通道值
 * - b_channel: 蓝色通道值
 * - w_channel: 白光通道值（亮度控制）
 * - y_channel: 黄光通道值（色温控制）
 * - type_uuid: 设备类型UUID
 */
export interface DeviceControlItem {
  control_sub_id: string;  // 控制的子设备ID
  control_sub_state: string; // 设备控制状态：'0'=打开，'1'=关闭
  name?: string;            // 设备名称（来自 device.ets 注释）
  r_channel?: number;      // 红色通道值
  g_channel?: number;      // 绿色通道值
  b_channel?: number;      // 蓝色通道值
  w_channel?: number;      // 白光通道值（亮度控制）
  y_channel?: number;      // 黄光通道值（色温控制）
  //control_state?: string;  // 控制状态
  type_uuid: string;       // 设备类型UUID
  //lightness?: number;      // 亮度值
}