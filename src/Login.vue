<script setup>
import { login_account_ffi, login_last_used_ffi } from 'lib/ms/login/login.js';
import { NCard, NForm, NFormItem, NInput, NButton, NAlert } from 'naive-ui';
import { ref } from 'vue';
import { pollMod } from './utils';

const { game } = defineProps({
  game: Object
});
const emit = defineEmits(['logined']);

const loginMod = ref(null);
// Initialize the login module
const account = ref('');
const password = ref('');
const loading = ref(false);
const errorMessage = ref(null);
pollMod(loginMod, 'login', game);

const handleLogin = () => {
  // clear error message
  errorMessage.value = null;
  if (!account.value || !password.value) {
    errorMessage.value = 'Please enter both account and password';
    return;
  }

  loading.value = true;
  login_account_ffi(loginMod.value, account.value, password.value, (message) => {
    if (message) {
      errorMessage.value = message;
    } else {
      errorMessage.value = null;
      emit('logined');
    }
    loading.value = false;
  });
};

const handleLoginLastUsed = () => {
  errorMessage.value = null;
  loading.value = true;
  login_last_used_ffi(loginMod.value, (message) => {
    if (message) {
      errorMessage.value = message;
    } else {
      errorMessage.value = null;
      emit('logined');
    }
    loading.value = false;
  });
};

const rules = {
  account: {
    required: true,
    message: 'Please enter your account',
  },
  password: {
    required: true,
    message: 'Please enter your password',
  },
};
</script>

<template>
  <div class="login-container">
    <n-alert v-if="errorMessage" type="error" closable @close="errorMessage = null" style="margin-bottom: 1rem">
      {{ errorMessage }}
    </n-alert>
    <div v-if="loginMod" class="login-form">
      <n-card title="Login" style="width: 350px;">
        <n-form :rules="rules">
          <n-form-item label="Account">
            <n-input v-model:value="account" autocomplete="username" />
          </n-form-item>
          <n-form-item label="Password">
            <n-input v-model:value="password" type="password" autocomplete="current-password"
              @keyup.enter="handleLogin" />
          </n-form-item>
          <div style="display: flex; justify-content: flex-end;">
            <n-button type="primary" @click="handleLogin" :loading="loading" style="margin-right: 8px;">
              Login
            </n-button>
            <n-button type="default" @click="handleLoginLastUsed" :loading="loading">
              Login Last Used
            </n-button>
          </div>
        </n-form>
      </n-card>
    </div>
    <div v-else class="loading">Loading...</div>
  </div>
</template>

<style scoped>
.login-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  height: 100%;
  background-color: #f5f7fa;
}

.loading {
  font-size: 18px;
  color: #666;
}
</style>
