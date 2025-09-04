<template>
  <div>
    <h2>摄像头预览</h2>
    <video v-show="isRecording" style="width: 80vw;" ref="previewRef" autoplay playsinline muted></video>

    <div style="margin-top: 10px;">
      <button @click="startRecording" :disabled="isRecording || !isSupported">开始录制</button>
      <button @click="stopRecording" :disabled="!isRecording">停止录制</button>
    </div>

    <div v-if="recordedBlob" style="margin-top: 20px;">
      <h2>回放录制视频</h2>
      <video style="width: 80vw;" ref="playbackRef" :src="recordedURL" controls></video>
    </div>

    <p v-if="!isSupported" style="color:red">当前浏览器不支持视频录制或摄像头权限</p>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";

const previewRef = ref(null);
const playbackRef = ref(null);
const mediaRecorder = ref(null);
const chunks = ref([]);
const recordedBlob = ref(null);
const recordedURL = ref(""); // blob URL
const isRecording = ref(false);
const streamRef = ref(null);
const isSupported = ref(true);

// 检测浏览器是否支持 MediaRecorder
onMounted(() => {
  if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia || !window.MediaRecorder) {
    isSupported.value = false;
    alert("当前浏览器不支持 MediaRecorder 或 getUserMedia");
    console.warn("当前浏览器不支持 MediaRecorder 或 getUserMedia");
  }
});

// 开始录制
const startRecording = async () => {
  if (!isSupported.value) return;

  try {
    const stream = await navigator.mediaDevices.getUserMedia({
      video: true,
      audio: {
        echoCancellation: true,
        noiseSuppression: true
      }
    });

    streamRef.value = stream;
    previewRef.value.srcObject = stream;
    previewRef.value.muted = true; // ⚡ 静音预览，避免回音

    let options = { mimeType: "video/webm;codecs=vp8,opus" };
    if (!MediaRecorder.isTypeSupported(options.mimeType)) {
      options = { mimeType: "video/mp4;codecs=h264,aac" };
      if (!MediaRecorder.isTypeSupported(options.mimeType)) options = {};
    }

    mediaRecorder.value = new MediaRecorder(stream, options);

    mediaRecorder.value.ondataavailable = (e) => {
      if (e.data.size > 0) chunks.value.push(e.data);
    };

    mediaRecorder.value.onstop = () => {
      recordedBlob.value = new Blob(chunks.value, { type: chunks.value[0]?.type || "video/webm" });
      chunks.value = [];
      // 生成本地 blob URL 用于回放
      recordedURL.value = URL.createObjectURL(recordedBlob.value);
    };

    mediaRecorder.value.start();
    isRecording.value = true;
    console.log("开始录制");
  } catch (err) {
    console.error("摄像头权限获取失败:", err);
  }
};

// 停止录制 + 释放摄像头
const stopRecording = () => {
  if (mediaRecorder.value && mediaRecorder.value.state === "recording") {
    mediaRecorder.value.stop();
    console.log("停止录制");
  }

  if (streamRef.value) {
    streamRef.value.getTracks().forEach(track => track.stop());
    streamRef.value = null;
    previewRef.value.srcObject = null;
    console.log("摄像头权限已释放");
  }

  isRecording.value = false;
};
</script>