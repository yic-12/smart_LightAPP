/**
 * 智能照明管理APP - 色温调节页面 (SW.ets)
 * 
 * 功能说明：
 * 1. 提供单个设备的亮度和色温调节功能
 * 2. 支持设备选择，通过按钮和滑块切换设备
 * 3. 提供自动调节功能，根据时间段自动调整灯光参数
 * 4. 支持设置记忆功能，保存用户的亮度、色温和自动调节状态
 * 5. 使用5个设备接口控制全部25个设备的自动调节
 * 
 * 技术特点：
 * - 使用HarmonyOS ArkUI框架
 * - 集成HTTP网络请求
 * - 使用PreferencesUtil进行本地存储
 * - 定时器实现自动调节
 * - 响应式UI设计
 * - 多设备协同控制
 */

// 导入数据模型接口
import { Data1, Data2, DeviceControlItem } from "../inter/Interface1";
// 导入HTTP工具类
import { HttpUtil } from "../inter/HttpUtil";
// 导入本地存储工具
import { PreferencesUtil, DeviceSettings } from "../inter/PreferencesUtil"
// 导入应用入口类
import EntryAbility from "../entryability/EntryAbility"
// 导入HarmonyOS上下文
import { Context } from '@kit.AbilityKit'
// 导入设备控制数据
import { deviceControls, turn } from "../utils/device"

// ==================== 构建器函数 ====================

/**
 * SWBuilder构建器函数
 * 
 * @Builder装饰器：
 * - 用于创建可重用的UI构建函数
 * - 可以在多个地方调用，提高代码复用性
 * - 支持参数传递，实现动态UI构建
 * 
 * 功能说明：
 * - 用于在导航系统中创建SW组件实例
 * - 提供统一的SW组件创建入口
 */
@Builder
export function SWBuilder() {
  SW();
}

// ==================== 主组件定义 ====================

/**
 * SW组件 - 色温调节主组件
 * 
 * @Entry装饰器：
 * - 标识这是应用的入口组件之一
 * - 可以与Index组件配合使用
 * 
 * @Component装饰器：
 * - 标识这是一个ArkUI自定义组件
 * - 可以使用build()方法构建UI
 * 
 * 功能说明：
 * - 提供色温和亮度调节功能
 * - 支持自动调节和手动调节
 * - 支持设置记忆功能
 */
@Entry
@Component
struct SW {
  
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

  // ==================== 请求数据模型 ====================
  
  /**
   * GET请求的数据模型
   * 
   * @State装饰器：
   * - 标识这是响应式状态变量
   * - 当值发生变化时，UI会自动重新渲染
   */
  @State data1: Data1 = {
    project_id: '',    // 项目ID，用于标识具体的项目
    timestamp: ''      // 时间戳，用于请求验证
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
    timestamp: '',                    // 请求时间戳，用于认证和防重放
    token: '',                        // 认证令牌，基于时间戳和密钥生成
    control_sub_id: '',               // 控制的子设备ID（目标灯光设备ID）
    control_sub_state: '0',           // 设备控制状态：'0'=打开，'1'=关闭
    r_channel: 200,                   // 红色通道值，可选参数
    g_channel: 0,                     // 绿色通道值，可选参数
    b_channel: 1,                     // 蓝色通道值，可选参数
    w_channel: 100,                   // 白光通道值（亮度控制），可选参数
    y_channel: 100,                   // 黄光通道值（色温控制），可选参数
    control_state: '',                // 控制状态，可选参数
    type_uuid: 'LIGHT_GROUP',         // 设备类型UUID
    lightness: 50,                    // 亮度值，可选参数（与w_channel可能重复，取决于API设计）
  }

  // ==================== 组件状态管理 ====================
  
  /**
   * 设备列表
   * 从deviceControls导入的所有可用设备
   */
  @State devices: DeviceControlItem[] = deviceControls
  
  /**
   * 当前选中的设备索引
   * 用于标识用户在设备列表中选择的设备位置
   */
  @State deviceIndex: number = 0
  
  /**
   * 当前选中设备的ID
   * 用于网络请求时指定要操作的设备
   */
  @State selectedDeviceId: string = ''
  
  /**
   * 当前亮度值
   * 范围：0-100，表示亮度百分比
   */
  @State currentBrightness: number = 50
  
  /**
   * 当前色温值
   * 范围：0-100，表示色温百分比
   */
  @State currentColorTemperature: number = 50
  
  /**
   * 设备开关状态
   * '0'表示开启，'1'表示关闭
   */
  @State turn: '1' | '0' = '1'
  
  /**
   * 自动调节开关状态
   * true表示开启自动调节，false表示关闭
   */
  @State autoAdjustEnabled: boolean = false
  
  /**
   * 自动调节定时器ID
   * 用于管理自动调节的定时器
   */
  autoAdjustTimerId?: number

  /**
   * 自动调节控制的设备列表
   * 使用turn数组中的5个设备控制全部25个设备
   * 这是自动调节功能的核心设备组
   */
  @State autoAdjustDevices: DeviceControlItem[] = turn

  // ==================== 业务方法 ====================
  
  /**
   * 设置设备亮度方法
   * 
   * 功能说明：
   * - 调用HTTP工具类设置指定设备的亮度
   * - 用于手动调节时的设备亮度控制
   * 
   * 参数说明：
   * - value1: number - 亮度值
   * - value2: number - 色温值
   * - id: string - 设备ID
   */
  async setBrightness(value1: number, value2: number, id: string) {
    // 始终以当前选中设备的ID进行控制
    const targetId = id || this.selectedDeviceId || this.data2.control_sub_id
    // 调用HTTP工具类设置设备亮度
    await HttpUtil.getInstance().setLightBrightness(`${this.URL}${this.url2}`, value1, value2, this.data2.control_sub_state || '0', targetId)
  }

  /**
   * 自动调节多设备控制方法
   * 
   * 功能说明：
   * - 使用5个设备接口控制全部25个设备
   * - 这是自动调节功能的核心方法
   * - 支持批量设备控制，提高效率
   * 
   * 参数说明：
   * - brightness: number - 目标亮度值
   * - colorTemp: number - 目标色温值
   * - state: string - 设备状态，默认为'0'（开启）
   */
  async setAutoAdjustMultiDeviceBrightness(brightness: number, colorTemp: number, state: string = '0') {
    try {
      // 在控制台输出自动调节开始信息
      console.log(`自动调节多设备控制开始，设备数量: ${this.autoAdjustDevices.length}`)
      console.log(`目标亮度: ${brightness}%, 色温: ${colorTemp}%`)

      // 遍历自动调节设备列表，逐个控制设备
      for (const device of this.autoAdjustDevices) {
        console.log(`自动调节控制设备: ${device.name} (${device.control_sub_id})`)
        // 调用HTTP工具类设置设备亮度
        await HttpUtil.getInstance().setLightBrightness(
          `${this.URL}${this.url2}`,
          brightness,
          colorTemp,
          state,
          device.control_sub_id
        )
        console.log(`设备 ${device.name} 自动调节成功`)
      }

      console.log(`自动调节多设备控制完成，共处理 ${this.autoAdjustDevices.length} 个设备`)
    } catch (error) {
      console.error('自动调节多设备控制失败:', error)
    }
  }

  // ==================== UI构建方法 ====================
  
  /**
   * 构建组件UI
   * 
   * 这是ArkUI组件的核心方法，用于定义页面的结构和样式
   * 主要构建标题、设备选择、亮度调节、色温调节等区域
   */
  build() {
    // 创建导航目标容器
    NavDestination() {
      // 创建主列容器
      Column() {
        
        // ==================== 标题区域 ====================
        // 标题区域 - 居中显示在最上方
        Text("色温调节")
          .fontSize(23)                    // 设置字体大小为23像素
          .fontWeight(FontWeight.Bold)     // 设置字体粗细为粗体
          .fontColor(Color.Blue)           // 设置字体颜色为蓝色
          .textAlign(TextAlign.Center)      // 设置文本居中对齐
          .width('100%')                   // 设置宽度为100%
          .margin({ top: 10, bottom: 20 }) // 设置上下边距

        // ==================== 设备选择与显示区域 ====================
        Column() {
          
          // ==================== 自动调节控制按钮 ====================
          // 自动调节控制按钮 - 移动到设备滑动块上方
          Row({ space: 12 }) {
            // 自动调节状态显示文本
            Text(this.autoAdjustEnabled ? '自动调节已开启' : '自动调节已关闭')
              .fontSize(14)                                                    // 设置字体大小为14像素
              .fontColor(this.autoAdjustEnabled ? Color.Green : '#666666')     // 根据状态设置颜色
            
            // 空白占位符
            Blank()
            
            // 自动调节开关按钮
            Button(this.autoAdjustEnabled ? '关闭自动调节' : '开启自动调节')
              .fontSize(16)                    // 设置字体大小为16像素
              .fontWeight(FontWeight.Medium)   // 设置字体粗细为中等
              .onClick(() => {
                // 自动调节按钮点击事件处理
                if (this.autoAdjustEnabled) {
                  // 如果当前已开启，则关闭自动调节
                  this.stopAutoAdjust()
                } else {
                  // 如果当前已关闭，则开启自动调节
                  this.startAutoAdjust()
                }
                
                // 保存自动调节状态到本地存储
                const ctx: Context = EntryAbility.appContext
                if (ctx) {
                  PreferencesUtil.saveSettings(ctx, {
                    brightness: this.currentBrightness,
                    colorTemperature: this.currentColorTemperature,
                    autoAdjustEnabled: this.autoAdjustEnabled
                  })
                }
              })
          }
          .width('100%')           // 设置宽度为100%
          .padding(16)             // 设置内边距为16像素
          .backgroundColor(Color.White) // 设置背景色为白色
          .borderRadius(20)         // 设置圆角边框，半径为20像素
          .margin({ bottom: 20 })   // 设置下边距为20像素

          // ==================== 设备切换按钮 ====================
          Row() {
            // "上一设备"按钮
            Button("上一设备")
              .onClick(() => {
                // 检查设备列表是否为空
                if (this.devices.length === 0) { return }
                // 计算上一个设备的索引（支持循环）
                this.deviceIndex = (this.deviceIndex - 1 + this.devices.length) % this.devices.length
                // 更新选中的设备ID
                this.selectedDeviceId = this.devices[this.deviceIndex].control_sub_id
                // 同步到请求数据模型
                this.data2.control_sub_id = this.selectedDeviceId
                // 更新设备状态
                this.data2.control_sub_state = this.devices[this.deviceIndex].control_sub_state || '0'
              })
            
            // 空白占位符
            Blank()
            
            // "下一设备"按钮
            Button("下一设备")
              .onClick(() => {
                // 检查设备列表是否为空
                if (this.devices.length === 0) { return }
                // 计算下一个设备的索引（支持循环）
                this.deviceIndex = (this.deviceIndex + 1) % this.devices.length
                // 更新选中的设备ID
                this.selectedDeviceId = this.devices[this.deviceIndex].control_sub_id
                // 同步到请求数据模型
                this.data2.control_sub_id = this.selectedDeviceId
                // 更新设备状态
                this.data2.control_sub_state = this.devices[this.deviceIndex].control_sub_state || '0'
              })
          }
          .width('100%')           // 设置宽度为100%
          .margin({ bottom: 12 })  // 设置下边距为12像素

          // ==================== 设备信息显示 ====================
          Row() {
            // 显示当前设备位置信息（如：当前设备: 1/25）
            Text(`当前设备: ${this.deviceIndex + 1}/${this.devices.length}`)
              .fontSize(14)                    // 设置字体大小为14像素
              .fontColor('#2c2c2c')            // 设置字体颜色为深灰色
            
            // 空白占位符
            Blank()
            
            // 显示当前设备的名称
            Text(`${this.devices[this.deviceIndex]?.name ?? '未命名设备'}`)
              .fontSize(16)                    // 设置字体大小为16像素
              .fontWeight(FontWeight.Medium)   // 设置字体粗细为中等
              .fontColor(Color.Gray)           // 设置字体颜色为灰色
          }
          .width('100%')           // 设置宽度为100%
          .margin({ bottom: 16 })  // 设置下边距为16像素

          // ==================== 设备选择滑块 ====================
          // 滑块快速选择设备
          Row() {
            // 设备索引滑块，用于快速选择设备
            Slider({
              value: this.deviceIndex,                           // 当前值（设备索引）
              min: 0,                                           // 最小值
              max: Math.max(this.devices.length - 1, 0),       // 最大值（设备数量-1）
              step: 1,                                          // 步长（每次移动1个单位）
              style: SliderStyle.OutSet                         // 滑块样式（外置样式）
            })
              .onChange((idx: number) => {
                // 滑块值变化时的回调函数
                const i = Math.floor(idx)  // 将浮点数转换为整数
                // 检查索引是否在有效范围内
                if (i >= 0 && i < this.devices.length) {
                  this.deviceIndex = i                                    // 更新设备索引
                  this.selectedDeviceId = this.devices[i].control_sub_id // 更新选中设备ID
                  this.data2.control_sub_id = this.selectedDeviceId       // 同步到请求数据模型
                  this.data2.control_sub_state = this.devices[i].control_sub_state || '0' // 更新设备状态
                }
              })
          }
          .width('100%')           // 设置宽度为100%
          .margin({ bottom: 12 })  // 设置下边距为12像素
        }
        .margin({ bottom: 20 })    // 设置下边距为20像素

        // ==================== 亮度调节区域 ====================
        Column({ space: 20 }) {
          // 亮度调节标题和当前值显示
          Row() {
            Text('亮度调节')
              .fontSize(16)                    // 设置字体大小为16像素
              .fontWeight(FontWeight.Medium)   // 设置字体粗细为中等
              .fontColor('#2c2c2c')            // 设置字体颜色为深灰色
            
            Blank()  // 占位空间
            
            // 当前亮度百分比显示
            Text(this.currentBrightness + '%')
              .fontSize(16)                    // 设置字体大小为16像素
              .fontColor('#2c2c2c')            // 设置字体颜色为深灰色
          }
          .width('100%')                       // 设置宽度为100%
          
          // 亮度调节滑块
          Slider({
            value: this.currentBrightness,      // 当前亮度值
            min: 0,                            // 最小值 0%
            max: 100,                          // 最大值 100%
            step: 1,                           // 步长 1%
            style: SliderStyle.OutSet          // 外凸样式
          })
            .onChange(async (value1: number) => {
              // 亮度调节滑块值变化时的回调函数
              this.currentBrightness = value1  // 更新亮度值
              
              // 设置设备控制参数
              this.data2.control_sub_id = this.data2.control_sub_id || '6b3f2977496844fd879845645099c5dd';
              // 控制类型：0=打开，1=关闭；若未设置，默认打开
              this.data2.control_sub_state = this.data2.control_sub_state || '1';
              // 灯类型必填：LIGHT_GROUP
              this.data2.type_uuid = this.data2.type_uuid || 'LIGHT_GROUP';
              
              // 调用设置亮度方法
              this.setBrightness(this.currentBrightness, this.currentColorTemperature, this.selectedDeviceId)
              
              // 在控制台输出调试信息
              console.log(`请求GET `)
              
              // 保存设置到本地存储
              const ctx: Context = EntryAbility.appContext
              if (ctx) {
                PreferencesUtil.saveSettings(ctx, { 
                  brightness: this.currentBrightness, 
                  colorTemperature: this.currentColorTemperature 
                })
              }
            })
        }
        .width('100%')                         // 设置宽度为100%
        .padding(20)                           // 设置内边距为20像素
        .backgroundColor(Color.White)           // 设置背景色为白色
        .border({ radius: 20 })                // 设置圆角边框，半径为20像素
        .margin({ bottom: 40 })                 // 设置下边距为40像素

        // ==================== 色温调节区域 ====================
        Column({ space: 20 }) {
          // 色温调节标题和当前值显示
          Row() {
            Text('色温调节')
              .fontSize(16)                    // 设置字体大小为16像素
              .fontWeight(FontWeight.Medium)   // 设置字体粗细为中等
              .fontColor('#2c2c2c')            // 设置字体颜色为深灰色
            
            Blank()  // 占位空间
            
            // 当前色温百分比显示
            Text(this.currentColorTemperature + '%')
              .fontSize(16)                    // 设置字体大小为16像素
              .fontColor('#2c2c2c')            // 设置字体颜色为深灰色
          }
          .width('100%')                       // 设置宽度为100%
          
          // 色温调节滑块
          Slider({
            value: this.currentColorTemperature, // 当前色温值
            min: 0,                            // 最小值 0%
            max: 100,                          // 最大值 100%
            step: 1,                           // 步长 1%
            style: SliderStyle.OutSet         // 外凸样式
          })
            .onChange(async (value2: number) => {
              // 色温调节滑块值变化时的回调函数
              this.currentColorTemperature = value2 // 更新色温值
              
              // 设置设备控制参数
              this.data2.control_sub_id = this.data2.control_sub_id || '6b3f2977496844fd879845645099c5dd';
              // 控制类型：0=打开，1=关闭；若未设置，默认打开
              this.data2.control_sub_state = this.data2.control_sub_state || '1';
              // 灯类型必填：LIGHT_GROUP
              this.data2.type_uuid = this.data2.type_uuid || 'LIGHT_GROUP';
              
              // 调用设置亮度方法
              this.setBrightness(this.currentBrightness, this.currentColorTemperature, this.selectedDeviceId)
              
              // 在控制台输出调试信息
              console.log(`请求GET `)
              
              // 保存设置到本地存储
              const ctx: Context = EntryAbility.appContext
              if (ctx) {
                PreferencesUtil.saveSettings(ctx, { 
                  brightness: this.currentBrightness, 
                  colorTemperature: this.currentColorTemperature 
                })
              }
            })
        }
        .width('100%')                         // 设置宽度为100%
        .padding(20)                           // 设置内边距为20像素
        .backgroundColor(Color.White)           // 设置背景色为白色
        .border({ radius: 20 })                 // 设置圆角边框，半径为20像素
        .margin({ top: 40 })                    // 设置上边距为40像素

        // 控制按钮区域（已迁移到 Setting 面板，此处移除 GET/POST 按钮）
      }
      .width('100%')                           // 设置宽度为100%
      .padding(20)                             // 设置内边距为20像素
      .borderRadius(20)                        // 设置圆角边框，半径为20像素
      .margin({ bottom: 20 })                   // 设置下边距为20像素

    }
    .backgroundColor('#F2F8FB')                 // 设置页面背景色为浅蓝色
    .onReady((context: NavDestinationContext) => {
      // 导航目标准备就绪时的回调函数
      this.pathStack = context.pathStack;
      
      // 加载已保存的亮度、色温和自动调节状态
      const ctx: Context = EntryAbility.appContext;
      if (ctx) {
        const settings: DeviceSettings = PreferencesUtil.loadSettings(ctx);
        this.currentBrightness = settings.brightness;
        this.currentColorTemperature = settings.colorTemperature;
        // 恢复自动调节状态
        if (settings.autoAdjustEnabled !== undefined) {
          this.autoAdjustEnabled = settings.autoAdjustEnabled;
          if (this.autoAdjustEnabled) {
            this.startAutoAdjust();
          }
        }
      }
      
      // 初始化设备选中状态
      if (this.devices.length > 0) {
        this.deviceIndex = 0
        this.selectedDeviceId = this.devices[0].control_sub_id
        this.data2.control_sub_id = this.selectedDeviceId
        this.data2.control_sub_state = this.devices[0].control_sub_state || '0'
      }
    })
    .onAppear(() => {
      // 页面出现时确保状态与存储同步
      const ctx: Context = EntryAbility.appContext;
      if (ctx) {
        const settings: DeviceSettings = PreferencesUtil.loadSettings(ctx);
        this.currentBrightness = settings.brightness;
        this.currentColorTemperature = settings.colorTemperature;
        // 恢复自动调节状态
        if (settings.autoAdjustEnabled !== undefined) {
          this.autoAdjustEnabled = settings.autoAdjustEnabled;
          if (this.autoAdjustEnabled) {
            this.startAutoAdjust();
          }
        }
      }
      
      // 确保设备选中状态正确
      if (!this.selectedDeviceId && this.devices.length > 0) {
        this.selectedDeviceId = this.devices[this.deviceIndex]?.control_sub_id || ''
        this.data2.control_sub_id = this.selectedDeviceId
      }
    })
    .onDisAppear(() => {
      // 页面消失时停止自动调节
      this.stopAutoAdjust()
    })
  }

  // ==================== 自动调节方法 ====================
  
  /**
   * 开启自动调节方法
   * 
   * 功能说明：
   * - 立即应用一次当前时间段的设置
   * - 启动定时器，每5分钟检查一次时间变化
   * - 根据时间段自动调整灯光参数
   */
  startAutoAdjust() {
    this.autoAdjustEnabled = true
    this.applyAutoSettings()
    // 每5分钟检查一次
    this.autoAdjustTimerId = setInterval(() => {
      if (this.autoAdjustEnabled) {
        this.applyAutoSettings()
      }
    }, 5 * 60 * 1000) as number
  }

  /**
   * 关闭自动调节方法
   * 
   * 功能说明：
   * - 停止自动调节功能
   * - 清理定时器，释放资源
   * - 防止内存泄漏
   */
  stopAutoAdjust() {
    this.autoAdjustEnabled = false
    if (this.autoAdjustTimerId !== undefined) {
      clearInterval(this.autoAdjustTimerId as number)
      this.autoAdjustTimerId = undefined
    }
  }

  /**
   * 根据当前时间计算并应用灯光参数
   * 
   * 功能说明：
   * - 根据当前时间自动计算合适的灯光参数
   * - 支持6个时间段的不同照明策略
   * - 使用5个设备接口控制全部25个设备
   * 
   * 时间段策略：
   * - 05:30-07:00 黎明：开灯，亮度50，色温30 (暖光唤醒)
   * - 07:00-09:00 早晨：开灯，亮度80，色温50 (活力开启)
   * - 09:00-17:00 白天：开灯，亮度90，色温60 (工作照明)
   * - 17:00-19:00 傍晚：开灯，亮度70，色温45 (舒适过渡)
   * - 19:00-22:00 晚上：开灯，亮度60，色温35 (休闲时光)
   * - 22:00-05:30 夜间：开灯，亮度30，色温20 (护眼模式)
   */
  async applyAutoSettings() {
    const now = new Date()
    const hours = now.getHours()
    const minutes = now.getMinutes()
    const currentTime = hours * 60 + minutes // 转换为分钟数，便于精确计算

    // 优化后的时间段策略：
    // 05:30-07:00 黎明：开灯，亮度50，色温30 (暖光唤醒)
    // 07:00-09:00 早晨：开灯，亮度80，色温50 (活力开启)
    // 09:00-17:00 白天：开灯，亮度90，色温60 (工作照明)
    // 17:00-19:00 傍晚：开灯，亮度70，色温45 (舒适过渡)
    // 19:00-22:00 晚上：开灯，亮度60，色温35 (休闲时光)
    // 22:00-05:30 夜间：开灯，亮度30，色温20 (护眼模式)

    let state: '0' | '1' = '0' // 默认开启
    let brightness = 0
    let colorTemp = 0
    let timeSlotName = ''

    if (currentTime >= 330 || currentTime < 330) { // 22:00-05:30 (22*60=1320, 5*60+30=330)
      // 夜间模式
      timeSlotName = '夜间模式'
      brightness = 30
      colorTemp = 20
    } else if (currentTime >= 330 && currentTime < 420) { // 05:30-07:00
      // 黎明模式
      timeSlotName = '黎明模式'
      brightness = 50
      colorTemp = 30
    } else if (currentTime >= 420 && currentTime < 540) { // 07:00-09:00
      // 早晨模式
      timeSlotName = '早晨模式'
      brightness = 80
      colorTemp = 50
    } else if (currentTime >= 540 && currentTime < 1020) { // 09:00-17:00
      // 白天模式
      timeSlotName = '白天模式'
      brightness = 90
      colorTemp = 60
    } else if (currentTime >= 1020 && currentTime < 1140) { // 17:00-19:00
      // 傍晚模式
      timeSlotName = '傍晚模式'
      brightness = 70
      colorTemp = 45
    } else if (currentTime >= 1140 && currentTime < 1320) { // 19:00-22:00
      // 晚上模式
      timeSlotName = '晚上模式'
      brightness = 60
      colorTemp = 35
    } else {
      // 默认白天模式
      timeSlotName = '默认模式'
      brightness = 90
      colorTemp = 60
    }

    // 更新本地状态
    this.currentBrightness = brightness
    this.currentColorTemperature = colorTemp
    this.data2.control_sub_state = state

    // 使用多设备控制（5个设备控制全部25个设备）
    console.log(`自动调节: ${timeSlotName} (${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}), 亮度 ${brightness}%, 色温 ${colorTemp}%`)
    await this.setAutoAdjustMultiDeviceBrightness(brightness, colorTemp, state)

    // 保存设置
    const ctx: Context = EntryAbility.appContext
    if (ctx) {
      PreferencesUtil.saveSettings(ctx, {
        brightness: this.currentBrightness,
        colorTemperature: this.currentColorTemperature,
        autoAdjustEnabled: this.autoAdjustEnabled
      })
    }
  }
}