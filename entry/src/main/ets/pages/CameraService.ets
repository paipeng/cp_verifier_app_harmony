import { camera } from '@kit.CameraKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';

class CameraService {
  private imageWidth: number = 1920;
  private imageHeight: number = 1080;
  private cameraManager: camera.CameraManager | undefined = undefined;
  private cameras: Array<camera.CameraDevice> | Array<camera.CameraDevice> = [];
  private cameraInput: camera.CameraInput | undefined = undefined;
  private previewOutput: camera.PreviewOutput | undefined = undefined;
  private photoOutput: camera.PhotoOutput | undefined = undefined;
  private session: camera.PhotoSession | camera.VideoSession | undefined = undefined;

  // 初始化相机
  async initCamera(context: Context, surfaceId: string): Promise<void> {
    console.info(`initCamera surfaceId: ${surfaceId}`);
    try {
      await this.releaseCamera();
      // 获取相机管理器实例
      this.cameraManager = getCameraManager(context)//camera.getCameraManager(context);
      if (this.cameraManager === undefined) {
        console.error('cameraManager is undefined');
        return;
      }
      this.cameras = this.cameraManager.getSupportedCameras();
      for (const cam of this.cameras) {
        // 0: back camera
        // 1: front camera
        console.debug('cameraId: ' + cam.cameraId + ' position: ' + cam.cameraPosition.valueOf() + ' type: ' + cam.cameraType.valueOf() + ' orientation: ' + cam.cameraOrientation + ' connectionType: ' + cam.connectionType.valueOf())
      }

      // 创建cameraInput输出对象
      this.cameraInput = this.cameraManager.createCameraInput(this.cameras[0]);
      if (this.cameraInput === undefined) {
        console.error('Failed to create the camera input.');
        return;
      }
      // 打开相机
      await this.cameraInput.open();

      let previewProfile: camera.Profile = {
        format: camera.CameraFormat.CAMERA_FORMAT_YUV_420_SP,
        size: {
          width: this.imageWidth,
          height: this.imageHeight
        }
      };
      // 创建预览流输出
      this.previewOutput = getPreviewOutput2(this.cameraManager, previewProfile, surfaceId)//this.cameraManager.createPreviewOutput(previewProfile, surfaceId);
      if (this.previewOutput === undefined) {
        console.error('Failed to create the preview stream.');
        return;
      }

      let photoProfile: camera.Profile = {
        format: camera.CameraFormat.CAMERA_FORMAT_JPEG,
        size: {
          width: this.imageWidth,
          height: this.imageHeight
        }
      };
      // 创建拍照流输出
      this.photoOutput = this.cameraManager.createPhotoOutput(photoProfile);
      if (this.photoOutput === undefined) {
        console.error('Failed to create the photoOutput.');
        return;
      }

      // 创建相机会话，启动会话
      this.session = this.cameraManager.createSession(camera.SceneMode.NORMAL_PHOTO) as camera.PhotoSession;
      this.session.beginConfig();
      this.session.addInput(this.cameraInput);
      this.session.addOutput(this.previewOutput);
      this.session.addOutput(this.photoOutput);
      await this.session.commitConfig();
      await this.session.start();
    } catch (error) {
      let err = error as BusinessError;
      console.error(`initCamera fail: ${JSON.stringify(err)}`);
    }
  }

  // 释放相机资源
  async releaseCamera(): Promise<void> {
    console.info('releaseCamera is called');
    try {
      await this.previewOutput?.release();
      await this.photoOutput?.release();
      await this.session?.release();
      await this.cameraInput?.close();
    } catch (error) {
      let err = error as BusinessError;
      console.error(`releaseCamera fail: error: ${JSON.stringify(err)}`);
    } finally {
      this.previewOutput = undefined;
      this.photoOutput = undefined;
      this.cameraManager = undefined;
      this.session = undefined;
      this.cameraInput = undefined;
    }
    console.info('releaseCamera success');
  }
}

export default new CameraService();


function getCameraManager(context: common.BaseContext): camera.CameraManager {
  let cameraManager: camera.CameraManager = camera.getCameraManager(context);
  return cameraManager;
}

function getCameraDevices(cameraManager: camera.CameraManager): Array<camera.CameraDevice> {
  let cameraArray: Array<camera.CameraDevice> = cameraManager.getSupportedCameras();
  if (cameraArray != undefined && cameraArray.length > 0) {
    for (let index = 0; index < cameraArray.length; index++) {
      console.info('cameraId : ' + cameraArray[index].cameraId); // 获取相机ID
      console.info('cameraPosition : ' + cameraArray[index].cameraPosition); // 获取相机位置
      console.info('cameraType : ' + cameraArray[index].cameraType); // 获取相机类型
      console.info('connectionType : ' + cameraArray[index].connectionType); // 获取相机连接类型
    }
    return cameraArray;
  } else {
    console.error("cameraManager.getSupportedCameras error");
    return [];
  }
}

function onCameraStatusChange(cameraManager: camera.CameraManager): void {
  cameraManager.on('cameraStatus', (err: BusinessError, cameraStatusInfo: camera.CameraStatusInfo) => {
    if (err !== undefined && err.code !== 0) {
      console.error(`Callback Error, errorCode: ${err.code}`);
      return;
    }
    // 如果当通过USB连接相机设备时，回调函数会返回新的相机出现状态
    if (cameraStatusInfo.status == camera.CameraStatus.CAMERA_STATUS_APPEAR) {
      console.info(`New Camera device appear.`);
    }
    // 如果当断开相机设备USB连接时，回调函数会返回相机被移除状态
    if (cameraStatusInfo.status == camera.CameraStatus.CAMERA_STATUS_DISAPPEAR) {
      console.info(`Camera device has been removed.`);
    }
    // 相机被关闭时，回调函数会返回相机可用状态
    if (cameraStatusInfo.status == camera.CameraStatus.CAMERA_STATUS_AVAILABLE) {
      console.info(`Current Camera is available.`);
    }
    // 相机被打开/占用时，回调函数会返回相机不可用状态
    if (cameraStatusInfo.status == camera.CameraStatus.CAMERA_STATUS_UNAVAILABLE) {
      console.info(`Current Camera has been occupied.`);
    }
    console.info(`camera: ${cameraStatusInfo.camera.cameraId}`);
    console.info(`status: ${cameraStatusInfo.status}`);
  });
}

async function createInput(cameraDevice: camera.CameraDevice,
  cameraManager: camera.CameraManager): Promise<camera.CameraInput | undefined> {
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

function getSupportedSceneMode(cameraDevice: camera.CameraDevice,
  cameraManager: camera.CameraManager): Array<camera.SceneMode> {
  // 获取相机设备支持的模式列表
  let sceneModeArray: Array<camera.SceneMode> = cameraManager.getSupportedSceneModes(cameraDevice);
  if (sceneModeArray != undefined && sceneModeArray.length > 0) {
    for (let index = 0; index < sceneModeArray.length; index++) {
      console.info('Camera SceneMode : ' + sceneModeArray[index]);
    }
    return sceneModeArray;
  } else {
    console.error("cameraManager.getSupportedSceneModes error");
    return [];
  }
}

async function getSupportedOutputCapability(cameraDevice: camera.CameraDevice, cameraManager: camera.CameraManager,
  sceneMode: camera.SceneMode): Promise<camera.CameraOutputCapability | undefined> {
  // 获取相机设备支持的输出流能力
  let cameraOutputCapability: camera.CameraOutputCapability =
    cameraManager.getSupportedOutputCapability(cameraDevice, sceneMode);
  if (!cameraOutputCapability) {
    console.error("cameraManager.getSupportedOutputCapability error");
    return undefined;
  }
  console.info("outputCapability: " + JSON.stringify(cameraOutputCapability));
  // 以NORMAL_PHOTO模式为例，需要添加预览流、拍照流
  // previewProfiles属性为获取当前设备支持的预览输出流
  let previewProfilesArray: Array<camera.Profile> = cameraOutputCapability.previewProfiles;
  if (!previewProfilesArray) {
    console.error("createOutput previewProfilesArray == null || undefined");
  }
  //photoProfiles属性为获取当前设备支持的拍照输出流
  let photoProfilesArray: Array<camera.Profile> = cameraOutputCapability.photoProfiles;
  if (!photoProfilesArray) {
    console.error("createOutput photoProfilesArray == null || undefined");
  }
  return cameraOutputCapability;
}

function getSession(cameraManager: camera.CameraManager): camera.Session | undefined {
  let session: camera.Session | undefined = undefined;
  try {
    session = cameraManager.createSession(camera.SceneMode.NORMAL_PHOTO) as camera.PhotoSession;
  } catch (error) {
    let err = error as BusinessError;
    console.error(`Failed to create the session instance. error: ${JSON.stringify(err)}`);
  }
  return session;
}

function beginConfig(photoSession: camera.PhotoSession): void {
  try {
    photoSession.beginConfig();
  } catch (error) {
    let err = error as BusinessError;
    console.error(`Failed to beginConfig. error: ${JSON.stringify(err)}`);
  }
}

async function startSession(photoSession: camera.PhotoSession, cameraInput: camera.CameraInput,
  previewOutput: camera.PreviewOutput, photoOutput: camera.PhotoOutput): Promise<void> {
  try {
    photoSession.addInput(cameraInput);
  } catch (error) {
    let err = error as BusinessError;
    console.error(`Failed to addInput. error: ${JSON.stringify(err)}`);
  }
  try {
    photoSession.addOutput(previewOutput);
  } catch (error) {
    let err = error as BusinessError;
    console.error(`Failed to add previewOutput. error: ${JSON.stringify(err)}`);
  }
  try {
    photoSession.addOutput(photoOutput);
  } catch (error) {
    let err = error as BusinessError;
    console.error(`Failed to add photoOutput. error: ${JSON.stringify(err)}`);
  }
  try {
    await photoSession.commitConfig();
  } catch (error) {
    let err = error as BusinessError;
    console.error(`Failed to commitConfig. error: ${JSON.stringify(err)}`);
  }

  try {
    await photoSession.start();
  } catch (error) {
    let err = error as BusinessError;
    console.error(`Failed to start. error: ${JSON.stringify(err)}`);
  }
}

async function switchOutput(photoSession: camera.PhotoSession, videoOutput: camera.VideoOutput,
  photoOutput: camera.PhotoOutput): Promise<void> {
  try {
    await photoSession.stop();
  } catch (error) {
    let err = error as BusinessError;
    console.error(`Failed to stop. error: ${JSON.stringify(err)}`);
  }

  try {
    photoSession.beginConfig();
  } catch (error) {
    let err = error as BusinessError;
    console.error(`Failed to beginConfig. error: ${JSON.stringify(err)}`);
  }
  // 从会话中移除拍照输出流
  try {
    photoSession.removeOutput(photoOutput);
  } catch (error) {
    let err = error as BusinessError;
    console.error(`Failed to remove photoOutput. error: ${JSON.stringify(err)}`);
  }
  // 向会话中添加视频输出流
  try {
    photoSession.addOutput(videoOutput);
  } catch (error) {
    let err = error as BusinessError;
    console.error(`Failed to add videoOutput. error: ${JSON.stringify(err)}`);
  }
}


async function cameraShootingCase(baseContext: common.BaseContext, surfaceId: string): Promise<void> {
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
  setPhotoOutputCb(photoOutput);

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

function getPreviewOutput(cameraManager: camera.CameraManager, cameraOutputCapability: camera.CameraOutputCapability,
  surfaceId: string): camera.PreviewOutput | undefined {
  let previewProfilesArray: Array<camera.Profile> = cameraOutputCapability.previewProfiles;
  let previewOutput: camera.PreviewOutput | undefined = undefined;
  try {
    previewOutput = cameraManager.createPreviewOutput(previewProfilesArray[0], surfaceId);
  } catch (error) {
    let err = error as BusinessError;
    console.error("Failed to create the PreviewOutput instance. error code: " + err.code);
  }
  return previewOutput;
}


function getPreviewOutput2(cameraManager: camera.CameraManager, cameraProfile: camera.Profile,
  surfaceId: string): camera.PreviewOutput | undefined {
  let previewOutput: camera.PreviewOutput | undefined = undefined;
  try {
    previewOutput = cameraManager.createPreviewOutput(cameraProfile, surfaceId);
  } catch (error) {
    let err = error as BusinessError;
    console.error("Failed to create the PreviewOutput instance. error code: " + err.code);
  }
  return previewOutput;
}

async function startPreviewOutput(cameraManager: camera.CameraManager,
  previewOutput: camera.PreviewOutput): Promise<void> {
  let cameraArray: Array<camera.CameraDevice> = [];
  cameraArray = cameraManager.getSupportedCameras();
  if (cameraArray.length == 0) {
    console.error('no camera.');
    return;
  }
  // 获取支持的模式类型
  let sceneModes: Array<camera.SceneMode> = cameraManager.getSupportedSceneModes(cameraArray[0]);
  let isSupportPhotoMode: boolean = sceneModes.indexOf(camera.SceneMode.NORMAL_PHOTO) >= 0;
  if (!isSupportPhotoMode) {
    console.error('photo mode not support');
    return;
  }
  let cameraInput: camera.CameraInput | undefined = undefined;
  cameraInput = cameraManager.createCameraInput(cameraArray[0]);
  if (cameraInput === undefined) {
    console.error('cameraInput is undefined');
    return;
  }
  // 打开相机
  await cameraInput.open();
  let session: camera.PhotoSession = cameraManager.createSession(camera.SceneMode.NORMAL_PHOTO) as camera.PhotoSession;
  session.beginConfig();
  session.addInput(cameraInput);
  session.addOutput(previewOutput);
  await session.commitConfig();
  await session.start();
}

function onPreviewOutputFrameStart(previewOutput: camera.PreviewOutput): void {
  previewOutput.on('frameStart', (err: BusinessError) => {
    if (err !== undefined && err.code !== 0) {
      return;
    }
    console.info('Preview frame started');
  });
}

function onPreviewOutputFrameEnd(previewOutput: camera.PreviewOutput): void {
  previewOutput.on('frameEnd', (err: BusinessError) => {
    if (err !== undefined && err.code !== 0) {
      return;
    }
    console.info('Preview frame ended');
  });
}

function onPreviewOutputError(previewOutput: camera.PreviewOutput): void {
  previewOutput.on('error', (previewOutputError: BusinessError) => {
    console.error(`Preview output error code: ${previewOutputError.code}`);
  });
}

function getPhotoOutput(cameraManager: camera.CameraManager, cameraOutputCapability: camera.CameraOutputCapability): camera.PhotoOutput | undefined {
  let photoProfilesArray: Array<camera.Profile> = cameraOutputCapability.photoProfiles;
  if (!photoProfilesArray) {
    console.error("createOutput photoProfilesArray == null || undefined");
  }
  let photoOutput: camera.PhotoOutput | undefined = undefined;
  try {
    photoOutput = cameraManager.createPhotoOutput(photoProfilesArray[0]);
  } catch (error) {
    let err = error as BusinessError;
    console.error(`Failed to createPhotoOutput. error: ${JSON.stringify(err)}`);
  }
  return photoOutput;
}

function setPhotoOutputCb(photoOutput: camera.PhotoOutput): void {
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

function configuringSession(photoSession: camera.PhotoSession): void {
  // 判断设备是否支持闪光灯
  let flashStatus: boolean = false;
  try {
    flashStatus = photoSession.hasFlash();
  } catch (error) {
    let err = error as BusinessError;
    console.error(`Failed to hasFlash. error: ${JSON.stringify(err)}`);
  }
  console.info(`Returned with the flash light support status: ${flashStatus}`);
  if (flashStatus) {
    // 判断是否支持自动闪光灯模式
    let flashModeStatus: boolean = false;
    try {
      let status: boolean = photoSession.isFlashModeSupported(camera.FlashMode.FLASH_MODE_AUTO);
      flashModeStatus = status;
    } catch (error) {
      let err = error as BusinessError;
      console.error(`Failed to check whether the flash mode is supported. error: ${JSON.stringify(err)}`);
    }
    if (flashModeStatus) {
      // 设置自动闪光灯模式
      try {
        photoSession.setFlashMode(camera.FlashMode.FLASH_MODE_AUTO);
      } catch (error) {
        let err = error as BusinessError;
        console.error(`Failed to set the flash mode. error: ${JSON.stringify(err)}`);
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
    console.error(`Failed to check whether the focus mode is supported. error: ${JSON.stringify(err)}`);
  }
  if (focusModeStatus) {
    // 设置连续自动变焦模式
    try {
      photoSession.setFocusMode(camera.FocusMode.FOCUS_MODE_CONTINUOUS_AUTO);
    } catch (error) {
      let err = error as BusinessError;
      console.error(`Failed to set the focus mode. error: ${JSON.stringify(err)}`);
    }
  }
  // 获取相机支持的可变焦距比范围
  let zoomRatioRange: Array<number> = [];
  try {
    zoomRatioRange = photoSession.getZoomRatioRange();
  } catch (error) {
    let err = error as BusinessError;
    console.error(`Failed to get the zoom ratio range. error: ${JSON.stringify(err)}`);
  }
  if (zoomRatioRange.length <= 0 ) {
    return;
  }
  // 设置可变焦距比
  try {
    photoSession.setZoomRatio(zoomRatioRange[0]);
  } catch (error) {
    let err = error as BusinessError;
    console.error(`Failed to set the zoom ratio value. error: ${JSON.stringify(err)}`);
  }
}

function capture(captureLocation: camera.Location, photoOutput: camera.PhotoOutput): void {
  let settings: camera.PhotoCaptureSetting = {
    quality: camera.QualityLevel.QUALITY_LEVEL_HIGH,  // 设置图片质量高
    rotation: camera.ImageRotation.ROTATION_0,  // 设置图片旋转角度的camera.ImageRotation.ROTATION_0是通过说明中获取拍照角度的getPhotoRotation方法获取的值进行设置
    location: captureLocation,  // 设置图片地理位置
    mirror: false  // 设置镜像使能开关(默认关)
  };
  photoOutput.capture(settings, (err: BusinessError) => {
    if (err) {
      console.error(`Failed to capture the photo. error: ${JSON.stringify(err)}`);
      return;
    }
    console.info('Callback invoked to indicate the photo capture request success.');
  });
}

function onPhotoOutputCaptureStart(photoOutput: camera.PhotoOutput): void {
  photoOutput.on('captureStartWithInfo', (err: BusinessError, captureStartInfo: camera.CaptureStartInfo) => {
    if (err !== undefined && err.code !== 0) {
      return;
    }
    console.info(`photo capture started, captureId : ${captureStartInfo.captureId}`);
  });
}

function onPhotoOutputCaptureEnd(photoOutput: camera.PhotoOutput): void {
  photoOutput.on('captureEnd', (err: BusinessError, captureEndInfo: camera.CaptureEndInfo) => {
    if (err !== undefined && err.code !== 0) {
      return;
    }
    console.info(`photo capture end, captureId : ${captureEndInfo.captureId}`);
    console.info(`frameCount : ${captureEndInfo.frameCount}`);
  });
}

function onPhotoOutputCaptureReady(photoOutput: camera.PhotoOutput): void {
  photoOutput.on('captureReady', (err: BusinessError) => {
    if (err !== undefined && err.code !== 0) {
      return;
    }
    console.info(`photo capture ready`);
  });
}

function onPhotoOutputError(photoOutput: camera.PhotoOutput): void {
  photoOutput.on('error', (error: BusinessError) => {
    console.error(`Photo output error code: ${error.code}`);
  });
}
