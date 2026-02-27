{{-- Livewire wire:stream examples --}}
<div>
    {{-- Basic streaming - append content to target --}}
    <div wire:stream="response">
        {{-- AI-generated content will be streamed here --}}
    </div>

    {{-- Stream with replace - overwrite target content --}}
    <div wire:stream.replace="statusMessage">
        Waiting for response...
    </div>

    {{-- Streaming AI chat response --}}
    <div class="chat-window">
        @foreach($messages as $message)
            <div wire:key="msg-{{ $message->id }}" class="message">
                <strong>{{ $message->role }}:</strong>
                <span>{{ $message->content }}</span>
            </div>
        @endforeach

        {{-- Stream target for new AI response --}}
        <div wire:stream="aiResponse" class="message ai-response"></div>
    </div>

    <form wire:submit="sendMessage">
        <input type="text" wire:model="prompt" placeholder="Ask something...">
        <button type="submit">Send</button>
    </form>

    {{-- Streaming progress updates --}}
    <div>
        <button wire:click="generateReport">Generate Report</button>
        <div wire:stream.replace="progress">Click to start</div>
    </div>

    {{-- Multiple stream targets --}}
    <div class="dashboard">
        <div wire:stream.replace="cpuUsage">--</div>
        <div wire:stream.replace="memoryUsage">--</div>
        <div wire:stream="activityLog"></div>
    </div>

    {{-- Stream within a card component --}}
    <div class="card">
        <h3>Summary</h3>
        <p wire:stream="summary">Generating summary...</p>
        <div wire:stream="details"></div>
    </div>
</div>