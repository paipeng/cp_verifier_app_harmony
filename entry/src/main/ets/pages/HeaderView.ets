
import { display } from '@kit.ArkUI';

@Entry
@Component
export struct HeaderView {
  @State widthA: number = 300
  @State heightA: string = '10%'
  @State fontSize: number = 26
  @State opacityA: number = 0.1
  @State imageHeight: string = '10%'
  aboutToAppear(): void {
    console.debug('HeaderPage aboutToAppear')

    setTimeout(() => {
      console.debug('timeout')
      animateTo({
        duration: 2000
      }, () => {
        console.debug('animateTo executed')
        let screenWidth = display.getDefaultDisplaySync().width;
        let screenHeight = display.getDefaultDisplaySync().height;
        console.debug(`screen size: ${screenWidth} - ${screenHeight}`)
        this.widthA = screenWidth
        this.heightA = '100%'
        this.fontSize = 40
        this.opacityA = 1.0
        this.imageHeight = '80%'
      })


    }, 200);
  }
  build() {
    Column() {
      Column() {
        Image($r('app.media.icon3'))
          .objectFit(ImageFit.Contain)
            //.backgroundColor(Color.Yellow)
          .height(this.imageHeight)
          .fillColor($r('app.color.PrimaryColor'))
          .padding({
            top: 50
          })

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