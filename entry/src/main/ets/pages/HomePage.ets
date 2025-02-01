import { HeaderPage } from './HeaderPage';

@Entry
@Component
struct HomePage {
  @State message: string = 'Hello World';
  onPageShow(): void {
    console.debug('HomePage onPageShow')


  }
  build() {
    Column() {
      HeaderPage()
    }
    .height('30%')
    .width('100%')
  }
}