/**
 * 智能照明管理APP - 设置页面 (WD.ets)
 * 
 * 功能说明：
 * 1. 提供设备选择功能，支持通过按钮和滑块切换设备
 * 2. 提供GET请求功能，用于查询设备状态
 * 3. 提供POST请求功能，用于控制设备开关
 * 4. 显示用户头像和用户名
 * 
 * 技术特点：
 * - 使用HarmonyOS ArkUI框架
 * - 支持HTTP网络请求
 * - 响应式UI设计
 * - 设备状态管理
 */

// 导入HarmonyOS网络请求模块
import { http } from "@kit.NetworkKit";
// 导入自定义的GET请求工具
import { httpGet } from "../inter/SmartHomeApi";
// 导入MD5加密工具，用于生成请求令牌
import { TokenGenerator } from "../inter/MD5";
// 导入数据模型接口
import { Data1, Data2, DeviceControlItem } from "../inter/Interface1";
// 导入HTTP工具类
import { HttpUtil } from "../inter/HttpUtil";
// 导入设备控制数据
import { deviceControls } from "../utils/device";

/**
 * WD组件 - 设置页面主组件
 * 
 * 这个组件是HarmonyOS ArkUI的自定义组件，用于构建设置页面
 * 主要功能包括设备选择、状态查询和设备控制
 */
@Component
export struct WD {
  
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
   * 请求时间戳
   * 用于生成唯一的请求标识，防止请求重复
   */
  timestamp: string = Date.now().toString()
  
  // ==================== 请求数据模型 ====================
  
  /**
   * GET请求的数据模型
   * 包含项目ID和时间戳信息
   */
  data1: Data1 = {
    project_id: '',      // 项目ID，用于标识具体的项目
    timestamp: ''        // 时间戳，用于请求验证
  }
  
  /**
   * POST请求的数据模型
   * 包含设备控制的所有参数
   */
  data2: Data2 = {
    timestamp: '',                    // 请求时间戳
    token: '',                         // 请求令牌，用于身份验证
    control_sub_id: '',                // 设备ID，标识要控制的设备
    control_sub_state: '0',           // 设备状态：'0'=开启，'1'=关闭
    r_channel: 200,                   // 红色通道值 (0-255)
    g_channel: 0,                     // 绿色通道值 (0-255)
    b_channel: 1,                     // 蓝色通道值 (0-255)
    w_channel: 100,                   // 白光通道值，控制亮度
    y_channel: 100,                   // 暖光通道值，控制色温
    control_state: '',                // 控制状态描述
    type_uuid: 'LIGHT_GROUP',         // 设备类型UUID
    lightness: 50,                     // 亮度值 (0-100)
  }
  
  // ==================== 组件状态管理 ====================
  
  /**
   * 设备列表
   * 从deviceControls导入的所有可用设备
   * @State装饰器表示这是响应式状态，数据变化时UI会自动更新
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

  // ==================== 组件生命周期 ====================
  
  /**
   * 组件即将显示时的生命周期回调
   * 在组件显示前执行初始化操作
   */
  aboutToAppear() {
    // 如果设备列表不为空且没有选中设备，则默认选择第一个设备
    if (this.devices.length > 0 && !this.selectedDeviceId) {
      this.deviceIndex = 0                                    // 设置设备索引为0
      this.selectedDeviceId = this.devices[0].control_sub_id  // 设置选中设备ID
      this.data2.control_sub_id = this.selectedDeviceId      // 同步到请求数据模型
    }
  }

  // ==================== UI构建方法 ====================
  
  /**
   * 构建组件UI
   * 这是ArkUI组件的核心方法，用于定义页面的结构和样式
   */
  build() {
    // 创建可滚动的容器，支持垂直滚动
    Scroll() {
      // 主列容器，包含页面的所有内容
      Column() {
        
        // ==================== 用户信息区域 ====================
        Column() {
          // 用户头像图片
          Image($r('app.media.touxiang'))  // 引用资源文件中的头像图片
            .width(50)                      // 设置图片宽度为50像素
            .fillColor(Color.Black)          // 设置图片填充颜色为黑色
          
          // 用户名显示
          Text('TOM')                       // 显示用户名
            .margin({ top: 20 })            // 设置上边距为20像素
            .fontSize(34)                  // 设置字体大小为34像素
            .fontColor('#2c2c2c')          // 设置字体颜色为深灰色
            .fontWeight(400)               // 设置字体粗细为400（正常）
        }
        .alignItems(HorizontalAlign.Center)  // 水平居中对齐
        .width('100%')                       // 设置宽度为100%
        .backgroundColor('#FFF')             // 设置背景色为白色
        .border({ radius: 20 })              // 设置圆角边框，半径为20像素
        .padding(10)                         // 设置内边距为10像素

        // ==================== 设备控制区域 ====================
        Column() {
          // 设备选择和控制面板
          Column() {
            
            // ==================== 设备切换按钮 ====================
            // 设备选择：上一/下一 + 索引滑块
            Row() {
              // "上一设备"按钮
              Button('上一设备')
                .onClick(() => {
                  // 检查设备列表是否为空
                  if (this.devices.length === 0) {
                    return  // 如果设备列表为空，直接返回
                  }
                  // 计算上一个设备的索引（支持循环）
                  this.deviceIndex = (this.deviceIndex - 1 + this.devices.length) % this.devices.length
                  // 更新选中的设备ID
                  this.selectedDeviceId = this.devices[this.deviceIndex].control_sub_id
                  // 同步到请求数据模型
                  this.data2.control_sub_id = this.selectedDeviceId
                })
              
              // 空白占位符，用于分隔两个按钮
              Blank()
              
              // "下一设备"按钮
              Button('下一设备')
                .onClick(() => {
                  // 检查设备列表是否为空
                  if (this.devices.length === 0) {
                    return  // 如果设备列表为空，直接返回
                  }
                  // 计算下一个设备的索引（支持循环）
                  this.deviceIndex = (this.deviceIndex + 1) % this.devices.length
                  // 更新选中的设备ID
                  this.selectedDeviceId = this.devices[this.deviceIndex].control_sub_id
                  // 同步到请求数据模型
                  this.data2.control_sub_id = this.selectedDeviceId
                })
            }
            .width('100%')        // 设置宽度为100%
            .margin({ bottom: 10 }) // 设置下边距为10像素

            // ==================== 设备信息显示 ====================
            Row() {
              // 显示当前设备位置信息（如：当前设备: 1/25）
              Text(`当前设备: ${this.deviceIndex + 1}/${this.devices.length}`)
                .fontSize(14)                    // 设置字体大小为14像素
                .fontColor('#2c2c2c')            // 设置字体颜色为深灰色
              
              // 空白占位符，用于分隔文本
              Blank()
              
              // 显示当前设备的名称
              Text(`${this.devices[this.deviceIndex]?.name ?? '未命名设备'}`)
                .fontSize(16)                    // 设置字体大小为16像素
                .fontWeight(FontWeight.Medium)   // 设置字体粗细为中等
                .fontColor(Color.Gray)            // 设置字体颜色为灰色
            }
            .width('100%')        // 设置宽度为100%
            .margin({ bottom: 8 }) // 设置下边距为8像素

            // ==================== 设备选择滑块 ====================
            Row() {
              // 设备索引滑块，用于快速选择设备
              Slider({
                value: this.deviceIndex,                           // 当前值（设备索引）
                min: 0,                                           // 最小值
                max: Math.max(this.devices.length - 1, 0),       // 最大值（设备数量-1）
                step: 1,                                          // 步长（每次移动1个单位）
                style: SliderStyle.OutSet                         // 滑块样式（外置样式）
              })
                .onChange((v: number) => {
                  // 滑块值变化时的回调函数
                  const i = Math.floor(v)  // 将浮点数转换为整数
                  // 检查索引是否在有效范围内
                  if (i >= 0 && i < this.devices.length) {
                    this.deviceIndex = i                                    // 更新设备索引
                    this.selectedDeviceId = this.devices[i].control_sub_id  // 更新选中设备ID
                    this.data2.control_sub_id = this.selectedDeviceId      // 同步到请求数据模型
                  }
                })
            }
            .width('100%')         // 设置宽度为100%
            .margin({ bottom: 12 }) // 设置下边距为12像素

            // ==================== GET请求按钮 ====================
            Button("GET(查询状态)")
              .fontSize(18)                    // 设置字体大小为18像素
              .fontWeight(FontWeight.Bold)     // 设置字体粗细为粗体
              .fontColor(Color.Blue)            // 设置字体颜色为蓝色
              .onClick(async () => {
                // 异步点击事件处理函数
                try {
                  // 生成新的时间戳
                  this.timestamp = Date.now().toString()
                  // 生成MD5加密的请求令牌
                  const token: string = (await TokenGenerator.generateToken(this.timestamp)).toLowerCase()
                  // 发送GET请求查询设备状态
                  httpGet(`${this.URL}${this.url1}/${this.timestamp}/${token}`, http.RequestMethod.GET, this.data1)
                  
                  // 在控制台输出请求信息，便于调试
                  console.log(`请求GET  ${this.URL}${this.url1}/${this.timestamp}/${token}`)
                } catch (error) {
                  // 捕获并处理请求错误
                  console.error('GET 请求失败:', error)
                }
              })
              .margin({ bottom: 12 }) // 设置下边距为12像素

            // ==================== POST请求按钮 ====================
            Button("POST(控制设备)")
              .fontSize(18)                    // 设置字体大小为18像素
              .fontWeight(FontWeight.Bold)     // 设置字体粗细为粗体
              .fontColor(Color.Blue)            // 设置字体颜色为蓝色
              .onClick(async () => {
                // 异步点击事件处理函数
                try {
                  // 设置设备控制参数
                  // 优先使用当前选中的设备ID，如果没有则使用默认值
                  this.data2.control_sub_id =
                    this.selectedDeviceId || this.data2.control_sub_id || '6b3f2977496844fd879845645099c5dd'
                  // 设置设备状态（'1'表示关闭，'0'表示开启）
                  this.data2.control_sub_state = this.data2.control_sub_state || '1'
                  // 设置设备类型
                  this.data2.type_uuid = this.data2.type_uuid || 'LIGHT_GROUP'

                  // 发送POST请求控制设备
                  await HttpUtil.getInstance().setLightBrightness(
                    `${this.URL}${this.url2}`,           // 请求URL
                    this.data2.w_channel ?? 100,        // 白光通道值（亮度）
                    this.data2.y_channel ?? 100,        // 暖光通道值（色温）
                    this.data2.control_sub_state,       // 设备状态
                    this.data2.control_sub_id            // 设备ID
                  )

                  // 在控制台输出请求信息，便于调试
                  console.log(`请求POST  ${this.URL}${this.url2}`)
                } catch (error) {
                  // 捕获并处理请求错误
                  console.error('POST 请求失败:', error)
                }
              })
          }
          .width('100%')           // 设置宽度为100%
          .padding(16)             // 设置内边距为16像素
          .backgroundColor('#FFF')  // 设置背景色为白色
          .border({ radius: 20 })  // 设置圆角边框，半径为20像素
          .margin({ top: 20 })      // 设置上边距为20像素

        }
        .width('100%')              // 设置宽度为100%
        .padding({
          left: 10,                 // 设置左边距为10像素
          right: 10,                // 设置右边距为10像素
          top: 5,                   // 设置上边距为5像素
          bottom: 5                  // 设置下边距为5像素
        })
      }
    }
    .scrollable(ScrollDirection.Vertical)  // 设置垂直滚动
    .scrollBar(BarState.Auto)               // 设置滚动条自动显示
    .scrollBarColor('#E0E0E0')              // 设置滚动条颜色为浅灰色
    .scrollBarWidth(8)                      // 设置滚动条宽度为8像素
    .edgeEffect(EdgeEffect.Spring)           // 设置边缘效果为弹簧效果
    .width('100%')                          // 设置宽度为100%
    .height('100%')                         // 设置高度为100%
  }
}