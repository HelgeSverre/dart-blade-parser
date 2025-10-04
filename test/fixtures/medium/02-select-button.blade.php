@aware(["placeholder"])

@props([
    "placeholder" => null,
    "invalid" => false,
    "size" => null,
])

@php
    $classes = Flux::classes()
        ->add("group/select-button cursor-default py-2 block w-full")
        ->add("flex items-center")
        ->add("rounded-lg shadow-sm border")
        ->add("bg-white dark:bg-white/10 dark:disabled:bg-white/[7%]")
        // Make the placeholder match the text color of standard input placeholders...
        ->add("disabled:shadow-none")
        ->add(
            match ($size) {
                default => "h-10 text-sm rounded-lg px-3 block w-full",
                "sm" => "h-8 text-sm rounded-md pl-3 pr-2 block w-full",
                "xs" => "h-6 text-xs rounded-md pl-3 pr-2 block w-full",
            },
        )
        ->add($invalid ? "border border-red-500" : "border border-zinc-200 border-b-zinc-300/80 dark:border-white/10");
@endphp

<button
    type="button"
    {{ $attributes->class($classes) }}
    data-flux-select-button
>
    <ui-selected
        wire:ignore
        class="flex flex-1 gap-2 truncate text-left text-zinc-700 dark:text-zinc-300 [&>*:has(+_*)]:after:content-[',_'] [[disabled]_&]:text-zinc-500 dark:[[disabled]_&]:text-zinc-400"
    >
        <span
            class="text-zinc-400 dark:text-zinc-400 [[disabled]_&]:text-zinc-400/70 dark:[[disabled]_&]:text-zinc-500"
        >
            {{ $placeholder }}
        </span>
    </ui-selected>

    <flux:icon.chevron-down
        variant="mini"
        class="-mr-1 ml-2 text-zinc-300 dark:text-white/60 [[data-flux-select-button]:hover_&]:text-zinc-800 dark:[[data-flux-select-button]:hover_&]:text-white [[disabled]_&]:!text-zinc-200 dark:[[disabled]_&]:!text-white/40"
    />
</button>
