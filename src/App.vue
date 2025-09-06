<template>
  <div>
    <h2>BNB Chain 钱包连接 Demo</h2>
    <button @click="connectWallet">连接钱包</button>
    <p v-if="address">已连接钱包地址: {{ address }}</p>
    签名: {{ signature }}
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { ethers } from 'ethers'
import EthereumProvider from '@walletconnect/ethereum-provider'

const address = ref(null)
const signature = ref("");

// ⚠️ 替换成你自己的 WalletConnect ProjectId
const projectId = '4a5226b1c7e51b36cc2daf2a9715f3ff'

async function connectWallet() {
  try {
    // 检测 window.ethereum（桌面插件 / 手机钱包浏览器）
    if (window.ethereum) {
      let provider = window.ethereum
      // 如果多个钱包共存，优先选第一个
      if (window.ethereum.providers?.length > 0) {
        provider = window.ethereum.providers[0]
      }

      // 请求授权
      await provider.request({ method: 'eth_requestAccounts' })
      const ethersProvider = new ethers.BrowserProvider(provider)
      const signer = await ethersProvider.getSigner()
      address.value = await signer.getAddress()
      console.log('已连接:', address.value)
    } else {
      // 手机普通浏览器或无插件 → 使用 WalletConnect
      const wcProvider = await EthereumProvider.init({
        projectId,
        chains: [56], // BNB Chain 主网
        showQrModal: true // 弹出二维码 / deep link
      })
      await wcProvider.connect()
      const ethersProvider = new ethers.BrowserProvider(wcProvider)
      const signer = await ethersProvider.getSigner()
      address.value = await signer.getAddress()
      console.log('已连接:', address.value)

         // 发起签名
      const msg = "Hello, this is a test signature"
      signature.value = await signer.signMessage(msg)
      console.log('签名结果:', signature.value)
    }
  } catch (err) {
    console.error('连接失败:', err)
  }
}
</script>