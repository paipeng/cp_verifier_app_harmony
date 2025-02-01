
import { display } from '@kit.ArkUI';

@Entry
@Component
export struct HeaderPage {
  @State widthA: number = 300
  @State heightA: number = 100
  @State fontSize: number = 26
  @State opacityA: number = 0.1
  aboutToAppear(): void {
    console.debug('HeaderPage aboutToAppear')

    setTimeout(() => {
      console.debug('timeout')
      animateTo({
        duration: 3000
      }, () => {
        console.debug('animateTo executed')
        let screenWidth = display.getDefaultDisplaySync().width;
        let screenHeight = display.getDefaultDisplaySync().height;
        console.debug(`screen size: ${screenWidth} - ${screenHeight}`)
        this.widthA = screenWidth
        this.heightA = screenHeight * 0.33
        this.fontSize = 50
        this.opacityA = 1.0
      })


    }, 200);
  }
  build() {
    Column() {
      Column()
        .backgroundColor(Color.Gray)
        .height('33%')
      Column() {
        Image($r('app.media.icon'))
          .objectFit(ImageFit.Contain)
            //.backgroundColor(Color.Yellow)
          .height('200')
        Text($r('app.string.app_name'))
          .id('HelloWorld')
          .fontSize(this.fontSize)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.PrimaryColor'))
      }
      .width(this.widthA)
      .height(this.heightA)
      .opacity(this.opacityA)
      .alignRules({
        center: { anchor: '__container__', align: VerticalAlign.Center },
        middle: { anchor: '__container__', align: HorizontalAlign.Center }
      })
      .animation({
        duration: 2000,
        curve: Curve.Ease,
        iterations: 1,
        playMode: PlayMode.Normal
      })

    }
    .height(this.heightA)
    .width('100%')
    .backgroundColor($r('app.color.SecondaryColor'))
  }
}