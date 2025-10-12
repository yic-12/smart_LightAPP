/**
 * 智能照明管理APP - 语音识别管理器 (SpeechRecognizerManager.ets)
 * 
 * 功能说明：
 * 1. 提供语音识别引擎的创建和管理
 * 2. 支持实时语音识别和结果回调
 * 3. 提供语音识别的启动、停止、取消等操作
 * 4. 支持引擎状态检查和资源管理
 * 5. 异常处理和错误日志记录
 * 
 * 技术特点：
 * - 使用HarmonyOS语音识别API
 * - 支持中文语音识别
 * - 实时识别模式
 * - 引擎复用和资源管理
 * - 异常安全处理
 */

// 导入HarmonyOS语音识别模块
import { speechRecognizer } from '@kit.CoreSpeechKit';

/**
 * SpeechRecognizerManager - 语音识别管理器
 * 
 * 功能说明：
 * - 封装HarmonyOS语音识别API
 * - 提供统一的语音识别接口
 * - 管理语音识别引擎的生命周期
 * - 支持实时语音识别和结果回调
 * 
 * 使用场景：
 * - 语音控制灯光开关
 * - 语音控制场景切换
 * - 实时语音转文字
 */
class SpeechRecognizerManager {
  
  // ==================== 配置参数 ====================
  
  /**
   * 语音识别额外参数配置
   * 
   * 功能说明：
   * - 配置语音识别的语言、模式等参数
   * - 支持标点符号和句子检测
   * - 使用实时识别模式
   */
  private static extraParam: Record<string, Object> = {
    "locate": "CN",                    // 地区设置为中国
    "recognizerMode": "short",          // 语音模式：短语音识别
    "enablePunctuation": true,         // 启用标点符号
    "enableSentenceDetection": true    // 启用句子检测
  };
  
  /**
   * 语音识别引擎初始化参数
   * 
   * 功能说明：
   * - 配置语音识别引擎的初始化参数
   * - 设置语言为中文
   * - 使用在线识别模式
   */
  private static initParamsInfo: speechRecognizer.CreateEngineParams = {
    /**
     * 地区信息
     * 设置为中文（简体）
     */
    language: 'zh-CN',
    /**
     * 识别模式
     * 1: 在线模式（需要网络连接）
     * 0: 离线模式（本地识别）
     */
    online: 1,
    extraParams: this.extraParam
  };

  // ==================== 引擎状态管理 ====================
  
  /**
   * 语音识别引擎实例
   * 
   * 功能说明：
   * - 存储语音识别引擎的实例
   * - 单例模式，确保只有一个引擎实例
   * - 初始值为null，表示未创建
   */
  private static asrEngine: speechRecognizer.SpeechRecognitionEngine | null = null
  
  /**
   * 语音识别结果
   * 
   * 功能说明：
   * - 存储最新的语音识别结果
   * - 包含识别文本和置信度等信息
   * - 初始值为null，表示无识别结果
   */
  static speechResult: speechRecognizer.SpeechRecognitionResult | null = null
  
  /**
   * 会话ID
   * 
   * 功能说明：
   * - 用于标识语音识别会话
   * - 每次开始识别时生成新的会话ID
   * - 格式：asr + 时间戳
   */
  private static sessionId: string = "asr" + Date.now()

  // ==================== 引擎管理方法 ====================
  
  /**
   * 创建语音识别引擎
   * 
   * 功能说明：
   * - 创建语音识别引擎实例
   * - 使用配置的初始化参数
   * - 单例模式，避免重复创建
   * 
   * 异常处理：
   * - 捕获创建失败异常
   * - 记录错误日志
   */
  private static async createEngine() {
    try {
      // 如果引擎已存在，直接返回
      if (SpeechRecognizerManager.asrEngine) {
        return;
      }
      // 设置创建引擎参数
      SpeechRecognizerManager.asrEngine = await speechRecognizer.createEngine(SpeechRecognizerManager.initParamsInfo)
    } catch (error) {
      console.error('创建语音识别引擎失败:', error);
    }
  }

  /**
   * 设置语音识别回调
   * 
   * 功能说明：
   * - 设置语音识别的各种回调函数
   * - 包括开始、结果、完成、错误等回调
   * - 支持自定义结果处理回调
   * 
   * 参数说明：
   * - callback: 自定义结果处理回调函数
   * 
   * 异常处理：
   * - 捕获设置回调失败异常
   * - 记录错误日志
   */
  private static setListener(callback: (srr: speechRecognizer.SpeechRecognitionResult) => void = () => {
  }) {
    try {
      // 创建回调对象
      let setListener: speechRecognizer.RecognitionListener = {
        // 开始识别成功回调
        onStart(_sessionId: string, eventMessage: string) {
          console.log("语音识别开始:", eventMessage)
        },
        // 事件回调
        onEvent(_sessionId: string, eventCode: number, eventMessage: string) {
          console.log("语音识别事件:", eventCode, eventMessage)
          // 事件3表示语音停止，立即处理
          if (eventCode === 3) {
            console.log("语音停止，准备结束识别")
          }
        },
        // 识别结果回调，包括中间结果和最终结果
        onResult(_sessionId: string, result: speechRecognizer.SpeechRecognitionResult) {
          SpeechRecognizerManager.speechResult = result
          console.log("实时识别结果:", JSON.stringify(result))
          callback && callback(result)
        },
        // 识别完成回调
        onComplete(_sessionId: string, eventMessage: string) {
          console.log("语音识别完成:", eventMessage)
        },
        // 错误回调，错误码通过本方法返回
        // 如：返回错误码1002200006，识别引擎正忙，引擎正在识别中
        // 更多错误码请参考错误码参考
        onError(_sessionId: string, errorCode: number, errorMessage: string) {
          console.error("语音识别错误:", errorCode, errorMessage)
        },
      }
      // 设置回调
      SpeechRecognizerManager.asrEngine?.setListener(setListener);
    } catch (error) {
      console.error('设置语音识别回调失败:', error);
    }
  }

  // ==================== 识别控制方法 ====================
  
  /**
   * 开始语音识别
   * 
   * 功能说明：
   * - 启动语音识别引擎
   * - 配置音频参数和识别参数
   * - 支持实时识别模式
   * 
   * 参数配置：
   * - 音频类型：PCM
   * - 采样率：16000Hz
   * - 声道数：1（单声道）
   * - 采样位数：16位
   * - 识别模式：实时录音识别
   * - 最大音频时长：30秒
   * - 识别间隔：100毫秒
   * 
   * 异常处理：
   * - 捕获启动失败异常
   * - 记录错误日志
   */
  static startListening() {
    try {
      // 设置开始识别的相关参数
      let recognizerParams: speechRecognizer.StartParams = {
        // 会话id
        sessionId: SpeechRecognizerManager.sessionId,
        // 音频配置信息
        audioInfo: {
          // 音频类型。当前仅支持"pcm"
          audioType: 'pcm',
          // 音频的采样率。当前仅支持16000采样率
          sampleRate: 16000,
          // 音频返回的通道数信息。当前仅支持通道1
          soundChannel: 1,
          // 音频返回的采样位数。当前仅支持16位
          sampleBit: 16
        },
        // 录音识别参数
        extraParams: {
          // 0:实时录音识别，会自动打开麦克风录制实时语音
          "recognitionMode": 0,
          // 最大支持音频时长（必须在20000-60000范围内）
          maxAudioDuration: 30000,
          // 启用实时识别
          "enableRealTimeResult": true,
          // 设置识别间隔（毫秒）
          "resultInterval": 100
        }
      }
      // 调用开始识别方法
      SpeechRecognizerManager.asrEngine?.startListening(recognizerParams);
    } catch (error) {
      console.error('开始语音识别失败:', error);
    }
  };

  /**
   * 取消语音识别
   * 
   * 功能说明：
   * - 取消当前正在进行的语音识别
   * - 使用会话ID标识要取消的识别任务
   * - 不释放引擎资源
   * 
   * 异常处理：
   * - 捕获取消失败异常
   * - 记录错误日志
   */
  static cancel() {
    try {
      if (SpeechRecognizerManager.asrEngine) {
        SpeechRecognizerManager.asrEngine.cancel(SpeechRecognizerManager.sessionId)
        console.log("取消识别成功")
      } else {
        console.log("引擎不存在，无需取消")
      }
    } catch (error) {
      console.error("取消识别失败:", error)
    }
  }

  /**
   * 释放语音识别引擎
   * 
   * 功能说明：
   * - 释放语音识别引擎资源
   * - 关闭引擎，释放系统资源
   * - 通常在应用退出时调用
   * 
   * 异常处理：
   * - 捕获释放失败异常
   * - 记录错误日志
   */
  static shutDown() {
    try {
      SpeechRecognizerManager.asrEngine?.shutdown()
    } catch (error) {
      console.error('释放语音识别引擎失败:', error);
    }
  }

  /**
   * 停止语音识别但不释放引擎
   * 
   * 功能说明：
   * - 停止当前语音识别
   * - 保持引擎活跃状态，便于下次使用
   * - 提高识别响应速度
   * 
   * 异常处理：
   * - 捕获停止失败异常
   * - 记录错误日志
   */
  static stopRecognition() {
    try {
      console.log("开始停止语音识别")
      // 检查引擎状态
      if (!SpeechRecognizerManager.asrEngine) {
        console.log("引擎不存在，无需停止")
        return
      }
      SpeechRecognizerManager.cancel()
      console.log("语音识别已停止")
    } catch (error) {
      console.error("停止语音识别失败:", error)
    }
  }

  /**
   * 快速停止语音识别
   * 
   * 功能说明：
   * - 立即停止语音识别，不等待处理
   * - 适用于需要快速响应的场景
   * - 不释放引擎资源
   * 
   * 异常处理：
   * - 捕获快速停止失败异常
   * - 记录错误日志
   */
  static quickStopRecognition() {
    try {
      console.log("快速停止语音识别")
      if (SpeechRecognizerManager.asrEngine) {
        // 直接调用引擎的停止方法
        SpeechRecognizerManager.asrEngine.cancel(SpeechRecognizerManager.sessionId)
        console.log("语音识别已快速停止")
      } else {
        console.log("引擎不存在，无需快速停止")
      }
    } catch (error) {
      console.error("快速停止语音识别失败:", error)
    }
  }

  /**
   * 停止并释放语音识别资源
   * 
   * 功能说明：
   * - 停止当前语音识别
   * - 释放引擎资源
   * - 重置引擎实例为null
   * - 通常在应用退出时调用
   * 
   * 异常处理：
   * - 捕获释放失败异常
   * - 记录错误日志
   */
  static async release() {
    try {
      SpeechRecognizerManager.cancel()
      SpeechRecognizerManager.shutDown()
      SpeechRecognizerManager.asrEngine = null
    } catch (error) {
      console.error('释放语音识别资源失败:', error);
    }
  }

  // ==================== 初始化和状态检查方法 ====================
  
  /**
   * 初始化语音识别引擎
   * 
   * 功能说明：
   * - 创建语音识别引擎
   * - 设置识别回调
   * - 开始语音识别
   * - 完整的初始化流程
   * 
   * 参数说明：
   * - callback: 自定义结果处理回调函数
   * 
   * 异常处理：
   * - 捕获初始化失败异常
   * - 记录错误日志
   */
  static async init(callback: (srr: speechRecognizer.SpeechRecognitionResult) => void = () => {
  }) {
    try {
      await SpeechRecognizerManager.createEngine()
      SpeechRecognizerManager.setListener(callback)
      SpeechRecognizerManager.startListening()
    } catch (error) {
      console.error('初始化语音识别引擎失败:', error);
    }
  }

  /**
   * 检查语音识别引擎是否可用
   * 
   * 功能说明：
   * - 检查引擎实例是否存在
   * - 返回引擎可用状态
   * 
   * 返回值：
   * - boolean - true表示引擎可用，false表示引擎不可用
   */
  static isEngineAvailable(): boolean {
    return SpeechRecognizerManager.asrEngine !== null
  }

  /**
   * 重新开始语音识别
   * 
   * 功能说明：
   * - 在引擎已存在时重新开始识别
   * - 更新会话ID
   * - 重新设置回调
   * - 开始新的识别会话
   * 
   * 参数说明：
   * - callback: 自定义结果处理回调函数
   * 
   * 异常处理：
   * - 捕获重新开始失败异常
   * - 记录错误日志
   */
  static restartRecognition(callback: (srr: speechRecognizer.SpeechRecognitionResult) => void = () => {
  }) {
    try {
      if (SpeechRecognizerManager.isEngineAvailable()) {
        // 先停止当前识别
        SpeechRecognizerManager.cancel()
        // 更新会话ID
        SpeechRecognizerManager.sessionId = "asr" + Date.now()
        SpeechRecognizerManager.setListener(callback)
        SpeechRecognizerManager.startListening()
      } else {
        // 如果引擎不存在，重新初始化
        SpeechRecognizerManager.init(callback)
      }
    } catch (error) {
      console.error('重新开始语音识别失败:', error);
    }
  }
}

// 导出默认实例
export default SpeechRecognizerManager