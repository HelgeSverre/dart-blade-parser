{{-- Alpine.js Global Store Test --}}

{{-- Define global stores in a script tag --}}
<script>
    document.addEventListener('alpine:init', () => {
        // Global authentication store
        Alpine.store('auth', {
            user: null,
            isAuthenticated: false,

            login(username, email) {
                this.user = { username, email, loginTime: new Date() };
                this.isAuthenticated = true;
            },

            logout() {
                this.user = null;
                this.isAuthenticated = false;
            }
        });

        // Global notification store
        Alpine.store('notifications', {
            items: [],
            unreadCount: 0,

            add(message, type = 'info') {
                const notification = {
                    id: Date.now(),
                    message,
                    type,
                    read: false,
                    timestamp: new Date()
                };
                this.items.unshift(notification);
                this.unreadCount++;
            },

            markAsRead(id) {
                const notification = this.items.find(n => n.id === id);
                if (notification && !notification.read) {
                    notification.read = true;
                    this.unreadCount = Math.max(0, this.unreadCount - 1);
                }
            },

            clear() {
                this.items = [];
                this.unreadCount = 0;
            }
        });

        // Global settings store
        Alpine.store('settings', {
            theme: 'light',
            language: 'en',
            notifications: true,

            toggleTheme() {
                this.theme = this.theme === 'light' ? 'dark' : 'light';
            }
        });
    });
</script>

<div class="max-w-6xl mx-auto p-6">
    <h1 class="text-3xl font-bold mb-8">Alpine.js Global Store Demo</h1>

    <div class="grid grid-cols-3 gap-6">

        {{-- Authentication Component --}}
        <div x-data="{
            username: '',
            email: '',

            handleLogin() {
                if (this.username && this.email) {
                    $store.auth.login(this.username, this.email);
                    $store.notifications.add('Successfully logged in!', 'success');
                    this.username = '';
                    this.email = '';
                }
            }
        }" class="bg-white rounded-lg shadow-lg p-6">
            <h2 class="text-xl font-semibold mb-4">Authentication</h2>

            <div x-show="!$store.auth.isAuthenticated">
                <input
                    type="text"
                    x-model="username"
                    placeholder="Username"
                    class="w-full mb-3 px-3 py-2 border rounded"
                >
                <input
                    type="email"
                    x-model="email"
                    placeholder="Email"
                    class="w-full mb-3 px-3 py-2 border rounded"
                >
                <button
                    @click="handleLogin()"
                    class="w-full px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
                >
                    Login
                </button>
            </div>

            <div x-show="$store.auth.isAuthenticated" class="space-y-3">
                <div class="p-3 bg-green-50 rounded">
                    <p class="font-semibold" x-text="$store.auth.user?.username"></p>
                    <p class="text-sm text-gray-600" x-text="$store.auth.user?.email"></p>
                </div>
                <button
                    @click="$store.auth.logout(); $store.notifications.add('Logged out', 'info')"
                    class="w-full px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
                >
                    Logout
                </button>
            </div>
        </div>

        {{-- Notifications Component --}}
        <div x-data class="bg-white rounded-lg shadow-lg p-6">
            <div class="flex justify-between items-center mb-4">
                <h2 class="text-xl font-semibold">
                    Notifications
                    <span
                        x-show="$store.notifications.unreadCount > 0"
                        x-text="$store.notifications.unreadCount"
                        class="ml-2 px-2 py-1 text-xs bg-red-500 text-white rounded-full"
                    ></span>
                </h2>
                <button
                    @click="$store.notifications.clear()"
                    class="text-sm text-gray-500 hover:text-gray-700"
                >
                    Clear
                </button>
            </div>

            <div class="space-y-2 max-h-64 overflow-y-auto">
                <template x-for="notification in $store.notifications.items" :key="notification.id">
                    <div
                        @click="$store.notifications.markAsRead(notification.id)"
                        class="p-3 rounded cursor-pointer"
                        :class="{
                            'bg-blue-50': notification.type === 'info',
                            'bg-green-50': notification.type === 'success',
                            'bg-red-50': notification.type === 'error',
                            'opacity-50': notification.read
                        }"
                    >
                        <p class="text-sm" x-text="notification.message"></p>
                        <span
                            x-show="!notification.read"
                            class="inline-block mt-1 w-2 h-2 bg-blue-500 rounded-full"
                        ></span>
                    </div>
                </template>

                <div x-show="$store.notifications.items.length === 0" class="text-center py-8 text-gray-400">
                    No notifications
                </div>
            </div>
        </div>

        {{-- Settings Component --}}
        <div x-data class="bg-white rounded-lg shadow-lg p-6">
            <h2 class="text-xl font-semibold mb-4">Settings</h2>

            <div class="space-y-4">
                <div class="flex justify-between items-center">
                    <span class="font-medium">Theme</span>
                    <button
                        @click="$store.settings.toggleTheme()"
                        class="px-3 py-1 border rounded"
                        x-text="$store.settings.theme === 'light' ? 'Light' : 'Dark'"
                    ></button>
                </div>

                <div class="flex justify-between items-center">
                    <span class="font-medium">Language</span>
                    <select
                        x-model="$store.settings.language"
                        class="px-3 py-1 border rounded"
                    >
                        <option value="en">English</option>
                        <option value="es">Spanish</option>
                        <option value="fr">French</option>
                    </select>
                </div>

                <div class="flex justify-between items-center">
                    <span class="font-medium">Notifications</span>
                    <label class="relative inline-flex items-center cursor-pointer">
                        <input
                            type="checkbox"
                            x-model="$store.settings.notifications"
                            class="sr-only peer"
                        >
                        <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:bg-blue-600"></div>
                    </label>
                </div>

                <button
                    @click="$store.notifications.add('Settings updated!', 'success')"
                    class="w-full mt-4 px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700"
                >
                    Save Settings
                </button>
            </div>
        </div>
    </div>

    {{-- Global State Display --}}
    <div x-data class="mt-6 p-4 bg-gray-100 rounded-lg">
        <h3 class="font-semibold mb-2">Global State Monitor</h3>
        <div class="grid grid-cols-3 gap-4 text-sm">
            <div>
                <strong>Auth:</strong>
                <span x-text="$store.auth.isAuthenticated ? 'Logged In' : 'Guest'"></span>
            </div>
            <div>
                <strong>Unread:</strong>
                <span x-text="$store.notifications.unreadCount"></span>
            </div>
            <div>
                <strong>Theme:</strong>
                <span x-text="$store.settings.theme"></span>
            </div>
        </div>
    </div>
</div>
