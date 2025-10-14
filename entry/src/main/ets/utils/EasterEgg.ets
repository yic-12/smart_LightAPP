import { DeviceControlItem } from "../inter/Interface1";
import { HttpUtil } from "../inter/HttpUtil";

// ==================== 接口定义 ====================

/**
 * RGBColor - RGB颜色接口
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
interface RGBColor {
  r: number;    // 红色通道值（0-255）
  g: number;    // 绿色通道值（0-255）
  b: number;    // 蓝色通道值（0-255）
}

/**
 * BeatPattern - 节拍模式接口
 * 
 * 功能说明：
 * - 定义音乐节拍的闪烁模式
 * - 支持不同的节拍强度和颜色
 * - 用于创建有节奏的灯光效果
 * 
 * 字段说明：
 * - name: 节拍模式名称
 * - bpm: 每分钟节拍数（Beats Per Minute）
 * - intensity: 节拍强度（0-100）
 * - color: 节拍颜色
 * - pattern: 节拍模式数组（1=强拍，0=弱拍）
 */
interface BeatPattern {
  name: string;           // 节拍模式名称
  bpm: number;           // 每分钟节拍数
  intensity: number;      // 节拍强度（0-100）
  color: RGBColor;       // 节拍颜色
  pattern: number[];     // 节拍模式数组
}

/**
 * MusicBeatMode - 音乐节拍模式枚举
 * 
 * 功能说明：
 * - 定义不同的音乐节拍模式
 * - 每种模式有不同的BPM和节拍模式
 */
export enum MusicBeatMode {
  SLOW_BALLAD = 0,      // 慢板抒情（60 BPM）
  MODERATE_POP = 1,     // 中等流行（120 BPM）
  FAST_DANCE = 2,       // 快节奏舞曲（140 BPM）
  CUSTOM = 3            // 自定义模式
}

// ==================== 彩蛋闪烁控制类 ====================

/**
 * EasterEggController - 音乐节拍跟随控制器
 * 
 * 功能说明：
 * - 控制彩蛋场景的音乐节拍跟随效果
 * - 支持多种音乐节拍模式
 * - 根据节拍强度和模式改变设备参数
 * - 使用定时器实现有节奏的闪烁
 */
export class EasterEggController {
  
  // ==================== 静态属性 ====================
  
  /**
   * 节拍定时器
   * 用于控制节拍间隔
   */
  private static beatTimer: number | null = null;
  
  /**
   * 闪烁状态
   * true: 正在跟随节拍，false: 已停止
   */
  private static isFlashing: boolean = false;
  
  /**
   * 当前音乐节拍模式
   * 默认为中等流行音乐模式
   */
  private static currentBeatMode: MusicBeatMode = MusicBeatMode.MODERATE_POP;
  
  /**
   * 当前节拍索引
   * 用于跟踪当前播放的节拍位置
   */
  private static currentBeatIndex: number = 0;
  
  /**
   * 节拍执行计数器
   * 用于控制节拍跳过逻辑
   */
  private static beatExecutionCounter: number = 0;
  
  /**
   * 请求队列管理
   * 用于控制并发请求数量，避免设备过载
   */
  private static requestQueue: Promise<void>[] = [];
  
  /**
   * 最大并发请求数
   * 限制同时发送的设备控制请求数量
   */
  private static readonly MAX_CONCURRENT_REQUESTS: number = 2;
  
  /**
   * 请求间隔时间（毫秒）
   * 在请求之间添加延迟，减少设备压力
   */
  private static readonly REQUEST_INTERVAL: number = 500;
  
  /**
   * 节拍间隔倍数
   * 将原始BPM间隔乘以这个倍数，降低请求频率
   */
  private static readonly BEAT_INTERVAL_MULTIPLIER: number = 4;
  
  /**
   * 节拍跳过间隔
   * 每隔几个节拍才执行一次设备控制，进一步降低频率
   */
  private static readonly BEAT_SKIP_INTERVAL: number = 2;
  
  /**
   * 节拍模式配置
   * 包含所有预定义的音乐节拍模式
   */
  private static beatPatterns: BeatPattern[] = [
    {
      name: "慢板抒情",
      bpm: 60,
      intensity: 70,
      color: { r: 255, g: 200, b: 200 }, // 温暖的粉色
      pattern: [1, 0, 0, 0, 1, 0, 0, 0] // 4/4拍，强拍在1和5
    },
    {
      name: "中等流行",
      bpm: 120,
      intensity: 80,
      color: { r: 200, g: 255, b: 200 }, // 清新的绿色
      pattern: [1, 0, 1, 0, 1, 0, 1, 0] // 4/4拍，每拍都有
    },
    {
      name: "快节奏舞曲",
      bpm: 140,
      intensity: 90,
      color: { r: 200, g: 200, b: 255 }, // 活力的蓝色
      pattern: [1, 1, 0, 1, 1, 0, 1, 1] // 复杂的节拍模式
    }
  ];
  
  /**
   * 氛围灯带颜色主题配置
   * 为氛围灯带提供丰富的颜色变化效果
   */
  private static ambientLightColorThemes: RGBColor[][] = [
    // 主题1：彩虹渐变
    [
      { r: 255, g: 0, b: 0 },     // 红色
      { r: 255, g: 127, b: 0 },   // 橙色
      { r: 255, g: 255, b: 0 },   // 黄色
      { r: 0, g: 255, b: 0 },     // 绿色
      { r: 0, g: 0, b: 255 },     // 蓝色
      { r: 75, g: 0, b: 130 },    // 靛色
      { r: 148, g: 0, b: 211 }    // 紫色
    ],
    // 主题2：温暖色调
    [
      { r: 255, g: 200, b: 200 }, // 粉红
      { r: 255, g: 180, b: 150 }, // 桃色
      { r: 255, g: 160, b: 100 }, // 珊瑚色
      { r: 255, g: 140, b: 80 },  // 橙红色
      { r: 255, g: 120, b: 60 },  // 深橙色
      { r: 255, g: 100, b: 40 },  // 红橙色
      { r: 255, g: 80, b: 20 }    // 深红橙
    ],
    // 主题3：活力色调
    [
      { r: 255, g: 0, b: 255 },   // 洋红
      { r: 255, g: 0, b: 128 },   // 粉红
      { r: 255, g: 0, b: 0 },     // 红色
      { r: 255, g: 128, b: 0 },   // 橙色
      { r: 255, g: 255, b: 0 },   // 黄色
      { r: 128, g: 255, b: 0 },   // 黄绿
      { r: 0, g: 255, b: 0 }      // 绿色
    ],
    // 主题4：活力色彩
    [
      { r: 255, g: 0, b: 255 },   // 洋红
      { r: 255, g: 0, b: 128 },   // 粉红
      { r: 255, g: 0, b: 0 },     // 红色
      { r: 255, g: 128, b: 0 },   // 橙色
      { r: 255, g: 255, b: 0 },   // 黄色
      { r: 128, g: 255, b: 0 },   // 黄绿
      { r: 0, g: 255, b: 0 }      // 绿色
    ],
    // 主题5：梦幻色彩
    [
      { r: 255, g: 200, b: 255 }, // 淡紫
      { r: 200, g: 200, b: 255 }, // 淡蓝
      { r: 200, g: 255, b: 255 }, // 淡青
      { r: 200, g: 255, b: 200 }, // 淡绿
      { r: 255, g: 255, b: 200 }, // 淡黄
      { r: 255, g: 200, b: 200 }, // 淡粉
      { r: 255, g: 180, b: 255 }  // 淡紫粉
    ]
  ];
  
  /**
   * 当前颜色主题索引
   * 用于循环切换颜色主题
   */
  private static currentColorThemeIndex: number = 0;
  
  /**
   * 当前颜色索引
   * 用于在当前主题内循环颜色
   */
  private static currentColorIndex: number = 0;
  
  /**
   * HTTP工具实例
   * 用于发送设备控制请求
   */
  private static httpUtil: HttpUtil = HttpUtil.getInstance();
  
  /**
   * 服务器API地址
   * 与主应用保持一致
   */
  private static readonly API_URL: string = "http://10.214.166.140:8081/SmartHome/ShenDaRest/controlLight";

  // ==================== 节拍参数生成方法 ====================
  
  /**
   * 根据节拍强度生成亮度值
   * 
   * 功能说明：
   * - 根据当前节拍强度和模式生成亮度值
   * - 强拍时亮度更高，弱拍时亮度较低
   * - 确保亮度变化符合音乐节拍
   * 
   * 参数说明：
   * - beatIntensity: number - 当前节拍强度（0-1）
   * - baseIntensity: number - 基础强度（0-100）
   * 
   * 返回值：
   * - number - 基于节拍的亮度值（0-100）
   */
  private static getBeatBasedBrightness(beatIntensity: number, baseIntensity: number): number {
    // 基础亮度范围：30-90
    const baseBrightness = 30 + (baseIntensity * 0.6);
    // 节拍强度影响：强拍时增加亮度，弱拍时减少亮度
    const beatMultiplier = 0.3 + (beatIntensity * 0.7);
    return Math.floor(baseBrightness * beatMultiplier);
  }
  
  /**
   * 根据节拍强度生成色温值
   * 
   * 功能说明：
   * - 根据节拍强度调整色温
   * - 强拍时色温偏暖，弱拍时色温偏冷
   * - 创造更有层次的光效
   * 
   * 参数说明：
   * - beatIntensity: number - 当前节拍强度（0-1）
   * 
   * 返回值：
   * - number - 基于节拍的色温值（0-100）
   */
  private static getBeatBasedColorTemperature(beatIntensity: number): number {
    // 基础色温范围：40-80
    const baseTemp = 40 + (beatIntensity * 40);
    return Math.floor(baseTemp);
  }
  
  /**
   * 根据节拍模式获取颜色
   * 
   * 功能说明：
   * - 根据当前音乐模式和节拍强度获取颜色
   * - 强拍时颜色更鲜艳，弱拍时颜色更柔和
   * - 每种音乐模式有独特的颜色主题
   * - 氛围灯带使用动态颜色主题，其他设备使用固定颜色
   * 
   * 参数说明：
   * - beatIntensity: number - 当前节拍强度（0-1）
   * - isAmbientLight: boolean - 是否为氛围灯带
   * 
   * 返回值：
   * - RGBColor - 基于节拍的颜色对象
   */
  private static getBeatBasedColor(beatIntensity: number, isAmbientLight: boolean = false): RGBColor {
    if (isAmbientLight) {
      // 氛围灯带使用动态颜色主题
      return EasterEggController.getAmbientLightColor(beatIntensity);
    } else {
      // 其他设备使用音乐模式的基础颜色
      const currentPattern = EasterEggController.beatPatterns[EasterEggController.currentBeatMode];
      const baseColor = currentPattern.color;
      
      // 根据节拍强度调整颜色饱和度
      const intensityMultiplier = 0.5 + (beatIntensity * 0.5);
      
      return {
        r: Math.floor(baseColor.r * intensityMultiplier),
        g: Math.floor(baseColor.g * intensityMultiplier),
        b: Math.floor(baseColor.b * intensityMultiplier)
      };
    }
  }
  
  /**
   * 获取氛围灯带的动态颜色
   * 
   * 功能说明：
   * - 为氛围灯带提供丰富的颜色变化效果
   * - 根据节拍强度和音乐模式选择颜色主题
   * - 支持颜色渐变和主题切换
   * - 强拍时切换颜色，弱拍时保持当前颜色
   * 
   * 参数说明：
   * - beatIntensity: number - 当前节拍强度（0-1）
   * 
   * 返回值：
   * - RGBColor - 氛围灯带的颜色对象
   */
  private static getAmbientLightColor(beatIntensity: number): RGBColor {
    const currentPattern = EasterEggController.beatPatterns[EasterEggController.currentBeatMode];
    
    // 根据音乐模式选择颜色主题
    let themeIndex: number;
    switch (EasterEggController.currentBeatMode) {
      case MusicBeatMode.SLOW_BALLAD:
        themeIndex = 1; // 温暖色调
        break;
      case MusicBeatMode.MODERATE_POP:
        themeIndex = 2; // 冷色调
        break;
      case MusicBeatMode.FAST_DANCE:
        themeIndex = 3; // 活力色彩
        break;
      default:
        themeIndex = 0; // 彩虹渐变
        break;
    }
    
    const colorTheme = EasterEggController.ambientLightColorThemes[themeIndex];
    
    // 强拍时（强度>0.7）切换颜色
    if (beatIntensity > 0.7) {
      EasterEggController.currentColorIndex = (EasterEggController.currentColorIndex + 1) % colorTheme.length;
      
      // 每完成一轮颜色循环，切换到下一个主题
      if (EasterEggController.currentColorIndex === 0) {
        EasterEggController.currentColorThemeIndex = (EasterEggController.currentColorThemeIndex + 1) % EasterEggController.ambientLightColorThemes.length;
      }
    }
    
    // 获取当前颜色
    const currentColor = colorTheme[EasterEggController.currentColorIndex];
    
    // 根据节拍强度调整颜色亮度
    const brightnessMultiplier = 0.3 + (beatIntensity * 0.7);
    
    return {
      r: Math.floor(currentColor.r * brightnessMultiplier),
      g: Math.floor(currentColor.g * brightnessMultiplier),
      b: Math.floor(currentColor.b * brightnessMultiplier)
    };
  }
  
  /**
   * 根据节拍强度决定设备状态
   * 
   * 功能说明：
   * - 根据节拍强度决定设备是否开启
   * - 强拍时设备开启，弱拍时可能关闭
   * - 创造更有节奏感的开关效果
   * 
   * 参数说明：
   * - beatIntensity: number - 当前节拍强度（0-1）
   * 
   * 返回值：
   * - string - '0'表示开启，'1'表示关闭
   */
  private static getBeatBasedState(beatIntensity: number): string {
    // 强拍时（强度>0.7）100%开启，中等节拍时80%开启，弱拍时60%开启
    const openProbability = 0.6 + (beatIntensity * 0.4);
    return Math.random() < openProbability ? '0' : '1';
  }

  // ==================== 请求队列管理方法 ====================
  
  /**
   * 添加请求到队列并等待执行
   * 
   * 功能说明：
   * - 将设备控制请求添加到队列中
   * - 控制并发请求数量，避免设备过载
   * - 在请求之间添加延迟，减少设备压力
   * 
   * 参数说明：
   * - requestPromise: Promise<void> - 设备控制请求的Promise
   */
  private static async addToRequestQueue(requestPromise: Promise<void>): Promise<void> {
    // 如果队列已满，等待一个请求完成
    if (EasterEggController.requestQueue.length >= EasterEggController.MAX_CONCURRENT_REQUESTS) {
      await Promise.race(EasterEggController.requestQueue);
    }
    
    // 添加请求到队列
    EasterEggController.requestQueue.push(requestPromise);
    
    // 请求完成后从队列中移除
    requestPromise.finally(() => {
      const index = EasterEggController.requestQueue.indexOf(requestPromise);
      if (index > -1) {
        EasterEggController.requestQueue.splice(index, 1);
      }
    });
    
    // 添加请求间隔延迟
    await new Promise<void>(resolve => setTimeout(resolve, EasterEggController.REQUEST_INTERVAL));
  }
  
  /**
   * 清空请求队列
   * 
   * 功能说明：
   * - 清空所有待处理的请求
   * - 用于快速停止节拍时清理队列
   */
  private static clearRequestQueue(): void {
    EasterEggController.requestQueue = [];
    console.log('音乐节拍 - 请求队列已清空');
  }
  
  /**
   * 重置颜色状态
   * 
   * 功能说明：
   * - 重置颜色主题和颜色索引
   * - 用于停止节拍时重置颜色状态
   * - 确保下次启动时颜色从主题开始
   */
  private static resetColorState(): void {
    EasterEggController.currentColorThemeIndex = 0;
    EasterEggController.currentColorIndex = 0;
    console.log('音乐节拍 - 颜色状态已重置');
  }

  // ==================== 设备控制方法 ====================
  
  /**
   * 应用节拍参数到设备
   * 
   * 功能说明：
   * - 为指定设备生成基于节拍的参数
   * - 根据设备类型和节拍强度应用不同的控制参数
   * - 支持RGB颜色控制（仅氛围灯带）
   * - 使用请求队列管理，避免设备过载
   * 
   * 参数说明：
   * - device: DeviceControlItem - 要控制的设备
   * - beatIntensity: number - 当前节拍强度（0-1）
   * 
   * 设备类型处理：
   * - inSona_group: 仅控制开关状态
   * - LIGHT_GROUP: 控制亮度、色温，氛围灯带额外控制颜色
   */
  private static async applyBeatParamsToDevice(device: DeviceControlItem, beatIntensity: number): Promise<void> {
    try {
      // 检查是否还在节拍状态，如果已停止则直接返回
      if (!EasterEggController.isFlashing) {
        console.log(`音乐节拍 - 设备 ${device.name} 节拍已停止，跳过控制`);
        return;
      }
      
      const currentPattern = EasterEggController.beatPatterns[EasterEggController.currentBeatMode];
      
      // 生成基于节拍的参数
      const beatBrightness = EasterEggController.getBeatBasedBrightness(beatIntensity, currentPattern.intensity);
      const beatColorTemp = EasterEggController.getBeatBasedColorTemperature(beatIntensity);
      const beatState = EasterEggController.getBeatBasedState(beatIntensity);
      
      // 检查是否为氛围灯带，使用不同的颜色生成逻辑
      const isAmbientLight = device.control_sub_id === '6b3f2977496844fd879845645099c5dd';
      const beatColor = EasterEggController.getBeatBasedColor(beatIntensity, isAmbientLight);
      
      // 创建设备控制请求Promise
      let controlPromise: Promise<void>;
      
      // 根据设备类型应用不同的控制策略
      if (device.type_uuid === 'inSona_group') {
        // 对于inSona_group类型设备，仅控制开关状态
        controlPromise = EasterEggController.httpUtil.setDeviceStateOnly(
          EasterEggController.API_URL,
          beatState,
          device.control_sub_id
        );
      } else if (device.type_uuid === 'LIGHT_GROUP') {
        // 检查是否为氛围灯带（支持颜色控制）
        const isAmbientLight = device.control_sub_id === '6b3f2977496844fd879845645099c5dd';
        const isLightGroup = device.control_sub_id === 'a22b228be3b540638a3af2350982549b';
        
        if (isAmbientLight || isLightGroup) {
          // 氛围灯带和灯带灯组：控制颜色、亮度、色温
          controlPromise = EasterEggController.httpUtil.setLightColorBrightness(
            EasterEggController.API_URL,
            beatBrightness,
            beatColorTemp,
            beatState,
            beatColor.r,
            beatColor.g,
            beatColor.b,
            device.control_sub_id
          );
        } else {
          // 其他LIGHT_GROUP设备：仅控制亮度、色温
          controlPromise = EasterEggController.httpUtil.setLightBrightness(
            EasterEggController.API_URL,
            beatBrightness,
            beatColorTemp,
            beatState,
            device.control_sub_id
          );
        }
      } else {
        // 未知设备类型，直接返回
        return;
      }
      
      // 将请求添加到队列中管理
      await EasterEggController.addToRequestQueue(controlPromise);
      
      if (isAmbientLight) {
        console.log(`音乐节拍 - 氛围灯带 应用节拍参数: 强度=${beatIntensity.toFixed(2)}, 亮度=${beatBrightness}, 色温=${beatColorTemp}, 状态=${beatState}, 颜色=RGB(${beatColor.r},${beatColor.g},${beatColor.b})`);
      } else {
        console.log(`音乐节拍 - 设备 ${device.name} 应用节拍参数: 强度=${beatIntensity.toFixed(2)}, 亮度=${beatBrightness}, 色温=${beatColorTemp}, 状态=${beatState}`);
      }
    } catch (error) {
      console.error(`音乐节拍 - 设备 ${device.name} 控制失败:`, error);
    }
  }
  
  /**
   * 执行一轮节拍跟随
   * 
   * 功能说明：
   * - 对所有彩蛋场景设备应用节拍参数
   * - 串行控制设备，避免设备过载
   * - 异常处理确保单个设备失败不影响其他设备
   * - 检查节拍状态，如果已停止则中断执行
   * 
   * 参数说明：
   * - devices: DeviceControlItem[] - 要控制的设备列表
   * - beatIntensity: number - 当前节拍强度（0-1）
   */
  private static async executeBeatFlash(devices: DeviceControlItem[], beatIntensity: number): Promise<void> {
    try {
      // 检查是否还在节拍状态
      if (!EasterEggController.isFlashing) {
        console.log('音乐节拍 - 节拍已停止，跳过设备控制');
        return;
      }
      
      console.log(`音乐节拍 - 开始执行节拍跟随，设备数量: ${devices.length}, 节拍强度: ${beatIntensity.toFixed(2)}`);
      
      // 串行控制设备，避免设备过载
      for (const device of devices) {
        // 每次控制前检查节拍状态
        if (!EasterEggController.isFlashing) {
          console.log('音乐节拍 - 节拍已停止，中断设备控制');
          break;
        }
        
        // 控制单个设备
        await EasterEggController.applyBeatParamsToDevice(device, beatIntensity);
      }
      
      console.log(`音乐节拍 - 完成一轮节拍跟随，控制设备数量: ${devices.length}, 节拍强度: ${beatIntensity.toFixed(2)}`);
    } catch (error) {
      console.error('音乐节拍 - 执行节拍跟随失败:', error);
    }
  }

  // ==================== 音乐节拍控制方法 ====================
  
  /**
   * 开始音乐节拍跟随
   * 
   * 功能说明：
   * - 启动音乐节拍跟随模式
   * - 使用定时器持续执行节拍跟随
   * - 支持多种音乐节拍模式
   * 
   * 节拍逻辑：
   * - 根据BPM计算节拍间隔
   * - 按照节拍模式执行强弱拍
   * - 对设备应用基于节拍强度的参数
   * 
   * 异常处理：
   * - 捕获定时器创建异常
   * - 记录错误日志
   */
  static startEasterEggFlash(): void {
    try {
      // 如果已经在闪烁，先停止
      if (EasterEggController.isFlashing) {
        EasterEggController.stopEasterEggFlash();
        return;
      }
      
      const currentPattern = EasterEggController.beatPatterns[EasterEggController.currentBeatMode];
      console.log(`音乐节拍 - 开始${currentPattern.name}模式 (${currentPattern.bpm} BPM)`);
      
      EasterEggController.isFlashing = true;
      EasterEggController.currentBeatIndex = 0;
      EasterEggController.beatExecutionCounter = 0;
      
      // 根据BPM计算节拍间隔（毫秒），并应用倍数降低请求频率
      const baseBeatInterval = 60000 / currentPattern.bpm; // 60秒 / BPM = 每拍间隔
      const beatInterval = baseBeatInterval * EasterEggController.BEAT_INTERVAL_MULTIPLIER;
      
      // 创建定时器，按照BPM执行节拍
      EasterEggController.beatTimer = setInterval(async () => {
        try {
          // 检查是否还在节拍状态，如果已停止则直接返回
          if (!EasterEggController.isFlashing) {
            console.log('音乐节拍 - 检测到停止状态，定时器即将退出');
            return;
          }
          
          // 增加节拍执行计数器
          EasterEggController.beatExecutionCounter++;
          
          // 检查是否需要跳过本次节拍执行（降低请求频率）
          if (EasterEggController.beatExecutionCounter % EasterEggController.BEAT_SKIP_INTERVAL !== 0) {
            console.log(`音乐节拍 - 跳过本次节拍执行 (计数器: ${EasterEggController.beatExecutionCounter})`);
            // 更新节拍索引，但不执行设备控制
            EasterEggController.currentBeatIndex = (EasterEggController.currentBeatIndex + 1) % currentPattern.pattern.length;
            return;
          }
          
          // 获取当前节拍强度
          const currentBeatValue = currentPattern.pattern[EasterEggController.currentBeatIndex];
          const beatIntensity = currentBeatValue; // 0或1，直接作为强度
          
          // 随机选择场景（1-3）
          const randomScene = Math.floor(Math.random() * 3) + 1;
          let selectedDevices: DeviceControlItem[] = [];
          
          // 根据随机数选择对应的场景设备
          switch (randomScene) {
            case 1:
              selectedDevices = easterEgg1;
              break;
            case 2:
              selectedDevices = easterEgg2;
              break;
            case 3:
              selectedDevices = easterEgg3;
              break;
            default:
              selectedDevices = easterEgg1;
          }
          
          // 再次检查状态，防止在异步操作期间状态发生变化
          if (!EasterEggController.isFlashing) {
            console.log('音乐节拍 - 执行前检测到停止状态，取消本次节拍');
            return;
          }
          
          console.log(`音乐节拍 - 执行节拍控制 (计数器: ${EasterEggController.beatExecutionCounter}, 间隔: ${EasterEggController.BEAT_SKIP_INTERVAL})`);
          
          // 执行节拍跟随
          await EasterEggController.executeBeatFlash(selectedDevices, beatIntensity);
          
          // 更新节拍索引，循环播放
          EasterEggController.currentBeatIndex = (EasterEggController.currentBeatIndex + 1) % currentPattern.pattern.length;
          
        } catch (error) {
          console.error('音乐节拍 - 定时器执行失败:', error);
        }
      }, beatInterval);
      
    } catch (error) {
      console.error('音乐节拍 - 启动失败:', error);
      EasterEggController.isFlashing = false;
    }
  }
  
  /**
   * 停止音乐节拍跟随
   * 
   * 功能说明：
   * - 停止音乐节拍跟随模式
   * - 清除定时器和请求队列
   * - 重置闪烁状态
   * - 停止后全部开灯
   * 
   * 清理逻辑：
   * - 立即设置停止状态
   * - 清除定时器
   * - 清空请求队列
   * - 执行全部开灯操作
   * - 记录停止日志
   */
  static async stopEasterEggFlash(): Promise<void> {
    try {
      console.log('音乐节拍 - 开始停止节拍跟随模式');
      
      // 立即设置停止状态，防止定时器继续执行
      EasterEggController.isFlashing = false;
      
      // 清除定时器
      if (EasterEggController.beatTimer) {
        clearInterval(EasterEggController.beatTimer);
        EasterEggController.beatTimer = null;
        console.log('音乐节拍 - 定时器已清除');
      }
      
      // 清空请求队列，避免继续发送请求
      EasterEggController.clearRequestQueue();
      
      // 重置颜色状态
      EasterEggController.resetColorState();
      
      // 等待一小段时间，让正在处理的请求完成
      await new Promise<void>(resolve => setTimeout(resolve, 500));
      
      // 停止后全部开灯
      await EasterEggController.turnOnAllLights();
      
      console.log('音乐节拍 - 已停止节拍跟随模式，所有灯光已开启');
      
    } catch (error) {
      console.error('音乐节拍 - 停止失败:', error);
    }
  }
  
  /**
   * 切换彩蛋闪烁状态
   * 
   * 功能说明：
   * - 切换彩蛋闪烁的开启/关闭状态
   * - 如果正在闪烁则停止，如果已停止则开始
   * 
   * 返回值：
   * - boolean - 切换后的闪烁状态（true=正在闪烁，false=已停止）
   */
  static async toggleEasterEggFlash(): Promise<boolean> {
    if (EasterEggController.isFlashing) {
      await EasterEggController.stopEasterEggFlash();
      return false;
    } else {
      EasterEggController.startEasterEggFlash();
      return true;
    }
  }
  
  /**
   * 获取当前闪烁状态
   * 
   * 功能说明：
   * - 返回当前彩蛋闪烁的状态
   * - 用于UI显示和状态判断
   * 
   * 返回值：
   * - boolean - true表示正在闪烁，false表示已停止
   */
  static getFlashStatus(): boolean {
    return EasterEggController.isFlashing;
  }
  
  /**
   * 全部开灯
   * 
   * 功能说明：
   * - 停止彩蛋后，将所有灯光设备开启
   * - 使用合理的亮度、色温和颜色参数
   * - 确保所有设备都处于开启状态
   * 
   * 开灯参数：
   * - 亮度：80%（适中的亮度）
   * - 色温：60%（偏暖的色温）
   * - 颜色：白色（RGB: 255, 255, 255）
   * - 状态：开启（'0'）
   */
  private static async turnOnAllLights(): Promise<void> {
    try {
      console.log('彩蛋闪烁 - 开始全部开灯操作');
      
      // 定义全部开灯的设备配置
      const allLightsOn: DeviceControlItem[] = [

        {
          control_sub_id: "c9b6bf04da8c453ba5b37f7bd1bc8db9",
          control_sub_state: '0', // 开启
          name: '教学区射灯1',
          w_channel: 80,          // 亮度80%
          y_channel: 60,          // 色温60%
          type_uuid: 'LIGHT_GROUP'
        },
        {
          control_sub_id: "b4e3359c8c3c420faa81e2b0c7aed1e0",
          control_sub_state: '0', // 开启
          name: '教学区线型灯带1',
          w_channel: 80,          // 亮度80%
          y_channel: 60,          // 色温60%
          type_uuid: 'LIGHT_GROUP'
        },
        

        {
          control_sub_id: "ed6839e106ae49cdb84d4b920772abd4",
          control_sub_state: '0', // 开启
          name: '实操区射灯灯组 1',
          w_channel: 80,          // 亮度80%
          y_channel: 60,          // 色温60%
          type_uuid: 'LIGHT_GROUP'
        },

        {
          control_sub_id: "420dece3d98e41e8b4bac04cc825d6b2",
          control_sub_state: '0', // 开启
          name: '实操区环形灯带1',
          w_channel: 80,          // 亮度80%
          y_channel: 60,          // 色温60%
          type_uuid: 'LIGHT_GROUP'
        },
        {
          control_sub_id: "60e5b7d5b4034d09a59bbfcc4cf5b363",
          control_sub_state: '0', // 开启
          name: '实操区线形灯带1',
          w_channel: 80,          // 亮度80%
          y_channel: 60,          // 色温60%
          type_uuid: 'LIGHT_GROUP'
        },
        
        // 氛围灯带
        {
          control_sub_id: "6b3f2977496844fd879845645099c5dd",
          control_sub_state: '0', // 开启
          name: '氛围灯带',
          w_channel: 80,          // 亮度80%
          y_channel: 60,          // 色温60%
          r_channel: 255,         // 白色
          g_channel: 255,         // 白色
          b_channel: 255,         // 白色
          type_uuid: 'LIGHT_GROUP'
        },
        // 设备24 教学区灯
        {
          control_sub_id: "8d623ab85ad9439f8910738bc48d51c8",
          control_sub_state: '1', // 关闭
          name: '教学区灯',
          type_uuid: 'inSona_group'
        },
        // 设备26 - 实操区灯
        {
          control_sub_id: "ad99035d023e4017bc4b546a4a170f14",
          control_sub_state: '1', // 关闭
          name: '实操区灯',
          type_uuid: 'inSona_group'
        },

        // 设备26 - 通道平板灯
        {
          control_sub_id: "b39ef83110374aada64d8dc1b99b6c68",
          control_sub_state: '1', // 关闭
          name: '通道平板灯',
          type_uuid: 'inSona_group'
        }
      ];
      
      // 并行控制所有设备开灯
      const controlPromises = allLightsOn.map(device => 
        EasterEggController.applyParamsToDevice(device)
      );
      
      // 等待所有设备控制完成
      await Promise.allSettled(controlPromises);
      
      console.log('彩蛋闪烁 - 全部开灯操作完成');
      
    } catch (error) {
      console.error('彩蛋闪烁 - 全部开灯失败:', error);
    }
  }
  
  /**
   * 应用参数到设备（用于全部开灯）
   * 
   * 功能说明：
   * - 为指定设备应用固定参数
   * - 根据设备类型应用不同的控制参数
   * - 支持RGB颜色控制（仅氛围灯带）
   * 
   * 参数说明：
   * - device: DeviceControlItem - 要控制的设备
   */
  private static async applyParamsToDevice(device: DeviceControlItem): Promise<void> {
    try {
      // 根据设备类型应用不同的控制策略
      if (device.type_uuid === 'inSona_group') {
        // 对于·类型设备，仅控制开关状态
        await EasterEggController.httpUtil.setDeviceStateOnly(
          EasterEggController.API_URL,
          device.control_sub_state,
          device.control_sub_id
        );
      } else if (device.type_uuid === 'LIGHT_GROUP') {
        // 检查是否为氛围灯带（支持颜色控制）
        const isAmbientLight = device.control_sub_id === '6b3f2977496844fd879845645099c5dd';
        const isLightGroup = device.control_sub_id === 'a22b228be3b540638a3af2350982549b';
        
        if (isAmbientLight || isLightGroup) {
          // 氛围灯带和灯带灯组：控制颜色、亮度、色温
          await EasterEggController.httpUtil.setLightColorBrightness(
            EasterEggController.API_URL,
            device.w_channel || 80,
            device.y_channel || 60,
            device.control_sub_state,
            device.r_channel || 255,
            device.g_channel || 255,
            device.b_channel || 255,
            device.control_sub_id
          );
        } else {
          // 其他LIGHT_GROUP设备：仅控制亮度、色温
          await EasterEggController.httpUtil.setLightBrightness(
            EasterEggController.API_URL,
            device.w_channel || 80,
            device.y_channel || 60,
            device.control_sub_state,
            device.control_sub_id
          );
        }
      }
      
      console.log(`彩蛋闪烁 - 设备 ${device.name} 已开启`);
    } catch (error) {
      console.error(`彩蛋闪烁 - 设备 ${device.name} 开启失败:`, error);
    }
  }

  /**
   * 设置音乐节拍模式
   * 
   * 功能说明：
   * - 切换不同的音乐节拍模式
   * - 每种模式有不同的BPM和节拍模式
   * - 如果正在播放，会重启以应用新模式
   * 
   * 参数说明：
   * - mode: MusicBeatMode - 音乐节拍模式
   * 
   * 支持的模式：
   * - SLOW_BALLAD: 慢板抒情（60 BPM）
   * - MODERATE_POP: 中等流行（120 BPM）
   * - FAST_DANCE: 快节奏舞曲（140 BPM）
   */
  static setBeatMode(mode: MusicBeatMode): void {
    if (mode < 0 || mode >= EasterEggController.beatPatterns.length) {
      console.warn('音乐节拍 - 无效的节拍模式');
      return;
    }
    
    const wasFlashing = EasterEggController.isFlashing;
    
    if (wasFlashing) {
      EasterEggController.stopEasterEggFlash();
    }
    
    EasterEggController.currentBeatMode = mode;
    const pattern = EasterEggController.beatPatterns[mode];
    console.log(`音乐节拍 - 切换到${pattern.name}模式 (${pattern.bpm} BPM)`);
    
    if (wasFlashing) {
      EasterEggController.startEasterEggFlash();
    }
  }
  
  /**
   * 获取当前音乐节拍模式
   * 
   * 功能说明：
   * - 返回当前选择的音乐节拍模式
   * - 用于UI显示和状态判断
   * 
   * 返回值：
   * - MusicBeatMode - 当前音乐节拍模式
   */
  static getCurrentBeatMode(): MusicBeatMode {
    return EasterEggController.currentBeatMode;
  }
  
  /**
   * 获取当前节拍模式信息
   * 
   * 功能说明：
   * - 返回当前节拍模式的详细信息
   * - 包含名称、BPM、强度等信息
   * 
   * 返回值：
   * - BeatPattern - 当前节拍模式信息
   */
  static getCurrentBeatPattern(): BeatPattern {
    return EasterEggController.beatPatterns[EasterEggController.currentBeatMode];
  }
  
  /**
   * 获取所有可用的节拍模式
   * 
   * 功能说明：
   * - 返回所有预定义的节拍模式
   * - 用于UI显示和选择
   * 
   * 返回值：
   * - BeatPattern[] - 所有节拍模式数组
   */
  static getAllBeatPatterns(): BeatPattern[] {
    return EasterEggController.beatPatterns;
  }
}

// ==================== 彩蛋场景配置 ====================

export const easterEgg1: DeviceControlItem[] = [

  // 设备24 - 教学区射灯1（全部小灯）
  {
    control_sub_id: "c9b6bf04da8c453ba5b37f7bd1bc8db9",
    control_sub_state: '0', // 关闭
    name: '教学区射灯1',
    w_channel: 96,          // 亮度值66%
    y_channel: 66,          // 色温值66%
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备25 - 教学区线型灯带1（全部灯管）
  {
    control_sub_id: "b4e3359c8c3c420faa81e2b0c7aed1e0",
    control_sub_state: '0', // 关闭
    name: '教学区线型灯带1',
    w_channel: 96,          // 亮度值66%
    y_channel: 66,          // 色温值66%
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备2 - 氛围灯带
  {
    control_sub_id: "6b3f2977496844fd879845645099c5dd",
    control_sub_state: '0', // 关闭
    name: '氛围灯带',
    w_channel: 96,          // 亮度值66%
    y_channel: 96,          // 色温值66%
    r_channel: 128,         // 红色通道255
    g_channel: 0,         // 绿色通道255
    b_channel: 0,         // 蓝色通道255
    type_uuid: 'LIGHT_GROUP'
  },

  // 设备1 - 实操区射灯灯组1（控制全部小灯）
  {
    control_sub_id: "ed6839e106ae49cdb84d4b920772abd4",
    control_sub_state: '0', // 关闭
    name: '实操区射灯灯组 1',
    w_channel: 96,          // 亮度值66%
    y_channel: 96,          // 色温值66%
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备23 - 实操区线形灯带1（只有灯管）
  {
    control_sub_id: "60e5b7d5b4034d09a59bbfcc4cf5b363",
    control_sub_state: '0', // 打开
    name: '实操区线形灯带1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  }
]

export const easterEgg2: DeviceControlItem[] = [
  // 设备24 - 教学区射灯1（全部小灯）
  {
    control_sub_id: "c9b6bf04da8c453ba5b37f7bd1bc8db9",
    control_sub_state: '0', // 关闭
    name: '教学区射灯1',
    w_channel: 40,          // 亮度值66%
    y_channel: 30,          // 色温值66%
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备25 - 教学区线型灯带1（全部灯管）
  {
    control_sub_id: "b4e3359c8c3c420faa81e2b0c7aed1e0",
    control_sub_state: '1', // 关闭
    name: '教学区线型灯带1',
    w_channel: 40,          // 亮度值66%
    y_channel: 30,          // 色温值66%
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备2 - 氛围灯带
  {
    control_sub_id: "6b3f2977496844fd879845645099c5dd",
    control_sub_state: '0', // 关闭
    name: '氛围灯带',
    w_channel: 96,          // 亮度值66%
    y_channel: 50,          // 色温值66%
    r_channel: 128,         // 红色通道255
    g_channel: 0,         // 绿色通道255
    b_channel: 0,         // 蓝色通道255
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备21 - 实操区环形灯带1
  {
    control_sub_id: "420dece3d98e41e8b4bac04cc825d6b2",
    control_sub_state: '0', // 打开
    name: '实操区环形灯带1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备23 - 实操区线形灯带1（只有灯管）
  {
    control_sub_id: "60e5b7d5b4034d09a59bbfcc4cf5b363",
    control_sub_state: '0', // 打开
    name: '实操区线形灯带1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备1 - 实操区射灯灯组1（控制全部小灯）
  {
    control_sub_id: "ed6839e106ae49cdb84d4b920772abd4",
    control_sub_state: '0', // 关闭
    name: '实操区射灯灯组 1',
    w_channel: 40,          // 亮度值66%
    y_channel: 30,          // 色温值66%
    type_uuid: 'LIGHT_GROUP'
  },
// 设备21 - 实操区环形灯带1
{
  control_sub_id: "420dece3d98e41e8b4bac04cc825d6b2",
  control_sub_state: '0', // 打开
name: '实操区环形灯带1',
w_channel: 66,          // 亮度值
y_channel: 66,          // 色温值
type_uuid: 'LIGHT_GROUP'
},
  // 设备23 - 实操区线形灯带1（只有灯管）
  {
    control_sub_id: "60e5b7d5b4034d09a59bbfcc4cf5b363",
    control_sub_state: '0', // 打开
    name: '实操区线形灯带1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  }
]


export const easterEgg3: DeviceControlItem[] = [
  // 设备24 - 教学区射灯1（全部小灯）
  {
    control_sub_id: "c9b6bf04da8c453ba5b37f7bd1bc8db9",
    control_sub_state: '0', // 关闭
    name: '教学区射灯1',
    w_channel: 40,          // 亮度值66%
    y_channel: 30,          // 色温值66%
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备25 - 教学区线型灯带1（全部灯管）
  {
    control_sub_id: "b4e3359c8c3c420faa81e2b0c7aed1e0",
    control_sub_state: '0', // 关闭
    name: '教学区线型灯带1',
    w_channel: 40,          // 亮度值66%
    y_channel: 30,          // 色温值66%
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备2 - 氛围灯带
  {
    control_sub_id: "6b3f2977496844fd879845645099c5dd",
    control_sub_state: '0', // 关闭
    name: '氛围灯带',
    w_channel: 96,          // 亮度值66%
    y_channel: 50,          // 色温值66%
    r_channel: 128,         // 红色通道255
    g_channel: 0,         // 绿色通道255
    b_channel: 0,         // 蓝色通道255
    type_uuid: 'LIGHT_GROUP'
  },

  // 设备1 - 实操区射灯灯组1（控制全部小灯）
  {
    control_sub_id: "ed6839e106ae49cdb84d4b920772abd4",
    control_sub_state: '0', // 关闭
    name: '实操区射灯灯组 1',
    w_channel: 40,          // 亮度值66%
    y_channel: 30,          // 色温值66%
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备21 - 实操区环形灯带1
  {
    control_sub_id: "420dece3d98e41e8b4bac04cc825d6b2",
    control_sub_state: '0', // 打开
    name: '实操区环形灯带1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备23 - 实操区线形灯带1（只有灯管）
  {
    control_sub_id: "60e5b7d5b4034d09a59bbfcc4cf5b363",
    control_sub_state: '0', // 打开
    name: '实操区线形灯带1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  }
]

