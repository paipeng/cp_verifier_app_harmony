import { camera } from '@kit.CameraKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import hilog from '@ohos.hilog';
import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit';



@Entry
@Component
export struct CameraPage {

  TAG: string = CameraPage.name

  onPageShow(): void {
    hilog.info(0x0000, this.TAG, 'onPageShow');
    this.checkPermissions()
  }

  build() {
    RelativeContainer(){

    }.width('100%')
    .height('100%')
    .backgroundColor(0xffff00)
  }

  async checkPermissionGrant(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;

    // 获取应用程序的accessTokenID
    let tokenId: number = 0;
    try {
      let bundleInfo: bundleManager.BundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
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
    let grantStatus1: boolean = await this.checkPermissionGrant('ohos.permission.CAMERA') === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;// 获取精确定位权限状态
    let grantStatus2: boolean = await this.checkPermissionGrant('ohos.permission.MEDIA_LOCATION') === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;// 获取模糊定位权限状态
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

  getCameraManager(context: common.BaseContext): camera.CameraManager {
    let cameraManager: camera.CameraManager = camera.getCameraManager(context);
    return cameraManager;
  }
}