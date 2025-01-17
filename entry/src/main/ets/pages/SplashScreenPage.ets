@Entry
@Component
struct Index {
  //@State message: string = ;
  @State widthA: number = 300
  @State heightA: string = '10%'
  @State fontSize: number = 26
  @State opacityA: number = 0.1
  onPageShow(): void {
    animateTo({
      duration: 1000
    }, () => {
      this.widthA = 650
      this.heightA = '100%'
      this.fontSize = 50
      this.opacityA = 1.0
    })

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
        .height('30%')
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
        iterations: -1,
        playMode: PlayMode.Normal
      })

    }
    .height('100%')
    .width('100%')
    .backgroundColor($r('app.color.SecondaryColor'))
  }
}