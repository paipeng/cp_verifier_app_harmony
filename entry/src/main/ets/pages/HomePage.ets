import { HeaderView } from './HeaderView';
import bundleManager from '@ohos.bundle.bundleManager';
import hilog from '@ohos.hilog';

@Entry
@Component
struct HomePage {
  @State versionString: string = ''
  @State bgColors: ResourceColor[] =
    ['rgb(213,213,213)', 'rgb(150,150,150)', 'rgb(0,74,175)', 'rgb(39,135,217)', 'rgb(61,157,180)', 'rgb(23,169,141)',
      'rgb(255,192,0)', 'rgb(170,10,33)'];

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
    RelativeContainer(){
      Column() {
        HeaderView()

        Column() {
          Grid() {
            ForEach(this.bgColors, (color: ResourceColor, index?: number | undefined) => {
              GridItem() {
                Text(`${index}`)
              }.backgroundColor(color)
            })
          }
          .columnsTemplate('1fr 1fr')
        }.height('60%')

      }
      .height('30%')
      .width('100%')

      Text(this.versionString)
        .padding({
          bottom: 20
        })
        .alignRules({
          bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
    }

  }

  resourceToString(resource: Resource): string {
    return getContext(this).resourceManager.getStringSync(resource)
  }
}