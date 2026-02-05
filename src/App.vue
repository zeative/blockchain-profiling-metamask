<script setup>
import { ref } from "vue";
import { ethers } from "ethers";

const provider = new ethers.BrowserProvider(window.ethereum);

const isLoading = ref(true);

const network = ref({});
const profile = ref({
  isHasLoggedIn: false,
});

const connectMetaMask = async () => {
  isLoading.value = true;

  if (!window.ethereum) {
    location.href = "#mt5-not-installed";
  }

  try {
    const accounts = await provider.send("eth_requestAccounts");

    if (accounts.length) {
      const signer = await provider.getSigner();
      const balance = await provider.getBalance(signer.address);
      const owner = await signer.getAddress();
      const blockNumber = await provider.getBlockNumber();
      const block = await provider.getBlock(blockNumber);

      const getNetwork = await provider.getNetwork();
      network.value = getNetwork.toJSON();

      profile.value.address = signer.address;
      profile.value.owner = owner;
      profile.value.blockNumber = blockNumber;
      profile.value.balance = ethers.formatEther(balance);

      for (let i = 0; i < Object.keys(block).length; i++) {
        const e = Object.keys(block)[i];
        profile.value[e] = block[e];
      }

      profile.value.isHasLoggedIn = true;
    }

    isLoading.value = false;
  } catch (error) {
    isLoading.value = false;
    console.error(error);
  }
};

if (!window.ethereum) {
  location.href = "#mt5-not-installed";
} else {
  connectMetaMask();
}
</script>

<template>
  <div class="flex flex-col items-center min-h-dvh p-3 pb-10 max-w-3xl border-x border-base-content/20 mx-auto w-full bg-neutral drop-shadow-xl">
    <div class="flex items-center gap-5 mt-5">
      <img src="/mt5.png" class="size-12" />
      <h1 class="text-3xl font-bold">Blockchain Profiling with MetaMask</h1>
    </div>

    <button class="btn btn-md" :class="profile.isHasLoggedIn ? 'my-10' : 'my-auto'" @click="connectMetaMask" :disabled="isLoading || profile.isHasLoggedIn">
      <img src="/mt5.png" class="size-4" :hidden="isLoading" />
      <span class="loading loading-xs loading-spinner" :hidden="!isLoading"></span>
      {{ profile.isHasLoggedIn ? `Connected (${network?.name}) ✅` : "Connect with MetaMask" }}
    </button>

    <div
      class="grid grid-cols-2 gap-6 w-full border border-base-content/20 p-3"
      v-for="(item, index) in Object.keys(profile)"
      :hidden="!profile.isHasLoggedIn || index == 0"
      :key="index"
    >
      <label :for="`name-${index}`" class="text-sm font-semibold capitalize">{{ item }}</label>
      <h1 class="text-sm font-light capitalize col-end-4">{{ profile[item] }}</h1>
    </div>
  </div>

  <div class="modal" role="dialog" id="mt5-not-installed">
    <div class="modal-box bg-error-content">
      <h3 class="text-lg font-bold">MetaMask Not Installed</h3>
      <p class="py-4">
        Please install MetaMask to use this application. You can install it from
        <a href="https://chromewebstore.google.com/detail/metamask/nkbihfbeogaeaoehlefnkodbefgpgknn" class="link link-error" target="_blank">Chrome Web Store</a>.
      </p>
      <div class="modal-action">
        <a href="#" class="btn btn-error">Install</a>
      </div>
    </div>
  </div>

  <footer class="fixed bottom-0 w-full bg-base-100">
    <p class="text-center text-xs p-1">Made with ❤️ by <a href="https://github.com/zeative" class="link link-primary" target="_blank">zaadevofc</a></p>
  </footer>
</template>
