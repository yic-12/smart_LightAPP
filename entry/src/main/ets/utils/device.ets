/**
 * 智能照明管理APP - 设备控制数据 (device.ets)
 * 
 * 功能说明：
 * 1. 定义所有灯光设备的数据结构
 * 2. 提供不同场景下的设备组合配置
 * 3. 支持设备控制参数（亮度、色温、颜色等）
 * 4. 提供批量控制设备接口
 * 
 * 技术特点：
 * - 使用TypeScript接口定义
 * - 支持场景模式配置
 * - 设备参数可配置
 * - 支持多设备协同控制
 */

// 导入设备控制项接口
import { DeviceControlItem } from '../inter/Interface1'

// ==================== 设备控制数据定义 ====================

/**
 * 设备控制列表 - 全部25个设备
 * 
 * 功能说明：
 * - 包含实训中心所有25个灯光设备
 * - 每个设备包含完整的控制参数
 * - 用于单个设备控制和设备列表显示
 * 
 * 设备分布：
 * - 教室区域：10个设备（教室1-10行射灯）
 * - 实操区域：13个设备（实操区1-7行射灯、环形灯带、灯带灯组、线形灯带）
 * - 教学区域：2个设备（教学区射灯、线型灯带）
 * 
 * 参数说明：
 * - control_sub_id: 设备唯一标识符
 * - control_sub_state: 设备状态（'0'=开启，'1'=关闭）
 * - name: 设备名称
 * - w_channel: 白光通道值（亮度控制）
 * - y_channel: 暖光通道值（色温控制）
 * - type_uuid: 设备类型标识
 */
export const deviceControls: DeviceControlItem[] = [
  // 设备1 - 实操区射灯灯组 1（控制全部小灯）
  {
    control_sub_id: "ed6839e106ae49cdb84d4b920772abd4",
    control_sub_state: '0', // 打开
    name: '实操区射灯灯组 1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备2 - 氛围灯带
  {
    control_sub_id: "6b3f2977496844fd879845645099c5dd",
    control_sub_state: '0', // 打开
    name: '氛围灯带',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备3 - 教室1行射灯1
  {
    control_sub_id: "1d6f7bb91c824668bec9a40fd0720146",
    control_sub_state: '0', // 打开
    name: '教室1行射灯1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备4 - 教室2行射灯1
  {
    control_sub_id: "2303a8e63b524430ad872c653587fc7d",
    control_sub_state: '0', // 打开
    name: '教室2行射灯1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备5 - 教室3行射灯1
  {
    control_sub_id: "129ae737e4534ad7810f824ab6c0fe6e",
    control_sub_state: '0', // 打开
    name: '教室3行射灯1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备6 - 教室4行射灯1
  {
    control_sub_id: "e264629cd1c744c98c534d8f534b0356",
    control_sub_state: '0', // 打开
    name: '教室4行射灯1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备7 - 教室5行射灯1
  {
    control_sub_id: "631f332e5b814726acd856a8f6b40d10",
    control_sub_state: '0', // 打开
    name: '教室5行射灯1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备8 - 教室6行射灯1
  {
    control_sub_id: "dc87bfa72d0745f4a468a3818e4da223",
    control_sub_state: '0', // 打开
    name: '教室6行射灯1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备9 - 教室7行射灯1
  {
    control_sub_id: "a02aee173a7b46b89315a60423e375eb",
    control_sub_state: '0', // 打开
    name: '教室7行射灯1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备10 - 教室8行射灯1
  {
    control_sub_id: "feecc342d97749dfac992cc8103e3348",
    control_sub_state: '0', // 打开
    name: '教室8行射灯1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备11 - 教室9行射灯1
  {
    control_sub_id: "46a32f06de184ac7815e8d4bfcce6c48",
    control_sub_state: '0', // 打开
    name: '教室9行射灯1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备12 - 教室10行射灯1
  {
    control_sub_id: "ac8d971606a0448a94f2b8bf21a62271",
    control_sub_state: '0', // 打开
    name: '教室10行射灯1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备13 - 教室11行射灯1
  {
    control_sub_id: "cc30e58a9cd44b138a24db565c41653b",
    control_sub_state: '0', // 打开
    name: '教室11行射灯1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备14 - 实操区1行射灯1
  {
    control_sub_id: "1033cc1ffc974b50836020dd06110038",
    control_sub_state: '0', // 打开
    name: '实操区1行射灯1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备15 - 实操区2行射灯1
  {
    control_sub_id: "3e1fcedc89794db1926149cc1170489e",
    control_sub_state: '0', // 打开
    name: '实操区2行射灯1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备16 - 实操区3行射灯1
  {
    control_sub_id: "b3336b40cfe741e5a2610c85b0a14831",
    control_sub_state: '0', // 打开
    name: '实操区3行射灯1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备17 - 实操区4行射灯1
  {
    control_sub_id: "09c4be277a7943678cb5e1982bd41567",
    control_sub_state: '0', // 打开
    name: '实操区4行射灯1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备18 - 实操区5行射灯1
  {
    control_sub_id: "458c578f97764355acc180e19ecbe06b",
    control_sub_state: '0', // 打开
    name: '实操区5行射灯1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备19 - 实操区6行射灯1
  {
    control_sub_id: "603396ab55a04387a1a025a392f6f3ed",
    control_sub_state: '0', // 打开
    name: '实操区6行射灯1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备20 - 实操区7行射灯1
  {
    control_sub_id: "ea954931e6264c8db2c89bc0631ace3c",
    control_sub_state: '0', // 打开
    name: '实操区7行射灯1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备21 - 实操区环形灯带1
  {
    control_sub_id: "420dece3d98e41e8b4bac04cc825d6b2",
    control_sub_state: '0', // 打开
    name: '实操区环形灯带1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备22 - 实操区灯带灯组1（包括环形灯带及灯管）
  {
    control_sub_id: "a22b228be3b540638a3af2350982549b",
    control_sub_state: '0', // 打开
    name: '实操区灯带灯组1 ',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备23 - 实操区线形灯带1（只有灯管）
  {
    control_sub_id: "60e5b7d5b4034d09a59bbfcc4cf5b363",
    control_sub_state: '0', // 打开
    name: '实操区线形灯带1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备24 - 教学区射灯1（全部小灯）
  {
    control_sub_id: "c9b6bf04da8c453ba5b37f7bd1bc8db9",
    control_sub_state: '0', // 打开
    name: '教学区射灯1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备25 - 教学区线型灯带1（全部灯管）
  {
    control_sub_id: "b4e3359c8c3c420faa81e2b0c7aed1e0",
    control_sub_state: '0', // 打开
    name: '教学区线型灯带1',
    w_channel: 66,          // 亮度值
    y_channel: 66,          // 色温值
    type_uuid: 'LIGHT_GROUP'
  }
]

// ==================== 场景模式设备配置 ====================

/**
 * 教学场景设备配置
 * 
 * 功能说明：
 * - 适用于教学和学习环境
 * - 提供充足的照明，适合阅读和书写
 * - 色温偏暖，保护视力
 * 
 * 设备组合：
 * - 教学区射灯1：亮度80%，色温50%
 * - 教学区线型灯带1：亮度80%，色温50%
 * - 氛围灯带：亮度80%，色温50%，白色光
 * 
 * 参数特点：
 * - 亮度较高（80%），确保充足照明
 * - 色温适中（50%），减少眼疲劳
 * - 白色光，提供清晰的视觉环境
 */
export const deviceClass: DeviceControlItem[] = [
  // 设备24 - 教学区射灯1（全部小灯）
  {
    control_sub_id: "c9b6bf04da8c453ba5b37f7bd1bc8db9",
    control_sub_state: '0', // 打开
    w_channel: 80,          // 亮度值80%
    y_channel: 50,          // 色温值50%
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备25 - 教学区线型灯带1（全部灯管）
  {
    control_sub_id: "b4e3359c8c3c420faa81e2b0c7aed1e0",
    control_sub_state: '0', // 打开
    w_channel: 80,          // 亮度值80%
    y_channel: 50,          // 色温值50%
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备2 - 氛围灯带
  {
    control_sub_id: "6b3f2977496844fd879845645099c5dd",
    control_sub_state: '0', // 打开
    w_channel: 80,          // 亮度值80%
    y_channel: 50,          // 色温值50%
    r_channel: 255,         // 红色通道255
    g_channel: 255,         // 绿色通道255
    b_channel: 255,         // 蓝色通道255
    type_uuid: 'LIGHT_GROUP'
  }
]

/**
 * 实操场景设备配置
 * 
 * 功能说明：
 * - 适用于实践操作和实验环境
 * - 提供明亮的工作照明
 * - 适合精细操作和观察
 * 
 * 设备组合：
 * - 实操区灯带灯组1：亮度80%，色温50%，白色光
 * - 实操区射灯灯组1：亮度80%，色温50%
 * 
 * 参数特点：
 * - 亮度较高（80%），确保工作区域明亮
 * - 色温适中（50%），提供舒适的工作环境
 * - 白色光，确保颜色还原准确
 */
export const exper: DeviceControlItem[] = [
  // 设备22 - 实操区灯带灯组1（包括环形灯带及灯管）
  {
    control_sub_id: "a22b228be3b540638a3af2350982549b",
    control_sub_state: '0', // 打开
    w_channel: 80,          // 亮度值80%
    y_channel: 50,          // 色温值50%
    r_channel: 255,         // 红色通道255
    g_channel: 255,         // 绿色通道255
    b_channel: 255,         // 蓝色通道255
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备1 - 实操区射灯灯组1（控制全部小灯）
  {
    control_sub_id: "ed6839e106ae49cdb84d4b920772abd4",
    control_sub_state: '0', // 打开
    w_channel: 80,          // 亮度值80%
    y_channel: 50,          // 色温值50%
    type_uuid: 'LIGHT_GROUP'
  }
]

/**
 * 会议场景设备配置
 * 
 * 功能说明：
 * - 适用于会议和讨论环境
 * - 提供适中的照明，营造会议氛围
 * - 色温偏冷，提高专注度
 * 
 * 设备组合：
 * - 教学区射灯1：亮度60%，色温70%
 * - 教学区线型灯带1：亮度60%，色温70%
 * - 氛围灯带：亮度60%，色温70%，淡蓝色光
 * 
 * 参数特点：
 * - 亮度适中（60%），避免过亮影响讨论
 * - 色温较高（70%），提高专注度
 * - 淡蓝色光，营造专业氛围
 */
export const per: DeviceControlItem[] = [
  // 设备24 - 教学区射灯1（全部小灯）
  {
    control_sub_id: "c9b6bf04da8c453ba5b37f7bd1bc8db9",
    control_sub_state: '0', // 打开
    w_channel: 60,          // 亮度值60%
    y_channel: 70,          // 色温值70%
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备25 - 教学区线型灯带1（全部灯管）
  {
    control_sub_id: "b4e3359c8c3c420faa81e2b0c7aed1e0",
    control_sub_state: '0', // 打开
    w_channel: 60,          // 亮度值60%
    y_channel: 70,          // 色温值70%
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备2 - 氛围灯带
  {
    control_sub_id: "6b3f2977496844fd879845645099c5dd",
    control_sub_state: '0', // 打开
    w_channel: 60,          // 亮度值60%
    y_channel: 70,          // 色温值70%
    r_channel: 240,         // 红色通道240
    g_channel: 240,         // 绿色通道240
    b_channel: 255,         // 蓝色通道255
    type_uuid: 'LIGHT_GROUP'
  }
]

/**
 * 休息场景设备配置
 * 
 * 功能说明：
 * - 适用于休息和放松环境
 * - 提供柔和的照明，营造舒适氛围
 * - 色温偏暖，有助于放松
 * 
 * 设备组合：
 * - 教学区射灯1：亮度40%，色温30%
 * - 教学区线型灯带1：亮度40%，色温30%
 * - 氛围灯带：亮度40%，色温30%，暖黄色光
 * - 实操区灯带灯组1：亮度40%，色温30%，暖黄色光
 * - 实操区射灯灯组1：亮度40%，色温30%
 * 
 * 参数特点：
 * - 亮度较低（40%），营造放松氛围
 * - 色温较低（30%），暖光有助于放松
 * - 暖黄色光，营造温馨舒适的环境
 */
export const break1: DeviceControlItem[] = [
  // 设备24 - 教学区射灯1（全部小灯）
  {
    control_sub_id: "c9b6bf04da8c453ba5b37f7bd1bc8db9",
    control_sub_state: '0', // 打开
    w_channel: 40,          // 亮度值40%
    y_channel: 30,          // 色温值30%
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备25 - 教学区线型灯带1（全部灯管）
  {
    control_sub_id: "b4e3359c8c3c420faa81e2b0c7aed1e0",
    control_sub_state: '0', // 打开
    w_channel: 40,          // 亮度值40%
    y_channel: 30,          // 色温值30%
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备2 - 氛围灯带
  {
    control_sub_id: "6b3f2977496844fd879845645099c5dd",
    control_sub_state: '0', // 打开
    w_channel: 40,          // 亮度值40%
    y_channel: 30,          // 色温值30%
    r_channel: 255,         // 红色通道255
    g_channel: 220,         // 绿色通道220
    b_channel: 150,         // 蓝色通道150
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备22 - 实操区灯带灯组1（包括环形灯带及灯管）
  {
    control_sub_id: "a22b228be3b540638a3af2350982549b",
    control_sub_state: '0', // 打开
    w_channel: 40,          // 亮度值40%
    y_channel: 30,          // 色温值30%
    r_channel: 255,         // 红色通道255
    g_channel: 220,         // 绿色通道220
    b_channel: 150,         // 蓝色通道150
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备1 - 实操区射灯灯组1（控制全部小灯）
  {
    control_sub_id: "ed6839e106ae49cdb84d4b920772abd4",
    control_sub_state: '0', // 打开
    w_channel: 40,          // 亮度值40%
    y_channel: 30,          // 色温值30%
    type_uuid: 'LIGHT_GROUP'
  }
]

// ==================== 批量控制设备配置 ====================

/**
 * 批量控制设备配置
 * 
 * 功能说明：
 * - 用于批量控制全部25个设备
 * - 通过5个关键设备接口间接控制所有设备
 * - 支持全部开启/全部关闭操作
 * 
 * 设备组合：
 * - 教学区射灯1：控制教学区域所有小灯
 * - 教学区线型灯带1：控制教学区域所有灯管
 * - 氛围灯带：控制整体氛围照明
 * - 实操区灯带灯组1：控制实操区域灯带和灯管
 * - 实操区射灯灯组1：控制实操区域所有小灯
 * 
 * 参数特点：
 * - 使用默认参数（亮度66%，色温66%）
 * - 白色光配置，确保颜色还原
 * - 通过这5个设备可以控制全部25个设备
 */
export const turn: DeviceControlItem[] = [
  // 设备24 - 教学区射灯1（全部小灯）
  {
    control_sub_id: "c9b6bf04da8c453ba5b37f7bd1bc8db9",
    control_sub_state: '0', // 打开
    name: '教学区射灯1',
    w_channel: 66,          // 亮度值66%
    y_channel: 66,          // 色温值66%
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备25 - 教学区线型灯带1（全部灯管）
  {
    control_sub_id: "b4e3359c8c3c420faa81e2b0c7aed1e0",
    control_sub_state: '0', // 打开
    name: '教学区线型灯带1',
    w_channel: 66,          // 亮度值66%
    y_channel: 66,          // 色温值66%
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备2 - 氛围灯带
  {
    control_sub_id: "6b3f2977496844fd879845645099c5dd",
    control_sub_state: '0', // 打开
    name: '氛围灯带',
    w_channel: 66,          // 亮度值66%
    y_channel: 66,          // 色温值66%
    r_channel: 255,         // 红色通道255
    g_channel: 255,         // 绿色通道255
    b_channel: 255,         // 蓝色通道255
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备22 - 实操区灯带灯组1（包括环形灯带及灯管）
  {
    control_sub_id: "a22b228be3b540638a3af2350982549b",
    control_sub_state: '0', // 打开
    name: '实操区灯带灯组1',
    w_channel: 66,          // 亮度值66%
    y_channel: 66,          // 色温值66%
    r_channel: 255,         // 红色通道255
    g_channel: 255,         // 绿色通道255
    b_channel: 255,         // 蓝色通道255
    type_uuid: 'LIGHT_GROUP'
  },
  // 设备1 - 实操区射灯灯组1（控制全部小灯）
  {
    control_sub_id: "ed6839e106ae49cdb84d4b920772abd4",
    control_sub_state: '0', // 打开
    name: '实操区射灯灯组 1',
    w_channel: 66,          // 亮度值66%
    y_channel: 66,          // 色温值66%
    type_uuid: 'LIGHT_GROUP'
  }
]