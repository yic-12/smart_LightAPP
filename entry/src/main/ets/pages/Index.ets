import { LightDevice, LightingManager } from '../model/LightModel';

/**
 * 智能照明系统主界面
 * Smart Lighting System Main Interface
 */
@Entry
@Component
struct Index {
  @State lightingManager: LightingManager = LightingManager.getInstance();
  @State currentLight: LightDevice = this.lightingManager.getDevice('light_001')!;
  @State isLightOn: boolean = false;
  @State brightness: number = 50;
  @State colorTemperature: number = 4000;

  build() {
    Column() {
      // 标题栏 Title Bar
      Row() {
        Text($r('app.string.light_control'))
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .height(60)
      .padding({ left: 20, right: 20 })
      .backgroundColor(Color.White)

      Scroll() {
        Column() {
          // 灯光状态卡片 Light Status Card
          Column() {
            // 灯泡图标 Light Bulb Icon
            Text('💡')
              .fontSize(80)
              .margin({ bottom: 20 })

            // 灯光名称 Light Name
            Text($r('app.string.living_room_light'))
              .fontSize(24)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .margin({ bottom: 10 })

            // 状态文本 Status Text
            Text(this.isLightOn ? $r('app.string.light_on') : $r('app.string.light_off'))
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: 30 })

            // 开关按钮 Power Button
            Button(this.isLightOn ? $r('app.string.turn_off') : $r('app.string.turn_on'))
              .width(120)
              .height(50)
              .fontSize(18)
              .backgroundColor(this.isLightOn ? $r('app.color.light_on_color') : $r('app.color.light_off_color'))
              .borderRadius(25)
              .onClick(() => {
                this.currentLight.togglePower();
                this.isLightOn = this.currentLight.isOn;
              })
          }
          .width('90%')
          .padding(30)
          .margin({ top: 20 })
          .backgroundColor(Color.White)
          .borderRadius(16)
          .shadow({
            radius: 10,
            color: '#1F000000',
            offsetX: 0,
            offsetY: 2
          })

          // 亮度控制 Brightness Control
          Column() {
            Row() {
              Text($r('app.string.brightness'))
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
              Blank()
              Text(`${this.brightness}%`)
                .fontSize(18)
                .fontColor($r('app.color.primary_color'))
            }
            .width('100%')
            .margin({ bottom: 20 })

            Slider({
              value: this.brightness,
              min: 0,
              max: 100,
              step: 1,
              style: SliderStyle.OutSet
            })
              .width('100%')
              .trackColor($r('app.color.background_color'))
              .selectedColor($r('app.color.primary_color'))
              .showTips(false)
              .onChange((value: number) => {
                this.brightness = Math.round(value);
                this.currentLight.setBrightness(this.brightness);
              })
          }
          .width('90%')
          .padding(20)
          .margin({ top: 20 })
          .backgroundColor(Color.White)
          .borderRadius(16)
          .shadow({
            radius: 10,
            color: '#1F000000',
            offsetX: 0,
            offsetY: 2
          })

          // 色温控制 Color Temperature Control
          Column() {
            Row() {
              Text($r('app.string.color_temperature'))
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
              Blank()
              Text(`${this.colorTemperature}K`)
                .fontSize(18)
                .fontColor($r('app.color.primary_color'))
            }
            .width('100%')
            .margin({ bottom: 20 })

            Row() {
              Text($r('app.string.warm'))
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
              Blank()
              Text($r('app.string.cool'))
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
            }
            .width('100%')
            .margin({ bottom: 10 })

            Slider({
              value: this.colorTemperature,
              min: 2700,
              max: 6500,
              step: 100,
              style: SliderStyle.OutSet
            })
              .width('100%')
              .trackColor($r('app.color.background_color'))
              .selectedColor($r('app.color.primary_color'))
              .showTips(false)
              .onChange((value: number) => {
                this.colorTemperature = Math.round(value);
                this.currentLight.setColorTemperature(this.colorTemperature);
              })
          }
          .width('90%')
          .padding(20)
          .margin({ top: 20, bottom: 30 })
          .backgroundColor(Color.White)
          .borderRadius(16)
          .shadow({
            radius: 10,
            color: '#1F000000',
            offsetX: 0,
            offsetY: 2
          })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .backgroundColor($r('app.color.background_color'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_color'))
  }
}
