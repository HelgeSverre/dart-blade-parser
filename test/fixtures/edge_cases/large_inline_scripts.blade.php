{{-- Large inline JavaScript and SVG blocks for performance testing --}}
{{-- Tests raw text mode scanning with substantial content --}}

<div class="dashboard" x-data="{ loading: false }">
    @if($showChart)
    <div class="chart-container">
        <canvas id="chart-{{ $chartId }}"></canvas>
    </div>
    @endif

    <script>
        // Chart configuration - large inline JavaScript block
        // This tests raw text lexer performance with substantial JS content

        const ChartManager = (function() {
            'use strict';

            const config = {!! json_encode($chartConfig) !!};
            const apiEndpoint = '{{ config("app.url") }}/api/v2/charts';
            const csrfToken = '{{ csrf_token() }}';

            // Utility functions
            function debounce(func, wait) {
                let timeout;
                return function executedFunction(...args) {
                    const later = () => {
                        clearTimeout(timeout);
                        func(...args);
                    };
                    clearTimeout(timeout);
                    timeout = setTimeout(later, wait);
                };
            }

            function throttle(func, limit) {
                let inThrottle;
                return function(...args) {
                    if (!inThrottle) {
                        func.apply(this, args);
                        inThrottle = true;
                        setTimeout(() => inThrottle = false, limit);
                    }
                };
            }

            // Color utilities
            const ColorUtils = {
                hexToRgb(hex) {
                    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
                    return result ? {
                        r: parseInt(result[1], 16),
                        g: parseInt(result[2], 16),
                        b: parseInt(result[3], 16)
                    } : null;
                },
                rgbToHsl(r, g, b) {
                    r /= 255; g /= 255; b /= 255;
                    const max = Math.max(r, g, b), min = Math.min(r, g, b);
                    let h, s, l = (max + min) / 2;
                    if (max === min) {
                        h = s = 0;
                    } else {
                        const d = max - min;
                        s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
                        switch (max) {
                            case r: h = ((g - b) / d + (g < b ? 6 : 0)) / 6; break;
                            case g: h = ((b - r) / d + 2) / 6; break;
                            case b: h = ((r - g) / d + 4) / 6; break;
                        }
                    }
                    return { h: h * 360, s: s * 100, l: l * 100 };
                },
                generatePalette(baseColor, count) {
                    const rgb = this.hexToRgb(baseColor);
                    if (!rgb) return [];
                    const hsl = this.rgbToHsl(rgb.r, rgb.g, rgb.b);
                    const palette = [];
                    for (let i = 0; i < count; i++) {
                        const hue = (hsl.h + (360 / count) * i) % 360;
                        palette.push(`hsl(${hue}, ${hsl.s}%, ${hsl.l}%)`);
                    }
                    return palette;
                }
            };

            // Data processing pipeline
            class DataProcessor {
                constructor(options = {}) {
                    this.cache = new Map();
                    this.maxCacheSize = options.maxCacheSize || 1000;
                    this.transformers = [];
                    this.filters = [];
                    this.aggregators = {};
                }

                addTransformer(name, fn) {
                    this.transformers.push({ name, fn });
                    return this;
                }

                addFilter(name, predicate) {
                    this.filters.push({ name, predicate });
                    return this;
                }

                addAggregator(name, fn) {
                    this.aggregators[name] = fn;
                    return this;
                }

                process(data) {
                    const cacheKey = JSON.stringify(data).substring(0, 100);
                    if (this.cache.has(cacheKey)) {
                        return this.cache.get(cacheKey);
                    }

                    let result = [...data];

                    // Apply filters
                    for (const filter of this.filters) {
                        result = result.filter(filter.predicate);
                    }

                    // Apply transformers
                    for (const transformer of this.transformers) {
                        result = result.map(transformer.fn);
                    }

                    // Apply aggregators
                    const aggregated = {};
                    for (const [name, fn] of Object.entries(this.aggregators)) {
                        aggregated[name] = fn(result);
                    }

                    const output = { data: result, aggregations: aggregated };

                    // Cache management
                    if (this.cache.size >= this.maxCacheSize) {
                        const firstKey = this.cache.keys().next().value;
                        this.cache.delete(firstKey);
                    }
                    this.cache.set(cacheKey, output);

                    return output;
                }

                clearCache() {
                    this.cache.clear();
                }
            }

            // Chart rendering engine
            class ChartRenderer {
                constructor(canvas, options = {}) {
                    this.canvas = canvas;
                    this.ctx = canvas.getContext('2d');
                    this.width = options.width || canvas.width;
                    this.height = options.height || canvas.height;
                    this.padding = options.padding || { top: 40, right: 20, bottom: 60, left: 60 };
                    this.animations = [];
                    this.isAnimating = false;
                    this.dpr = window.devicePixelRatio || 1;

                    this._setupCanvas();
                }

                _setupCanvas() {
                    this.canvas.width = this.width * this.dpr;
                    this.canvas.height = this.height * this.dpr;
                    this.canvas.style.width = this.width + 'px';
                    this.canvas.style.height = this.height + 'px';
                    this.ctx.scale(this.dpr, this.dpr);
                }

                get plotArea() {
                    return {
                        x: this.padding.left,
                        y: this.padding.top,
                        width: this.width - this.padding.left - this.padding.right,
                        height: this.height - this.padding.top - this.padding.bottom
                    };
                }

                clear() {
                    this.ctx.clearRect(0, 0, this.width, this.height);
                }

                drawGrid(xTicks, yTicks, options = {}) {
                    const { x, y, width, height } = this.plotArea;
                    const gridColor = options.color || 'rgba(0, 0, 0, 0.1)';

                    this.ctx.strokeStyle = gridColor;
                    this.ctx.lineWidth = 0.5;

                    // Vertical grid lines
                    for (let i = 0; i <= xTicks; i++) {
                        const xPos = x + (width / xTicks) * i;
                        this.ctx.beginPath();
                        this.ctx.moveTo(xPos, y);
                        this.ctx.lineTo(xPos, y + height);
                        this.ctx.stroke();
                    }

                    // Horizontal grid lines
                    for (let i = 0; i <= yTicks; i++) {
                        const yPos = y + (height / yTicks) * i;
                        this.ctx.beginPath();
                        this.ctx.moveTo(x, yPos);
                        this.ctx.lineTo(x + width, yPos);
                        this.ctx.stroke();
                    }
                }

                drawLine(points, options = {}) {
                    if (points.length < 2) return;

                    const color = options.color || '#3b82f6';
                    const lineWidth = options.lineWidth || 2;
                    const smooth = options.smooth !== false;

                    this.ctx.strokeStyle = color;
                    this.ctx.lineWidth = lineWidth;
                    this.ctx.lineCap = 'round';
                    this.ctx.lineJoin = 'round';

                    this.ctx.beginPath();

                    if (smooth && points.length > 2) {
                        this.ctx.moveTo(points[0].x, points[0].y);
                        for (let i = 1; i < points.length - 1; i++) {
                            const xc = (points[i].x + points[i + 1].x) / 2;
                            const yc = (points[i].y + points[i + 1].y) / 2;
                            this.ctx.quadraticCurveTo(points[i].x, points[i].y, xc, yc);
                        }
                        const last = points[points.length - 1];
                        const secondLast = points[points.length - 2];
                        this.ctx.quadraticCurveTo(secondLast.x, secondLast.y, last.x, last.y);
                    } else {
                        this.ctx.moveTo(points[0].x, points[0].y);
                        for (let i = 1; i < points.length; i++) {
                            this.ctx.lineTo(points[i].x, points[i].y);
                        }
                    }

                    this.ctx.stroke();

                    // Draw gradient fill under line
                    if (options.fill) {
                        const gradient = this.ctx.createLinearGradient(0, this.plotArea.y, 0, this.plotArea.y + this.plotArea.height);
                        gradient.addColorStop(0, color.replace(')', ', 0.3)').replace('rgb', 'rgba'));
                        gradient.addColorStop(1, color.replace(')', ', 0)').replace('rgb', 'rgba'));

                        this.ctx.fillStyle = gradient;
                        this.ctx.beginPath();
                        this.ctx.moveTo(points[0].x, this.plotArea.y + this.plotArea.height);
                        for (const point of points) {
                            this.ctx.lineTo(point.x, point.y);
                        }
                        this.ctx.lineTo(points[points.length - 1].x, this.plotArea.y + this.plotArea.height);
                        this.ctx.closePath();
                        this.ctx.fill();
                    }
                }

                drawBars(data, options = {}) {
                    const { x, y, width, height } = this.plotArea;
                    const barWidth = (width / data.length) * 0.8;
                    const gap = (width / data.length) * 0.2;
                    const maxVal = Math.max(...data.map(d => d.value));
                    const colors = options.colors || ColorUtils.generatePalette('#3b82f6', data.length);

                    data.forEach((item, i) => {
                        const barHeight = (item.value / maxVal) * height;
                        const barX = x + (width / data.length) * i + gap / 2;
                        const barY = y + height - barHeight;

                        // Bar shadow
                        this.ctx.fillStyle = 'rgba(0, 0, 0, 0.05)';
                        this.ctx.fillRect(barX + 2, barY + 2, barWidth, barHeight);

                        // Bar
                        const gradient = this.ctx.createLinearGradient(barX, barY, barX, barY + barHeight);
                        gradient.addColorStop(0, colors[i % colors.length]);
                        gradient.addColorStop(1, colors[i % colors.length].replace('50%', '40%'));
                        this.ctx.fillStyle = gradient;

                        // Rounded top corners
                        const radius = Math.min(barWidth / 4, 4);
                        this.ctx.beginPath();
                        this.ctx.moveTo(barX, barY + barHeight);
                        this.ctx.lineTo(barX, barY + radius);
                        this.ctx.arcTo(barX, barY, barX + radius, barY, radius);
                        this.ctx.lineTo(barX + barWidth - radius, barY);
                        this.ctx.arcTo(barX + barWidth, barY, barX + barWidth, barY + radius, radius);
                        this.ctx.lineTo(barX + barWidth, barY + barHeight);
                        this.ctx.closePath();
                        this.ctx.fill();

                        // Value label
                        this.ctx.fillStyle = '#374151';
                        this.ctx.font = '11px Inter, system-ui, sans-serif';
                        this.ctx.textAlign = 'center';
                        this.ctx.fillText(
                            item.value.toLocaleString(),
                            barX + barWidth / 2,
                            barY - 5
                        );
                    });
                }

                animate(duration, drawFrame) {
                    return new Promise(resolve => {
                        const startTime = performance.now();
                        const tick = (currentTime) => {
                            const elapsed = currentTime - startTime;
                            const progress = Math.min(elapsed / duration, 1);
                            const eased = 1 - Math.pow(1 - progress, 3); // ease-out cubic

                            this.clear();
                            drawFrame(eased);

                            if (progress < 1) {
                                requestAnimationFrame(tick);
                            } else {
                                resolve();
                            }
                        };
                        requestAnimationFrame(tick);
                    });
                }
            }

            // Tooltip manager
            class TooltipManager {
                constructor(container) {
                    this.container = container;
                    this.tooltip = document.createElement('div');
                    this.tooltip.className = 'chart-tooltip';
                    this.tooltip.style.cssText = `
                        position: absolute;
                        display: none;
                        background: white;
                        border: 1px solid #e5e7eb;
                        border-radius: 8px;
                        padding: 8px 12px;
                        font-size: 13px;
                        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
                        pointer-events: none;
                        z-index: 1000;
                        transition: opacity 0.15s;
                    `;
                    container.appendChild(this.tooltip);
                }

                show(x, y, content) {
                    this.tooltip.innerHTML = content;
                    this.tooltip.style.display = 'block';
                    this.tooltip.style.left = (x + 10) + 'px';
                    this.tooltip.style.top = (y - 10) + 'px';
                    this.tooltip.style.opacity = '1';
                }

                hide() {
                    this.tooltip.style.opacity = '0';
                    setTimeout(() => {
                        this.tooltip.style.display = 'none';
                    }, 150);
                }

                destroy() {
                    this.tooltip.remove();
                }
            }

            // Event bus for chart communication
            class EventBus {
                constructor() {
                    this.listeners = new Map();
                }

                on(event, callback) {
                    if (!this.listeners.has(event)) {
                        this.listeners.set(event, new Set());
                    }
                    this.listeners.get(event).add(callback);
                    return () => this.off(event, callback);
                }

                off(event, callback) {
                    const callbacks = this.listeners.get(event);
                    if (callbacks) {
                        callbacks.delete(callback);
                    }
                }

                emit(event, data) {
                    const callbacks = this.listeners.get(event);
                    if (callbacks) {
                        callbacks.forEach(cb => cb(data));
                    }
                }
            }

            // Main initialization
            async function init() {
                const canvas = document.getElementById('chart-{{ $chartId }}');
                if (!canvas) return;

                const renderer = new ChartRenderer(canvas, {
                    width: config.width || 800,
                    height: config.height || 400
                });

                const processor = new DataProcessor()
                    .addFilter('nonZero', d => d.value > 0)
                    .addTransformer('normalize', d => ({
                        ...d,
                        normalizedValue: d.value / config.maxValue
                    }))
                    .addAggregator('total', data => data.reduce((sum, d) => sum + d.value, 0))
                    .addAggregator('average', data => data.reduce((sum, d) => sum + d.value, 0) / data.length);

                const tooltips = new TooltipManager(canvas.parentElement);
                const bus = new EventBus();

                // Fetch and render data
                try {
                    const response = await fetch(apiEndpoint, {
                        headers: {
                            'X-CSRF-TOKEN': csrfToken,
                            'Content-Type': 'application/json',
                            'Accept': 'application/json'
                        }
                    });

                    if (!response.ok) throw new Error(`HTTP ${response.status}`);
                    const rawData = await response.json();
                    const processed = processor.process(rawData.data);

                    // Render based on chart type
                    if (config.type === 'line') {
                        const points = processed.data.map((d, i) => ({
                            x: renderer.plotArea.x + (renderer.plotArea.width / (processed.data.length - 1)) * i,
                            y: renderer.plotArea.y + renderer.plotArea.height * (1 - d.normalizedValue)
                        }));

                        await renderer.animate(800, (progress) => {
                            renderer.drawGrid(10, 5);
                            const visiblePoints = points.slice(0, Math.ceil(points.length * progress));
                            renderer.drawLine(visiblePoints, { color: config.color || '#3b82f6', fill: true });
                        });
                    } else if (config.type === 'bar') {
                        await renderer.animate(600, (progress) => {
                            renderer.drawGrid(processed.data.length, 5);
                            const animatedData = processed.data.map(d => ({
                                ...d,
                                value: d.value * progress
                            }));
                            renderer.drawBars(animatedData);
                        });
                    }

                    bus.emit('chart:rendered', { id: '{{ $chartId }}', type: config.type });
                } catch (error) {
                    console.error('Chart initialization failed:', error);
                    bus.emit('chart:error', { id: '{{ $chartId }}', error });
                }

                // Resize handler
                const handleResize = debounce(() => {
                    renderer._setupCanvas();
                    bus.emit('chart:resize', { id: '{{ $chartId }}' });
                }, 250);
                window.addEventListener('resize', handleResize);

                // Cleanup
                return {
                    destroy() {
                        window.removeEventListener('resize', handleResize);
                        tooltips.destroy();
                        processor.clearCache();
                    }
                };
            }

            return { init, ColorUtils, DataProcessor, EventBus };
        })();

        // Initialize when DOM is ready
        document.addEventListener('DOMContentLoaded', () => {
            ChartManager.init().then(instance => {
                window.__chartInstances = window.__chartInstances || {};
                window.__chartInstances['{{ $chartId }}'] = instance;
            });
        });
    </script>

    {{-- Large inline SVG icon set --}}
    <svg xmlns="http://www.w3.org/2000/svg" style="display: none;">
        <defs>
            <linearGradient id="grad-primary-{{ $themeId }}" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style="stop-color:{{ $primaryColor }};stop-opacity:1" />
                <stop offset="100%" style="stop-color:{{ $secondaryColor }};stop-opacity:1" />
            </linearGradient>
            <filter id="shadow-{{ $themeId }}" x="-20%" y="-20%" width="140%" height="140%">
                <feDropShadow dx="0" dy="2" stdDeviation="3" flood-opacity="0.15"/>
            </filter>
            <clipPath id="clip-circle-{{ $themeId }}">
                <circle cx="12" cy="12" r="10"/>
            </clipPath>
        </defs>

        <symbol id="icon-dashboard" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <rect x="3" y="3" width="7" height="7" rx="1"/>
            <rect x="14" y="3" width="7" height="7" rx="1"/>
            <rect x="3" y="14" width="7" height="7" rx="1"/>
            <rect x="14" y="14" width="7" height="7" rx="1"/>
        </symbol>

        <symbol id="icon-chart-line" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M3 3v18h18"/>
            <path d="M18.7 8l-5.1 5.2-2.8-2.7L7 14.3"/>
        </symbol>

        <symbol id="icon-chart-bar" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M3 3v18h18"/>
            <rect x="7" y="10" width="3" height="8" rx="0.5"/>
            <rect x="12" y="6" width="3" height="12" rx="0.5"/>
            <rect x="17" y="8" width="3" height="10" rx="0.5"/>
        </symbol>

        <symbol id="icon-chart-pie" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M21.21 15.89A10 10 0 1 1 8 2.83"/>
            <path d="M22 12A10 10 0 0 0 12 2v10z"/>
        </symbol>

        <symbol id="icon-users" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
            <circle cx="9" cy="7" r="4"/>
            <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
            <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
        </symbol>

        <symbol id="icon-settings" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="12" cy="12" r="3"/>
            <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/>
        </symbol>

        <symbol id="icon-bell" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
            <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
        </symbol>

        <symbol id="icon-search" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="11" cy="11" r="8"/>
            <line x1="21" y1="21" x2="16.65" y2="16.65"/>
        </symbol>

        <symbol id="icon-filter" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/>
        </symbol>

        <symbol id="icon-download" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
            <polyline points="7 10 12 15 17 10"/>
            <line x1="12" y1="15" x2="12" y2="3"/>
        </symbol>

        <symbol id="icon-refresh" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="23 4 23 10 17 10"/>
            <polyline points="1 20 1 14 7 14"/>
            <path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/>
        </symbol>

        <symbol id="icon-calendar" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
            <line x1="16" y1="2" x2="16" y2="6"/>
            <line x1="8" y1="2" x2="8" y2="6"/>
            <line x1="3" y1="10" x2="21" y2="10"/>
        </symbol>

        <symbol id="icon-arrow-up" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <line x1="12" y1="19" x2="12" y2="5"/>
            <polyline points="5 12 12 5 19 12"/>
        </symbol>

        <symbol id="icon-arrow-down" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <line x1="12" y1="5" x2="12" y2="19"/>
            <polyline points="19 12 12 19 5 12"/>
        </symbol>

        <symbol id="icon-check-circle" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>
            <polyline points="22 4 12 14.01 9 11.01"/>
        </symbol>

        <symbol id="icon-alert-triangle" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
            <line x1="12" y1="9" x2="12" y2="13"/>
            <line x1="12" y1="17" x2="12.01" y2="17"/>
        </symbol>

        <symbol id="icon-x-circle" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="12" cy="12" r="10"/>
            <line x1="15" y1="9" x2="9" y2="15"/>
            <line x1="9" y1="9" x2="15" y2="15"/>
        </symbol>
    </svg>

    <style>
        /* Dashboard theme - dynamic colors from Blade */
        :root {
            --dashboard-primary: {{ $primaryColor }};
            --dashboard-secondary: {{ $secondaryColor }};
            --dashboard-accent: {{ $accentColor ?? '#f59e0b' }};
            --dashboard-bg: {{ $bgColor ?? '#f9fafb' }};
            --dashboard-text: {{ $textColor ?? '#111827' }};
            --dashboard-border: {{ $borderColor ?? '#e5e7eb' }};
            --dashboard-radius: {{ $borderRadius ?? '8' }}px;
            --dashboard-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px -1px rgba(0, 0, 0, 0.1);
        }

        .dashboard {
            font-family: 'Inter', system-ui, -apple-system, sans-serif;
            background-color: var(--dashboard-bg);
            color: var(--dashboard-text);
            min-height: 100vh;
        }

        .chart-container {
            background: white;
            border-radius: var(--dashboard-radius);
            border: 1px solid var(--dashboard-border);
            box-shadow: var(--dashboard-shadow);
            padding: 24px;
            margin-bottom: 24px;
            position: relative;
        }

        .chart-container canvas {
            width: 100%;
            height: auto;
        }

        .chart-tooltip {
            font-family: 'Inter', system-ui, sans-serif;
        }

        /* Icon styles */
        .icon {
            width: 20px;
            height: 20px;
            display: inline-block;
            vertical-align: middle;
        }

        .icon-sm { width: 16px; height: 16px; }
        .icon-lg { width: 24px; height: 24px; }
        .icon-xl { width: 32px; height: 32px; }

        /* Stat cards */
        .stat-card {
            background: white;
            border-radius: var(--dashboard-radius);
            border: 1px solid var(--dashboard-border);
            box-shadow: var(--dashboard-shadow);
            padding: 20px;
            display: flex;
            align-items: center;
            gap: 16px;
            transition: box-shadow 0.2s;
        }

        .stat-card:hover {
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.1);
        }

        .stat-card .icon-wrapper {
            width: 48px;
            height: 48px;
            border-radius: 12px;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .stat-card .value {
            font-size: 24px;
            font-weight: 700;
            line-height: 1;
            color: var(--dashboard-text);
        }

        .stat-card .label {
            font-size: 13px;
            color: #6b7280;
            margin-top: 4px;
        }

        .stat-card .change {
            font-size: 12px;
            font-weight: 500;
            display: flex;
            align-items: center;
            gap: 2px;
            margin-top: 4px;
        }

        .stat-card .change.positive { color: #059669; }
        .stat-card .change.negative { color: #dc2626; }

        /* Responsive grid */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 16px;
            margin-bottom: 24px;
        }

        /* Animation classes */
        @keyframes fadeInUp {
            from {
                opacity: 0;
                transform: translateY(20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .animate-in {
            animation: fadeInUp 0.5s ease-out forwards;
        }

        @media (max-width: 768px) {
            .stats-grid {
                grid-template-columns: 1fr;
            }

            .chart-container {
                padding: 16px;
            }
        }

        @media (prefers-color-scheme: dark) {
            .dashboard {
                --dashboard-bg: #111827;
                --dashboard-text: #f9fafb;
                --dashboard-border: #374151;
            }

            .chart-container,
            .stat-card {
                background: #1f2937;
            }
        }
    </style>
</div>
