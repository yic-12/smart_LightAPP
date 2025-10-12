/**
 * 智能照明管理APP - 主布局页面 (Layout.ets)
 * 
 * 功能说明：
 * 1. 作为应用的主布局容器，管理整个应用的页面结构
 * 2. 提供底部标签栏导航，支持在Home和Setting页面间切换
 * 3. 使用Tabs组件实现多页面切换功能
 * 4. 管理导航栈和页面状态
 * 
 * 技术特点：
 * - 使用HarmonyOS ArkUI框架
 * - 集成Tabs标签栏组件
 * - 使用NavDestination进行导航管理
 * - 支持安全区域适配
 * - 响应式UI设计
 */

// 导入Home页面组件
import { SOUY } from './SOUY'
// 导入Setting页面组件
import { WD } from './WD'

// ==================== 数据模型定义 ====================

/**
 * 标签页数据模型接口
 * 
 * 用于定义标签页的数据结构
 * 包含标签页的显示文本和图标资源
 */
interface TabClass {
  text: string        // 标签页显示文本
  icon: ResourceStr  // 标签页图标资源路径
}

// ==================== 构建器函数 ====================

/**
 * LayoutBuilder构建器函数
 * 
 * @Builder装饰器：
 * - 用于创建可重用的UI构建函数
 * - 可以在多个地方调用，提高代码复用性
 * - 支持参数传递，实现动态UI构建
 * 
 * 功能说明：
 * - 用于在导航系统中创建Layout组件实例
 * - 提供统一的Layout组件创建入口
 */
@Builder
export function LayoutBuilder() {
  Layout();
}

// ==================== 主组件定义 ====================

/**
 * Layout组件 - 主布局组件
 * 
 * @Entry装饰器：
 * - 标识这是应用的入口组件之一
 * - 可以与Index组件配合使用
 * 
 * @Component装饰器：
 * - 标识这是一个ArkUI自定义组件
 * - 可以使用build()方法构建UI
 */
@Entry
@Component
struct Layout {
  
  // ==================== 组件状态管理 ====================
  
  /**
   * 当前选中的标签页索引
   * 
   * @State装饰器：
   * - 标识这是响应式状态变量
   * - 当值发生变化时，UI会自动重新渲染
   * - 初始值为0，表示默认选中第一个标签页
   */
  @State currentIndex: number = 0
  
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
   * 标签页数据数组
   * 
   * 定义应用的两个主要标签页：
   * - Home：首页，显示设备场景和分类
   * - Setting：设置页，提供设备控制和测试功能
   */
  tabData: TabClass[] = [
    { 
      text: 'Home',                    // 标签页显示文本
      icon: $r('app.media.home')       // 首页图标资源
    },
    { 
      text: 'Setting',                 // 标签页显示文本
      icon: $r('app.media.setting')   // 设置页图标资源
    }
  ]

  // ==================== UI构建器方法 ====================
  
  /**
   * 标签栏构建器
   * 
   * @Builder装饰器：
   * - 用于创建可重用的UI构建函数
   * - 支持参数传递，实现动态UI构建
   * 
   * 参数说明：
   * - item: TabClass - 标签页数据对象
   * - index: number - 标签页索引
   * 
   * 功能说明：
   * - 构建单个标签页的UI结构
   * - 包含图标和文本
   * - 根据选中状态动态改变颜色
   */
  @Builder
  tabBuilder(item: TabClass, index: number) {
    // 创建水平排列的容器
    Row({ space: 5 }) {
      // 标签页图标
      Image(item.icon)
        .width(24)                                                    // 设置图标宽度为24像素
        .fillColor(this.currentIndex === index ? '#e16531' : '#707070') // 根据选中状态设置颜色
        .margin({ top: 20 })                                           // 设置上边距为20像素
      
      // 标签页文本
      Text(item.text)
        .fontSize(14)                                                 // 设置字体大小为14像素
        .fontColor(this.currentIndex === index ? '#e16531' : '#707070') // 根据选中状态设置颜色
        .margin({ top: 20 })                                           // 设置上边距为20像素
    }
  }

  // ==================== 主UI构建方法 ====================
  
  /**
   * 构建组件UI
   * 
   * 这是ArkUI组件的核心方法，用于定义页面的结构和样式
   * 主要构建标签栏导航和页面内容区域
   */
  build() {
    // 创建导航目标容器
    NavDestination() {
      // 创建标签栏组件
      Tabs({ barPosition: BarPosition.End }) {
        // 遍历标签页数据，创建对应的标签页内容
        ForEach(this.tabData, (item: TabClass, index: number) => {
          // 创建标签页内容容器
          TabContent() {
            // 根据当前选中的标签页索引显示对应的页面组件
            if (this.currentIndex === 0) {
              // 显示Home页面组件
              SOUY()
            } else if (this.currentIndex === 1) {
              // 显示Setting页面组件
              WD()
            }
          }
          .tabBar(this.tabBuilder(item, index))  // 设置标签栏UI
          .backgroundColor('#F2F8FB')            // 设置背景色为浅蓝色
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]) // 扩展安全区域
        })
      }
      .onChange((index: number) => {
        // 标签页切换时的回调函数
        // 更新当前选中的标签页索引
        this.currentIndex = index
      })
      .backgroundColor('#FFFFFF')                // 设置标签栏背景色为白色
      .scrollable(false)                         // 禁用滚动
      .animationDuration(0)                      // 设置动画时长为0（无动画）
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]) // 扩展安全区域
    }
    .onReady((context: NavDestinationContext) => {
      // 导航目标准备就绪时的回调函数
      // 获取导航栈上下文，用于页面间的导航操作
      this.pathStack = context.pathStack;
    })
  }
}