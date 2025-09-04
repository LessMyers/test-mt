<template>
  <div>
    <video ref="videoRef" autoplay playsinline></video>
    <div>
      <button @click="startRecording" :disabled="isRecording || !isSupported">开始录制</button>
      <button @click="stopRecording" :disabled="!isRecording">停止录制</button>
      <button @click="uploadVideo" :disabled="!recordedBlob">上传视频</button>
      <p v-if="!isSupported" style="color:red">当前设备/浏览器不支持视频录制</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from "vue";

const videoRef = ref(null);
const mediaRecorder = ref(null);
const chunks = ref([]);
const recordedBlob = ref(null);
const isRecording = ref(false);
const streamRef = ref(null);
const isSupported = ref(true); // 是否支持 MediaRecorder

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
    const stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
    streamRef.value = stream;
    videoRef.value.srcObject = stream;

    // 自动选择可用的 mimeType
    let options = { mimeType: "video/webm;codecs=vp8,opus" };
    if (!MediaRecorder.isTypeSupported(options.mimeType)) {
      options = { mimeType: "video/mp4;codecs=h264,aac" }; // iOS Safari 兼容
      if (!MediaRecorder.isTypeSupported(options.mimeType)) {
        options = {}; // 浏览器自己选择默认
      }
    }

    mediaRecorder.value = new MediaRecorder(stream, options);

    mediaRecorder.value.ondataavailable = (e) => {
      if (e.data.size > 0) chunks.value.push(e.data);
    };

    mediaRecorder.value.onstop = () => {
      recordedBlob.value = new Blob(chunks.value, { type: chunks.value[0]?.type || "video/webm" });
      chunks.value = [];
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
    videoRef.value.srcObject = null;
    console.log("摄像头权限已释放");
  }

  isRecording.value = false;
};

// 上传视频
const uploadVideo = async () => {
  if (!recordedBlob.value) return;

  const formData = new FormData();
  formData.append("file", recordedBlob.value, "video.webm");

  try {
    const res = await fetch("http://192.168.0.127/api/upload", {
      method: "POST",
      body: formData,
    });
    console.log("上传成功", await res.json());
  } catch (err) {
    console.error("上传失败", err);
  }
};
</script>