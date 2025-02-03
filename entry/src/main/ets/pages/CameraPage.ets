import { camera } from '@kit.CameraKit';
import { BusinessError } from '@kit.BasicServicesKit';
import hilog from '@ohos.hilog';
import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit';
import { worker } from '@kit.ArkTS';
import { display } from '@kit.ArkUI';


@Entry
@Component
export struct CameraPage {
  private TAG: string = CameraPage.name
  private mXComponentController: XComponentController = new XComponentController();
  private surfaceId: string = '';
  private displayClass: display.Display | undefined
  @State imageWidth: number = 1920;//3840;
  @State imageHeight: number = 1080;//2160;
  // 创建ThreadWorker对象获取worker实例
  private workerInstance: worker.ThreadWorker = new worker.ThreadWorker('entry/ets/workers/CameraWorker.ets');

  onPageShow(): void {
    hilog.info(0x0000, this.TAG, 'onPageShow');
    this.checkPermissions()
    if ('' !== this.surfaceId) {
      // 通过worker实例向worker线程发送消息初始化相机
      this.workerInstance.postMessage({
        type: 'initCamera',
        context: getContext(this),
        surfaceId: this.surfaceId,
        previewSize: {
          width: this.imageWidth,
          height: this.imageHeight
        }
      })
    }
  }

  onPageHide(): void {
    // 通过worker实例向worker线程发送消息销毁相机
    this.workerInstance.postMessage({
      type: 'releaseCamera',
    })
  }

  aboutToAppear(): void {
    //let displayClass = null
    try {
      this.displayClass = display.getDefaultDisplaySync()
      console.info(' screen width: ' + this.displayClass.width)
      console.info(' screen height: ' + this.displayClass.height)
    } catch (exception) {

    }
  }

  build() {
    RelativeContainer() {
      Column() {
        XComponent({
          id: 'componentId',
          type: XComponentType.SURFACE,
          controller: this.mXComponentController
        })
          .onLoad(async () => {
            console.info('onLoad is called');
            // 初始化XComponent获取预览流surfaceId
            this.surfaceId = this.mXComponentController.getXComponentSurfaceId();
            let surfaceRect: SurfaceRect = {
              surfaceWidth: this.imageHeight * 1.25,
              surfaceHeight: this.imageWidth * 1.25
            };
            this.mXComponentController.setXComponentSurfaceRect(surfaceRect);
            console.info(`onLoad surfaceId: ${this.surfaceId}`);
            if (!this.workerInstance) {
              console.error('create stage worker failed');
              return;
            }
            // 宿主线程向worker线程发送初始化相机消息
            this.workerInstance.postMessage({
              type: 'initCamera',
              context: getContext(this), // 将宿主线程的context传给worker线程使用
              surfaceId: this.surfaceId, // 将surfaceId传给worker线程使用
              previewSize: {
                width: this.imageWidth,
                height: this.imageHeight
              }
            })
          })// The width and height of the surface are opposite to those of the XComponent.
          //.width(px2vp(this.imageHeight))
          //.height(px2vp(this.imageWidth))
          .width(this.displayClass?.width)
          .height(this.displayClass?.width! * this.imageHeight / this.imageWidth)

      }.justifyContent(FlexAlign.Center)
      .height('100%')

      Image($r('app.media.productchain_icon_inv'))
        .width(100)
        .padding({
          bottom: 20
        })
        .alignRules({
          bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick((event) => {
          hilog.info(0x0000, this.TAG, 'capture: ' + event);

          if (!this.workerInstance) {
            console.error('create stage worker failed');
            return;
          }
          // 宿主线程向worker线程发送初始化相机消息
          this.workerInstance.postMessage({
            type: 'capturePhoto',
            context: getContext(this), // 将宿主线程的context传给worker线程使用
            surfaceId: this.surfaceId,
            location: this.location
          })
        })
    }
    //.justifyContent(FlexAlign.End)
    .height('100%')
    .width('100%')
    .backgroundColor(0xFF00FF)
  }

  async checkPermissionGrant(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;

    // 获取应用程序的accessTokenID
    let tokenId: number = 0;
    try {
      let bundleInfo: bundleManager.BundleInfo =
        await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
      tokenId = appInfo.accessTokenId;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to get bundle info for self. Code is ${err.code}, message is ${err.message}`);
    }

    // 校验应用是否被授予权限
    try {
      grantStatus = await atManager.checkAccessToken(tokenId, permission);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to check access token. Code is ${err.code}, message is ${err.message}`);
    }

    return grantStatus;
  }

  async checkPermissions(): Promise<void> {
    let grantStatus1: boolean = await this.checkPermissionGrant('ohos.permission.CAMERA') ===
    abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED; // 获取精确定位权限状态
    let grantStatus2: boolean = await this.checkPermissionGrant('ohos.permission.MEDIA_LOCATION') ===
    abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED; // 获取模糊定位权限状态
    hilog.info(0x0000, this.TAG, 'grantStatus1: ' + grantStatus1);
    hilog.info(0x0000, this.TAG, 'grantStatus2: ' + grantStatus2);
    if (grantStatus2 && !grantStatus1) {
      // 申请精确定位权限
    } else if (!grantStatus1 && !grantStatus2) {
      // 申请模糊定位权限与精确定位权限或单独申请模糊定位权限
    } else {
      // 已经授权，可以继续访问目标操作
    }
  }
}