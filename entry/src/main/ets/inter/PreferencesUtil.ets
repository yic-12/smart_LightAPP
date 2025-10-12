/**
 * 智能照明管理APP - 偏好设置工具类 (PreferencesUtil.ets)
 * 
 * 功能说明：
 * 1. 提供应用设置的持久化存储功能
 * 2. 管理设备亮度、色温等设置
 * 3. 管理自动调节功能的开关状态
 * 4. 管理定时任务列表的存储和加载
 * 5. 提供设置数据的增删改查功能
 * 
 * 技术特点：
 * - 使用HarmonyOS preferences数据持久化框架
 * - 支持同步和异步操作
 * - 异常处理和错误恢复
 * - 类型安全的数据接口
 * - 静态方法设计，便于调用
 */

// 导入HarmonyOS数据持久化模块
import { preferences } from '@kit.ArkData';
// 导入HarmonyOS应用上下文模块
import { Context } from '@kit.AbilityKit';
// 导入定时任务接口
import { TimerItem } from './Interface1';

// ==================== 数据接口定义 ====================

/**
 * DeviceSettings - 设备设置接口
 * 
 * 功能说明：
 * - 定义设备相关的设置数据结构
 * - 包含亮度、色温和自动调节状态
 * - 用于设置数据的持久化存储
 * 
 * 字段说明：
 * - brightness: 设备亮度值（0-100）
 * - colorTemperature: 设备色温值（0-100）
 * - autoAdjustEnabled: 自动调节功能开关状态，可选参数
 */
export interface DeviceSettings {
  brightness: number;           // 设备亮度值（0-100）
  colorTemperature: number;     // 设备色温值（0-100）
  autoAdjustEnabled?: boolean; // 自动调节开关状态
}

// ==================== 工具类定义 ====================

/**
 * PreferencesUtil - 偏好设置工具类
 * 
 * 功能说明：
 * - 提供应用设置的持久化存储功能
 * - 管理设备设置和定时任务数据
 * - 支持设置数据的加载、保存和清理
 * - 提供异常处理和错误恢复机制
 * 
 * 设计特点：
 * - 静态方法设计，无需实例化
 * - 使用HarmonyOS preferences框架
 * - 支持同步操作，性能稳定
 * - 异常处理机制，确保数据安全
 */
export class PreferencesUtil {
  
  // ==================== 常量定义 ====================
  
  /**
   * 设备设置存储名称
   * 用于区分不同的数据存储空间
   */
  private static readonly STORE_NAME: string = 'device_settings_store';
  
  /**
   * 定时任务存储名称
   * 用于存储定时任务列表数据
   */
  private static readonly TIMER_STORE_NAME: string = 'timer_tasks_store';
  
  /**
   * 亮度设置键名
   * 用于存储和读取亮度值
   */
  private static readonly KEY_BRIGHTNESS: string = 'brightness';
  
  /**
   * 色温设置键名
   * 用于存储和读取色温值
   */
  private static readonly KEY_COLOR_TEMPERATURE: string = 'color_temperature';
  
  /**
   * 自动调节开关键名
   * 用于存储和读取自动调节功能状态
   */
  private static readonly KEY_AUTO_ADJUST_ENABLED: string = 'auto_adjust_enabled';
  
  /**
   * 定时任务列表键名
   * 用于存储和读取定时任务列表
   */
  private static readonly KEY_TIMER_LIST: string = 'timer_list';

  // ==================== 设备设置管理 ====================
  
  /**
   * 加载设备设置
   * 
   * 功能说明：
   * - 从持久化存储中加载设备设置
   * - 提供默认值，确保数据完整性
   * - 异常处理，返回默认设置
   * 
   * 参数说明：
   * - appContext: Context - 应用上下文，用于访问preferences
   * 
   * 返回值：
   * - DeviceSettings - 设备设置对象
   * 
   * 异常处理：
   * - 捕获加载过程中的异常
   * - 记录错误日志
   * - 返回默认设置值
   * 
   * 默认值：
   * - 亮度：50
   * - 色温：50
   * - 自动调节：false
   */
  static loadSettings(appContext: Context): DeviceSettings {
    try {
      // 创建preferences选项
      const options: preferences.Options = { name: PreferencesUtil.STORE_NAME };
      
      // 获取preferences存储实例
      const store = preferences.getPreferencesSync(appContext, options);
      
      // 加载各项设置，提供默认值
      const brightness = store.getSync(PreferencesUtil.KEY_BRIGHTNESS, 50) as number;
      const colorTemperature = store.getSync(PreferencesUtil.KEY_COLOR_TEMPERATURE, 50) as number;
      const autoAdjustEnabled = store.getSync(PreferencesUtil.KEY_AUTO_ADJUST_ENABLED, false) as boolean;
      
      // 返回加载的设置
      return { brightness, colorTemperature, autoAdjustEnabled };
    } catch (error) {
      console.error('加载设备设置失败:', error);
      // 返回默认设置
      return { brightness: 50, colorTemperature: 50, autoAdjustEnabled: false };
    }
  }

  /**
   * 保存设备设置
   * 
   * 功能说明：
   * - 将设备设置保存到持久化存储
   * - 支持部分字段更新
   * - 异常处理，确保数据安全
   * 
   * 参数说明：
   * - appContext: Context - 应用上下文，用于访问preferences
   * - settings: DeviceSettings - 要保存的设备设置
   * 
   * 保存逻辑：
   * - 保存亮度值
   * - 保存色温值
   * - 如果自动调节状态已定义，则保存
   * - 刷新存储，确保数据持久化
   * 
   * 异常处理：
   * - 捕获保存过程中的异常
   * - 记录错误日志
   * - 不抛出异常，确保应用稳定性
   */
  static saveSettings(appContext: Context, settings: DeviceSettings): void {
    try {
      // 创建preferences选项
      const options: preferences.Options = { name: PreferencesUtil.STORE_NAME };
      
      // 获取preferences存储实例
      const store = preferences.getPreferencesSync(appContext, options);
      
      // 保存各项设置
      store.putSync(PreferencesUtil.KEY_BRIGHTNESS, settings.brightness);
      store.putSync(PreferencesUtil.KEY_COLOR_TEMPERATURE, settings.colorTemperature);
      
      // 如果自动调节状态已定义，则保存
      if (settings.autoAdjustEnabled !== undefined) {
        store.putSync(PreferencesUtil.KEY_AUTO_ADJUST_ENABLED, settings.autoAdjustEnabled);
      }
      
      // 刷新存储，确保数据持久化
      store.flushSync();
    } catch (error) {
      console.error('保存设备设置失败:', error);
    }
  }

  // ==================== 定时任务管理 ====================
  
  /**
   * 保存定时任务列表
   * 
   * 功能说明：
   * - 将定时任务列表保存到持久化存储
   * - 使用JSON序列化存储复杂对象
   * - 异常处理，确保数据安全
   * 
   * 参数说明：
   * - appContext: Context - 应用上下文，用于访问preferences
   * - timerList: TimerItem[] - 要保存的定时任务列表
   * 
   * 存储方式：
   * - 将TimerItem数组序列化为JSON字符串
   * - 使用专门的定时任务存储空间
   * - 刷新存储，确保数据持久化
   * 
   * 异常处理：
   * - 捕获保存过程中的异常
   * - 记录错误日志
   * - 不抛出异常，确保应用稳定性
   */
  static saveTimerList(appContext: Context, timerList: TimerItem[]): void {
    try {
      // 创建定时任务存储选项
      const options: preferences.Options = { name: PreferencesUtil.TIMER_STORE_NAME };
      
      // 获取preferences存储实例
      const store = preferences.getPreferencesSync(appContext, options);
      
      // 将定时任务列表序列化为JSON字符串
      const timerListJson = JSON.stringify(timerList);
      
      // 保存定时任务列表
      store.putSync(PreferencesUtil.KEY_TIMER_LIST, timerListJson);
      
      // 刷新存储，确保数据持久化
      store.flushSync();
    } catch (error) {
      console.error('保存定时任务列表失败:', error);
    }
  }

  /**
   * 加载定时任务列表
   * 
   * 功能说明：
   * - 从持久化存储中加载定时任务列表
   * - 提供默认值，确保数据完整性
   * - 异常处理，返回空列表
   * 
   * 参数说明：
   * - appContext: Context - 应用上下文，用于访问preferences
   * 
   * 返回值：
   * - TimerItem[] - 定时任务列表
   * 
   * 加载逻辑：
   * - 从存储中读取JSON字符串
   * - 反序列化为TimerItem数组
   * - 提供默认空数组，确保返回有效数据
   * 
   * 异常处理：
   * - 捕获加载过程中的异常
   * - 记录错误日志
   * - 返回空数组，确保应用稳定性
   */
  static loadTimerList(appContext: Context): TimerItem[] {
    try {
      // 创建定时任务存储选项
      const options: preferences.Options = { name: PreferencesUtil.TIMER_STORE_NAME };
      
      // 获取preferences存储实例
      const store = preferences.getPreferencesSync(appContext, options);
      
      // 加载定时任务列表JSON字符串
      const timerListJson = store.getSync(PreferencesUtil.KEY_TIMER_LIST, '[]') as string;
      
      // 反序列化为TimerItem数组
      const timerList = JSON.parse(timerListJson) as TimerItem[];
      
      // 返回定时任务列表，确保不为null
      return timerList || [];
    } catch (error) {
      console.error('加载定时任务列表失败:', error);
      return [];
    }
  }

  /**
   * 清空定时任务列表
   * 
   * 功能说明：
   * - 清空持久化存储中的定时任务列表
   * - 释放存储空间
   * - 异常处理，确保操作安全
   * 
   * 参数说明：
   * - appContext: Context - 应用上下文，用于访问preferences
   * 
   * 清理逻辑：
   * - 删除定时任务列表键
   * - 刷新存储，确保操作生效
   * 
   * 异常处理：
   * - 捕获清理过程中的异常
   * - 记录错误日志
   * - 不抛出异常，确保应用稳定性
   */
  static clearTimerList(appContext: Context): void {
    try {
      // 创建定时任务存储选项
      const options: preferences.Options = { name: PreferencesUtil.TIMER_STORE_NAME };
      
      // 获取preferences存储实例
      const store = preferences.getPreferencesSync(appContext, options);
      
      // 删除定时任务列表键
      store.deleteSync(PreferencesUtil.KEY_TIMER_LIST);
      
      // 刷新存储，确保操作生效
      store.flushSync();
    } catch (error) {
      console.error('清空定时任务列表失败:', error);
    }
  }
}