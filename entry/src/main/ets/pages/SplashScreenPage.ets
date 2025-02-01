//import featureAbility from '@ohos.ability.featureAbility';
import { router } from '@kit.ArkUI'

@Entry
@Component
struct Index {
  //@State message: string = ;
  @State widthA: number = 300
  @State heightA: string = '10%'
  @State fontSize: number = 26
  @State opacityA: number = 0.1
  @State imageHeight: string = '10%'
  onPageShow(): void {
    console.debug('SplashScreenPage onPageShow')

    animateTo({
      duration: 500
    }, () => {
      console.debug('animateTo executed')
      this.widthA = 650
      this.heightA = '100%'
      this.fontSize = 50
      this.opacityA = 1.0
    })

    setTimeout(() => {

      animateTo({
        duration: 2000
      }, () => {
        console.debug('animateTo executed')
        this.imageHeight = '30%'
      })

      setTimeout(() => {

        router.replaceUrl({
          url: 'pages/HomePage'
        })
      }, 2000); // 延迟2000毫秒（2秒）后执行
    }, 500); // 延迟2000毫秒（2秒）后执行

  }
  build() {
    Column() {
      Column()
        //.backgroundColor(Color.Gray)
        .height('33%')
      Column() {
      Image($r('app.media.icon3'))
        .objectFit(ImageFit.Contain)
        //.backgroundColor(Color.Yellow)
        .height(this.imageHeight)
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
    .height('100%')
    .width('100%')
    .backgroundColor($r('app.color.SecondaryColor'))
    .onClick(() => {


    })
  }
}