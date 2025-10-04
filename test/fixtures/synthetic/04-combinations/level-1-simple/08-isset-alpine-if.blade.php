---
description: Optional data display with Alpine.js conditional rendering
features:
  - isset-directive
  - alpine-if
difficulty: level-1-simple
---
<div x-data="{
    showDetails: false,
    showContact: false,
    editMode: false
}">
    <div class="user-card">
        <h2>User Profile</h2>

        <div class="basic-info">
            <p><strong>Name:</strong> {{ $user->name }}</p>
            <p><strong>Email:</strong> {{ $user->email }}</p>

            @isset($user->phone)
                <div x-data="{ revealed: false }">
                    <p><strong>Phone:</strong></p>
                    <template x-if="!revealed">
                        <button @click="revealed = true" class="btn-reveal">
                            Show Phone Number
                        </button>
                    </template>
                    <template x-if="revealed">
                        <span>{{ $user->phone }}</span>
                    </template>
                </div>
            @endisset
        </div>

        @isset($user->bio)
            <div class="bio-section">
                <button @click="showDetails = !showDetails" class="btn-toggle">
                    <span x-text="showDetails ? 'Hide Bio' : 'Show Bio'"></span>
                </button>
                <template x-if="showDetails">
                    <div class="bio-content">
                        <p>{{ $user->bio }}</p>
                    </div>
                </template>
            </div>
        @endisset

        @isset($user->company)
            <div class="company-info" x-show="showContact">
                <h3>Company Information</h3>
                <p><strong>Company:</strong> {{ $user->company->name }}</p>

                @isset($user->company->address)
                    <template x-if="editMode">
                        <input type="text" value="{{ $user->company->address }}" class="form-control">
                    </template>
                    <template x-if="!editMode">
                        <p><strong>Address:</strong> {{ $user->company->address }}</p>
                    </template>
                @endisset
            </div>

            <button @click="showContact = !showContact" class="btn-secondary">
                <span x-text="showContact ? 'Hide' : 'Show'"></span> Company Details
            </button>
        @endisset

        @isset($user->socialLinks)
            <div class="social-links">
                <button @click="editMode = !editMode" class="btn-edit">
                    <span x-text="editMode ? 'Cancel' : 'Edit'"></span>
                </button>

                <template x-if="!editMode">
                    <div>
                        <a href="{{ $user->socialLinks->twitter }}">Twitter</a>
                        <a href="{{ $user->socialLinks->linkedin }}">LinkedIn</a>
                    </div>
                </template>
            </div>
        @endisset
    </div>
</div>
