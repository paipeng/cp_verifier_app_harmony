import { ErrorEvent, MessageEvents, ThreadWorkerGlobalScope, worker } from '@kit.ArkTS';
import CameraService from '../pages/CameraService';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { camera } from '@kit.CameraKit';

const workerPort: ThreadWorkerGlobalScope = worker.workerPort;


// 自定义消息格式
interface MessageInfo {
  hasResolve: boolean;
  type: string;
  context: Context; // 注意worker线程中无法使用getContext()直接获取宿主线程context，需要通过消息从宿主线程通信到worker线程使用。
  surfaceId: string;
  previewSize: image.Size;
  location: camera.Location;
}

/**
 * Defines the event handler to be called when the worker thread receives a message sent by the host thread.
 * The event handler is executed in the worker thread.
 *
 * @param e message data
 */
workerPort.onmessage = async (e: MessageEvents) => {
  const messageInfo: MessageInfo = e.data;
  console.info(`worker onmessage type:${messageInfo.type}`)
  if ('initCamera' === messageInfo.type) {
    // 在worker线程中收到宿主线程初始化相机的消息
    console.info(`worker initCamera surfaceId:${messageInfo.surfaceId}  ${messageInfo.previewSize}`)
    // 在worker线程中初始化相机
    await CameraService.initCamera(messageInfo.context, messageInfo.surfaceId, messageInfo.previewSize);
  } else if ('releaseCamera' === messageInfo.type) {
    // 在worker线程中收到宿主线程释放相机的消息
    console.info('worker releaseCamera.');
    // 在worker线程中释放相机
    await CameraService.releaseCamera();
  } else if ('capturePhoto' == messageInfo.type) {
    hilog.info(0x0000, 'CameraWorker', 'capturePhoto')
    await CameraService.capturePhoto(messageInfo.location)
  }
}

/**
 * Defines the event handler to be called when the worker receives a message that cannot be deserialized.
 * The event handler is executed in the worker thread.
 *
 * @param e message data
 */
workerPort.onmessageerror = (e: MessageEvents) => {
}

/**
 * Defines the event handler to be called when an exception occurs during worker execution.
 * The event handler is executed in the worker thread.
 *
 * @param e error message
 */
workerPort.onerror = (e: ErrorEvent) => {
}