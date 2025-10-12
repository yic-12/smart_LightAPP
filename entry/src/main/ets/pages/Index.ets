/**
 * 智能照明管理APP - 应用入口页面 (Index.ets)
 * 
 * 功能说明：
 * 1. 作为整个应用的入口点，负责初始化导航系统
 * 2. 管理应用级别的导航栈，支持页面间的跳转
 * 3. 自动跳转到主布局页面(Layout)
 * 
 * 技术特点：
 * - 使用HarmonyOS ArkUI框架
 * - 集成Navigation导航组件
 * - 使用AppStorageV2进行全局状态管理
 * - 隐藏系统导航栏，提供沉浸式体验
 */

// 导入HarmonyOS ArkUI的AppStorageV2模块
// AppStorageV2用于应用级别的状态管理和数据共享
import { AppStorageV2 } from '@kit.ArkUI';

/**
 * Index组件 - 应用入口组件
 * 
 * @Entry装饰器：
 * - 标识这是应用的入口组件
 * - 系统启动时会首先加载这个组件
 * - 整个应用的根组件
 * 
 * @Component装饰器：
 * - 标识这是一个ArkUI自定义组件
 * - 可以使用build()方法构建UI
 */
@Entry
@Component
struct Index {
  
  // ==================== 导航栈管理 ====================
  
  /**
   * 导航路径栈
   * 
   * 功能说明：
   * - 管理整个应用的页面导航栈
   * - 支持页面的push、pop、replace等操作
   * - 维护页面间的导航关系
   * 
   * AppStorageV2.connect()说明：
   * - 将导航栈连接到应用级别的存储
   * - 确保导航状态在整个应用生命周期中保持
   * - 支持多页面间的状态共享
   * 
   * 注释掉的代码：
   * pathStack: NavPathStack = new NavPathStack();
   * - 这是本地导航栈的创建方式
   * - 与AppStorageV2.connect()相比，无法实现全局状态共享
   */
  pathStack: NavPathStack = AppStorageV2.connect(NavPathStack, 'navStack', () => new NavPathStack())!;

  // ==================== UI构建方法 ====================
  
  /**
   * 构建组件UI
   * 
   * 这是ArkUI组件的核心方法，用于定义页面的结构和样式
   * 在这个入口页面中，主要构建导航容器
   */
  build() {
    // 创建导航容器
    // Navigation是HarmonyOS提供的导航组件，用于管理页面间的跳转
    Navigation(this.pathStack) {
      // 导航容器内容为空
      // 实际的页面内容将通过pushPathByName()方法动态加载
    }
    .onAppear(() => {
      // 页面显示时的回调函数
      // 当Index页面显示时，自动跳转到Layout页面
      
      /**
       * pushPathByName()方法说明：
       * - 参数1："Layout" - 目标页面名称
       * - 参数2：null - 传递给目标页面的参数（这里不需要传递参数）
       * - 参数3：false - 是否替换当前页面（false表示不替换，保留当前页面在栈中）
       * 
       * 这样设计的原因：
       * - Index作为入口页面，主要负责初始化导航系统
       * - Layout作为主布局页面，包含实际的应用内容
       * - 通过自动跳转，用户直接看到主界面，提升用户体验
       */
      this.pathStack.pushPathByName("Layout", null, false)
    })
    .hideNavBar(true)  // 隐藏系统导航栏，提供沉浸式体验
  }
}