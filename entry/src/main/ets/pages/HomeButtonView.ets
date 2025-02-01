
@Entry
@Component
export struct HomeButtonView {
  @State widthA: number = 300
  @State heightA: string = '10%'
  @State fontSize: number = 16
  @State subFontSize: number = 12
  @State opacityA: number = 0.1
  @State imageHeight: string = '10%'

  aboutToAppear(): void {
    console.debug('HomeButtonView aboutToAppear')
  }

  build() {
    Row() {
      Image($r('app.media.icon3'))
        .objectFit(ImageFit.Contain)
          //.backgroundColor(Color.Yellow)
        .height(this.imageHeight)
        .fillColor($r('app.color.PrimaryColor'))
        .width('40%')
        .padding({
          top: 8,
          bottom: 8,
          left: 16

        })
      Column() {
        Text('title')
          .id('text')
          .fontSize(this.fontSize)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.PrimaryColor'))
        Text('subtitle')
          .id('subtitle')
          .fontSize(this.subFontSize)
          .fontColor($r('app.color.PrimaryColor'))
      }.width('60%')

    }.margin({
      top: 10,
      left: 1,
      right: 1,
      bottom: 10
    })

  }
}
