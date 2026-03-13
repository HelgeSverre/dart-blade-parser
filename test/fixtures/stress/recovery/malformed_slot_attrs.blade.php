<x-layout>
    <x-slot:header class="bg-blue" data-x>
        <h1>Title with slot attributes</h1>
    </x-slot>

    <x-card ???broken-attr>
        <x-slot:body>
            <p>Content inside slot</p>
            </bogus>
        </x-slot>

        <x-slot:footer>
            <p>Footer content</p>
        </x-slot>
    </x-card>

    <x-modal>
        <x-slot:content>
            <div>Modal content</div>
        </x-slot>
    </x-modal>

    @if($show)
        <p>Conditional content</p>
</x-layout>
