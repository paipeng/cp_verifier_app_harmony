import { HeaderPage } from './HeaderPage';
import bundleManager from '@ohos.bundle.bundleManager';
import hilog from '@ohos.hilog';

@Entry
@Component
struct HomePage {
  @State message: string = 'Hello World';
  @State versionString: string = ''
  onPageShow(): void {
    console.debug('HomePage onPageShow')

    let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION

    try {
      bundleManager.getBundleInfoForSelf(bundleFlags, (err, data) => {
        if (err) {
          hilog.error(0x0000, 'testTag', 'getBundleInfoForSelf failed: %{public}s', err.message);
        } else {
          hilog.info(0x0000, 'testTag', 'getBundleInfoForSelf successfully: %{public}s', JSON.stringify(data));

          this.versionString = this.resourceToString($r('app.string.version')) + ': ' + data.versionName
        }


      });
    } catch (err) {
      hilog.error(0x0000, 'testTag', 'getBundleInfoForSelf failed: %{public}s', err.message);
    }


  }
  build() {
    Column() {
      HeaderPage()
    }
    .height('30%')
    .width('100%')
  resourceToString(resource: Resource): string {
    return getContext(this).resourceManager.getStringSync(resource)
  }
}