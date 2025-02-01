import { camera } from '@kit.CameraKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import hilog from '@ohos.hilog';
import { abilityAccessCtrl, bundleManager, Permissions } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';


@Entry
@Component
export struct CameraPage {

  TAG: string = CameraPage.name
  //cameraManager: camera.CameraManager

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

  getCameraDevices(cameraManager: camera.CameraManager): Array<camera.CameraDevice> {
    let cameraArray: Array<camera.CameraDevice> = cameraManager.getSupportedCameras();
    if (cameraArray != undefined && cameraArray.length > 0) {
      for (let index = 0; index < cameraArray.length; index++) {
        console.info('cameraId : ' + cameraArray[index].cameraId);  // 获取相机ID
        console.info('cameraPosition : ' + cameraArray[index].cameraPosition);  // 获取相机位置
        console.info('cameraType : ' + cameraArray[index].cameraType);  // 获取相机类型
        console.info('connectionType : ' + cameraArray[index].connectionType);  // 获取相机连接类型
      }
      return cameraArray;
    } else {
      console.error("cameraManager.getSupportedCameras error");
      return [];
    }
  }
  async createInput(cameraDevice: camera.CameraDevice, cameraManager: camera.CameraManager): Promise<camera.CameraInput | undefined> {
    // 创建相机输入流
    let cameraInput: camera.CameraInput | undefined = undefined;
    try {
      cameraInput = cameraManager.createCameraInput(cameraDevice);
    } catch (error) {
      let err = error as BusinessError;
      console.error('Failed to createCameraInput errorCode = ' + err.code);
    }
    if (cameraInput === undefined) {
      return undefined;
    }
    // 监听cameraInput错误信息
    cameraInput.on('error', cameraDevice, (error: BusinessError) => {
      console.error(`Camera input error code: ${error.code}`);
    });
    // 打开相机
    await cameraInput.open();
    return cameraInput;
  }

  setPhotoOutputCb(photoOutput: camera.PhotoOutput): void {
    //设置回调之后，调用photoOutput的capture方法，就会将拍照的buffer回传到回调中
    photoOutput.on('photoAvailable', (errCode: BusinessError, photo: camera.Photo): void => {
      console.info('getPhoto start');
      console.info(`err: ${JSON.stringify(errCode)}`);
      if (errCode || photo === undefined) {
        console.error('getPhoto failed');
        return;
      }
      let imageObj = photo.main;
      imageObj.getComponent(image.ComponentType.JPEG, (errCode: BusinessError, component: image.Component): void => {
        console.info('getComponent start');
        if (errCode || component === undefined) {
          console.error('getComponent failed');
          return;
        }

        if (component.byteBuffer) {
          //let buffer: ArrayBuffer;
          //buffer = component.byteBuffer;
        } else {
          console.error('byteBuffer is null');

          return;
        }

        // 如需要在图库中看到所保存的图片、视频资源，请使用用户无感的安全控件创建媒体资源。

        // buffer处理结束后需要释放该资源，如果未正确释放资源会导致后续拍照获取不到buffer
        imageObj.release();
      });
    });
  }

  async cameraShootingCase(baseContext: common.BaseContext, surfaceId: string): Promise<void> {
    // 创建CameraManager对象
    let cameraManager: camera.CameraManager = camera.getCameraManager(baseContext);
    if (!cameraManager) {
      console.error("camera.getCameraManager error");
      return;
    }
    // 监听相机状态变化
    cameraManager.on('cameraStatus', (err: BusinessError, cameraStatusInfo: camera.CameraStatusInfo) => {
      if (err !== undefined && err.code !== 0) {
        console.error('cameraStatus with errorCode = ' + err.code);
        return;
      }
      console.info(`camera : ${cameraStatusInfo.camera.cameraId}`);
      console.info(`status: ${cameraStatusInfo.status}`);
    });

    // 获取相机列表
    let cameraArray: Array<camera.CameraDevice> = cameraManager.getSupportedCameras();
    if (cameraArray.length <= 0) {
      console.error("cameraManager.getSupportedCameras error");
      return;
    }

    for (let index = 0; index < cameraArray.length; index++) {
      console.info('cameraId : ' + cameraArray[index].cameraId); // 获取相机ID
      console.info('cameraPosition : ' + cameraArray[index].cameraPosition); // 获取相机位置
      console.info('cameraType : ' + cameraArray[index].cameraType); // 获取相机类型
      console.info('connectionType : ' + cameraArray[index].connectionType); // 获取相机连接类型
    }

    // 创建相机输入流
    let cameraInput: camera.CameraInput | undefined = undefined;
    try {
      cameraInput = cameraManager.createCameraInput(cameraArray[0]);
    } catch (error) {
      let err = error as BusinessError;
      console.error('Failed to createCameraInput errorCode = ' + err.code);
    }
    if (cameraInput === undefined) {
      return;
    }

    // 监听cameraInput错误信息
    let cameraDevice: camera.CameraDevice = cameraArray[0];
    cameraInput.on('error', cameraDevice, (error: BusinessError) => {
      console.error(`Camera input error code: ${error.code}`);
    })

    // 打开相机
    await cameraInput.open();

    // 获取支持的模式类型
    let sceneModes: Array<camera.SceneMode> = cameraManager.getSupportedSceneModes(cameraArray[0]);
    let isSupportPhotoMode: boolean = sceneModes.indexOf(camera.SceneMode.NORMAL_PHOTO) >= 0;
    if (!isSupportPhotoMode) {
      console.error('photo mode not support');
      return;
    }
    // 获取相机设备支持的输出流能力
    let cameraOutputCap: camera.CameraOutputCapability =
      cameraManager.getSupportedOutputCapability(cameraArray[0], camera.SceneMode.NORMAL_PHOTO);
    if (!cameraOutputCap) {
      console.error("cameraManager.getSupportedOutputCapability error");
      return;
    }
    console.info("outputCapability: " + JSON.stringify(cameraOutputCap));

    let previewProfilesArray: Array<camera.Profile> = cameraOutputCap.previewProfiles;
    if (!previewProfilesArray) {
      console.error("createOutput previewProfilesArray == null || undefined");
    }

    let photoProfilesArray: Array<camera.Profile> = cameraOutputCap.photoProfiles;
    if (!photoProfilesArray) {
      console.error("createOutput photoProfilesArray == null || undefined");
    }

    // 创建预览输出流,其中参数 surfaceId 参考上文 XComponent 组件，预览流为XComponent组件提供的surface
    let previewOutput: camera.PreviewOutput | undefined = undefined;
    try {
      previewOutput = cameraManager.createPreviewOutput(previewProfilesArray[0], surfaceId);
    } catch (error) {
      let err = error as BusinessError;
      console.error(`Failed to create the PreviewOutput instance. error code: ${err.code}`);
    }
    if (previewOutput === undefined) {
      return;
    }
    // 监听预览输出错误信息
    previewOutput.on('error', (error: BusinessError) => {
      console.error(`Preview output error code: ${error.code}`);
    });

    // 创建拍照输出流
    let photoOutput: camera.PhotoOutput | undefined = undefined;
    try {
      photoOutput = cameraManager.createPhotoOutput(photoProfilesArray[0]);
    } catch (error) {
      let err = error as BusinessError;
      console.error('Failed to createPhotoOutput errorCode = ' + err.code);
    }
    if (photoOutput === undefined) {
      return;
    }

    //调用上面的回调函数来保存图片
    this.setPhotoOutputCb(photoOutput);

    //创建会话
    let photoSession: camera.PhotoSession | undefined = undefined;
    try {
      photoSession = cameraManager.createSession(camera.SceneMode.NORMAL_PHOTO) as camera.PhotoSession;
    } catch (error) {
      let err = error as BusinessError;
      console.error('Failed to create the session instance. errorCode = ' + err.code);
    }
    if (photoSession === undefined) {
      return;
    }
    // 监听session错误信息
    photoSession.on('error', (error: BusinessError) => {
      console.error(`Capture session error code: ${error.code}`);
    });

    // 开始配置会话
    try {
      photoSession.beginConfig();
    } catch (error) {
      let err = error as BusinessError;
      console.error('Failed to beginConfig. errorCode = ' + err.code);
    }

    // 向会话中添加相机输入流
    try {
      photoSession.addInput(cameraInput);
    } catch (error) {
      let err = error as BusinessError;
      console.error('Failed to addInput. errorCode = ' + err.code);
    }

    // 向会话中添加预览输出流
    try {
      photoSession.addOutput(previewOutput);
    } catch (error) {
      let err = error as BusinessError;
      console.error('Failed to addOutput(previewOutput). errorCode = ' + err.code);
    }

    // 向会话中添加拍照输出流
    try {
      photoSession.addOutput(photoOutput);
    } catch (error) {
      let err = error as BusinessError;
      console.error('Failed to addOutput(photoOutput). errorCode = ' + err.code);
    }

    // 提交会话配置
    await photoSession.commitConfig();

    // 启动会话
    await photoSession.start().then(() => {
      console.info('Promise returned to indicate the session start success.');
    });
    // 判断设备是否支持闪光灯
    let flashStatus: boolean = false;
    try {
      flashStatus = photoSession.hasFlash();
    } catch (error) {
      let err = error as BusinessError;
      console.error('Failed to hasFlash. errorCode = ' + err.code);
    }
    console.info('Returned with the flash light support status:' + flashStatus);

    if (flashStatus) {
      // 判断是否支持自动闪光灯模式
      let flashModeStatus: boolean = false;
      try {
        let status: boolean = photoSession.isFlashModeSupported(camera.FlashMode.FLASH_MODE_AUTO);
        flashModeStatus = status;
      } catch (error) {
        let err = error as BusinessError;
        console.error('Failed to check whether the flash mode is supported. errorCode = ' + err.code);
      }
      if (flashModeStatus) {
        // 设置自动闪光灯模式
        try {
          photoSession.setFlashMode(camera.FlashMode.FLASH_MODE_AUTO);
        } catch (error) {
          let err = error as BusinessError;
          console.error('Failed to set the flash mode. errorCode = ' + err.code);
        }
      }
    }
    // 判断是否支持连续自动变焦模式
    let focusModeStatus: boolean = false;
    try {
      let status: boolean = photoSession.isFocusModeSupported(camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO);
      focusModeStatus = status;
    } catch (error) {
      let err = error as BusinessError;
      console.error('Failed to check whether the focus mode is supported. errorCode = ' + err.code);
    }

    if (focusModeStatus) {
      // 设置连续自动变焦模式
      try {
        photoSession.setFocusMode(camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO);
      } catch (error) {
        let err = error as BusinessError;
        console.error('Failed to set the focus mode. errorCode = ' + err.code);
      }
    }

    // 获取相机支持的可变焦距比范围
    let zoomRatioRange: Array<number> = [];
    try {
      zoomRatioRange = photoSession.getZoomRatioRange();
    } catch (error) {
      let err = error as BusinessError;
      console.error('Failed to get the zoom ratio range. errorCode = ' + err.code);
    }
    if (zoomRatioRange.length <= 0) {
      return;
    }
    // 设置可变焦距比
    try {
      photoSession.setZoomRatio(zoomRatioRange[0]);
    } catch (error) {
      let err = error as BusinessError;
      console.error('Failed to set the zoom ratio value. errorCode = ' + err.code);
    }
    let photoCaptureSetting: camera.PhotoCaptureSetting = {
      quality: camera.QualityLevel.QUALITY_LEVEL_HIGH, // 设置图片质量高
      rotation: camera.ImageRotation.ROTATION_0 // 设置图片旋转角度0
    }
    // 使用当前拍照设置进行拍照
    photoOutput.capture(photoCaptureSetting, (err: BusinessError) => {
      if (err) {
        console.error(`Failed to capture the photo ${err.message}`);
        return;
      }
      console.info('Callback invoked to indicate the photo capture request success.');
    });

    // 需要在拍照结束之后调用以下关闭摄像头和释放会话流程，避免拍照未结束就将会话释放。
    // 停止当前会话
    await photoSession.stop();

    // 释放相机输入流
    await cameraInput.close();

    // 释放预览输出流
    await previewOutput.release();

    // 释放拍照输出流
    await photoOutput.release();

    // 释放会话
    await photoSession.release();

    // 会话置空
    photoSession = undefined;
  }
}