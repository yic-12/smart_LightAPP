/**
 * 智能照明管理APP - MD5令牌生成器 (MD5.ets)
 * 
 * 功能说明：
 * 1. 使用MD5加密算法生成智能家居API所需的认证令牌
 * 2. 提供安全的API请求认证机制
 * 3. 支持时间戳和密钥的组合加密
 * 4. 提供令牌格式验证功能
 * 5. 集成HarmonyOS加密框架
 * 
 * 技术特点：
 * - 使用HarmonyOS cryptoFramework加密框架
 * - MD5摘要算法实现
 * - 十六进制字符串输出
 * - 异常处理和错误日志
 * - 静态方法设计，便于调用
 */

// 导入HarmonyOS加密框架
import { cryptoFramework } from "@kit.CryptoArchitectureKit";
// 导入HarmonyOS工具类
import util from "@ohos.util";

/**
 * TokenGenerator - MD5令牌生成器类
 * 
 * 功能说明：
 * - 使用MD5加密算法生成智能家居API所需的token
 * - 生成公式: MD5(timestamp + key)
 * - 其中 key = "2023GSD_smart_home%$Sd"
 * - 提供安全的API请求认证机制
 * 
 * 设计特点：
 * - 静态方法设计，无需实例化
 * - 私有密钥保护，防止泄露
 * - 异常处理机制，确保稳定性
 * - 日志记录，便于调试
 */
export class TokenGenerator {
  
  // ==================== 常量定义 ====================
  
  /**
   * 私有密钥常量
   * 
   * 功能说明：
   * - 用于MD5加密的固定密钥
   * - 与时间戳组合生成认证令牌
   * - 私有属性，防止外部访问
   * 
   * 安全考虑：
   * - 密钥硬编码在客户端
   * - 生产环境建议使用更安全的密钥管理方案
   */
  private static readonly SECRET_KEY: string = "2023GSD_smart_home%$Sd";

  // ==================== 核心方法 ====================
  
  /**
   * 生成API请求token
   * 
   * 功能说明：
   * - 使用MD5算法生成认证令牌
   * - 支持自定义时间戳或使用当前时间
   * - 返回32位十六进制字符串
   * 
   * 参数说明：
   * - timestamp: string | undefined - 用于生成token的时间戳，如果不提供则使用当前时间
   * 
   * 返回值：
   * - Promise<string> - 生成的MD5 token（32位十六进制字符串）
   * 
   * 异常处理：
   * - 捕获加密过程中的异常
   * - 记录错误日志
   * - 抛出详细的错误信息
   * 
   * 使用示例：
   * ```typescript
   * // 使用当前时间戳
   * const token1 = await TokenGenerator.generateToken();
   * 
   * // 使用自定义时间戳
   * const token2 = await TokenGenerator.generateToken("1640995200000");
   * ```
   */
  static async generateToken(timestamp?: string): Promise<string> {
    try {
      // 使用传入的时间戳或获取当前时间戳
      const actualTimestamp: string = timestamp || Date.now().toString();

      // 拼接时间戳和密钥
      const rawStr: string = `${actualTimestamp}${TokenGenerator.SECRET_KEY}`;

      console.info(`[TokenGenerator] 原始字符串: ${rawStr}`);

      // 使用标准编码方式将字符串转换为字节数组
      // 正确：encode() 直接返回字符串对应的Uint8Array
      const encodedData: Uint8Array = new util.TextEncoder().encode(rawStr);

      // 创建MD5摘要算法实例
      const md5 = cryptoFramework.createMd("MD5");

      // 更新摘要数据
      await md5.update({ data: encodedData });

      // 计算MD5摘要
      const md5Result = await md5.digest();

      // 将结果转换为十六进制字符串
      // 先生成大写，再由调用方根据需要选择大小写
      const hexToken = TokenGenerator.dataBlobToHex(md5Result).toUpperCase();

      console.info(`[TokenGenerator] 生成的Token: ${hexToken}`);

      return hexToken;
    } catch (error) {
      console.error("[TokenGenerator] Token生成失败：", error);
      throw new Error(`Token生成失败: ${error}`);
    }
  }

  // ==================== 工具方法 ====================
  
  /**
   * 将DataBlob转换为十六进制字符串
   * 
   * 功能说明：
   * - 将加密框架返回的DataBlob转换为十六进制字符串
   * - 每个字节转换为两位十六进制数
   * - 用于MD5结果的格式化输出
   * 
   * 参数说明：
   * - blob: cryptoFramework.DataBlob - 数据块
   * 
   * 返回值：
   * - string - 十六进制字符串
   * 
   * 实现原理：
   * - 遍历DataBlob中的每个字节
   * - 将每个字节转换为十六进制
   * - 使用padStart确保两位格式
   * - 拼接成完整的十六进制字符串
   */
  private static dataBlobToHex(blob: cryptoFramework.DataBlob): string {
    return Array.from(blob.data)
      .map(byte => byte.toString(16).padStart(2, "0"))
      .join("");
  }

  /**
   * 获取当前时间戳
   * 
   * 功能说明：
   * - 返回当前时间的毫秒时间戳
   * - 用于生成认证令牌
   * - 提供统一的时间戳获取方式
   * 
   * 返回值：
   * - number - 当前时间戳（毫秒）
   * 
   * 使用场景：
   * - API请求认证
   * - 防重放攻击
   * - 时间同步
   */
  static getCurrentTimestamp(): number {
    return Date.now();
  }

  /**
   * 获取密钥
   * 
   * 功能说明：
   * - 返回用于MD5加密的密钥字符串
   * - 主要用于调试和日志记录
   * - 不推荐在生产环境中暴露密钥
   * 
   * 返回值：
   * - string - 密钥字符串
   * 
   * 安全注意：
   * - 密钥应该保密
   * - 仅用于调试目的
   * - 生产环境建议使用更安全的密钥管理
   */
  static getSecretKey(): string {
    return TokenGenerator.SECRET_KEY;
  }

  /**
   * 验证token格式是否正确
   * 
   * 功能说明：
   * - 验证token是否为有效的MD5格式
   * - 检查长度和字符格式
   * - 用于输入验证和错误检测
   * 
   * 参数说明：
   * - token: string - 要验证的token
   * 
   * 返回值：
   * - boolean - 是否为有效的MD5格式
   * 
   * 验证规则：
   * - 长度必须为32位
   * - 只能包含十六进制字符（0-9, A-F, a-f）
   * - 使用正则表达式验证
   * 
   * 使用示例：
   * ```typescript
   * const isValid = TokenGenerator.isValidTokenFormat("A1B2C3D4E5F6789012345678901234567");
   * console.log(isValid); // true
   * ```
   */
  static isValidTokenFormat(token: string): boolean {
    const md5Regex = /^[A-Fa-f0-9]{32}$/;
    return md5Regex.test(token);
  }
}