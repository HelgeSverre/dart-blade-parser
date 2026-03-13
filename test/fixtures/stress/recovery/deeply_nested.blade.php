@extends('layouts.app')

@section('content')
    <x-page-layout>
        <x-slot:header>
            <h1>Dashboard</h1>
        </x-slot>

        <x-card>
            <x-slot:title>
                {{ $title }}
            </x-slot>

            @if($user->isAdmin())
                <x-admin-panel>
                    @foreach($reports as $report)
                        <x-report-card>
                            <div class="metric">
                                @if($report->hasChart())
                                    <x-chart :data="$report->data">
                                        <canvas id="{{ $report->id }}"></canvas>
                                @endif
                            </div>
                        </x-report-card>
                    @endforeach
                </x-admin-panel>
            @else
                <p>Access denied</p>

        </x-card>
    </x-page-layout>
