/**
 * 智能照明管理APP - 定时功能页面 (DS.ets)
 * 
 * 功能说明：
 * 1. 提供定时任务的创建、编辑、删除功能
 * 2. 支持场景模式定时控制（教学、实操、会议、休息）
 * 3. 支持定时任务的启用/禁用开关
 * 4. 提供分钟级精度的定时执行
 * 5. 支持重复周期设置（每天、工作日、自定义）
 * 6. 自动执行定时任务，控制场景设备
 * 
 * 技术特点：
 * - 使用HarmonyOS ArkUI框架
 * - 集成HTTP网络请求
 * - 使用PreferencesUtil进行本地存储
 * - 定时器实现自动执行
 * - 响应式UI设计
 * - 多设备协同控制
 */

// 导入数据模型接口
import { Data1, Data2, TimerItem, DeviceControlItem, scenceRgb } from "../inter/Interface1";
// 导入HarmonyOS上下文
import { Context } from '@kit.AbilityKit'
// 导入HTTP工具类
import { HttpUtil } from "../inter/HttpUtil";
// 导入本地存储工具
import { PreferencesUtil } from "../inter/PreferencesUtil";
// 导入设备控制数据
import { deviceControls, deviceClass, exper, per, break1 } from "../utils/device";

// ==================== 构建器函数 ====================

/**
 * DSBuilder构建器函数
 * 
 * @Builder装饰器：
 * - 用于创建可重用的UI构建函数
 * - 可以在多个地方调用，提高代码复用性
 * - 支持参数传递，实现动态UI构建
 * 
 * 功能说明：
 * - 用于在导航系统中创建DS组件实例
 * - 提供统一的DS组件创建入口
 */
@Builder
export function DSBuilder() {
  DS();
}

// ==================== 主组件定义 ====================

/**
 * DS组件 - 定时功能主组件
 * 
 * @Component装饰器：
 * - 标识这是一个ArkUI自定义组件
 * - 可以使用build()方法构建UI
 * 
 * 功能说明：
 * - 提供定时任务的完整管理功能
 * - 支持场景模式定时控制
 * - 自动执行定时任务
 */
@Component
export struct DS {

  // ==================== 场景数据配置 ====================
  
  /**
   * 场景设备映射数据
   * 
   * @State装饰器：
   * - 标识这是响应式状态变量
   * - 当值发生变化时，UI会自动重新渲染
   * 
   * 定义每个场景对应的设备列表：
   * - 教学场景：使用deviceClass设备组
   * - 实操场景：使用exper设备组
   * - 会议场景：使用per设备组
   * - 休息场景：使用break1设备组
   */
  @State scene: scenceRgb[] = [
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
  @State currentIndex3: number = -1

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
  URL: string = "http://10.214.166.140:8081";
  
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
   * 应用上下文
   * 用于访问应用级别的资源和功能
   */
  context: Context = getContext(this) as Context;

  // ==================== 请求数据模型 ====================
  
  /**
   * GET请求的数据模型
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

  // ==================== 定时任务状态管理 ====================
  
  /**
   * 定时任务列表
   * 
   * 存储所有创建的定时任务
   * 每个任务包含名称、时间、动作、重复周期等信息
   */
  @State timerList: TimerItem[] = [];

  /**
   * 是否处于添加新定时任务模式
   * true表示显示添加表单，false表示显示任务列表
   */
  @State isAdding: boolean = false;
  
  /**
   * 新定时任务名称
   * 用户在添加表单中输入的任务名称
   */
  @State newTimerName: string = '';
  
  /**
   * 选中的时间
   * 格式为"HH:MM"，如"08:00"
   */
  @State selectedTime: string = '08:00';
  
  /**
   * 选中的时间索引
   * 8:00对应的分钟数（8*60=480）
   * 用于滑块控制，范围0-1439（24小时*60分钟-1）
   */
  @State selectedTimeIndex: number = 480;
  
  /**
   * 当前选中的设备ID
   * 用于定时任务执行的设备标识
   */
  @State selectedDevice: string = 'light_001';
  
  /**
   * 选中的动作
   * '0'表示开灯，'1'表示关灯
   */
  @State selectedAction: '0' | '1' = '0';

  /**
   * 显示删除确认对话框
   * true表示显示删除确认对话框
   */
  @State showDeleteDialog: boolean = false;
  
  /**
   * 正在删除的定时任务ID
   * 用于删除确认对话框中的任务标识
   */
  @State deletingTimerId: string = '';
  
  /**
   * 正在删除的定时任务名称
   * 用于删除确认对话框中的任务名称显示
   */
  @State deletingTimerName: string = '';
  
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

  // ==================== 设备状态管理 ====================
  
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

  // ==================== 定时器管理 ====================
  
  /**
   * 调度器定时器ID
   * 用于管理定时任务检查的定时器
   */
  private scheduleIntervalId: number | undefined = undefined
  
  /**
   * 最后触发的任务键
   * 用于防止同一分钟内重复触发相同任务
   * 格式：任务ID-时间，如"1234567890-08:00"
   */
  private lastTriggeredKey: string | undefined = undefined

  // ==================== 数据持久化方法 ====================
  
  /**
   * 加载定时任务数据
   * 
   * 功能说明：
   * - 从本地存储中加载已保存的定时任务列表
   * - 在页面初始化时调用
   * - 使用try-catch处理可能的异常
   */
  async loadTimerData() {
    try {
      // 从本地存储加载定时任务列表
      const savedTimerList = PreferencesUtil.loadTimerList(this.context);
      this.timerList = savedTimerList;
    } catch (error) {
      console.error('加载定时任务数据失败:', error);
    }
  }

  /**
   * 保存定时任务数据
   * 
   * 功能说明：
   * - 将当前定时任务列表保存到本地存储
   * - 在添加、删除、修改任务时调用
   * - 使用try-catch处理可能的异常
   */
  async saveTimerData() {
    try {
      // 保存定时任务列表到本地存储
      PreferencesUtil.saveTimerList(this.context, this.timerList);
    } catch (error) {
      console.error('保存定时任务数据失败:', error);
    }
  }

  /**
   * 设置设备亮度方法
   * 
   * 功能说明：
   * - 调用HTTP工具类设置指定设备的亮度
   * - 用于定时任务执行时的设备控制
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
    console.log('测试定时')
  }

  // ==================== UI构建方法 ====================
  
  /**
   * 构建组件UI
   * 
   * 这是ArkUI组件的核心方法，用于定义页面的结构和样式
   * 主要构建标题、任务列表、添加表单等区域
   */
  build() {
    // 创建导航目标容器
    NavDestination() {
      // 创建主列容器
      Column() {
        
        // ==================== 页面标题 ====================
        Column() {
          Text("定时功能")
            .fontSize(23)                    // 设置字体大小为23像素
            .fontWeight(FontWeight.Bold)      // 设置字体粗细为粗体
            .fontColor(Color.Blue)            // 设置字体颜色为蓝色
        }
        .margin({ bottom: 10 })              // 设置下边距为10像素

        // ==================== 主要内容区域 ====================
        // 主要内容区域：根据模式显示列表或添加表单
        Column() {
          if (this.isAdding) {
            // 如果处于添加模式，显示添加表单
            this.BuildAddTimerView();  // 添加定时任务视图
          } else {
            // 如果处于列表模式，显示任务列表
            this.BuildTimerListView();  // 定时任务列表视图
          }
        }
        .width('100%')                       // 设置宽度为100%
        .layoutWeight(1)                     // 占据剩余空间

        // ==================== 添加按钮 ====================
        // 圆形添加按钮 × 位于中下方
        if (!this.isAdding) {
          Row() {
            Blank()  // 左侧占位
            
            // 圆形+号按钮
            Button() {
              Text('+')
                .fontSize(30)                    // 设置字体大小为30像素
                .fontWeight(FontWeight.Bold)     // 设置字体粗细为粗体
                .fontColor(Color.White)          // 设置字体颜色为白色
            }
            .width(60)                           // 设置按钮宽度为60像素
            .height(60)                           // 设置按钮高度为60像素
            .backgroundColor('#e16531')           // 设置背景色为主题橙色
            .borderRadius(30)                     // 设置圆角半径为30像素（圆形按钮）
            .onClick(() => {
              // 添加按钮点击事件处理
              this.isAdding = true;              // 进入添加模式
              this.newTimerName = '';            // 重置名称
              this.selectedTime = '08:00';        // 重置时间为默认值
              this.selectedTimeIndex = 480;       // 8:00对应的分钟数
              this.selectedAction = '0';          // 默认开灯动作
            })
            
            Blank()  // 右侧占位
          }
          .width('100%')                       // 设置宽度为100%
          .margin({ top: 20, bottom: 10 })     // 设置上下边距
        }

      }
      .width('100%')                           // 设置宽度为100%
      .height('100%')                           // 设置高度为100%
      .padding(20)                              // 设置内边距为20像素

      // ==================== 删除确认对话框 ====================
      // 删除确认对话框
      if (this.showDeleteDialog) {
        this.BuildDeleteDialog();
      }
    }
    .onReady((context: NavDestinationContext) => {
      // 导航目标准备就绪时的回调函数
      this.pathStack = context.pathStack;
      
      // 页面准备就绪时加载定时任务数据
      this.loadTimerData();
      
      // 启动分钟级调度器
      this.startScheduler();
      
      // 初始化默认设备
      if (this.devices.length > 0) {
        this.deviceIndex = 0
        this.selectedDevice = this.devices[0].control_sub_id
      }
    })
    .backgroundColor('#F2F8FB')                 // 设置页面背景色为浅蓝色
  }

  // ==================== UI构建器方法 ====================
  
  /**
   * 构建定时任务列表视图
   * 
   * @Builder装饰器：
   * - 用于创建可重用的UI构建函数
   * - 支持参数传递，实现动态UI构建
   * 
   * 功能说明：
   * - 显示所有定时任务的列表或空状态
   * - 支持任务的启用/禁用和删除操作
   */
  @Builder
  BuildTimerListView() {
    Column() {
      if (this.timerList.length === 0) {
        // ==================== 空状态显示 ====================
        // 空状态：显示图标和提示文字
        Column() {
          // 定时功能图标
          Image($r('app.media.dinshi'))
            .width(100)                         // 设置图标宽度为100像素
            .height(100)                         // 设置图标高度为100像素
            .margin({ bottom: 20 })              // 设置下边距为20像素
          
          // 空状态提示文本
          Text('暂无定时任务')
            .fontSize(16)                        // 设置字体大小为16像素
            .fontColor('#999')                    // 设置字体颜色为灰色
          
          // 操作提示文本
          Text('点击下方"+"按钮创建定时任务')
            .fontSize(14)                        // 设置字体大小为14像素
            .fontColor('#666')                    // 设置字体颜色为深灰色
            .margin({ top: 10 })                  // 设置上边距为10像素
        }
        .alignItems(HorizontalAlign.Center)      // 水平居中对齐
        .justifyContent(FlexAlign.Center)        // 垂直居中对齐
        .layoutWeight(1)                         // 占据剩余空间，实现居中显示
      } else {
        // ==================== 定时任务列表 ====================
        // 定时任务列表
        List({ space: 10 }) {
          // 遍历定时任务列表，创建任务项
          ForEach(this.timerList, (item: TimerItem) => {
            ListItem() {
              this.BuildTimerItem(item);  // 构建单个定时任务项
            }
          }, (item: TimerItem) => item.id)  // 使用id作为key
        }
        .width('100%')                         // 设置宽度为100%
        .height('100%')                        // 设置高度为100%
        .layoutWeight(1)                       // 设置布局权重为1
      }
    }
    .width('100%')                             // 设置宽度为100%
    .height('100%')                            // 设置高度为100%
  }

  /**
   * 构建单个定时任务项
   * 
   * 功能说明：
   * - 显示定时任务的详细信息和控制开关
   * - 包含任务名称、时间、重复周期、动作等信息
   * - 提供启用/禁用开关和删除按钮
   * 
   * 参数说明：
   * - item: TimerItem - 定时任务数据对象
   */
  @Builder
  BuildTimerItem(item: TimerItem) {
    Column() {
      // ==================== 任务信息行 ====================
      // 第一行：任务名称、时间和开关
      Row() {
        Column() {
          // ==================== 任务名称和动作图标 ====================
          Row({ space: 8 }) {
            // 动作状态指示器
            Text(this.getActionSymbol(item.action))
              .fontSize(16)                        // 设置字体大小为16像素
              .fontWeight(FontWeight.Bold)          // 设置字体粗细为粗体
              .fontColor(this.getActionColor(item.action)) // 根据动作设置颜色

            // 任务名称
            Text(item.name)
              .fontSize(16)                        // 设置字体大小为16像素
              .fontWeight(FontWeight.Medium)       // 设置字体粗细为中等
              .fontColor('#2c2c2c')                 // 设置字体颜色为深灰色
          }
          .alignItems(VerticalAlign.Center)         // 垂直居中对齐

          // ==================== 任务详细信息 ====================
          // 时间、重复周期和动作描述
          Text(`${item.time} • ${this.getRepeatText(item.repeat)} • ${this.getActionText(item.action)}`)
            .fontSize(14)                           // 设置字体大小为14像素
            .fontColor('#666')                      // 设置字体颜色为灰色
            .margin({ top: 5 })                     // 设置上边距为5像素
        }
        .alignItems(HorizontalAlign.Start)         // 左对齐
        .layoutWeight(1)                           // 占据左侧空间

        // ==================== 操作按钮区域 ====================
        // 右侧操作区域：开关和删除按钮
        Row({ space: 10 }) {
          // ==================== 启用/禁用开关 ====================
          // 启用/禁用开关
          Toggle({ type: ToggleType.Switch, isOn: item.enabled })
            .onChange(async (value: boolean) => {
              // 开关状态变化时的回调函数
              item.enabled = value;  // 更新启用状态
              
              if (item.enabled) {
                // 如果启用，执行场景设备控制
                this.controlSceneDevices()
              } else {
                // 如果禁用，也执行场景设备控制（可能是关闭操作）
                this.controlSceneDevices()
              }
              
              // 保存到持久化存储
              await this.saveTimerData();
            })

          // ==================== 删除按钮 ====================
          // 删除按钮 × 圆形红色背景的减号
          Button() {
            Text('×')
              .fontSize(20)                         // 设置字体大小为20像素
              .fontWeight(FontWeight.Bold)          // 设置字体粗细为粗体
              .fontColor(Color.White)               // 设置字体颜色为白色
          }
          .width(36)                               // 设置按钮宽度为36像素
          .height(36)                               // 设置按钮高度为36像素
          .backgroundColor('#FF6B6B')               // 设置背景色为红色
          .borderRadius(18)                         // 设置圆角半径为18像素（圆形按钮）
          .onClick(() => {
            // 删除按钮点击事件处理
            this.showDeleteConfirmation(item.id, item.name);  // 显示删除确认
          })
        }
        .alignItems(VerticalAlign.Center)           // 垂直居中对齐
      }

    }
    .width('100%')                                 // 设置宽度为100%
    .padding(15)                                   // 设置内边距为15像素
    .backgroundColor(Color.White)                  // 设置背景色为白色
    .borderRadius(15)                              // 设置圆角边框，半径为15像素
  }

  /**
   * 构建删除确认对话框
   * 
   * 功能说明：
   * - 显示删除确认对话框
   * - 包含任务名称和确认/取消按钮
   * - 使用半透明背景覆盖整个页面
   */
  @Builder
  BuildDeleteDialog() {
    // 半透明背景层
    Column() {
      // 对话框内容
      Column() {
        // ==================== 对话框标题 ====================
        Text('删除定时任务')
          .fontSize(18)                            // 设置字体大小为18像素
          .fontWeight(FontWeight.Bold)             // 设置字体粗细为粗体
          .fontColor('#2c2c2c')                    // 设置字体颜色为深灰色
          .margin({ bottom: 10 })                  // 设置下边距为10像素

        // ==================== 确认消息 ====================
        Text(`确定要删除"${this.deletingTimerName}"吗？`)
          .fontSize(16)                            // 设置字体大小为16像素
          .fontColor('#666')                       // 设置字体颜色为灰色
          .textAlign(TextAlign.Center)             // 设置文本居中对齐
          .margin({ bottom: 20 })                  // 设置下边距为20像素

        // ==================== 操作按钮 ====================
        Row({ space: 15 }) {
          // 取消按钮
          Button('取消')
            .layoutWeight(1)                       // 设置布局权重为1
            .backgroundColor('#F0F0F0')            // 设置背景色为浅灰色
            .fontColor(Color.Black)                 // 设置字体颜色为黑色
            .borderRadius(20)                       // 设置圆角边框，半径为20像素
            .height(45)                            // 设置按钮高度为45像素
            .onClick(() => {
              // 取消按钮点击事件处理
              this.showDeleteDialog = false;       // 关闭对话框
            })

          // 删除按钮
          Button('删除')
            .layoutWeight(1)                       // 设置布局权重为1
            .backgroundColor('#FF6B6B')            // 设置背景色为红色
            .fontColor(Color.White)                 // 设置字体颜色为白色
            .borderRadius(20)                       // 设置圆角边框，半径为20像素
            .height(45)                            // 设置按钮高度为45像素
            .onClick(() => {
              // 删除按钮点击事件处理
              this.deleteTimer(this.deletingTimerId);  // 执行删除
              this.showDeleteDialog = false;       // 关闭对话框
            })
        }
        .width('100%')                             // 设置宽度为100%
      }
      .width('80%')                                // 设置对话框宽度为80%
      .padding(25)                                 // 设置内边距为25像素
      .backgroundColor(Color.White)                 // 设置背景色为白色
      .borderRadius(20)                             // 设置圆角边框，半径为20像素
      .shadow({ radius: 20, color: '#1A000000', offsetX: 0, offsetY: 5 })  // 添加阴影效果
    }
    .width('100%')                                 // 设置宽度为100%
    .height('100%')                                // 设置高度为100%
    .justifyContent(FlexAlign.Center)              // 垂直居中对齐
    .backgroundColor('#80000000')                  // 设置半透明黑色背景
    .position({ x: 0, y: 0 })                      // 覆盖整个页面
  }

  /**
   * 构建添加定时任务视图
   * 
   * 功能说明：
   * - 提供表单用于创建新的定时任务
   * - 包含任务名称、场景选择、动作选择、时间选择等字段
   * - 支持滚动查看所有表单内容
   */
  @Builder
  BuildAddTimerView() {
    Scroll() {
      Column() {
        // ==================== 表单标题 ====================
        Text('新建定时')
          .fontSize(18)                            // 设置字体大小为18像素
          .fontWeight(FontWeight.Bold)             // 设置字体粗细为粗体
          .fontColor('#2c2c2c')                    // 设置字体颜色为深灰色
          .margin({ bottom: 20 })                  // 设置下边距为20像素

        // ==================== 定时名称输入区域 ====================
        Column() {
          Text('定时名称')
            .fontSize(14)                           // 设置字体大小为14像素
            .fontWeight(FontWeight.Medium)          // 设置字体粗细为中等
            .alignSelf(ItemAlign.Start)             // 左对齐
            .margin({ bottom: 8 })                  // 设置下边距为8像素
          
          // 文本输入框
          TextInput({ placeholder: '输入定时任务名称', text: this.newTimerName })
            .onChange((value: string) => {
              // 文本变化时的回调函数
              this.newTimerName = value;            // 更新定时任务名称
            })
        }
        .width('100%')                             // 设置宽度为100%
        .padding(15)                               // 设置内边距为15像素
        .backgroundColor(Color.White)              // 设置背景色为白色
        .borderRadius(15)                           // 设置圆角边框，半径为15像素
        .margin({ bottom: 15 })                     // 设置下边距为15像素

        // ==================== 场景选择区域 ====================
        Column() {
          Text('场景选择')
            .fontSize(14)                           // 设置字体大小为14像素
            .fontWeight(FontWeight.Medium)          // 设置字体粗细为中等
            .alignSelf(ItemAlign.Start)             // 左对齐
            .margin({ bottom: 8 })                  // 设置下边距为8像素
          
          // 场景选择按钮组
          Row({ space: 10 }) {
            ForEach(this.scene, (item: scenceRgb, index: number) => {
              Button(item.scence)
                .backgroundColor(this.currentIndex3 === index ? '#e16531' : '#FFF') // 根据选中状态设置背景色
                .fontColor(this.currentIndex3 === index ? Color.White : Color.Black) // 根据选中状态设置字体颜色
                .borderRadius(20)                   // 设置圆角边框，半径为20像素
                .padding(10)                        // 设置内边距为10像素
                .layoutWeight(1)                    // 设置布局权重为1
                .onClick(async () => {
                  // 场景按钮点击事件处理
                  // 切换选择：首次选中为"开"，再次点击同一项为"关"
                  const isTurningOff = this.currentIndex3 === index;
                  // 更新当前索引，高亮仅在"开"时保留
                  this.currentIndex3 = isTurningOff ? -1 : index;
                  // 根据点击意图构造设备列表：开= '0'，关= '1'
                })
            })
          }
        }
        .width('100%')                             // 设置宽度为100%
        .padding(15)                               // 设置内边距为15像素
        .backgroundColor(Color.White)              // 设置背景色为白色
        .borderRadius(15)                           // 设置圆角边框，半径为15像素
        .margin({ bottom: 15 })                     // 设置下边距为15像素

        // ==================== 动作选择区域 ====================
        Column() {
          Text('定时动作')
            .fontSize(14)                           // 设置字体大小为14像素
            .fontWeight(FontWeight.Medium)          // 设置字体粗细为中等
            .alignSelf(ItemAlign.Start)             // 左对齐
            .margin({ bottom: 8 })                  // 设置下边距为8像素

          // 动作选择按钮组
          Row({ space: 10 }) {
            // 打开灯光按钮
            Button('打开灯光')
              .backgroundColor(this.selectedAction === '0' ? '#e16531' : '#F0F0F0') // 根据选中状态设置背景色
              .fontColor(this.selectedAction === '0' ? Color.White : Color.Black)     // 根据选中状态设置字体颜色
              .borderRadius(20)                     // 设置圆角边框，半径为20像素
              .padding(10)                          // 设置内边距为10像素
              .layoutWeight(1)                      // 设置布局权重为1
              .onClick(() => {
                // 打开灯光按钮点击事件处理
                this.selectedAction = '0';          // 选择开灯动作
              })

            // 关闭灯光按钮
            Button('关闭灯光')
              .backgroundColor(this.selectedAction === '1' ? '#e16531' : '#F0F0F0') // 根据选中状态设置背景色
              .fontColor(this.selectedAction === '1' ? Color.White : Color.Black)     // 根据选中状态设置字体颜色
              .borderRadius(20)                     // 设置圆角边框，半径为20像素
              .padding(10)                          // 设置内边距为10像素
              .layoutWeight(1)                      // 设置布局权重为1
              .onClick(() => {
                // 关闭灯光按钮点击事件处理
                this.selectedAction = '1';          // 选择关灯动作
              })
          }
          .width('100%')                           // 设置宽度为100%
        }
        .width('100%')                             // 设置宽度为100%
        .padding(15)                               // 设置内边距为15像素
        .backgroundColor(Color.White)              // 设置背景色为白色
        .borderRadius(15)                           // 设置圆角边框，半径为15像素
        .margin({ bottom: 15 })                     // 设置下边距为15像素

        // ==================== 执行时间选择区域 ====================
        // 执行时间选择区域 - 使用滑动选择器
        Column() {
          Text('执行时间')
            .fontSize(14)                           // 设置字体大小为14像素
            .fontWeight(FontWeight.Medium)          // 设置字体粗细为中等
            .alignSelf(ItemAlign.Start)             // 左对齐
            .margin({ bottom: 8 })                  // 设置下边距为8像素

          // 当前选中时间显示
          Text(this.selectedTime)
            .fontSize(24)                           // 设置字体大小为24像素
            .fontWeight(FontWeight.Bold)            // 设置字体粗细为粗体
            .fontColor('#e16531')                   // 设置字体颜色为主题橙色
            .margin({ bottom: 15 })                 // 设置下边距为15像素

          // 滑动时间选择器
          Column() {
            // 时间刻度滑块 + 加减1分钟按钮
            Row({ space: 10 }) {
              // 减1分钟按钮
              Button('-1')
                .borderRadius(14)                   // 设置圆角边框，半径为14像素
                .height(28)                         // 设置按钮高度为28像素
                .padding({ left: 10, right: 10 })   // 设置左右内边距为10像素
                .backgroundColor('#F0F0F0')         // 设置背景色为浅灰色
                .fontColor(Color.Black)              // 设置字体颜色为黑色
                .onClick(() => {
                  // 减1分钟按钮点击事件处理
                  if (this.selectedTimeIndex > 0) {
                    this.selectedTimeIndex = this.selectedTimeIndex - 1;
                    this.updateSelectedTime();
                  }
                })

              // 时间滑块
              Slider({
                value: this.selectedTimeIndex,       // 当前值（时间索引）
                min: 0,                            // 最小值（00:00）
                max: 1439,                         // 最大值（23:59）
                step: 1,                           // 步长（1分钟）
                style: SliderStyle.OutSet          // 滑块样式（外置样式）
              })
                .layoutWeight(1)                   // 设置布局权重为1
                .onChange((value: number) => {
                  // 滑块值变化时的回调函数
                  this.selectedTimeIndex = value;
                  this.updateSelectedTime();
                })

              // 加1分钟按钮
              Button('+1')
                .borderRadius(14)                   // 设置圆角边框，半径为14像素
                .height(28)                         // 设置按钮高度为28像素
                .padding({ left: 10, right: 10 })   // 设置左右内边距为10像素
                .backgroundColor('#F0F0F0')         // 设置背景色为浅灰色
                .fontColor(Color.Black)              // 设置字体颜色为黑色
                .onClick(() => {
                  // 加1分钟按钮点击事件处理
                  if (this.selectedTimeIndex < 1439) {
                    this.selectedTimeIndex = this.selectedTimeIndex + 1;
                    this.updateSelectedTime();
                  }
                })
            }
            .width('100%')                         // 设置宽度为100%

            // 时间刻度标签
            Row() {
              Text('00:00')
                .fontSize(12)                       // 设置字体大小为12像素
                .fontColor('#999')                  // 设置字体颜色为灰色
              Blank()
              Text('12:00')
                .fontSize(12)                       // 设置字体大小为12像素
                .fontColor('#999')                  // 设置字体颜色为灰色
              Blank()
              Text('23:59')
                .fontSize(12)                       // 设置字体大小为12像素
                .fontColor('#999')                  // 设置字体颜色为灰色
            }
            .width('100%')                         // 设置宽度为100%
            .margin({ top: 10 })                   // 设置上边距为10像素
          }
          .width('100%')                           // 设置宽度为100%
        }
        .width('100%')                             // 设置宽度为100%
        .padding(15)                               // 设置内边距为15像素
        .backgroundColor(Color.White)              // 设置背景色为白色
        .borderRadius(15)                           // 设置圆角边框，半径为15像素
        .margin({ bottom: 15 })                     // 设置下边距为15像素

        // ==================== 操作按钮 ====================
        // 操作按钮：取消和保存
        Row({ space: 15 }) {
          // 取消按钮
          Button('取消')
            .layoutWeight(1)                       // 设置布局权重为1
            .backgroundColor('#F0F0F0')            // 设置背景色为浅灰色
            .fontColor(Color.Black)                 // 设置字体颜色为黑色
            .borderRadius(20)                       // 设置圆角边框，半径为20像素
            .onClick(() => {
              // 取消按钮点击事件处理
              this.isAdding = false;                // 退出添加模式
            })

          // 保存按钮
          Button('保存')
            .layoutWeight(1)                       // 设置布局权重为1
            .backgroundColor('#e16531')            // 设置背景色为主题橙色
            .fontColor(Color.White)                 // 设置字体颜色为白色
            .borderRadius(20)                       // 设置圆角边框，半径为20像素
            .onClick(() => {
              // 保存按钮点击事件处理
              this.saveNewTimer();                  // 保存新定时任务
            })
        }
        .width('100%')                             // 设置宽度为100%
      }
      .width('100%')                               // 设置宽度为100%
      .padding({ left: 20, right: 20, bottom: 20 }) // 设置左右下内边距为20像素
    }
    .scrollable(ScrollDirection.Vertical)           // 设置垂直滚动
    .scrollBar(BarState.Auto)                      // 设置滚动条自动显示
    .scrollBarColor('#E0E0E0')                     // 设置滚动条颜色为浅灰色
    .scrollBarWidth(8)                             // 设置滚动条宽度为8像素
    .edgeEffect(EdgeEffect.Spring)                 // 设置边缘效果为弹簧效果
    .width('100%')                                 // 设置宽度为100%
    .height('100%')                                // 设置高度为100%
  }

  // ==================== 定时器管理方法 ====================
  
  /**
   * 启动调度器：每分钟检查一次是否需要执行定时动作
   * 
   * 功能说明：
   * - 启动定时器，每分钟检查一次定时任务
   * - 对齐到下一个整分钟开始执行
   * - 避免重复启动定时器
   */
  startScheduler() {
    // 先清理旧的定时器
    if (this.scheduleIntervalId !== undefined) {
      clearInterval(this.scheduleIntervalId as number)
    }
    
    // 对齐到下一个整分钟开始，再每分钟执行一次
    const now = new Date()
    const msToNextMinute = (60 - now.getSeconds()) * 1000 - now.getMilliseconds()
    
    setTimeout(() => {
      // 立即执行一次检查
      this.checkAndRunTimers()
      
      // 设置每分钟执行一次的定时器
      const id = setInterval(() => {
        this.checkAndRunTimers()
      }, 60 * 1000)
      
      this.scheduleIntervalId = id as number
    }, Math.max(0, msToNextMinute))
  }

  /**
   * 检查并执行符合条件的定时任务
   * 
   * 功能说明：
   * - 遍历所有启用的定时任务
   * - 检查当前时间是否匹配任务时间
   * - 检查重复周期是否包含当前日期
   * - 执行匹配的任务并防止重复触发
   */
  async checkAndRunTimers() {
    // 检查定时任务列表是否为空
    if (!this.timerList || this.timerList.length === 0) {
      return
    }
    
    // 获取当前时间信息
    const now = new Date()
    const hh = now.getHours().toString().padStart(2, '0')
    const mm = now.getMinutes().toString().padStart(2, '0')
    const currentTime = `${hh}:${mm}`
    
    // OpenHarmony 周一=1 ... 周日=7
    const day = ((now.getDay() + 6) % 7) + 1

    // 遍历所有定时任务
    for (const item of this.timerList) {
      // 跳过未启用的任务
      if (!item.enabled) continue
      
      // 跳过时间不匹配的任务
      if (item.time !== currentTime) continue
      
      // 跳过重复周期不包含当前日期的任务
      if (item.repeat && item.repeat.length > 0 && !item.repeat.includes(day)) continue

      // 生成触发键，防止重复触发
      const triggerKey = `${item.id}-${currentTime}`
      if (this.lastTriggeredKey === triggerKey) {
        // 本分钟已执行过，避免重复触发
        continue
      }

      // 记录触发键
      this.lastTriggeredKey = triggerKey

      // 执行动作：'0'开灯，'1'关灯
      try {
        // 使用当前亮度和色温设置执行场景控制
        this.controlSceneDevices()
        
        // 执行完成后自动关闭该定时任务开关（Toggle 置为关）
        item.enabled = false
        
        // 保存更新后的任务状态
        await this.saveTimerData()
      } catch (e) {
        console.error('定时执行失败:', e)
      }
    }
  }

  // ==================== 工具方法 ====================
  
  /**
   * 根据滑块值更新选中时间
   * 
   * 功能说明：
   * - 将时间索引转换为"HH:MM"格式
   * - 用于滑块控制时间选择
   */
  updateSelectedTime() {
    const totalMinutes = this.selectedTimeIndex;
    const hours = Math.floor(totalMinutes / 60);
    const minutes = totalMinutes % 60;

    const hourStr = hours.toString().padStart(2, '0');
    const minuteStr = minutes.toString().padStart(2, '0');

    this.selectedTime = `${hourStr}:${minuteStr}`;
  }

  /**
   * 保存新定时任务
   * 
   * 功能说明：
   * - 验证输入并添加到定时任务列表
   * - 创建新的定时任务对象
   * - 保存到本地存储
   */
  async saveNewTimer() {
    // 验证定时任务名称不能为空
    if (!this.newTimerName.trim()) {
      return;
    }

    // 创建新的定时任务对象
    const newTimer: TimerItem = {
      id: Date.now().toString(),  // 使用时间戳作为唯一ID
      name: this.newTimerName,
      time: this.selectedTime,
      enabled: true,              // 默认启用
      repeat: [1, 2, 3, 4, 5, 6, 7],  // 默认每天重复
      deviceId: this.selectedDevice,
      action: this.selectedAction  // 保存选择的动作
    };

    // 添加到列表
    this.timerList.push(newTimer);

    // 保存到持久化存储
    await this.saveTimerData();

    // 退出添加模式
    this.isAdding = false;
  }

  /**
   * 显示删除确认对话框
   * 
   * 功能说明：
   * - 设置要删除的任务信息
   * - 显示删除确认对话框
   * 
   * 参数说明：
   * - timerId: string - 要删除的任务ID
   * - timerName: string - 要删除的任务名称
   */
  showDeleteConfirmation(timerId: string, timerName: string) {
    this.deletingTimerId = timerId;
    this.deletingTimerName = timerName;
    this.showDeleteDialog = true;
  }

  /**
   * 删除定时任务
   * 
   * 功能说明：
   * - 从列表中移除指定ID的定时任务
   * - 保存更新后的列表到本地存储
   * - 重置删除状态
   * 
   * 参数说明：
   * - timerId: string - 要删除的任务ID
   */
  async deleteTimer(timerId: string) {
    // 从列表中移除指定ID的定时任务
    this.timerList = this.timerList.filter(item => item.id !== timerId);

    // 保存更新后的列表到持久化存储
    await this.saveTimerData();

    // 重置删除状态
    this.deletingTimerId = '';
    this.deletingTimerName = '';
  }

  /**
   * 获取动作对应的符号
   * 
   * 功能说明：
   * - 根据动作类型返回对应的符号
   * - '0'返回实心圆点，'1'返回空心圆点
   * 
   * 参数说明：
   * - action: '0' | '1' - 动作类型
   * 
   * 返回值：
   * - string - 对应的符号
   */
  getActionSymbol(action: '0' | '1'): string {
    return action === '0' ? '●' : '○';
  }

  /**
   * 获取动作对应的颜色
   * 
   * 功能说明：
   * - 根据动作类型返回对应的颜色
   * - '0'返回绿色，'1'返回红色
   * 
   * 参数说明：
   * - action: '0' | '1' - 动作类型
   * 
   * 返回值：
   * - Color - 对应的颜色
   */
  getActionColor(action: '0' | '1'): Color {
    return action === '0' ? Color.Green : Color.Red;
  }

  /**
   * 获取动作描述文本
   * 
   * 功能说明：
   * - 根据动作类型返回对应的描述文本
   * - '0'返回"开灯"，'1'返回"关灯"
   * 
   * 参数说明：
   * - action: '0' | '1' - 动作类型
   * 
   * 返回值：
   * - string - 对应的描述文本
   */
  getActionText(action: '0' | '1'): string {
    return action === '0' ? '开灯' : '关灯';
  }

  /**
   * 获取重复周期的文本描述
   * 
   * 功能说明：
   * - 将数字数组转换为用户友好的文本
   * - 支持每天、工作日、自定义等描述
   * 
   * 参数说明：
   * - repeat: number[] - 重复周期数组
   * 
   * 返回值：
   * - string - 对应的描述文本
   */
  getRepeatText(repeat: number[]): string {
    if (repeat.length === 7) return '每天';  // 包含所有7天
    if (repeat.length === 5 && !repeat.includes(6) && !repeat.includes(7)) return '工作日';  // 周一到周五
    return '自定义';  // 其他组合
  }

  // ==================== 设备控制方法 ====================
  
  /**
   * 控制场景设备的开关状态
   * 
   * 功能说明：
   * - 根据选中的场景控制对应的设备组
   * - 支持多设备协同控制
   * - 使用HTTP工具类发送控制命令
   * 
   * 参数说明：
   * - index: number - 场景索引（可选）
   * - isTurningOff: boolean - 是否关闭设备（可选）
   */
  private async controlSceneDevices(): Promise<void> {
    try {
      // 获取当前选中的场景数据
      const sceneData = this.scene[this.currentIndex3];
      const mappedDevices: DeviceControlItem[] = [];

      // 构建设备控制数据
      for (let i = 0; i < sceneData.device.length; i++) {
        const d = sceneData.device[i];
        const item = {
          control_sub_id: d.control_sub_id,           // 设备ID
          control_sub_state: this.selectedAction,    // 设备状态
          r_channel: d.r_channel,                     // 红色通道值
          g_channel: d.g_channel,                       //绿光通道值
          b_channel: d.b_channel,                       //蓝光通道值
          w_channel: d.w_channel,                     // 白光通道值
          y_channel: d.y_channel,                     // 暖光通道值
          type_uuid: d.type_uuid ? d.type_uuid : 'LIGHT_GROUP', // 设备类型
        } as DeviceControlItem;
        mappedDevices.push(item);
      }

      // 发送控制命令到多设备
      await HttpUtil.getInstance().controlColorMultipleDevices(
        `${this.URL}${this.url2}`,
        mappedDevices
      );

      // 日志输出
      console.log('场景控制多设备：', sceneData.scence);
      console.log('设备', JSON.stringify(mappedDevices));

    } catch (error) {
      console.error('场景设备控制失败:', error);
    }
  }
}