/**
 * 智能照明设备模型
 * Smart Lighting Device Model
 */
export class LightDevice {
  id: string;
  name: string;
  isOn: boolean;
  brightness: number; // 0-100
  colorTemperature: number; // 2700-6500K

  constructor(id: string, name: string) {
    this.id = id;
    this.name = name;
    this.isOn = false;
    this.brightness = 50;
    this.colorTemperature = 4000;
  }

  /**
   * 切换灯光开关
   * Toggle light power
   */
  togglePower(): void {
    this.isOn = !this.isOn;
  }

  /**
   * 设置亮度
   * Set brightness
   * @param brightness 亮度值 (0-100)
   */
  setBrightness(brightness: number): void {
    this.brightness = Math.max(0, Math.min(100, brightness));
  }

  /**
   * 设置色温
   * Set color temperature
   * @param temperature 色温值 (2700-6500)
   */
  setColorTemperature(temperature: number): void {
    this.colorTemperature = Math.max(2700, Math.min(6500, temperature));
  }

  /**
   * 获取灯光状态
   * Get light status
   * @returns boolean indicating if the light is on
   */
  getStatus(): boolean {
    return this.isOn;
  }
}

/**
 * 照明系统管理器
 * Lighting System Manager
 */
export class LightingManager {
  private static instance: LightingManager;
  private devices: Map<string, LightDevice>;

  private constructor() {
    this.devices = new Map();
    this.initializeDevices();
  }

  static getInstance(): LightingManager {
    if (!LightingManager.instance) {
      LightingManager.instance = new LightingManager();
    }
    return LightingManager.instance;
  }

  /**
   * 初始化设备
   * Initialize devices
   */
  private initializeDevices(): void {
    // Device name will be localized in the UI layer using resource strings
    const defaultLight = new LightDevice('light_001', 'Living Room Light');
    this.devices.set(defaultLight.id, defaultLight);
  }

  /**
   * 获取设备
   * Get device by id
   */
  getDevice(id: string): LightDevice | undefined {
    return this.devices.get(id);
  }

  /**
   * 获取所有设备
   * Get all devices
   */
  getAllDevices(): LightDevice[] {
    return Array.from(this.devices.values());
  }

  /**
   * 添加设备
   * Add device
   */
  addDevice(device: LightDevice): void {
    this.devices.set(device.id, device);
  }
}
