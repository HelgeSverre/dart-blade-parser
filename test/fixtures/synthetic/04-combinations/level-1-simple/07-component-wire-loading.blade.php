---
description: Component usage with Livewire loading states
features:
  - component-tag
  - livewire-loading
difficulty: level-1-simple
---
<div class="user-profile-page">
    <x-page-header
        :title="$user->name"
        :subtitle="$user->role"
    />

    <div class="profile-content">
        <x-profile-sidebar :user="$user">
            <button wire:click="updateAvatar" class="btn-upload">
                Change Avatar
                <span wire:loading wire:target="updateAvatar">
                    Uploading...
                </span>
            </button>
        </x-profile-sidebar>

        <div class="main-content">
            <x-stats-card
                :posts="$user->posts_count"
                :followers="$user->followers_count"
                :following="$user->following_count"
            >
                <button wire:click="refreshStats" class="btn-refresh">
                    <span wire:loading.remove wire:target="refreshStats">Refresh</span>
                    <span wire:loading wire:target="refreshStats">Loading...</span>
                </button>
            </x-stats-card>

            <x-activity-feed :activities="$recentActivities">
                <div wire:loading wire:target="loadMoreActivities" class="loading-spinner">
                    <div class="spinner"></div>
                    <p>Loading more activities...</p>
                </div>

                <button
                    wire:click="loadMoreActivities"
                    class="btn-load-more"
                    wire:loading.attr="disabled"
                >
                    Load More
                </button>
            </x-activity-feed>

            <x-settings-panel :settings="$userSettings">
                <form wire:submit.prevent="saveSettings">
                    <div wire:loading.class="opacity-50" wire:target="saveSettings">
                        <x-form-input name="email" :value="$user->email" />
                        <x-form-input name="phone" :value="$user->phone" />
                        <x-form-toggle name="notifications" :checked="$settings->notifications" />
                    </div>

                    <button type="submit" class="btn-primary">
                        <span wire:loading.remove wire:target="saveSettings">Save Changes</span>
                        <span wire:loading wire:target="saveSettings">Saving...</span>
                    </button>
                </form>
            </x-settings-panel>
        </div>
    </div>
</div>
