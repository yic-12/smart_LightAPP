/**
 * 智能照明管理APP - 首页 (SOUY.ets)
 * 
 * 功能说明：
 * 1. 显示欢迎信息和当前日期
 * 2. 提供场景模式控制（教学、实操、会议、休息）
 * 3. 提供设备功能入口（色温调节、定时功能、语音控制、设备控制）
 * 4. 支持场景的开启/关闭切换
 * 5. 支持页面导航跳转
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
// 导入数据模型接口
import { SceneClass, scenceRgb, DeviceControlItem } from "../inter/Interface1";
// 导入HTTP工具类
import { HttpUtil } from "../inter/HttpUtil";
// 导入设备控制数据
import { deviceClass, exper, per, break1 } from "../utils/device";

// ==================== 工具函数 ====================

/**
 * 格式化日期函数
 * 
 * 功能说明：
 * - 将Date对象格式化为 "Dec 5, 2019" 格式的字符串
 * - 用于在首页显示当前日期
 * 
 * 参数说明：
 * - date?: Date - 可选的日期对象，如果不传入则使用当前日期
 * 
 * 返回值：
 * - string - 格式化后的日期字符串
 * 
 * 示例：
 * - formatDate() -> "Dec 5, 2024"
 * - formatDate(new Date(2019, 11, 5)) -> "Dec 5, 2019"
 */
function formatDate(date?: Date): string {
  // 如果未传入日期，默认使用当前日期
  const targetDate = date ? date : new Date();

  // 月份缩写数组
  // 对应1-12月的英文缩写
  const monthAbbr = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  // 获取月份（0-11），对应到缩写数组
  const month = monthAbbr[targetDate.getMonth()];
  // 获取日期（1-31）
  const day = targetDate.getDate();
  // 获取年份（四位数）
  const year = targetDate.getFullYear();

  // 拼接成 "Dec 5, 2019" 格式
  return `${month} ${day}, ${year}`;
}

// ==================== 构建器函数 ====================

/**
 * SOUYBuilder构建器函数
 * 
 * @Builder装饰器：
 * - 用于创建可重用的UI构建函数
 * - 可以在多个地方调用，提高代码复用性
 * - 支持参数传递，实现动态UI构建
 * 
 * 功能说明：
 * - 用于在导航系统中创建SOUY组件实例
 * - 提供统一的SOUY组件创建入口
 */
@Builder
export function SOUYBuilder() {
  SOUY();
}

// ==================== 主组件定义 ====================

/**
 * SOUY组件 - 首页主组件
 * 
 * @Component装饰器：
 * - 标识这是一个ArkUI自定义组件
 * - 可以使用build()方法构建UI
 * 
 * 功能说明：
 * - 作为应用的主页，提供场景控制和功能入口
 * - 支持多设备协同控制
 * - 提供友好的用户界面
 */
@Component
export struct SOUY {
  
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

  // ==================== 组件状态管理 ====================
  
  /**
   * 场景模式数据
   * 
   * @State装饰器：
   * - 标识这是响应式状态变量
   * - 当值发生变化时，UI会自动重新渲染
   * 
   * 包含四种场景模式：
   * - 教学：适合学习和阅读的照明环境
   * - 实操：适合实践操作的照明环境
   * - 会议：适合会议讨论的照明环境
   * - 休息：适合休息放松的照明环境
   */
  @State scene: SceneClass[] = [
    { text: '教学', icon: $r('app.media.reading') },   // 教学场景
    { text: '实操', icon: $r('app.media.sleep') },     // 实操场景
    { text: '会议', icon: $r('app.media.chat') },       // 会议场景
    { text: '休息', icon: $r('app.media.watch') }      // 休息场景
  ]
  
  /**
   * 设备功能入口数据
   * 
   * 包含四个主要功能模块：
   * - 色温调节：调整灯光的色温和亮度
   * - 定时功能：设置定时开关灯
   * - 语音控制：通过语音控制灯光
   * - 设备控制：手动控制单个设备
   */
  @State devices: SceneClass[] = [
    { text: '色温调节', icon: $r('app.media.sewen') },     // 色温调节功能
    { text: '定时功能', icon: $r('app.media.dinshi') },     // 定时功能
    { text: '语音控制', icon: $r('app.media.yuying') },     // 语音控制功能
    { text: '设备控制', icon: $r('app.media.gexinghua') }   // 设备控制功能
  ]
  
  /**
   * 场景设备映射数据
   * 
   * 定义每个场景对应的设备列表：
   * - 教学场景：使用deviceClass设备组
   * - 实操场景：使用exper设备组
   * - 会议场景：使用per设备组
   * - 休息场景：使用break1设备组
   */
  @State scence1: scenceRgb[] = [
    { scence: '教学', device: deviceClass },  // 教学场景设备
    { scence: '实操', device: exper },        // 实操场景设备
    { scence: '会议', device: per },          // 会议场景设备
    { scence: '休息', device: break1 },       // 休息场景设备
  ]
  
  /**
   * 当前选中的场景索引
   * -1表示没有选中任何场景
   * 0-3分别对应教学、实操、会议、休息场景
   */
  @State currentIndex1: number = -1
  
  /**
   * 当前选中的设备功能索引
   * -1表示没有选中任何功能
   * 0-3分别对应色温调节、定时功能、语音控制、设备控制
   */
  @State currentIndex2: number = -1

  // ==================== 业务方法 ====================
  
  /**
   * 设置设备亮度方法
   * 
   * 功能说明：
   * - 调用HTTP工具类设置指定设备的亮度
   * - 用于场景控制时的设备亮度调节
   * 
   * 参数说明：
   * - value1: number - 亮度值
   * - value2: number - 色温值
   * - value3: string - 设备状态（'0'=开启，'1'=关闭）
   * - id: string - 设备ID
   */
  async setBrightness(value1: number, value2: number, value3: string, id: string) {
    // 调用HTTP工具类设置设备亮度
    await HttpUtil.getInstance().setLightBrightness(`${this.URL}${this.url2}`, value1, value2, value3, id)
    // 在控制台输出测试信息
    console.log('测试场景')
  }

  /**
   * 关闭当前场景的所有设备
   * 
   * 功能说明：
   * - 关闭当前激活场景的所有设备
   * - 在切换场景前调用，确保设备状态正确
   * - 避免多个场景同时开启造成冲突
   * 
   * 参数说明：
   * - sceneIndex: number - 要关闭的场景索引
   */
  async closeCurrentSceneDevices(sceneIndex: number) {
    // 获取当前场景的设备数据
    const sceneData = this.scence1[sceneIndex];
    
    // 构建设备关闭控制参数
    const mappedDevices: DeviceControlItem[] = []
    
    // 遍历场景设备，构建设备关闭参数
    for (let i = 0; i < sceneData.device.length; i++) {
      const d = sceneData.device[i]
      const item = {
        control_sub_id: d.control_sub_id,           // 设备ID
        control_sub_state: '1',                     // 设备状态：关闭
        r_channel: d.r_channel,                     // 红色通道值
        g_channel: d.g_channel,                     // 绿色通道值
        b_channel: d.b_channel,                     // 蓝色通道值
        w_channel: d.w_channel,                     // 白光通道值
        y_channel: d.y_channel,                     // 暖光通道值
        type_uuid: d.type_uuid ? d.type_uuid : 'LIGHT_GROUP', // 设备类型
      } as DeviceControlItem
      mappedDevices.push(item)
    }
    
    // 调用HTTP工具类关闭多个设备
    await HttpUtil.getInstance().controlColorMultipleDevices(`${this.URL}${this.url2}`, mappedDevices);
    
    // 在控制台输出调试信息
    console.log('关闭当前场景设备：', sceneData.scence);
    console.log('关闭设备列表：', JSON.stringify(mappedDevices))
  }

  // ==================== UI构建方法 ====================
  
  /**
   * 构建组件UI
   * 
   * 这是ArkUI组件的核心方法，用于定义页面的结构和样式
   * 主要构建欢迎区域、场景控制区域和设备功能区域
   */
  build() {
    // 创建主列容器
    Column() {
      
      // ==================== 欢迎信息区域 ====================
      Column({ space: 8 }) {
        // 显示当前日期
        Text(`${formatDate()}`)
          .fontSize(12)  // 设置字体大小为12像素
        
        // 欢迎信息和用户头像
        Row({ space: 100 }) {
          // 欢迎文本
          Text("Welcome,")
            .fontSize(34)        // 设置字体大小为34像素
            .fontColor('#2c2c2c') // 设置字体颜色为深灰色
            .fontWeight(700)     // 设置字体粗细为700（粗体）
          
          // 用户头像
          Image($r('app.media.touxiang'))
            .width(70)           // 设置头像宽度为70像素
            .fillColor(Color.Black) // 设置头像填充颜色为黑色
            .margin({ bottom: 10 }) // 设置下边距为10像素
        }
      }
      .alignItems(HorizontalAlign.Start) // 左对齐
      .width('100%')                     // 设置宽度为100%
      .backgroundColor('#FFF')            // 设置背景色为白色
      .border({ radius: 20 })             // 设置圆角边框，半径为20像素
      .padding(10)                        // 设置内边距为10像素

      // ==================== 场景控制区域 ====================
      Column() {
        // 场景标题
        Text('Scenes')
          .fontSize(22)        // 设置字体大小为22像素
          .fontColor('#2c2c2c') // 设置字体颜色为深灰色
          .fontWeight(600)      // 设置字体粗细为600（半粗体）
        
        // 场景按钮列表
        Row({ space: 10 }) {
          // 遍历场景数据，创建场景按钮
          ForEach(this.scene, (item: SceneClass, index: number) => {
            Column() {
              // 场景图标
              Image(item.icon)
                .width(24)  // 设置图标宽度为24像素
              
              // 场景名称
              Text(item.text)
                .fontSize(14)        // 设置字体大小为14像素
                .fontWeight(500)     // 设置字体粗细为500（中等）
                .fontColor(Color.Black) // 设置字体颜色为黑色
            }
            .onClick(async () => {
              // 场景按钮点击事件处理
              
              // 如果当前有其他场景开启，先关闭当前场景的设备
              if (this.currentIndex1 !== -1 && this.currentIndex1 !== index) {
                await this.closeCurrentSceneDevices(this.currentIndex1);
              }
              
              // 获取当前场景的设备数据
              const sceneData = this.scence1[index];
              
              // 切换选择：首次选中为"开"，再次点击同一项为"关"
              const isTurningOff = this.currentIndex1 === index;
              
              // 更新当前索引，高亮仅在"开"时保留
              this.currentIndex1 = isTurningOff ? -1 : index;

              // 根据点击意图构造设备列表：开= '0'，关= '1'
              const mappedDevices: DeviceControlItem[] = []
              
              // 遍历场景设备，构建设备控制参数
              for (let i = 0; i < sceneData.device.length; i++) {
                const d = sceneData.device[i]
                const item = {
                  control_sub_id: d.control_sub_id,           // 设备ID
                  control_sub_state: isTurningOff ? '1' : '0', // 设备状态
                  r_channel: d.r_channel,                      // 红色通道值
                  g_channel: d.g_channel,                       //绿光通道值
                  b_channel: d.b_channel,                       //蓝光通道值
                  w_channel: d.w_channel,                      // 白光通道值
                  y_channel: d.y_channel,                      // 暖光通道值
                  type_uuid: d.type_uuid ? d.type_uuid : 'LIGHT_GROUP', // 设备类型
                } as DeviceControlItem
                mappedDevices.push(item)
              }
              
              // 调用HTTP工具类控制多个设备
              await HttpUtil.getInstance().controlColorMultipleDevices(`${this.URL}${this.url2}`, mappedDevices);
              
              // 在控制台输出调试信息
              console.log('场景控制多设备：', sceneData.scence);
              console.log('场景', JSON.stringify(mappedDevices))
            })
            .padding(15)                                    // 设置内边距为15像素
            .layoutWeight(1)                                // 设置布局权重为1
            .backgroundColor(this.currentIndex1 === index ? '#e16531' : '#FFF') // 根据选中状态设置背景色
            .border({ radius: 20 })                          // 设置圆角边框，半径为20像素
          })
        }
        .margin({ top: 30 }) // 设置上边距为30像素
      }
      .alignItems(HorizontalAlign.Start) // 左对齐
      .width('100%')                     // 设置宽度为100%
      .border({ radius: 20 })             // 设置圆角边框，半径为20像素
      .padding(10)                        // 设置内边距为10像素

      // ==================== 设备功能区域 ====================
      Column() {
        // 设备功能标题
        Text('Devices')
          .fontSize(22)        // 设置字体大小为22像素
          .fontColor('#2c2c2c') // 设置字体颜色为深灰色
          .fontWeight(600)      // 设置字体粗细为600（半粗体）
          .margin({ bottom: 10 }) // 设置下边距为10像素
        
        // 设备功能列表
        List() {
          // 遍历设备功能数据，创建功能入口
          ForEach(this.devices, (item1: SceneClass, index1: number) => {
            ListItem() {
              Column({ space: 7 }) {
                // 功能图标
                Image(item1.icon)
                  .width(40)                    // 设置图标宽度为40像素
                  .fillColor(Color.Black)        // 设置图标填充颜色为黑色
                
                // 功能名称
                Text(item1.text)
                  .fontSize(14)        // 设置字体大小为14像素
                  .fontWeight(500)      // 设置字体粗细为500（中等）
                  .fontColor(Color.Black) // 设置字体颜色为黑色
              }
              .width('100%')           // 设置宽度为100%
              .height(150)             // 设置高度为150像素
              .backgroundColor('#FFF')  // 设置背景色为白色
              .border({ radius: 20 })   // 设置圆角边框，半径为20像素
              .padding(40)             // 设置内边距为40像素
              .onClick(async () => {
                // 功能入口点击事件处理
                
                // 更新当前选中的功能索引
                this.currentIndex2 = index1;

                // 根据选中的功能索引导航到对应页面
                if (this.currentIndex2 === 0) {
                  // 跳转到色温调节页面
                  this.pathStack.pushPathByName('SW', null, false);
                } else if (this.currentIndex2 === 1) {
                  // 跳转到定时功能页面
                  this.pathStack.pushPathByName('DS', null, false);
                } else if (this.currentIndex2 === 2) {
                  // 跳转到语音控制页面
                  this.pathStack.pushPathByName('YY', null, false);
                } else if (this.currentIndex2 === 3) {
                  // 跳转到设备控制页面
                  this.pathStack.pushPathByName('ZDY', null, false);
                }
              })
            }
            .padding(10) // 设置内边距为10像素
          })
        }
        .width('100%')                    // 设置宽度为100%
        .height('100%')                   // 设置高度为100%
        .listDirection(Axis.Vertical)     // 设置列表方向为垂直
        .lanes(2, 2)                      // 设置网格布局，2列2行
        .layoutWeight(1)                  // 设置布局权重为1
      }
      .alignItems(HorizontalAlign.Start) // 左对齐
      .width('100%')                     // 设置宽度为100%
      .border({ radius: 20 })             // 设置圆角边框，半径为20像素
      .padding(10)                        // 设置内边距为10像素
    }
    .width('100%')                       // 设置宽度为100%
    .height('100%')                      // 设置高度为100%
    .padding({                           // 设置内边距
      left: 10,                          // 左边距10像素
      right: 10,                         // 右边距10像素
      top: 5,                            // 上边距5像素
      bottom: 5                          // 下边距5像素
    })
  }
}