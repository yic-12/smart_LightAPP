/**
 * 智能照明管理APP - 主入口能力 (EntryAbility.ets)
 * 
 * 功能说明：
 * 1. 应用程序的主入口点，负责应用的生命周期管理
 * 2. 管理应用窗口的创建和销毁
 * 3. 处理应用的前台和后台切换
 * 4. 提供全局应用上下文访问
 * 5. 加载主页面内容
 * 
 * 技术特点：
 * - 继承自HarmonyOS UIAbility基类
 * - 实现完整的应用生命周期回调
 * - 集成窗口管理和日志记录
 * - 提供静态应用上下文存储
 * - 支持异步内容加载
 */

// 导入HarmonyOS能力框架模块
import { AbilityConstant, Context, UIAbility, Want } from '@kit.AbilityKit';
// 导入HarmonyOS性能分析模块
import { hilog } from '@kit.PerformanceAnalysisKit';
// 导入HarmonyOS窗口管理模块
import { window } from '@kit.ArkUI';

// ==================== 常量定义 ====================

/**
 * 日志域常量
 * 
 * 功能说明：
 * - 定义日志输出的域标识符
 * - 用于区分不同模块的日志输出
 * - 便于日志过滤和调试
 */
const DOMAIN = 0x0000;

// ==================== 主入口能力类 ====================

/**
 * EntryAbility - 主入口能力类
 * 
 * 功能说明：
 * - 应用程序的主入口点
 * - 继承自HarmonyOS UIAbility基类
 * - 管理应用的生命周期和窗口状态
 * - 提供全局应用上下文访问
 * 
 * 生命周期管理：
 * - onCreate: 应用创建时调用
 * - onDestroy: 应用销毁时调用
 * - onWindowStageCreate: 窗口阶段创建时调用
 * - onWindowStageDestroy: 窗口阶段销毁时调用
 * - onForeground: 应用进入前台时调用
 * - onBackground: 应用进入后台时调用
 */
export default class EntryAbility extends UIAbility {
  
  // ==================== 静态属性 ====================
  
  /**
   * 静态应用上下文
   * 
   * 功能说明：
   * - 存储全局应用上下文
   * - 供其他模块访问应用上下文
   * - 避免重复获取上下文的开销
   * 
   * 使用场景：
   * - 数据持久化操作
   * - 系统服务调用
   * - 资源访问
   */
  static appContext: Context;

  // ==================== 生命周期方法 ====================
  
  /**
   * 应用创建回调
   * 
   * 功能说明：
   * - 应用首次创建时调用
   * - 初始化应用上下文
   * - 记录应用创建日志
   * 
   * 参数说明：
   * - _want: Want - 启动参数，未使用（下划线前缀表示未使用）
   * - _launchParam: AbilityConstant.LaunchParam - 启动参数，未使用
   * 
   * 执行逻辑：
   * - 保存应用上下文到静态变量
   * - 记录应用创建成功日志
   * 
   * 注意事项：
   * - 参数使用下划线前缀，避免ArkTS linter警告
   * - 应用上下文在后续操作中会被频繁使用
   */
  onCreate(_want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    // 保存应用上下文到静态变量，供其他模块使用
    EntryAbility.appContext = this.context;
    
    // 记录应用创建成功日志
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  /**
   * 应用销毁回调
   * 
   * 功能说明：
   * - 应用销毁时调用
   * - 清理应用资源
   * - 记录应用销毁日志
   * 
   * 执行逻辑：
   * - 记录应用销毁日志
   * - 系统会自动清理相关资源
   * 
   * 注意事项：
   * - 应用销毁是不可逆的过程
   * - 确保重要数据已保存
   */
  onDestroy(): void {
    // 记录应用销毁日志
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  /**
   * 窗口阶段创建回调
   * 
   * 功能说明：
   * - 主窗口创建时调用
   * - 加载应用主页面内容
   * - 处理内容加载错误
   * 
   * 参数说明：
   * - windowStage: window.WindowStage - 窗口阶段对象
   * 
   * 执行逻辑：
   * - 记录窗口创建日志
   * - 异步加载主页面内容
   * - 处理加载成功和失败情况
   * 
   * 错误处理：
   * - 捕获内容加载错误
   * - 记录错误日志
   * - 确保应用稳定性
   */
  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 主窗口已创建，为此能力设置主页面
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 异步加载主页面内容
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        // 内容加载失败，记录错误日志
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      // 内容加载成功，记录成功日志
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  /**
   * 窗口阶段销毁回调
   * 
   * 功能说明：
   * - 主窗口销毁时调用
   * - 释放UI相关资源
   * - 记录窗口销毁日志
   * 
   * 执行逻辑：
   * - 记录窗口销毁日志
   * - 系统会自动释放UI资源
   * 
   * 注意事项：
   * - 窗口销毁后，UI相关操作将不可用
   * - 确保重要数据已保存
   */
  onWindowStageDestroy(): void {
    // 主窗口已销毁，释放UI相关资源
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  /**
   * 应用进入前台回调
   * 
   * 功能说明：
   * - 应用从后台切换到前台时调用
   * - 恢复应用状态
   * - 记录前台切换日志
   * 
   * 执行逻辑：
   * - 记录应用进入前台日志
   * - 可以在此处恢复应用状态
   * 
   * 使用场景：
   * - 恢复网络连接
   * - 刷新数据
   * - 恢复UI状态
   */
  onForeground(): void {
    // 应用已进入前台
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  /**
   * 应用进入后台回调
   * 
   * 功能说明：
   * - 应用从前台切换到后台时调用
   * - 保存应用状态
   * - 记录后台切换日志
   * 
   * 执行逻辑：
   * - 记录应用进入后台日志
   * - 可以在此处保存应用状态
   * 
   * 使用场景：
   * - 保存用户数据
   * - 暂停网络请求
   * - 释放临时资源
   */
  onBackground(): void {
    // 应用已进入后台
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}