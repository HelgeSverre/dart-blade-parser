{{-- Alpine.js x-init Initialization Test --}}
<div x-data="{
    user: null,
    posts: [],
    stats: { views: 0, likes: 0 },
    isLoading: true,
    error: null,

    async fetchUserData() {
        try {
            // Simulate API call to fetch user data
            await new Promise(resolve => setTimeout(resolve, 800));
            this.user = {
                name: 'John Doe',
                email: 'john@example.com',
                avatar: '/avatars/john.jpg'
            };
        } catch (e) {
            this.error = 'Failed to load user data';
        }
    },

    async fetchPosts() {
        try {
            await new Promise(resolve => setTimeout(resolve, 600));
            this.posts = [
                { id: 1, title: 'Getting Started with Alpine.js', excerpt: 'Learn the basics...' },
                { id: 2, title: 'Reactive Magic', excerpt: 'Understanding reactivity...' },
                { id: 3, title: 'Building UIs', excerpt: 'Create beautiful interfaces...' }
            ];
        } catch (e) {
            this.error = 'Failed to load posts';
        }
    },

    incrementViews() {
        this.stats.views++;
    }
}"
x-init="
    // Initialize component: fetch data on mount
    Promise.all([fetchUserData(), fetchPosts()])
        .then(() => { isLoading = false; })
        .catch(() => { isLoading = false; });

    // Set up interval to increment views
    setInterval(() => incrementViews(), 3000);

    // Initialize stats
    stats.views = Math.floor(Math.random() * 1000);
    stats.likes = Math.floor(Math.random() * 100);
"
class="max-w-2xl mx-auto p-6">

    <div x-show="isLoading" class="text-center py-8">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
        <p class="mt-4 text-gray-600">Loading dashboard...</p>
    </div>

    <div x-show="!isLoading && !error">
        <div x-show="user" class="mb-6 p-4 bg-white shadow rounded-lg">
            <h3 class="text-xl font-bold" x-text="user?.name"></h3>
            <p class="text-gray-600" x-text="user?.email"></p>
        </div>

        <div class="grid grid-cols-2 gap-4 mb-6">
            <div class="p-4 bg-blue-50 rounded-lg">
                <p class="text-sm text-gray-600">Views</p>
                <p class="text-2xl font-bold" x-text="stats.views"></p>
            </div>
            <div class="p-4 bg-green-50 rounded-lg">
                <p class="text-sm text-gray-600">Likes</p>
                <p class="text-2xl font-bold" x-text="stats.likes"></p>
            </div>
        </div>

        <div class="space-y-4">
            <h4 class="text-lg font-semibold">Recent Posts</h4>
            <template x-for="post in posts" :key="post.id">
                <div class="p-4 border rounded-lg hover:shadow-md transition">
                    <h5 class="font-semibold" x-text="post.title"></h5>
                    <p class="text-sm text-gray-600" x-text="post.excerpt"></p>
                </div>
            </template>
        </div>
    </div>

    <div x-show="error" class="p-4 bg-red-50 text-red-600 rounded-lg" x-text="error"></div>
</div>
