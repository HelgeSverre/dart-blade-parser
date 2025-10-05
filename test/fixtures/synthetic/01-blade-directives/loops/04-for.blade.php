---
description: "@for loop for pagination and numbered list generation"
tags: ["for", "pagination", "numbered-lists"]
---
<div class="pagination-container">
    <nav aria-label="Page navigation">
        <ul class="pagination">
            @if($currentPage > 1)
            <li class="page-item">
                <a href="?page={{ $currentPage - 1 }}" class="page-link" aria-label="Previous">
                    <span aria-hidden="true">&laquo;</span>
                </a>
            </li>
            @endif

            @for($i = 1; $i <= $totalPages; $i++)
                @if($i == 1 || $i == $totalPages || abs($i - $currentPage) <= 2)
                <li class="page-item {{ $i == $currentPage ? 'active' : '' }}">
                    <a href="?page={{ $i }}" class="page-link">{{ $i }}</a>
                </li>
                @elseif($i == $currentPage - 3 || $i == $currentPage + 3)
                <li class="page-item disabled">
                    <span class="page-link">...</span>
                </li>
                @endif
            @endfor

            @if($currentPage < $totalPages)
            <li class="page-item">
                <a href="?page={{ $currentPage + 1 }}" class="page-link" aria-label="Next">
                    <span aria-hidden="true">&raquo;</span>
                </a>
            </li>
            @endif
        </ul>
    </nav>
</div>

<section class="leaderboard">
    <h2>Top 10 Contributors This Month</h2>
    <ol class="ranked-list">
        @for($rank = 1; $rank <= 10; $rank++)
            @php
                $contributor = $contributors[$rank - 1] ?? null;
            @endphp

            @if($contributor)
            <li class="rank-item rank-{{ $rank }}">
                <span class="rank-number {{ $rank <= 3 ? 'medal-' . $rank : '' }}">
                    #{{ $rank }}
                </span>

                <div class="contributor-details">
                    <img src="{{ $contributor->avatar }}" alt="{{ $contributor->name }}">
                    <div class="contributor-info">
                        <strong>{{ $contributor->name }}</strong>
                        <span class="contribution-count">{{ $contributor->contributions }} contributions</span>
                    </div>
                </div>

                <div class="rank-stats">
                    <span class="points">{{ number_format($contributor->points) }} pts</span>
                </div>
            </li>
            @endif
        @endfor
    </ol>
</section>
