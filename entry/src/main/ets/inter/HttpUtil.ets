/**
 * 智能照明管理APP - HTTP网络请求工具 (HttpUtil.ets)
 * 
 * 功能说明：
 * 1. 提供HTTP网络请求的封装和管理
 * 2. 支持单个设备亮度控制
 * 3. 支持单个设备颜色和亮度控制
 * 4. 支持多设备批量控制
 * 5. 支持多设备颜色批量控制
 * 6. 集成MD5令牌生成和认证
 * 
 * 技术特点：
 * - 使用HarmonyOS网络请求API
 * - 单例模式设计
 * - 支持表单数据编码
 * - 异常处理和资源管理
 * - 超时控制
 */

// 导入HarmonyOS网络请求模块
import { http } from "@kit.NetworkKit"
// 导入数据模型接口
import { Data2, DeviceControlItem } from "../inter/Interface1";
// 导入MD5令牌生成器
import { TokenGenerator } from "../inter/MD5";

/**
 * HttpUtil - HTTP网络请求工具类
 * 
 * 功能说明：
 * - 封装HTTP网络请求操作
 * - 提供设备控制的网络接口
 * - 支持单设备和多设备控制
 * - 集成认证和令牌管理
 * 
 * 设计模式：
 * - 单例模式，确保全局只有一个实例
 * - 提供统一的网络请求接口
 */
export class HttpUtil {
  
  // ==================== 单例模式实现 ====================
  
  /**
   * 单例实例
   * 私有静态属性，存储唯一的HttpUtil实例
   */
  private static instance: HttpUtil = new HttpUtil()
  
  /**
   * 私有构造函数
   * 防止外部直接实例化，确保单例模式
   */
  private constructor() {
  }
  
  /**
   * 获取单例实例
   * 
   * 功能说明：
   * - 返回HttpUtil的唯一实例
   * - 确保全局只有一个HttpUtil对象
   * 
   * 返回值：
   * - HttpUtil - HttpUtil的单例实例
   */
  public static getInstance(): HttpUtil {
    return HttpUtil.instance
  }

  // ==================== 单设备控制方法 ====================
  
  /**
   * 设置单个设备亮度
   * 
   * 功能说明：
   * - 控制单个设备的亮度和色温
   * - 支持设备开关控制
   * - 集成MD5令牌认证
   * 
   * 参数说明：
   * - url: string - API请求地址
   * - light: number - 亮度值（0-100）
   * - temperature: number - 色温值（0-100）
   * - state: string - 设备状态（'0'=开启，'1'=关闭）
   * - id: string - 设备ID
   * 
   * 认证机制：
   * - 使用时间戳生成MD5令牌
   * - 防止重放攻击
   * - 确保请求安全性
   */
  async setLightBrightness(url: string, light: number, temperature: number, state: string, id: string) {
    // 判断设备是否关闭
    let isOff = state === '1'
    
    // 生成时间戳和认证令牌
    const timestamp: string = Date.now().toString()
    const token: string = (await TokenGenerator.generateToken(timestamp)).toLowerCase()
    
    // 构建设备控制数据
    let data1: Data2 = {
      timestamp: timestamp,        // 请求时间戳，用于认证和防重放（与token一致）
      token: token,                // 认证令牌：MD5(timestamp + key)
      control_sub_id: id,          // 控制的子设备ID（目标灯光设备ID）
      control_sub_state: state,    // 设备控制状态：'0'=打开，'1'=关闭
      r_channel: 0,               // 红色通道值，可选参数
      g_channel: 0,               // 绿色通道值，可选参数
      b_channel: 0,               // 蓝色通道值，可选参数
      w_channel: isOff ? 0 : light,      // 白光通道值（亮度控制），可选参数
      y_channel: temperature,      // 黄光通道值（色温控制），可选参数
      control_state: '',          // 控制状态，可选参数
      type_uuid: 'LIGHT_GROUP',   // 设备类型UUID
      lightness: 0,               // 亮度值，可选参数（与w_channel可能重复，取决于API设计）
    }
    
    // 构建 x-www-form-urlencoded 请求体（避免参数解构语法）
    let formPairs1: string[] = []
    const entries1: Array<[string, string | number]> = [
      ['timestamp', data1.timestamp],
      ['token', data1.token],
      ['control_sub_id', data1.control_sub_id],
      ['control_sub_state', data1.control_sub_state],
      ['r_channel', data1.r_channel ?? ''],
      ['g_channel', data1.g_channel ?? ''],
      ['b_channel', data1.b_channel ?? ''],
      ['w_channel', data1.w_channel ?? ''],
      ['y_channel', data1.y_channel ?? ''],
      ['control_state', data1.control_state ?? ''],
      ['type_uuid', data1.type_uuid],
      ['lightness', data1.lightness ?? ''],
    ]
    
    // 编码表单数据
    for (let i = 0; i < entries1.length; i++) {
      const key = entries1[i][0]
      const value = entries1[i][1]
      if (value !== undefined && value !== null && String(value) !== '') {
        formPairs1.push(`${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`)
      }
    }
    const formBody = formPairs1.join('&')
    
    // 配置HTTP请求选项
    let options: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      extraData: formBody,
      connectTimeout: 9000,  // 前端发送数据给后端如果9秒没有结果，前端主动终止行为
      readTimeout: 9000,      // 读取数据超过9秒，告诉前端请求失败
    }
    
    // 创建HTTP请求并发送
    const httpRequest = http.createHttp()
    httpRequest.request(url, options, (error: Error, data: http.HttpResponse) => {
      // error没有内容代表成功
      if (!error) {
        console.log(`请求成功，返回数据：${JSON.stringify(data)}`)
        // 取消订阅HTTP响应头事件
        httpRequest.off('headersReceive');
        // 当该请求使用完毕时，开发者务必调用destroy方法主动销毁该JavaScript Object
        httpRequest.destroy();
      } else {
        console.log(`请求失败，具体原因：${JSON.stringify(error)}`)
        // 取消订阅HTTP响应头事件
        httpRequest.off('headersReceive');
        // 当该请求使用完毕时，调用destroy方法主动销毁该JavaScript Object
        httpRequest.destroy();
      }
    })
  }

  /**
   * 设置单个设备颜色和亮度
   * 
   * 功能说明：
   * - 控制单个设备的颜色、亮度和色温
   * - 支持RGB颜色控制
   * - 支持设备开关控制
   * - 集成MD5令牌认证
   * 
   * 参数说明：
   * - url: string - API请求地址
   * - light: number - 亮度值（0-100）
   * - temperature: number - 色温值（0-100）
   * - state: string - 设备状态（'0'=开启，'1'=关闭）
   * - r: number - 红色通道值（0-255）
   * - g: number - 绿色通道值（0-255）
   * - b: number - 蓝色通道值（0-255）
   * - id: string - 设备ID
   * 
   * 颜色控制：
   * - 支持RGB三原色独立控制
   * - 可以创建各种颜色效果
   * - 与亮度和色温控制结合使用
   */
  async setLightColorBrightness(url: string, light: number, temperature: number, state: string, r: number, g: number, b: number, id: string) {
    // 判断设备是否关闭
    let isOff = state === '1'
    
    // 生成时间戳和认证令牌
    const timestamp: string = Date.now().toString()
    const token: string = (await TokenGenerator.generateToken(timestamp)).toLowerCase()
    
    // 构建设备控制数据
    let data1: Data2 = {
      timestamp: timestamp,        // 请求时间戳，用于认证和防重放（与token一致）
      token: token,                // 认证令牌：MD5(timestamp + key)
      control_sub_id: id,          // 控制的子设备ID（目标灯光设备ID）
      control_sub_state: state,    // 设备控制状态：'0'=打开，'1'=关闭
      r_channel: r,                // 红色通道值
      g_channel: g,                // 绿色通道值
      b_channel: b,                // 蓝色通道值
      w_channel: isOff ? 0 : light,      // 白光通道值（亮度控制），可选参数
      y_channel: temperature,      // 黄光通道值（色温控制），可选参数
      control_state: '',          // 控制状态，可选参数
      type_uuid: 'LIGHT_GROUP',   // 设备类型UUID
      lightness: 0,               // 亮度值，可选参数（与w_channel可能重复，取决于API设计）
    }
    
    // 构建 x-www-form-urlencoded 请求体（避免参数解构语法）
    let formPairs2: string[] = []
    const entries2: Array<[string, string | number]> = [
      ['timestamp', data1.timestamp],
      ['token', data1.token],
      ['control_sub_id', data1.control_sub_id],
      ['control_sub_state', data1.control_sub_state],
      ['r_channel', data1.r_channel ?? ''],
      ['g_channel', data1.g_channel ?? ''],
      ['b_channel', data1.b_channel ?? ''],
      ['w_channel', data1.w_channel ?? ''],
      ['y_channel', data1.y_channel ?? ''],
      ['control_state', data1.control_state ?? ''],
      ['type_uuid', data1.type_uuid],
      ['lightness', data1.lightness ?? ''],
    ]
    
    // 编码表单数据
    for (let i = 0; i < entries2.length; i++) {
      const key = entries2[i][0]
      const value = entries2[i][1]
      if (value !== undefined && value !== null && String(value) !== '') {
        formPairs2.push(`${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`)
      }
    }
    const formBody = formPairs2.join('&')
    
    // 配置HTTP请求选项
    let options: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      extraData: formBody,
      connectTimeout: 9000,  // 前端发送数据给后端如果9秒没有结果，前端主动终止行为
      readTimeout: 9000,      // 读取数据超过9秒，告诉前端请求失败
    }
    
    // 创建HTTP请求并发送
    const httpRequest = http.createHttp()
    httpRequest.request(url, options, (error: Error, data: http.HttpResponse) => {
      // error没有内容代表成功
      if (!error) {
        console.log(`请求成功，返回数据：${JSON.stringify(data)}`)
        // 取消订阅HTTP响应头事件
        httpRequest.off('headersReceive');
        // 当该请求使用完毕时，开发者务必调用destroy方法主动销毁该JavaScript Object
        httpRequest.destroy();
      } else {
        console.log(`请求失败，具体原因：${JSON.stringify(error)}`)
        // 取消订阅HTTP响应头事件
        httpRequest.off('headersReceive');
        // 当该请求使用完毕时，调用destroy方法主动销毁该JavaScript Object
        httpRequest.destroy();
      }
    })
  }

  // ==================== 多设备控制方法 ====================
  
  /**
   * 控制多个设备（亮度控制）
   * 
   * 功能说明：
   * - 批量控制多个设备的亮度
   * - 兼容后端单设备接口
   * - 逐个设备调用单设备控制
   * - 确保每个设备的control_sub_id在表单顶层
   * 
   * 参数说明：
   * - url: string - API请求地址
   * - deviceControls: DeviceControlItem[] - 设备控制项列表
   * 
   * 实现方式：
   * - 遍历设备列表
   * - 逐个调用setLightBrightness方法
   * - 记录成功和失败的设备
   * - 异常处理确保部分失败不影响其他设备
   */
  async controlMultipleDevices(url: string, deviceControls: DeviceControlItem[]) {
    // 兼容后端单设备接口：逐个设备调用单设备控制，保证 control_sub_id 在表单顶层
    for (let i = 0; i < deviceControls.length; i++) {
      const item = deviceControls[i]
      try {
        await this.setLightBrightness(
          url,
          item.w_channel ?? 0,
          item.y_channel ?? 0,
          item.control_sub_state,
          item.control_sub_id
        )
        console.log(`多设备子请求成功：id=${item.control_sub_id}`)
      } catch (e) {
        console.error(`多设备子请求失败：id=${item.control_sub_id}, err=${e}`)
      }
    }
  }

  /**
   * 控制多个设备（颜色控制）
   * 
   * 功能说明：
   * - 批量控制多个设备的颜色和亮度
   * - 支持RGB颜色控制
   * - 兼容后端单设备接口
   * - 逐个设备调用单设备控制
   * 
   * 参数说明：
   * - url: string - API请求地址
   * - deviceControls: DeviceControlItem[] - 设备控制项列表
   * 
   * 实现方式：
   * - 遍历设备列表
   * - 逐个调用setLightColorBrightness方法
   * - 传递RGB颜色参数
   * - 记录成功和失败的设备
   * - 异常处理确保部分失败不影响其他设备
   */
  async controlColorMultipleDevices(url: string, deviceControls: DeviceControlItem[]) {
    // 兼容后端单设备接口：逐个设备调用单设备控制，保证 control_sub_id 在表单顶层
    for (let i = 0; i < deviceControls.length; i++) {
      const item = deviceControls[i]
      try {
        await this.setLightColorBrightness(
          url,
          item.w_channel ?? 0,
          item.y_channel ?? 0,
          item.control_sub_state,
          item.r_channel ?? 0,
          item.g_channel ?? 0,
          item.b_channel ?? 0,
          item.control_sub_id,
        )
        console.log(`多设备子请求成功：id=${item.control_sub_id}`)
      } catch (e) {
        console.error(`多设备子请求失败：id=${item.control_sub_id}, err=${e}`)
      }
    }
  }
}