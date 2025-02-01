import { camera } from '@kit.CameraKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import hilog from '@ohos.hilog';


@Entry
@Component
export struct CameraPage {

  TAG: string = CameraPage.name

  onPageShow(): void {
    hilog.info(0x0000, this.TAG, 'onPageShow');

  }

  build() {
    RelativeContainer(){

    }.width('100%')
    .height('100%')
    .backgroundColor(0xffff00)
  }
}