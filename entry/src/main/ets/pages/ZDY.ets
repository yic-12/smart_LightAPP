/**
 * 智能照明管理APP - 设备控制页面 (ZDY.ets)
 * 
 * 功能说明：
 * 1. 提供单个设备的开关控制功能
 * 2. 支持设备选择，通过按钮和滑块切换设备
 * 3. 提供批量控制功能（全部开启/全部关闭）
 * 4. 显示设备状态和当前选中设备信息
 * 5. 支持确认对话框防止误操作
 * 6. 使用5个设备接口控制全部25个设备
 * 
 * 技术特点：
 * - 使用HarmonyOS ArkUI框架
 * - 集成HTTP网络请求
 * - 使用AppStorageV2进行全局状态管理
 * - 响应式UI设计
 * - 多设备协同控制
 */

// 导入HarmonyOS ArkUI的AppStorageV2模块
import { AppStorageV2 } from "@kit.ArkUI";
// 导入数据模型
import { LightDevice, ColorRGB } from '../model/DataModel';
// 导入设备控制数据
import { deviceControls, turn } from '../utils/device'
// 导入HTTP工具类
import { HttpUtil } from "../inter/HttpUtil";

// ==================== 构建器函数 ====================

/**
 * ZDYBuilder构建器函数
 * 
 * @Builder装饰器：
 * - 用于创建可重用的UI构建函数
 * - 可以在多个地方调用，提高代码复用性
 * - 支持参数传递，实现动态UI构建
 * 
 * 功能说明：
 * - 用于在导航系统中创建ZDY组件实例
 * - 提供统一的ZDY组件创建入口
 */
@Builder
export function ZDYBuilder() {
  ZDY();
}

// ==================== 主组件定义 ====================

/**
 * ZDY组件 - 设备控制主组件
 * 
 * @Component装饰器：
 * - 标识这是一个ArkUI自定义组件
 * - 可以使用build()方法构建UI
 * 
 * 功能说明：
 * - 提供设备控制的完整功能
 * - 支持单个设备控制和批量控制
 * - 显示设备状态和操作反馈
 */
@Component
export struct ZDY {
  
  // ==================== 导航和网络配置 ====================
  
  /**
   * 导航路径栈
   * 
   * AppStorageV2.connect()说明：
   * - 将导航栈连接到应用级别的存储
   * - 确保导航状态在整个应用生命周期中保持
   * - 支持多页面间的状态共享
   */
  pathStack: NavPathStack = AppStorageV2.connect(NavPathStack, 'navStack', () => new NavPathStack())!;

  // ==================== 组件状态管理 ====================
  
  /**
   * 当前选中的设备ID
   * @State装饰器表示这是响应式状态变量
   */
  @State selectedDevice: string = ""
  
  /**
   * 设备列表数据
   * 从deviceControls导入的所有25个设备
   */
  @State deviceList: LightDevice[] = []
  
  /**
   * 设备列表数据（批量控制用）
   * 从turn导入的5个设备，用于控制全部25个设备
   */
  @State deviceList1: LightDevice[] = []
  
  /**
   * 设备开关状态映射
   * 存储所有25个设备的开关状态
   */
  @State deviceStatus: Map<string, boolean> = new Map()
  
  /**
   * 设备开关状态映射（批量控制用）
   * 存储5个控制设备的开关状态
   */
  @State deviceStatus1: Map<string, boolean> = new Map()

  // ==================== 网络接口配置 ====================
  
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
   * POST请求的API路径
   * 用于控制设备开关状态
   */
  url2: string = '/SmartHome/ShenDaRest/controlLight'

  // ==================== 默认控制参数 ====================
  
  /**
   * 默认亮度值
   * 范围：0-100，表示亮度百分比
   */
  defaultBrightness: number = 60
  
  /**
   * 默认色温值
   * 范围：0-100，表示色温百分比
   */
  defaultColorTemperature: number = 60
  
  /**
   * 默认颜色值
   * RGB格式的颜色值
   */
  defaultColor: ColorRGB = { r: 255, g: 255, b: 255 }

  // ==================== UI状态管理 ====================
  
  /**
   * 当前亮度值
   * 用于显示当前设备的亮度设置
   */
  @State currentBrightness: number = 60
  
  /**
   * 当前色温值
   * 用于显示当前设备的色温设置
   */
  @State currentColorTemperature: number = 60
  
  /**
   * 当前设备索引
   * 用于标识用户在设备列表中选择的设备位置
   */
  @State deviceIndex: number = 0
  
  /**
   * 显示批量控制确认对话框
   * true表示显示确认对话框
   */
  @State showBulkDialog: boolean = false
  
  /**
   * 批量控制动作
   * 'on'表示全部开启，'off'表示全部关闭
   */
  @State bulkAction: 'on' | 'off' = 'off'

  // ==================== 组件生命周期 ====================
  
  /**
   * 组件即将显示时的生命周期回调
   * 
   * 功能说明：
   * - 在组件显示前执行初始化操作
   * - 加载设备数据并初始化设备状态
   */
  aboutToAppear() {
    this.loadDevices()
  }

  // ==================== 数据加载方法 ====================
  
  /**
   * 加载设备列表
   * 
   * 功能说明：
   * - 从deviceControls和turn数组构建设备列表
   * - 初始化设备状态映射
   * - 设置默认选中的设备
   */
  async loadDevices() {
    // 从 deviceControls 构建设备列表（真实控制使用 HttpUtil）
    const now: string = new Date().toISOString()

    // ==================== 构建设备列表（25个设备） ====================
    this.deviceList = deviceControls.map((dc): LightDevice => ({
      deviceId: dc.control_sub_id,                    // 设备ID
      deviceName: dc.name ?? dc.control_sub_id,      // 设备名称
      type: dc.type_uuid,                            // 设备类型
      status: (dc.control_sub_state === '0'),        // 设备状态（'0'=开启，'1'=关闭）
      brightness: dc.w_channel ?? this.defaultBrightness,     // 亮度值
      color: this.defaultColor,                       // 颜色值
      colorTemperature: dc.y_channel ?? this.defaultColorTemperature, // 色温值
      lastUpdateTime: now                             // 最后更新时间
    } as LightDevice))
    
    // 初始化设备状态映射
    this.deviceList.forEach(d => this.deviceStatus.set(d.deviceId, d.status))
    
    // 设置默认选中的设备
    if (this.deviceList.length > 0) {
      this.deviceIndex = 0
      this.selectedDevice = this.deviceList[0].deviceId
      this.currentBrightness = this.deviceList[0].brightness
      this.currentColorTemperature = this.deviceList[0].colorTemperature
    }

    // ==================== 构建设备列表（5个控制设备） ====================
    this.deviceList1 = turn.map((dc): LightDevice => ({
      deviceId: dc.control_sub_id,                    // 设备ID
      deviceName: dc.name ?? dc.control_sub_id,      // 设备名称
      type: dc.type_uuid,                            // 设备类型
      status: (dc.control_sub_state === '0'),        // 设备状态
      brightness: dc.w_channel ?? this.defaultBrightness,     // 亮度值
      color: this.defaultColor,                       // 颜色值
      colorTemperature: dc.y_channel ?? this.defaultColorTemperature, // 色温值
      lastUpdateTime: now                             // 最后更新时间
    } as LightDevice))
    
    // 初始化控制设备状态映射
    this.deviceList1.forEach(d => this.deviceStatus1.set(d.deviceId, d.status))
    
    // 设置默认选中的控制设备
    if (this.deviceList1.length > 0) {
      this.deviceIndex = 0
      this.selectedDevice = this.deviceList1[0].deviceId
      this.currentBrightness = this.deviceList1[0].brightness
      this.currentColorTemperature = this.deviceList1[0].colorTemperature
    }
  }

  // ==================== 设备控制方法 ====================
  
  /**
   * 获取当前选中设备的开关状态
   * 
   * 功能说明：
   * - 从设备状态映射中获取当前选中设备的状态
   * - 如果设备不存在则返回false
   * 
   * 返回值：
   * - boolean - 设备开关状态，true表示开启，false表示关闭
   */
  getCurrentDeviceStatus(): boolean {
    return this.deviceStatus.get(this.selectedDevice) || false
  }

  /**
   * 选择设备方法
   * 
   * 功能说明：
   * - 更新当前选中的设备
   * - 同步更新设备索引和相关状态
   * 
   * 参数说明：
   * - deviceId: string - 要选择的设备ID
   */
  private onSelectDevice(deviceId: string) {
    this.selectedDevice = deviceId
    const idx = this.deviceList.findIndex(d => d.deviceId === deviceId)
    if (idx >= 0) {
      this.deviceIndex = idx
      const found = this.deviceList[idx]
      this.currentBrightness = found.brightness
      this.currentColorTemperature = found.colorTemperature
    }
  }

  // ==================== UI构建方法 ====================
  
  /**
   * 构建灯光控制页面UI
   * 
   * 这是ArkUI组件的核心方法，用于定义页面的结构和样式
   * 主要构建标题、设备选择、状态显示、控制按钮等区域
   * 使用NavDestination包装确保正确的导航行为
   */
  build() {
    // 创建导航目标容器
    NavDestination() {
      // 创建主列容器
      Column() {
        
        // ==================== 顶部导航栏 ====================
        Row() {
          // 居中的页面标题
          Text('灯光控制')
            .fontSize(20)                    // 设置字体大小为20像素
            .fontWeight(FontWeight.Bold)     // 设置字体粗细为粗体
            .fontColor('#2c2c2c')            // 设置字体颜色为深灰色
        }
        .width('100%')                       // 设置宽度为100%
        .justifyContent(FlexAlign.Center)    // 居中显示
        .margin({ bottom: 20 })              // 设置下边距为20像素

        // ==================== 设备选择区域 ====================
        Column() {
          // 区域标题
          Text('选择设备')
            .fontSize(16)                    // 设置字体大小为16像素
            .fontWeight(FontWeight.Medium)   // 设置字体粗细为中等
            .alignSelf(ItemAlign.Start)      // 左对齐
            .margin({ bottom: 10 })          // 设置下边距为10像素

          // 设备按钮列表
          // 顶部橙色设备导航已移除

          // ==================== 设备切换按钮 ====================
          // 设备切换：上一/下一
          Row() {
            // "上一设备"按钮
            Button('上一设备')
              .onClick(() => {
                // 检查设备列表是否为空
                if (this.deviceList.length === 0) { return }
                // 计算上一个设备的索引（支持循环）
                this.deviceIndex = (this.deviceIndex - 1 + this.deviceList.length) % this.deviceList.length
                // 选择上一个设备
                this.onSelectDevice(this.deviceList[this.deviceIndex].deviceId)
              })
            
            // 空白占位符
            Blank()
            
            // "下一设备"按钮
            Button('下一设备')
              .onClick(() => {
                // 检查设备列表是否为空
                if (this.deviceList.length === 0) { return }
                // 计算下一个设备的索引（支持循环）
                this.deviceIndex = (this.deviceIndex + 1) % this.deviceList.length
                // 选择下一个设备
                this.onSelectDevice(this.deviceList[this.deviceIndex].deviceId)
              })
          }
          .width('100%')                     // 设置宽度为100%
          .margin({ top: 12 })                // 设置上边距为12像素

          // ==================== 当前设备信息显示 ====================
          Row() {
            // 显示当前设备位置信息（如：当前设备: 1/25）
            Text(`当前设备: ${this.deviceIndex + 1}/${this.deviceList.length}`)
              .fontSize(14)                    // 设置字体大小为14像素
              .fontColor('#2c2c2c')            // 设置字体颜色为深灰色
            
            // 空白占位符
            Blank()
            
            // 显示当前设备的名称
            Text(this.deviceList[this.deviceIndex]?.deviceName ?? '未命名设备')
              .fontSize(16)                    // 设置字体大小为16像素
              .fontWeight(FontWeight.Medium)   // 设置字体粗细为中等
              .fontColor(Color.Gray)           // 设置字体颜色为灰色
          }
          .width('100%')                       // 设置宽度为100%
          .margin({ top: 8 })                  // 设置上边距为8像素

          // ==================== 设备选择滑块 ====================
          Row() {
            // 设备索引滑块，用于快速选择设备
            Slider({
              value: this.deviceIndex,                           // 当前值（设备索引）
              min: 0,                                           // 最小值
              max: Math.max(this.deviceList.length - 1, 0),    // 最大值（设备数量-1）
              step: 1,                                         // 步长（每次移动1个单位）
              style: SliderStyle.OutSet                         // 滑块样式（外置样式）
            })
              .onChange((idx: number) => {
                // 滑块值变化时的回调函数
                const i = Math.floor(idx)  // 将浮点数转换为整数
                // 检查索引是否在有效范围内
                if (i >= 0 && i < this.deviceList.length) {
                  this.deviceIndex = i                                    // 更新设备索引
                  this.onSelectDevice(this.deviceList[i].deviceId)       // 选择对应设备
                }
              })
          }
          .width('100%')                       // 设置宽度为100%
          .margin({ top: 8 })                  // 设置上边距为8像素
        }
        .width('100%')                         // 设置宽度为100%
        .padding(20)                           // 设置内边距为20像素
        .backgroundColor('#FFF')               // 白色背景卡片
        .borderRadius(20)                      // 设置圆角边框，半径为20像素
        .margin({ bottom: 20 })                 // 设置下边距为20像素

        // ==================== 设备状态显示区域 ====================
        Column() {
          // 区域标题
          Text('设备状态')
            .fontSize(16)                    // 设置字体大小为16像素
            .fontWeight(FontWeight.Medium)   // 设置字体粗细为中等
            .alignSelf(ItemAlign.Start)      // 左对齐
            .margin({ bottom: 15 })          // 设置下边距为15像素

          // ==================== 状态显示卡片 ====================
          Row() {
            // 状态图标
            Column() {
              if (this.getCurrentDeviceStatus()) {
                // 开启状态
                Text('💡')  // 灯泡图标
                  .fontSize(40)                    // 设置字体大小为40像素
                  .fontColor('#07C160')            // 设置字体颜色为绿色
              } else {
                // 关闭状态
                Text('🔌')  // 插头图标
                  .fontSize(40)                    // 设置字体大小为40像素
                  .fontColor('#999999')            // 设置字体颜色为灰色
              }
            }
            .width(80)                         // 设置宽度为80像素
            .justifyContent(FlexAlign.Center)   // 垂直居中对齐

            // 状态文本
            Column() {
              // 状态描述文本
              Text(this.getCurrentDeviceStatus() ? '灯光已开启' : '灯光已关闭')
                .fontSize(18)                    // 设置字体大小为18像素
                .fontWeight(FontWeight.Medium)   // 设置字体粗细为中等
                .fontColor('#2c2c2c')            // 设置字体颜色为深灰色
              
              // 状态详情文本
              Text(this.getCurrentDeviceStatus() ? '设备正在运行中' : '设备已关闭')
                .fontSize(14)                    // 设置字体大小为14像素
                .fontColor('#666666')            // 设置字体颜色为灰色
                .margin({ top: 5 })               // 设置上边距为5像素
            }
            .layoutWeight(1)                    // 设置布局权重为1
            .justifyContent(FlexAlign.Center)    // 垂直居中对齐
          }
          .width('100%')                         // 设置宽度为100%
          .padding(20)                           // 设置内边距为20像素
          .backgroundColor(this.getCurrentDeviceStatus() ? '#F0F9FF' : '#F5F5F5')  // 根据状态设置背景色
          .borderRadius(15)                      // 设置圆角边框，半径为15像素
        }
        .width('100%')                           // 设置宽度为100%
        .padding(20)                             // 设置内边距为20像素
        .backgroundColor(Color.White)             // 设置背景色为白色
        .borderRadius(20)                        // 设置圆角边框，半径为20像素
        .margin({ bottom: 20 })                   // 设置下边距为20像素

        // （滑块调节亮度/色温已按需求移除，仅保留设备选择滑块与开关控制）

        // ==================== 控制按钮区域 ====================
        Column() {
          // 区域标题
          Text('灯光控制')
            .fontSize(16)                    // 设置字体大小为16像素
            .fontWeight(FontWeight.Medium)   // 设置字体粗细为中等
            .alignSelf(ItemAlign.Start)      // 左对齐
            .margin({ bottom: 15 })          // 设置下边距为15像素

          // ==================== 单个设备控制按钮 ====================
          // 控制按钮
          Button(this.getCurrentDeviceStatus() ? '关闭灯光' : '开启灯光')
            .width('100%')                       // 设置宽度为100%
            .height(60)                          // 设置高度为60像素
            .fontSize(18)                        // 设置字体大小为18像素
            .fontWeight(FontWeight.Medium)       // 设置字体粗细为中等
            .fontColor(Color.White)              // 设置字体颜色为白色
            .backgroundColor(this.getCurrentDeviceStatus() ? '#FF6B6B' : '#07C160')  // 根据状态设置背景色
            .borderRadius(15)                    // 设置圆角边框，半径为15像素
            .onClick(() => {
              // 控制按钮点击事件处理
              if (this.getCurrentDeviceStatus()) {
                // 如果当前已开启，则关闭灯光
                this.turnOffLight()
              } else {
                // 如果当前已关闭，则开启灯光
                this.turnOnLight()
              }
            })

          // ==================== 批量控制按钮 ====================
          // 批量控制：全部开启 / 全部关闭（带确认弹窗）
          Row({ space: 12 }) {
            // "全部开启"按钮
            Button('全部开启')
              .layoutWeight(1)                   // 设置布局权重为1
              .height(50)                         // 设置高度为50像素
              .fontSize(16)                       // 设置字体大小为16像素
              .fontColor(Color.White)             // 设置字体颜色为白色
              .backgroundColor('#07C160')         // 设置背景色为绿色
              .borderRadius(12)                   // 设置圆角边框，半径为12像素
              .onClick(() => {
                // 全部开启按钮点击事件处理
                this.bulkAction = 'on'             // 设置批量动作为开启
                this.showBulkDialog = true         // 显示确认对话框
              })

            // "全部关闭"按钮
            Button('全部关闭')
              .layoutWeight(1)                   // 设置布局权重为1
              .height(50)                         // 设置高度为50像素
              .fontSize(16)                       // 设置字体大小为16像素
              .fontColor(Color.White)             // 设置字体颜色为白色
              .backgroundColor('#FF6B6B')          // 设置背景色为红色
              .borderRadius(12)                   // 设置圆角边框，半径为12像素
              .onClick(() => {
                // 全部关闭按钮点击事件处理
                this.bulkAction = 'off'            // 设置批量动作为关闭
                this.showBulkDialog = true        // 显示确认对话框
              })
          }
          .width('100%')                         // 设置宽度为100%
          .margin({ top: 12 })                   // 设置上边距为12像素
        }
        .width('100%')                           // 设置宽度为100%
        .padding(20)                             // 设置内边距为20像素
        .backgroundColor(Color.White)             // 设置背景色为白色
        .borderRadius(20)                        // 设置圆角边框，半径为20像素

      }
      .width('100%')                             // 设置宽度为100%
      .height('100%')                            // 设置高度为100%
      .padding(20)                               // 设置内边距为20像素
      
      // ==================== 批量控制确认对话框 ====================
      if (this.showBulkDialog) {
        Column() {
          Column() {
            // 对话框标题
            Text(this.bulkAction === 'on' ? '确认全部开启？' : '确认全部关闭？')
              .fontSize(18)                        // 设置字体大小为18像素
              .fontWeight(FontWeight.Bold)         // 设置字体粗细为粗体
              .fontColor('#2c2c2c')                // 设置字体颜色为深灰色
              .margin({ bottom: 12 })               // 设置下边距为12像素

            // 确认消息
            Text('请确认是否执行该批量操作')
              .fontSize(14)                        // 设置字体大小为14像素
              .fontColor('#666')                   // 设置字体颜色为灰色
              .textAlign(TextAlign.Center)         // 设置文本居中对齐
              .margin({ bottom: 18 })               // 设置下边距为18像素

            // ==================== 操作按钮 ====================
            Row({ space: 12 }) {
              // 取消按钮
              Button('取消')
                .layoutWeight(1)                   // 设置布局权重为1
                .height(42)                         // 设置高度为42像素
                .backgroundColor('#F0F0F0')         // 设置背景色为浅灰色
                .fontColor(Color.Black)              // 设置字体颜色为黑色
                .borderRadius(12)                   // 设置圆角边框，半径为12像素
                .onClick(() => {
                  // 取消按钮点击事件处理
                  this.showBulkDialog = false      // 关闭对话框
                })

              // 确认按钮
              Button('确认')
                .layoutWeight(1)                   // 设置布局权重为1
                .height(42)                         // 设置高度为42像素
                .backgroundColor('#e16531')         // 设置背景色为主题橙色
                .fontColor(Color.White)              // 设置字体颜色为白色
                .borderRadius(12)                   // 设置圆角边框，半径为12像素
                .onClick(async () => {
                  // 确认按钮点击事件处理
                  this.showBulkDialog = false      // 关闭对话框
                  if (this.bulkAction === 'on') {
                    // 如果选择开启，则执行全部开启
                    await this.turnOnAll()
                  } else {
                    // 如果选择关闭，则执行全部关闭
                    await this.turnOffAll()
                  }
                })
            }
          }
          .width('80%')                            // 设置对话框宽度为80%
          .padding(20)                             // 设置内边距为20像素
          .backgroundColor(Color.White)             // 设置背景色为白色
          .borderRadius(16)                        // 设置圆角边框，半径为16像素
          .shadow({ radius: 20, color: '#1A000000', offsetX: 0, offsetY: 5 })  // 添加阴影效果
        }
        .width('100%')                             // 设置宽度为100%
        .height('100%')                            // 设置高度为100%
        .justifyContent(FlexAlign.Center)          // 垂直居中对齐
        .backgroundColor('#80000000')               // 设置半透明黑色背景
        .position({ x: 0, y: 0 })                  // 覆盖整个页面
      }
    }
    .onReady((context: NavDestinationContext) => {
      // 导航目标准备就绪时的回调函数
      this.pathStack = context.pathStack;  // 获取导航栈上下文
    })
    .backgroundColor('#F2F8FB')                   // 页面背景色
  }

  // ==================== 设备控制方法 ====================
  
  /**
   * 打开选中设备的灯光
   * 
   * 功能说明：
   * - 调用HTTP工具类开启指定设备
   * - 更新本地设备状态
   * - 触发UI更新
   */
  private async turnOnLight() {
    try {
      // 真实接口：state '0' 表示打开
      await HttpUtil.getInstance().setLightBrightness(
        `${this.URL}${this.url2}`,
        this.defaultBrightness,
        this.defaultColorTemperature,
        '0',
        this.selectedDevice
      )
      // 更新本地状态
      this.deviceStatus.set(this.selectedDevice, true)
      // 触发UI更新
      this.deviceStatus = new Map(this.deviceStatus)
    } catch (error) {
      console.error('打开灯光失败:', error)
    }
  }

  /**
   * 关闭选中设备的灯光
   * 
   * 功能说明：
   * - 调用HTTP工具类关闭指定设备
   * - 更新本地设备状态
   * - 触发UI更新
   */
  private async turnOffLight() {
    try {
      // 真实接口：state '1' 表示关闭
      await HttpUtil.getInstance().setLightBrightness(
        `${this.URL}${this.url2}`,
        this.defaultBrightness,
        this.defaultColorTemperature,
        '1',
        this.selectedDevice
      )
      // 更新本地状态
      this.deviceStatus.set(this.selectedDevice, false)
      // 触发UI更新
      this.deviceStatus = new Map(this.deviceStatus)
    } catch (error) {
      console.error('关闭灯光失败:', error)
    }
  }

  /**
   * 批量开启所有设备
   * 
   * 功能说明：
   * - 使用5个设备接口控制全部25个设备
   * - 遍历控制设备列表，逐个开启设备
   * - 更新本地设备状态
   */
  private async turnOnAll() {
    try {
      // 遍历5个控制设备
      for (const d of this.deviceList1) {
        // 调用HTTP工具类开启设备
        await HttpUtil.getInstance().setLightBrightness(
          `${this.URL}${this.url2}`,
          this.defaultBrightness,
          this.defaultColorTemperature,
          '0',  // '0'表示开启
          d.deviceId
        )
        // 更新本地状态
        this.deviceStatus1.set(d.deviceId, true)
      }
      // 触发UI更新
      this.deviceStatus1 = new Map(this.deviceStatus1)
    } catch (e) {
      console.error('批量开启失败:', e)
    }
  }

  /**
   * 批量关闭所有设备
   * 
   * 功能说明：
   * - 使用5个设备接口控制全部25个设备
   * - 遍历控制设备列表，逐个关闭设备
   * - 更新本地设备状态
   */
  private async turnOffAll() {
    try {
      // 遍历5个控制设备
      for (const d of this.deviceList1) {
        // 调用HTTP工具类关闭设备
        await HttpUtil.getInstance().setLightBrightness(
          `${this.URL}${this.url2}`,
          this.defaultBrightness,
          this.defaultColorTemperature,
          '1',  // '1'表示关闭
          d.deviceId
        )
        // 更新本地状态
        this.deviceStatus1.set(d.deviceId, false)
      }
      // 触发UI更新
      this.deviceStatus1 = new Map(this.deviceStatus1)
    } catch (e) {
      console.error('批量关闭失败:', e)
    }
  }
}