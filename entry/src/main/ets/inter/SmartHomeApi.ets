/**
 * 智能照明管理APP - 智能家居API接口 (SmartHomeApi.ets)
 * 
 * 功能说明：
 * 1. 提供智能家居系统的HTTP请求接口
 * 2. 支持GET和POST请求方法
 * 3. 封装HTTP请求的通用逻辑
 * 4. 提供请求超时和错误处理
 * 5. 支持JSON格式的数据传输
 * 
 * 技术特点：
 * - 使用HarmonyOS网络请求API
 * - 支持异步回调处理
 * - 自动资源管理和清理
 * - 统一的错误处理机制
 * - 类型安全的数据接口
 */

// 导入HarmonyOS网络请求模块
import { http } from "@kit.NetworkKit";
// 导入数据接口定义
import { Data1, Data2 } from "../inter/Interface1";

// ==================== GET请求方法 ====================

/**
 * httpGet - HTTP GET请求方法
 * 
 * 功能说明：
 * - 发送HTTP GET请求到指定URL
 * - 支持可选的数据参数
 * - 使用JSON格式传输数据
 * - 提供超时控制和错误处理
 * 
 * 参数说明：
 * - url: string - 请求的目标URL地址
 * - method: http.RequestMethod - HTTP请求方法（GET）
 * - requestData: Data1 | undefined - 可选的请求数据
 * 
 * 请求配置：
 * - Content-Type: application/json
 * - 连接超时：9秒
 * - 读取超时：9秒
 * 
 * 回调处理：
 * - 成功：打印响应数据，清理资源
 * - 失败：打印错误信息，清理资源
 * 
 * 资源管理：
 * - 自动取消HTTP响应头事件订阅
 * - 自动销毁HTTP请求对象
 * - 防止内存泄漏
 * 
 * 使用示例：
 * ```typescript
 * const requestData: Data1 = {
 *   project_id: "project123",
 *   timestamp: Date.now().toString()
 * };
 * 
 * httpGet("https://api.example.com/data", http.RequestMethod.GET, requestData);
 * ```
 */
export function httpGet(url: string, method: http.RequestMethod, requestData?: Data1) {
  // 创建HTTP请求实例
  const httpRequest = http.createHttp()
  
  // 发送HTTP请求
  httpRequest.request(url, {
    method: method,              // 请求方式
    header: {
      // 设置请求头
      // 前端浏览器告诉后端，前端传递的数据格式
      'Content-Type': 'application/json'
    },
    extraData: requestData,      // 设置请求要传给后端的数据
    connectTimeout: 9000,        // 前端发送数据给后端如果9秒没有结果，前端主动终止行为
    readTimeout: 9000,          // 读取数据超过9秒，告诉前端请求失败
  }, (error: Error, data: http.HttpResponse) => {
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

// ==================== POST请求方法 ====================

/**
 * httpPost - HTTP POST请求方法
 * 
 * 功能说明：
 * - 发送HTTP POST请求到指定URL
 * - 支持可选的数据参数
 * - 使用JSON格式传输数据
 * - 提供超时控制和错误处理
 * 
 * 参数说明：
 * - url: string - 请求的目标URL地址
 * - method: http.RequestMethod - HTTP请求方法（POST）
 * - requestData: Data2 | undefined - 可选的请求数据
 * 
 * 请求配置：
 * - Content-Type: application/json
 * - 连接超时：9秒
 * - 读取超时：9秒
 * 
 * 回调处理：
 * - 成功：打印响应数据，清理资源
 * - 失败：打印错误信息，清理资源
 * 
 * 资源管理：
 * - 自动取消HTTP响应头事件订阅
 * - 自动销毁HTTP请求对象
 * - 防止内存泄漏
 * 
 * 使用示例：
 * ```typescript
 * const requestData: Data2 = {
 *   timestamp: Date.now().toString(),
 *   token: "abc123",
 *   control_sub_id: "device001",
 *   control_sub_state: "0",
 *   type_uuid: "LIGHT_GROUP"
 * };
 * 
 * httpPost("https://api.example.com/control", http.RequestMethod.POST, requestData);
 * ```
 */
export function httpPost(url: string, method: http.RequestMethod, requestData?: Data2) {
  // 创建HTTP请求实例
  const httpRequest = http.createHttp()
  
  // 发送HTTP请求
  httpRequest.request(url, {
    method: method,              // 请求方式
    header: {
      // 设置请求头
      // 前端浏览器告诉后端，前端传递的数据格式
      'Content-Type': 'application/json'
    },
    extraData: requestData,      // 设置请求要传给后端的数据
    connectTimeout: 9000,        // 前端发送数据给后端如果9秒没有结果，前端主动终止行为
    readTimeout: 9000,          // 读取数据超过9秒，告诉前端请求失败
  }, (error: Error, data: http.HttpResponse) => {
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