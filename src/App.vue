<script setup>
import { ethers } from "ethers";
import { ref, watch } from "vue";
import { ABI_CONFIG, SC_ADDRESS_CONFIG } from "./consts";
import { ErrorDecoder } from "ethers-decode-error";

if (!window.ethereum) {
  location.href = "#mt5-not-installed";
}

const errorDecoder = ErrorDecoder.create();

const isLoading = ref(true);
const errors = ref(null);

const ethersProvider = ref(null);

watch(
  () => errors.value,
  (newVal) => {
    if (newVal) {
      location.href = "#errors";
    }
  },
);

const network = ref({});
const profile = ref({
  isHasLoggedIn: false,
});

const connectMetaMask = async () => {
  if (!window.ethereum) {
    location.href = "#mt5-not-installed";
    return;
  }

  isLoading.value = true;

  try {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const accounts = await provider.send("eth_requestAccounts");

    if (accounts.length) {
      const signer = await provider.getSigner();
      const contract = new ethers.Contract(SC_ADDRESS_CONFIG, ABI_CONFIG, signer);

      const balance = await provider.getBalance(signer.address);
      const owner = await contract.owner();
      const blockNumber = await provider.getBlockNumber();
      const block = await provider.getBlock(blockNumber);

      const getNetwork = await provider.getNetwork();
      network.value = getNetwork.toJSON();

      profile.value.address = signer.address;
      profile.value.owner = owner;
      profile.value.blockNumber = blockNumber;
      profile.value.balance = ethers.formatEther(balance) + " ETH";

      for (let i = 0; i < Object.keys(block).length; i++) {
        const e = Object.keys(block)[i];

        if (e == "timestamp") {
          profile.value[e] = new Date(block[e] * 1000).toLocaleString() + ` (${block[e]})`;
        } else {
          profile.value[e] = block[e];
        }
      }

      profile.value.isHasLoggedIn = true;
    }

    isLoading.value = false;
  } catch (error) {
    isLoading.value = false;

    const err = await errorDecoder.decode(error);
    errors.value = err.reason;
  }
};

if (!window.ethereum) {
  location.href = "#mt5-not-installed";
} else {
  connectMetaMask();
}

const checkProfile = async () => {
  try {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    const contract = new ethers.Contract(SC_ADDRESS_CONFIG, ABI_CONFIG, signer);

    const tx = await contract.getProfile(profile.value.address);

    console.log(tx);
  } catch (error) {
    const err = await errorDecoder.decode(error);
    errors.value = err.reason;
  }
};

const insertProfile = async () => {
  try {
    const name = profile.value.name;
    const key = profile.value.key;

    if (!name || !key) {
      errors.value = "Please fill in all fields";
      return;
    }

    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
    const contract = new ethers.Contract(SC_ADDRESS_CONFIG, ABI_CONFIG, signer);

    const tx = await contract.createProfile(name, key);
    await tx.wait();

    console.log(tx);

    profile.value.name = name;
    profile.value.key = key;
  } catch (error) {
    const err = await errorDecoder.decode(error);
    errors.value = err.reason;
  }
};
</script>

<template>
  <div class="flex flex-col items-center min-h-dvh p-3 pb-10 max-w-3xl border-x border-base-content/20 mx-auto w-full bg-neutral drop-shadow-xl">
    <div class="flex flex-col items-center gap-5 mt-5">
      <img src="/mt5.png" class="size-13" />
      <h1 class="max-sm:text-xl text-3xl font-bold max-w-lg text-center">Blockchain Profiling with MetaMask (Sepolia)</h1>
    </div>

    <button class="btn btn-md" :class="profile.isHasLoggedIn ? 'my-10' : 'my-auto'" @click="connectMetaMask" :disabled="isLoading || profile.isHasLoggedIn">
      <img src="/mt5.png" class="size-4" :hidden="isLoading" />
      <span class="loading loading-xs loading-spinner" :hidden="!isLoading"></span>
      {{ profile.isHasLoggedIn ? `Connected (${network?.name}) ✅` : "Connect with MetaMask" }}
    </button>

    <div class="tabs tabs-border tabs-xs self-start gap-x-2 tracking-wide w-full" :hidden="!profile.isHasLoggedIn">
      <input type="radio" name="tabs" class="tab mb-3" aria-label="Overview" checked="checked" />
      <div class="tab-content">
        <div
          class="grid grid-cols-[150px_1fr] gap-2 w-full border border-base-content/20 p-3 hover:bg-base-content/5 max-sm:text-xs text-sm"
          v-for="(item, index) in Object.keys(profile)"
          :hidden="index == 0"
          :key="index"
        >
          <label :for="`name-${index}`" class="font-semibold capitalize truncate">{{ item }}</label>
          <h1 class="font-light font-mono capitalize truncate max-sm:col-span-2">{{ profile[item] }}</h1>
        </div>
      </div>

      <input type="radio" name="tabs" class="tab mb-3" aria-label="Check Profile" />
      <div class="tab-content px-3 mt-4">
        <div class="flex flex-col items-center w-full gap-2 mx-auto">
          <input type="text" class="input input-sm w-xl" placeholder="Input address..." />
          <button class="btn btn-sm btn-primary" @click="checkProfile">Check Now</button>
        </div>
      </div>

      <input type="radio" name="tabs" class="tab mb-3" aria-label="Input Profile" />
      <div class="tab-content px-3 mt-4">
        <div class="flex flex-col items-center w-full gap-2 mx-auto">
          <input type="text" class="input input-sm w-xl" placeholder="Input name..." v-model="profile.name" />
          <input type="text" class="input input-sm w-xl" placeholder="Input key..." v-model="profile.key" />
          <button class="btn btn-sm btn-primary" @click="insertProfile">Insert Now</button>
        </div>
      </div>
    </div>
  </div>

  <div class="modal" role="dialog" id="mt5-not-installed">
    <div class="modal-box bg-error-content">
      <h3 class="text-lg font-bold">MetaMask Not Installed</h3>
      <p class="mt-4">
        Please install MetaMask to use this application. You can install it from
        <a
          href="https://chromewebstore.google.com/detail/metamask/nkbihfbeogaeaoehlefnkodbefgpgknn?ref=https://zeative.github.io/blockchain-profiling-metamask/"
          class="link link-error"
          target="_blank"
          >Chrome Web Store</a
        >.
      </p>
      <div class="modal-action">
        <a
          href="https://chromewebstore.google.com/detail/metamask/nkbihfbeogaeaoehlefnkodbefgpgknn?ref=https://zeative.github.io/blockchain-profiling-metamask/"
          class="btn btn-error btn-sm"
          target="_blank"
          >Install</a
        >
      </div>
    </div>
  </div>

  <div class="modal" role="dialog" id="errors">
    <div class="modal-box bg-error-content">
      <h3 class="text-lg font-bold">Internal System Error</h3>
      <p class="mt-4 font-mono text-sm bg-base-100/30 px-2 py-1 rounded-md">
        {{ errors }}
      </p>
      <div class="modal-action">
        <a href="#" class="btn btn-error btn-sm">Close</a>
      </div>
    </div>
  </div>

  <footer class="fixed bottom-0 w-full bg-base-100">
    <p class="text-center text-xs p-1">
      Made with ❤️ by
      <a href="https://github.com/zeative?ref=https://zeative.github.io/blockchain-profiling-metamask/" class="link link-primary" target="_blank">zaadevofc</a> |
      <a
        href="https://github.com/zeative/blockchain-profiling-metamask?ref=https://zeative.github.io/blockchain-profiling-metamask/"
        class="link link-primary"
        target="_blank"
        >Source Code</a
      >
    </p>
  </footer>
</template>
