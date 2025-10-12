/**
 * 智能照明管理APP - 权限管理工具 (permissionMananger.ets)
 * 
 * 功能说明：
 * 1. 提供权限检查功能，检查应用是否已获得指定权限
 * 2. 提供权限请求功能，向用户请求授权指定权限
 * 3. 支持多种权限类型（如麦克风权限等）
 * 4. 异常处理和错误日志记录
 * 
 * 技术特点：
 * - 使用HarmonyOS权限管理API
 * - 支持同步和异步权限操作
 * - 异常安全处理
 * - 静态方法设计，便于调用
 */

// 导入必要的模块，包括权限管理相关的功能
import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';

/**
 * PermissionManager - 权限管理工具类
 * 
 * 功能说明：
 * - 提供权限检查和请求的静态方法
 * - 封装HarmonyOS权限管理API
 * - 提供统一的权限管理接口
 * 
 * 使用场景：
 * - 语音控制功能需要麦克风权限
 * - 网络访问权限检查
 * - 其他系统权限管理
 */
export class PermissionManager {
  
  // ==================== 权限检查方法 ====================
  
  /**
   * 检查权限是否已被授予
   * 
   * 功能说明：
   * - 检查给定的权限是否已经被授予
   * - 支持多个权限同时检查
   * - 返回布尔值表示权限状态
   * 
   * 参数说明：
   * - permissions: Permissions[] - 需要检查的权限数组
   * 
   * 返回值：
   * - boolean - true表示所有权限都已授予，false表示有权限未授予
   * 
   * 使用示例：
   * ```typescript
   * const permissions: Permissions[] = ["ohos.permission.MICROPHONE"]
   * const hasPermission = PermissionManager.checkPermission(permissions)
   * if (hasPermission) {
   *   // 权限已授予，可以执行相关操作
   * } else {
   *   // 权限未授予，需要请求权限
   * }
   * ```
   */
  static checkPermission(permissions: Permissions[]): boolean {
    try {
      // 创建一个访问令牌管理器实例
      // AtManager是HarmonyOS提供的访问令牌管理器，用于权限管理
      let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
      
      // 初始化tokenID为0，稍后将获取真实的tokenID
      let tokenID: number = 0;

      // 获取本应用的包信息
      // BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION表示获取包含应用信息的包信息
      const bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);

      // 设置tokenID为应用的访问令牌ID
      // 访问令牌ID是应用在系统中的唯一标识，用于权限验证
      tokenID = bundleInfo.appInfo.accessTokenId;

      // 如果没有传入任何权限，则返回false表示没有权限
      if (permissions.length === 0) {
        return false;
      } else {
        // 检查所有请求的权限是否都被授予
        // every()方法确保所有权限都满足条件才返回true
        return permissions.every(permission =>
          // GrantStatus.PERMISSION_GRANTED表示权限已授予
          // checkAccessTokenSync()方法同步检查访问令牌的权限状态
          abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED ===
          atManager.checkAccessTokenSync(tokenID, permission)
        );
      }
    } catch (error) {
      // 异常处理：记录错误日志并返回false
      console.error('检查权限失败:', error);
      return false; // 发生异常时返回false，表示没有权限
    }
  }

  // ==================== 权限请求方法 ====================
  
  /**
   * 请求用户授权指定权限
   * 
   * 功能说明：
   * - 向用户请求授权指定的权限
   * - 异步方法，返回Promise<boolean>
   * - 支持多个权限同时请求
   * 
   * 参数说明：
   * - permissions: Permissions[] - 需要请求的权限数组
   * 
   * 返回值：
   * - Promise<boolean> - true表示所有权限请求成功，false表示有权限请求失败
   * 
   * 使用示例：
   * ```typescript
   * const permissions: Permissions[] = ["ohos.permission.MICROPHONE"]
   * const result = await PermissionManager.requestPermission(permissions)
   * if (result) {
   *   // 权限请求成功，可以执行相关操作
   * } else {
   *   // 权限请求失败，需要处理失败情况
   * }
   * ```
   */
  static async requestPermission(permissions: Permissions[]): Promise<boolean> {
    try {
      // 创建一个访问令牌管理器实例
      // AtManager是HarmonyOS提供的访问令牌管理器，用于权限管理
      let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();

      // 获取上下文（这里假设getContext是一个可以获取到UI能力上下文的方法）
      // UIAbilityContext是HarmonyOS UI能力的上下文，提供应用级别的功能
      let context: Context = getContext() as common.UIAbilityContext;

      // 请求用户授权指定的权限
      // requestPermissionsFromUser()方法会弹出权限请求对话框
      // 用户可以选择允许或拒绝权限请求
      const result = await atManager.requestPermissionsFromUser(context, permissions);

      // 检查请求结果是否成功
      // authResults数组中每个元素都应该是0，表示成功
      // 0表示权限请求成功，其他值表示失败
      return !!result.authResults.length && result.authResults.every(authResults => authResults === 0);
    } catch (error) {
      // 异常处理：记录错误日志并返回false
      console.error('请求权限失败:', error);
      return false; // 发生异常时返回false，表示请求失败
    }
  }
}