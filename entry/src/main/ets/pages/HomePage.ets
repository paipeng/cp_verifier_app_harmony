import { HeaderPage } from './HeaderPage';

@Entry
@Component
struct HomePage {
  @State message: string = 'Hello World';

  build() {
    Column() {
      HeaderPage()
    }
    .height('100%')
    .width('100%')
  }
}