/**
 * 智能照明管理APP - 语音控制页面 (YY.ets)
 * 
 * 功能说明：
 * 1. 提供实时语音识别功能，支持语音转文字
 * 2. 支持语音控制场景模式（教学、实操、会议、休息）
 * 3. 支持语音控制灯光开关（开启全部灯、关闭全部灯）
 * 4. 提供录音动画和状态显示
 * 5. 支持麦克风权限管理
 * 6. 实时显示识别结果和控制反馈
 * 
 * 技术特点：
 * - 使用HarmonyOS ArkUI框架
 * - 集成语音识别API
 * - 集成HTTP网络请求
 * - 权限管理
 * - 动画效果
 * - 多设备协同控制
 */

// 导入HarmonyOS网络请求模块
import { http } from "@kit.NetworkKit";
// 导入数据模型接口
import { Data1, Data2 } from "../inter/Interface1";
// 导入权限管理工具
import { PermissionManager } from '../utils/permissionMananger'
// 导入HarmonyOS权限类型
import { Permissions } from '@kit.AbilityKit'
// 导入语音识别管理器
import SpeechRecognizerManager from '../utils/SpeechRecognizerManager'
// 导入HTTP工具类
import { HttpUtil } from '../inter/HttpUtil'
// 导入设备控制数据
import { deviceControls, turn, deviceClass, exper, per, break1 } from '../utils/device'

// ==================== 语音识别组件 ====================

/**
 * VoiceRecognitionComponent - 语音识别组件
 * 
 * @Component装饰器：
 * - 标识这是一个ArkUI自定义组件
 * - 可以使用build()方法构建UI
 * 
 * 功能说明：
 * - 提供语音识别的UI界面
 * - 支持录音动画和状态显示
 * - 提供录音按钮和波形动画
 * - 支持回调函数处理识别结果
 */
@Component
export struct VoiceRecognitionComponent {
  
  // ==================== 回调函数 ====================
  
  /**
   * 开始识别回调函数
   * 当用户点击开始录音时触发
   */
  onStartRecognition?: () => void;
  
  /**
   * 停止识别回调函数
   * 当用户点击停止录音时触发
   */
  onStopRecognition?: () => void;
  
  /**
   * 识别结果回调函数
   * 当语音识别完成时触发，传递识别结果
   * 
   * 参数说明：
   * - result: string - 识别结果文本
   */
  onRecognitionResult?: (result: string) => void;
  
  /**
   * 状态变化回调函数
   * 当识别状态发生变化时触发
   * 
   * 参数说明：
   * - status: string - 状态描述文本
   */
  onStatusChange?: (status: string) => void;
  
  /**
   * 外部状态文本
   * @Prop装饰器表示这是从父组件传递的属性
   */
  @Prop statusText: string = "点击开始语音识别";

  // ==================== 组件状态管理 ====================
  
  /**
   * 是否正在录音
   * @State装饰器表示这是响应式状态变量
   */
  @State isRecording: boolean = false;
  
  /**
   * 录音时间（秒）
   * 用于显示录音时长
   */
  @State recordingTime: number = 0;
  
  /**
   * 动画缩放比例
   * 用于录音按钮的缩放动画
   */
  @State animationScale: number = 1.0;
  
  /**
   * 波形振幅数组
   * 用于生成录音时的波形动画效果
   */
  @State waveAmplitudes: number[] = [0.3, 0.5, 0.7, 0.4, 0.6, 0.8, 0.5, 0.3];
  
  /**
   * 语音识别结果
   * 存储最终的识别结果文本
   */
  @State recognitionResult: string = "";

  // ==================== 定时器管理 ====================
  
  /**
   * 录音计时器ID
   * 用于管理录音时间的计时器
   */
  private timer: number = -1;
  
  /**
   * 动画计时器ID
   * 用于管理波形动画的计时器
   */
  private animationTimer: number = -1;

  // ==================== 录音控制方法 ====================
  
  /**
   * 开始录音方法
   * 
   * 功能说明：
   * - 设置录音状态为true
   * - 重置录音时间
   * - 更新状态文本
   * - 启动计时器和动画
   */
  private startRecording() {
    this.isRecording = true;
    this.recordingTime = 0;
    this.onStatusChange?.("正在录音...");
    this.startTimer();
    this.startAnimation();
    console.info("开始录音");
  }

  /**
   * 结束录音方法
   * 
   * 功能说明：
   * - 设置录音状态为false
   * - 更新状态文本
   * - 停止计时器和动画
   */
  private stopRecording() {
    this.isRecording = false;
    this.onStatusChange?.("录音结束，正在识别...");
    this.stopTimer();
    this.stopAnimation();
    console.info("结束录音");
  }

  /**
   * 开始计时器方法
   * 
   * 功能说明：
   * - 启动每秒递增的计时器
   * - 用于显示录音时长
   */
  private startTimer() {
    this.timer = setInterval(() => {
      this.recordingTime++;
    }, 1000);
  }

  /**
   * 停止计时器方法
   * 
   * 功能说明：
   * - 清理计时器资源
   * - 防止内存泄漏
   */
  private stopTimer() {
    if (this.timer !== -1) {
      clearInterval(this.timer);
      this.timer = -1;
    }
  }

  /**
   * 开始动画方法
   * 
   * 功能说明：
   * - 启动波形动画和按钮缩放动画
   * - 每200ms更新一次动画状态
   */
  private startAnimation() {
    this.animationTimer = setInterval(() => {
      // 更新波形振幅
      this.waveAmplitudes = this.waveAmplitudes.map(() => Math.random() * 0.8 + 0.2);
      // 更新按钮缩放
      this.animationScale = this.animationScale === 1.0 ? 1.1 : 1.0;
    }, 200);
  }

  /**
   * 停止动画方法
   * 
   * 功能说明：
   * - 清理动画计时器资源
   * - 重置动画状态
   */
  private stopAnimation() {
    if (this.animationTimer !== -1) {
      clearInterval(this.animationTimer);
      this.animationTimer = -1;
    }
    this.animationScale = 1.0;
  }

  /**
   * 格式化时间显示方法
   * 
   * 功能说明：
   * - 将秒数转换为"MM:SS"格式
   * - 用于显示录音时长
   * 
   * 参数说明：
   * - seconds: number - 秒数
   * 
   * 返回值：
   * - string - 格式化后的时间字符串
   */
  private formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  // ==================== UI构建器方法 ====================
  
  /**
   * 波形动画组件
   * 
   * @Builder装饰器：
   * - 用于创建可重用的UI构建函数
   * - 支持参数传递，实现动态UI构建
   * 
   * 功能说明：
   * - 创建录音时的波形动画效果
   * - 根据录音状态显示不同的颜色
   * - 支持动画过渡效果
   */
  @Builder
  private WaveAnimation() {
    Row({ space: 4 }) {
      ForEach(this.waveAmplitudes, (amplitude: number, _index: number) => {
        Rect()
          .width(4)                                                    // 设置矩形宽度为4像素
          .height(amplitude * 30 + 10)                                // 设置矩形高度，根据振幅变化
          .fill(this.isRecording ? '#FF6B6B' : '#E0E0E0')            // 根据录音状态设置填充颜色
          .radius(2)                                                  // 设置圆角半径为2像素
          .animation({
            duration: 200,                                            // 动画持续时间为200ms
            curve: Curve.EaseInOut                                     // 动画曲线为缓入缓出
          })
      })
    }
    .justifyContent(FlexAlign.Center)                                // 水平居中对齐
    .opacity(this.isRecording ? 1 : 0.3)                            // 根据录音状态设置透明度
  }

  // ==================== UI构建方法 ====================
  
  /**
   * 构建组件UI
   * 
   * 这是ArkUI组件的核心方法，用于定义页面的结构和样式
   * 主要构建标题、状态显示、录音按钮、使用说明等区域
   */
  build() {
    Column({ space: 30 }) {
      
      // ==================== 页面标题 ====================
      Text("语音识别")
        .fontSize(28)                    // 设置字体大小为28像素
        .fontWeight(FontWeight.Bold)      // 设置字体粗细为粗体
        .fontColor('#2C3E50')            // 设置字体颜色为深蓝色
        .margin({ top: 20 })              // 设置上边距为20像素

      // ==================== 状态文本显示 ====================
      Text(this.statusText)
        .fontSize(16)                    // 设置字体大小为16像素
        .fontColor('#7F8C8D')            // 设置字体颜色为灰色
        .textAlign(TextAlign.Center)     // 设置文本居中对齐
        .margin({ bottom: 10 })           // 设置下边距为10像素

      // ==================== 语音识别结果显示 ====================
      if (this.recognitionResult) {
        Column() {
          Text("识别结果：")
            .fontSize(14)                    // 设置字体大小为14像素
            .fontColor('#2C3E50')            // 设置字体颜色为深蓝色
            .fontWeight(FontWeight.Medium)   // 设置字体粗细为中等
            .margin({ bottom: 8 })           // 设置下边距为8像素

          Text(this.recognitionResult)
            .fontSize(16)                    // 设置字体大小为16像素
            .fontColor('#27AE60')            // 设置字体颜色为绿色
            .textAlign(TextAlign.Center)     // 设置文本居中对齐
            .padding(12)                      // 设置内边距为12像素
            .backgroundColor('#F8F9FA')      // 设置背景色为浅灰色
            .borderRadius(8)                 // 设置圆角边框，半径为8像素
            .border({
              width: 1,                      // 设置边框宽度为1像素
              color: '#E0E0E0'               // 设置边框颜色为浅灰色
            })
        }
        .width('90%')                         // 设置宽度为90%
        .margin({ bottom: 20 })                // 设置下边距为20像素
      }

      // ==================== 录音时间显示 ====================
      if (this.isRecording) {
        Text(this.formatTime(this.recordingTime))
          .fontSize(24)                    // 设置字体大小为24像素
          .fontWeight(FontWeight.Medium)   // 设置字体粗细为中等
          .fontColor('#E74C3C')            // 设置字体颜色为红色
          .margin({ bottom: 20 })           // 设置下边距为20像素
      }

      // ==================== 波形动画 ====================
      Row() {
        this.WaveAnimation()
      }
      .margin({ bottom: 20 })               // 设置下边距为20像素

      // ==================== 录音按钮 ====================
      Button() {
        Column({ space: 8 }) {
          // 录音图标
          Image($r('app.media.yuying'))
            .width(40)                      // 设置图标宽度为40像素
            .height(40)                     // 设置图标高度为40像素
            .fillColor(this.isRecording ? Color.White : '#3498DB') // 根据录音状态设置图标颜色

          // 按钮文本
          Text(this.isRecording ? "停止录音" : "开始录音")
            .fontSize(14)                   // 设置字体大小为14像素
            .fontColor(this.isRecording ? Color.White : '#3498DB') // 根据录音状态设置文本颜色
            .fontWeight(FontWeight.Medium)  // 设置字体粗细为中等
        }
      }
      .width(120)                           // 设置按钮宽度为120像素
      .height(120)                          // 设置按钮高度为120像素
      .backgroundColor(this.isRecording ? '#E74C3C' : '#FFFFFF') // 根据录音状态设置背景色
      .borderRadius(60)                     // 设置圆角边框，半径为60像素（圆形按钮）
      .border({
        width: this.isRecording ? 0 : 3,    // 根据录音状态设置边框宽度
        color: '#3498DB'                     // 设置边框颜色为蓝色
      })
      .shadow({
        radius: this.isRecording ? 20 : 10, // 根据录音状态设置阴影半径
        color: this.isRecording ? '#E74C3C' : '#3498DB', // 根据录音状态设置阴影颜色
        offsetX: 0,                         // 设置阴影X偏移量为0
        offsetY: 4                          // 设置阴影Y偏移量为4像素
      })
      .scale({ x: this.animationScale, y: this.animationScale }) // 设置缩放比例
      .animation({
        duration: 200,                      // 设置动画持续时间为200ms
        curve: Curve.EaseInOut              // 设置动画曲线为缓入缓出
      })
      .onClick(() => {
        // 录音按钮点击事件处理
        if (this.isRecording) {
          // 如果正在录音，则停止录音
          this.stopRecording();
          this.onStopRecognition?.(); // 停止语音识别
          console.log("停止识别")
        } else {
          // 如果未在录音，则开始录音
          this.startRecording();
          this.onStartRecognition?.(); // 开始语音识别
          console.log("开始识别")
        }
      })

      // ==================== 使用说明 ====================
      Column({ space: 8 }) {
        Text("使用说明")
          .fontSize(16)                    // 设置字体大小为16像素
          .fontWeight(FontWeight.Medium)   // 设置字体粗细为中等
          .fontColor('#2C3E50')            // 设置字体颜色为深蓝色

        Text("•点击按钮开始录音，实时语音转文字")
          .fontSize(14)                    // 设置字体大小为14像素
          .fontColor('#7F8C8D')            // 设置字体颜色为灰色

        Text("•再次点击结束录音 ")
          .fontSize(14)                    // 设置字体大小为14像素
          .fontColor('#7F8C8D')            // 设置字体颜色为灰色

        Text("•能够实现语音控制开关教学、实操、会议、休息四个情景")
          .fontSize(14)                    // 设置字体大小为14像素
          .fontColor('#7F8C8D')            // 设置字体颜色为灰色

        Text("•能够实现语音控制同时开关所有灯")
          .fontSize(14)                    // 设置字体大小为14像素
          .fontColor('#7F8C8D')            // 设置字体颜色为灰色
      }
      .alignItems(HorizontalAlign.Start)   // 左对齐
      .margin({ top: 40 })                 // 设置上边距为40像素
      .padding(20)                         // 设置内边距为20像素
      .backgroundColor('#F8F9FA')           // 设置背景色为浅灰色
      .borderRadius(12)                    // 设置圆角边框，半径为12像素
      .width('90%')                        // 设置宽度为90%
      
      Blank()                              // 空白占位符
    }
  }
}

// ==================== 页面组件 ====================

/**
 * YYPage组件 - 语音控制页面包装组件
 * 
 * 功能说明：
 * - 作为YY组件的包装器
 * - 提供页面级别的布局
 */
@Component
export struct YYPage {
  build() {
    Column() {
      YY();
    }
    .width('100%')                         // 设置宽度为100%
    .height('100%')                        // 设置高度为100%
  }
}

// ==================== 构建器函数 ====================

/**
 * YYBuilder构建器函数
 * 
 * @Builder装饰器：
 * - 用于创建可重用的UI构建函数
 * - 可以在多个地方调用，提高代码复用性
 * - 支持参数传递，实现动态UI构建
 * 
 * 功能说明：
 * - 用于在导航系统中创建YY组件实例
 * - 提供统一的YY组件创建入口
 */
@Builder
export function YYBuilder() {
  YY();
}

// ==================== 主组件定义 ====================

/**
 * YY组件 - 语音控制主组件
 * 
 * @Component装饰器：
 * - 标识这是一个ArkUI自定义组件
 * - 可以使用build()方法构建UI
 * 
 * 功能说明：
 * - 提供语音识别的完整功能
 * - 支持场景控制和灯光控制
 * - 处理语音命令识别和执行
 */
@Component
export struct YY {
  
  // ==================== 导航和网络配置 ====================
  
  /**
   * 导航路径栈
   * 
   * 功能说明：
   * - 管理页面间的导航关系
   * - 支持页面的push、pop等操作
   * - 维护导航历史记录
   */
  pathStack: NavPathStack = new NavPathStack();
  
  /**
   * 服务器基础URL地址
   * 支持两种网络环境：
   * - 局域网：http://192.168.2.170:8081
   * - 校园网：http://10.214.166.140:8081
   * 
   * 当前使用校园网地址，如需切换网络环境，请修改此URL
   */
  URL: string = "http://10.214.166.140:8081" // 校园网地址
  
  /**
   * 请求时间戳
   * 用于生成唯一的请求标识，防止请求重复
   */
  timestamp: string = Date.now().toString()
  
  /**
   * GET请求的API路径
   * 用于查询设备状态信息
   */
  url1: string = "/SmartHome/ShenDaRest/getLights"
  
  /**
   * POST请求的API路径
   * 用于控制设备开关状态
   */
  url2: string = '/SmartHome/ShenDaRest/controlLight'
  
  /**
   * HTTP请求对象
   * 用于发送网络请求
   */
  httpRequest = http.createHttp()

  // ==================== 请求数据模型 ====================
  
  /**
   * GET请求的数据模型
   */
  @State data1: Data1 = {
    project_id: '',    // 项目ID，用于标识具体的项目
    timestamp: ''       // 时间戳，用于请求验证
  }
  
  /**
   * POST请求的数据模型
   * 
   * 包含设备控制的所有参数：
   * - 时间戳和令牌用于身份验证
   * - 设备ID和状态用于控制目标设备
   * - 各通道值用于调节灯光效果
   */
  @State data2: Data2 = {
    timestamp: '',        // 请求时间戳，用于认证和防重放
    token: '',           // 认证令牌，基于时间戳和密钥生成
    control_sub_id: '',  // 控制的子设备ID（目标灯光设备ID）
    control_sub_state: '', // 设备控制状态：'0'=打开，'1'=关闭
    r_channel: 1,        // 红色通道值，可选参数
    g_channel: 1,        // 绿色通道值，可选参数
    b_channel: 1,        // 蓝色通道值，可选参数
    w_channel: 1,        // 白光通道值（亮度控制），可选参数
    y_channel: 1,        // 黄光通道值（色温控制），可选参数
    control_state: '',   // 控制状态，可选参数
    type_uuid: '',       // 设备类型UUID
    lightness: 1,        // 亮度值，可选参数（与w_channel可能重复，取决于API设计）
  }

  // ==================== 语音识别状态管理 ====================
  
  /**
   * 语音识别结果文本
   * 存储最终的识别结果
   */
  @State text: string = ""
  
  /**
   * 状态文本
   * 显示当前语音识别的状态
   */
  @State statusText: string = "点击开始语音识别"
  
  /**
   * 实时识别结果
   * 存储实时识别过程中的结果
   */
  @State realtimeText: string = ""
  
  /**
   * 是否处于实时识别模式
   * true表示正在实时识别，false表示未在识别
   */
  @State isRealtimeMode: boolean = false

  // ==================== 场景控制相关 ====================
  
  /**
   * 场景关键词数组
   * 用于识别语音命令中的场景关键词
   */
  @State sceneKeywords: string[] = ['教学', '实操', '会议', '休息']
  
  /**
   * 灯光控制关键词数组
   * 用于识别语音命令中的灯光控制关键词
   */
  @State lightControlKeywords: string[] = ['开启全部灯', '开启所有灯', '打开全部灯', '打开所有灯', '关闭全部灯', '关闭所有灯', '关掉全部灯', '关掉所有灯']
  
  /**
   * 场景控制结果
   * 显示场景控制操作的反馈信息
   */
  @State sceneControlResult: string = ""

  // ==================== 场景控制方法 ====================
  
  /**
   * 控制场景方法
   * 
   * 功能说明：
   * - 根据场景名称控制对应的设备组
   * - 支持教学、实操、会议、休息四种场景
   * - 使用多设备控制API
   * 
   * 参数说明：
   * - sceneName: string - 场景名称
   */
  async controlScene(sceneName: string) {
    try {
      console.log(`开始控制场景: ${sceneName}`)
      this.sceneControlResult = `正在切换到${sceneName}模式...`

      // 调用多设备控制API
      //await HttpUtil.getInstance().controlMultipleDevices(`${this.URL}${this.url2}`, deviceControls)
      if (sceneName === '教学') {
        // 控制教学场景设备
        await HttpUtil.getInstance().controlColorMultipleDevices(`${this.URL}${this.url2}`, deviceClass)
      } else if (sceneName === '实操') {
        // 控制实操场景设备
        await HttpUtil.getInstance().controlColorMultipleDevices(`${this.URL}${this.url2}`, exper)
      } else if (sceneName === '会议') {
        // 控制会议场景设备
        await HttpUtil.getInstance().controlColorMultipleDevices(`${this.URL}${this.url2}`, per)
      } else if (sceneName === '休息') {
        // 控制休息场景设备
        await HttpUtil.getInstance().controlColorMultipleDevices(`${this.URL}${this.url2}`, break1)
      }

      this.sceneControlResult = `${sceneName}模式已激活！`
      console.log(`场景控制成功: ${sceneName}`)

      // 3秒后清除结果
      setTimeout(() => {
        this.sceneControlResult = ""
      }, 3000)

    } catch (error) {
      console.error(`场景控制失败: ${sceneName}`, error)
      this.sceneControlResult = `${sceneName}模式切换失败`
      setTimeout(() => {
        this.sceneControlResult = ""
      }, 3000)
    }
  }

  /**
   * 灯光控制方法
   * 
   * 功能说明：
   * - 控制所有灯光的开关状态
   * - 支持开启和关闭两种操作
   * - 使用5个设备接口控制全部25个设备
   * 
   * 参数说明：
   * - action: string - 控制动作描述
   */
  async controlAllLights(action: string) {
    try {
      console.log(`开始控制所有灯: ${action}`)
      console.log(`设备数量: ${deviceControls.length}`)
      console.log(`API地址: ${this.URL}${this.url2}`)

      this.sceneControlResult = `正在${action}所有灯...`

      // 判断是开启还是关闭
      const isTurnOn = action.includes('开启') || action.includes('打开')
      const controlState = isTurnOn ? '0' : '1'
      console.log(`控制状态: ${controlState} (${isTurnOn ? '开启' : '关闭'})`)

      // 批量控制所有设备
      for (let i = 0; i < turn.length; i++) {
        const device = turn[i]
        console.log(`正在控制设备 ${i + 1}/${turn.length}: ${device.name} (${device.control_sub_id})`)

        try {
          await HttpUtil.getInstance().setLightBrightness(
            `${this.URL}${this.url2}`,
            66, // 默认亮度
            66, // 默认色温
            controlState,
            device.control_sub_id
          )
          console.log(`设备 ${i + 1} 控制成功`)
        } catch (deviceError) {
          console.error(`设备 ${i + 1} 控制失败:`, deviceError)
        }
      }

      this.sceneControlResult = `所有灯${isTurnOn ? '已开启' : '已关闭'}！`
      console.log(`灯光控制成功: ${action}`)

      // 3秒后清除结果
      setTimeout(() => {
        this.sceneControlResult = ""
      }, 3000)

    } catch (error) {
      console.error(`灯光控制失败: ${action}`, error)
      this.sceneControlResult = `灯光控制失败`
      setTimeout(() => {
        this.sceneControlResult = ""
      }, 3000)
    }
  }

  /**
   * 语音识别结果处理方法
   * 
   * 功能说明：
   * - 解析语音识别结果
   * - 识别场景控制命令和灯光控制命令
   * - 执行对应的控制操作
   * 
   * 参数说明：
   * - voiceText: string - 语音识别结果文本
   * 
   * 返回值：
   * - boolean - 是否找到匹配的命令
   */
  processVoiceCommand(voiceText: string) {
    console.log(`处理语音命令: ${voiceText}`)
    console.log(`灯光控制关键词: ${JSON.stringify(this.lightControlKeywords)}`)
    console.log(`场景关键词: ${JSON.stringify(this.sceneKeywords)}`)

    // 检查是否包含灯光控制关键词
    for (const keyword of this.lightControlKeywords) {
      console.log(`检查关键词: ${keyword}, 包含: ${voiceText.includes(keyword)}`)
      if (voiceText.includes(keyword)) {
        console.log(`识别到灯光控制关键词: ${keyword}`)
        this.controlAllLights(keyword)
        return true // 找到匹配的灯光控制命令
      }
    }

    // 检查是否包含场景关键词
    for (const keyword of this.sceneKeywords) {
      console.log(`检查场景关键词: ${keyword}, 包含: ${voiceText.includes(keyword)}`)
      if (voiceText.includes(keyword)) {
        console.log(`识别到场景关键词: ${keyword}`)
        this.controlScene(keyword)
        return true // 找到匹配的场景
      }
    }

    console.log(`没有找到匹配的命令`)
    return false // 没有找到匹配的命令
  }

  // ==================== 语音识别控制方法 ====================
  
  /**
   * 申请权限方法
   * 
   * 功能说明：
   * - 申请麦克风权限
   * - 检查当前权限状态
   * - 如果没有权限则主动申请
   */
  fn1 = async () => {
    // 准备好需要申请的权限 麦克风权限
    const permissions: Permissions[] = ["ohos.permission.MICROPHONE"]
    // 检查是否拥有权限
    const isPermission = PermissionManager.checkPermission(permissions)
    if (!isPermission) {
      // 如果没权限，就主动申请
      PermissionManager.requestPermission(permissions)
    }
  }

  /**
   * 实时语音识别方法
   * 
   * 功能说明：
   * - 启动实时语音识别
   * - 设置识别状态和模式
   * - 处理识别结果和命令
   */
  fn2 = () => {
    try {
      // 开始录音时立即更新状态
      this.statusText = "正在录音..."
      this.isRealtimeMode = true
      this.realtimeText = ""
      console.log("引擎状态:", SpeechRecognizerManager.isEngineAvailable() ? "可用" : "不可用")
      
      // 重启语音识别
      SpeechRecognizerManager.restartRecognition(res => {
        console.log("实时语音识别", JSON.stringify(res))
        if (res && res.result) {
          // 实时更新识别结果
          this.realtimeText = res.result
          this.text = res.result // 保存最终结果

          // 处理语音命令
          this.processVoiceCommand(res.result)
        }
      })
    } catch (error) {
      console.error("语音识别初始化失败:", error)
      this.statusText = "语音识别初始化失败"
      this.isRealtimeMode = false
      setTimeout(() => {
        this.statusText = "点击开始语音识别"
      }, 2000)
    }
  }

  /**
   * 停止语音识别方法
   * 
   * 功能说明：
   * - 停止实时语音识别
   * - 更新识别状态
   * - 保持引擎活跃状态
   */
  fn3 = () => {
    try {
      console.log("用户点击停止录音")
      this.isRealtimeMode = false
      this.statusText = "正在结束识别..."

      // 立即停止识别
      SpeechRecognizerManager.quickStopRecognition();
      console.info("快速停止语音识别");

      // 延迟显示完成状态，给系统时间处理
      setTimeout(() => {
        this.statusText = "识别完成！"
        setTimeout(() => {
          this.statusText = "点击开始语音识别"
        }, 1500) // 减少等待时间
      }, 500) // 给系统500ms处理时间

      // 不释放引擎，保持引擎活跃状态以便下次使用
    } catch (error) {
      console.error("停止语音识别失败:", error);
      this.statusText = "停止识别失败"
      setTimeout(() => {
        this.statusText = "点击开始语音识别"
      }, 2000)
    }
  }

  // ==================== 组件生命周期 ====================
  
  /**
   * 组件即将显示时的生命周期回调
   * 
   * 功能说明：
   * - 在组件显示前执行初始化操作
   * - 申请麦克风权限
   */
  aboutToAppear(): void {
    this.fn1()
    //console.log('litePagr')
  }

  /**
   * 组件即将消失时的生命周期回调
   * 
   * 功能说明：
   * - 在组件消失前执行清理操作
   * - 释放语音识别资源
   */
  aboutToDisappear(): void {
    // 页面销毁时释放语音识别资源
    try {
      SpeechRecognizerManager.release();
      console.info("页面销毁，释放语音识别资源");
    } catch (error) {
      console.error("释放语音识别资源失败:", error);
    }
  }

  // ==================== UI构建方法 ====================
  
  /**
   * 构建组件UI
   * 
   * 这是ArkUI组件的核心方法，用于定义页面的结构和样式
   * 主要构建语音识别组件、结果显示、控制反馈等区域
   */
  build() {
    // 创建导航目标容器
    NavDestination() {
      Scroll() {
        Column() {
          
          // ==================== 语音识别组件 ====================
          VoiceRecognitionComponent({
            statusText: this.statusText,
            onStartRecognition: this.fn2,
            onStopRecognition: this.fn3,
            onRecognitionResult: (result: string) => {
              this.text = result
            },
            onStatusChange: (status: string) => {
              this.statusText = status
            }
          })

          // ==================== 实时识别结果显示 ====================
          if (this.isRealtimeMode && this.realtimeText) {
            Column() {
              Text("实时识别：")
                .fontSize(16)                    // 设置字体大小为16像素
                .fontWeight(FontWeight.Medium)   // 设置字体粗细为中等
                .fontColor('#2C3E50')            // 设置字体颜色为深蓝色
                .margin({ bottom: 10 })           // 设置下边距为10像素

              Text(this.realtimeText)
                .fontSize(18)                    // 设置字体大小为18像素
                .fontColor('#E67E22')            // 设置字体颜色为橙色
                .textAlign(TextAlign.Center)     // 设置文本居中对齐
                .padding(15)                      // 设置内边距为15像素
                .backgroundColor('#FEF9E7')       // 设置背景色为浅橙色
                .borderRadius(12)                 // 设置圆角边框，半径为12像素
                .border({
                  width: 2,                      // 设置边框宽度为2像素
                  color: '#E67E22'               // 设置边框颜色为橙色
                })
                .width('90%')                    // 设置宽度为90%
                .animation({
                  duration: 200,                 // 设置动画持续时间为200ms
                  curve: Curve.EaseInOut         // 设置动画曲线为缓入缓出
                })
            }
            .width('100%')                       // 设置宽度为100%
            .margin({ top: 20 })                  // 设置上边距为20像素
          }

          // ==================== 场景控制结果显示 ====================
          if (this.sceneControlResult) {
            Column() {
              Text("场景控制：")
                .fontSize(16)                    // 设置字体大小为16像素
                .fontWeight(FontWeight.Medium)   // 设置字体粗细为中等
                .fontColor('#2C3E50')            // 设置字体颜色为深蓝色
                .margin({ bottom: 10 })           // 设置下边距为10像素

              Text(this.sceneControlResult)
                .fontSize(18)                    // 设置字体大小为18像素
                .fontColor('#8E44AD')            // 设置字体颜色为紫色
                .textAlign(TextAlign.Center)     // 设置文本居中对齐
                .padding(15)                      // 设置内边距为15像素
                .backgroundColor('#F4F0FF')      // 设置背景色为浅紫色
                .borderRadius(12)                 // 设置圆角边框，半径为12像素
                .border({
                  width: 2,                      // 设置边框宽度为2像素
                  color: '#8E44AD'               // 设置边框颜色为紫色
                })
                .width('90%')                    // 设置宽度为90%
                .animation({
                  duration: 200,                 // 设置动画持续时间为200ms
                  curve: Curve.EaseInOut         // 设置动画曲线为缓入缓出
                })
            }
            .width('100%')                       // 设置宽度为100%
            .margin({ top: 20 })                  // 设置上边距为20像素
          }

          // ==================== 最终识别结果显示 ====================
          if (this.text && !this.isRealtimeMode) {
            Column() {
              Row() {
                Text("语音识别结果：")
                  .fontSize(16)                    // 设置字体大小为16像素
                  .fontWeight(FontWeight.Medium)   // 设置字体粗细为中等
                  .fontColor('#2C3E50')            // 设置字体颜色为深蓝色
                  .layoutWeight(1)                 // 设置布局权重为1

                // 清空按钮
                Button("清空")
                  .fontSize(12)                    // 设置字体大小为12像素
                  .fontColor('#FF6B6B')            // 设置字体颜色为红色
                  .backgroundColor('#FFF5F5')      // 设置背景色为浅红色
                  .borderRadius(8)                 // 设置圆角边框，半径为8像素
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 }) // 设置内边距
                  .onClick(() => {
                    // 清空按钮点击事件处理
                    this.text = ""
                    this.realtimeText = ""
                    this.sceneControlResult = ""
                  })
              }
              .width('90%')                       // 设置宽度为90%
              .margin({ bottom: 10 })             // 设置下边距为10像素

              Text(this.text)
                .fontSize(18)                    // 设置字体大小为18像素
                .fontColor('#27AE60')            // 设置字体颜色为绿色
                .textAlign(TextAlign.Center)     // 设置文本居中对齐
                .padding(15)                      // 设置内边距为15像素
                .backgroundColor('#F0F9FF')      // 设置背景色为浅蓝色
                .borderRadius(12)                 // 设置圆角边框，半径为12像素
                .border({
                  width: 2,                      // 设置边框宽度为2像素
                  color: '#27AE60'               // 设置边框颜色为绿色
                })
                .width('90%')                    // 设置宽度为90%
            }
            .width('100%')                       // 设置宽度为100%
            .margin({ top: 20 })                  // 设置上边距为20像素
          }
        }
        .width('100%')                           // 设置宽度为100%
        .padding({ left: 20, right: 20, bottom: 20 }) // 设置左右下内边距为20像素
      }
      .scrollable(ScrollDirection.Vertical)       // 设置垂直滚动
      .scrollBar(BarState.Auto)                   // 设置滚动条自动显示
      .scrollBarColor('#E0E0E0')                  // 设置滚动条颜色为浅灰色
      .scrollBarWidth(8)                          // 设置滚动条宽度为8像素
      .edgeEffect(EdgeEffect.Spring)              // 设置边缘效果为弹簧效果
      .width('100%')                              // 设置宽度为100%
      .height('100%')                             // 设置高度为100%
    }
    .onReady((context: NavDestinationContext) => {
      // 导航目标准备就绪时的回调函数
      this.pathStack = context.pathStack;
    })
    .backgroundColor('#F2F8FB')                  // 设置页面背景色为浅蓝色
  }
}