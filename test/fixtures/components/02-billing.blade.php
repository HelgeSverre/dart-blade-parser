<x-layouts.base>
    <x-slot:title>Fakturainnstillinger</x-slot>

    <x-layouts.settings wide>
        <x-slot:actions>
            <x-layouts.breadcrumbs>Fakturainnstillinger</x-layouts.breadcrumbs>
        </x-slot>
        <div>
            @if ($hasInvoiceIntegrationActive)
                <div class="mb-4">
                    <div class="border-l-4 border-yellow-400 bg-yellow-50 p-4">
                        <div class="flex">
                            <div class="flex-shrink-0">
                                <!-- Heroicon name: solid/exclamation -->
                                <svg
                                    class="size-5 text-yellow-400"
                                    xmlns="http://www.w3.org/2000/svg"
                                    viewBox="0 0 20 20"
                                    fill="currentColor"
                                    aria-hidden="true"
                                >
                                    <path
                                        fill-rule="evenodd"
                                        d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                                        clip-rule="evenodd"
                                    />
                                </svg>
                            </div>
                            <div class="ml-3">
                                <p class="text-sm text-yellow-700">
                                    Du har en fakturaintegrasjon aktivert, disse
                                    innstillingene er da ikke i bruk.
                                    <a
                                        href="{{ route('integration.index') }}"
                                        class="font-medium text-yellow-700 underline hover:text-yellow-600"
                                    >
                                        Gå til Integrasjoner
                                    </a>
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            @endif

            <x-panel
                class="{{ $hasInvoiceIntegrationActive ? 'opacity-50' : '' }}"
            >
                <x-slot name="heading">
                    Fakturainnstillinger og KID-nummer
                </x-slot>

                @if ($hasInvoiceIntegrationActive == false)
                    <x-slot name="footer">
                        <x-button.primary
                            :href="route('invoice-settings.edit')"
                        >
                            Endre
                        </x-button.primary>
                    </x-slot>
                @endif

                <dl class="sm:divide-y sm:divide-gray-200">
                    <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:py-5">
                        <dt class="text-sm font-medium text-gray-500">
                            Kontonummer
                        </dt>
                        <dd
                            class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0"
                        >
                            {{ $company->account_number }}
                        </dd>
                    </div>
                    <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:py-5">
                        <dt class="text-sm font-medium text-gray-500">
                            Standard forfallsdager
                        </dt>
                        <dd
                            class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0"
                        >
                            {{ $company->default_due_days }}
                        </dd>
                    </div>
                    <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:py-5">
                        <dt class="text-sm font-medium text-gray-500">
                            Faktura Nummerserie
                        </dt>
                        <dd
                            class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0"
                        >
                            {{ $company->invoice_series }}
                        </dd>
                    </div>
                    <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:py-5">
                        <dt class="text-sm font-medium text-gray-500">
                            Kreditnota Nummerserie
                        </dt>
                        <dd
                            class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0"
                        >
                            {{ $company->credit_note_series }}
                        </dd>
                    </div>
                    <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:py-5">
                        <dt class="text-sm font-medium text-gray-500">
                            Ordre Nummerserie
                        </dt>
                        <dd
                            class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0"
                        >
                            {{ $company->order_series }}
                        </dd>
                    </div>
                    <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:py-5">
                        <dt class="text-sm font-medium text-gray-500">
                            Tilbud Nummerserie
                        </dt>
                        <dd
                            class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0"
                        >
                            {{ $company->offer_series }}
                        </dd>
                    </div>
                    <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:py-5">
                        <dt class="text-sm font-medium text-gray-500">
                            KID-nummer aktivt?
                        </dt>
                        <dd
                            class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0"
                        >
                            @if ($company->kid_enabled)
                                <span
                                    class="inline-flex items-center rounded-full bg-green-100 px-3 py-0.5 text-sm font-medium text-green-800"
                                >
                                    Aktivert
                                </span>
                            @else
                                <span
                                    class="inline-flex items-center rounded-full bg-red-100 px-3 py-0.5 text-sm font-medium text-red-800"
                                >
                                    Deaktivert
                                </span>
                            @endif
                        </dd>
                    </div>
                    <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:py-5">
                        <dt class="text-sm font-medium text-gray-500">
                            KID-nummer lengde
                        </dt>
                        <dd
                            class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0"
                        >
                            {{ $company->kid_length ?? 'Ikke satt' }}
                        </dd>
                    </div>

                    <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:py-5">
                        <dt class="text-sm font-medium text-gray-500">
                            KID-nummer genereres med
                        </dt>
                        <dd
                            class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0"
                        >
                            {{ $company->kid_algo ?? 'Ikke satt' }}
                        </dd>
                    </div>
                </dl>
            </x-panel>
        </div>
    </x-layouts.settings>
</x-layouts.base>
