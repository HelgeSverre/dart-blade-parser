{{-- PHP blocks used inline within Blade template HTML --}}

{{-- PHP echo mixed with HTML --}}
<table>
    <tr>
        <td><?= $row['name'] ?></td>
        <td><?= $row['email'] ?></td>
        <td><?= number_format($row['balance'], 2) ?></td>
    </tr>
</table>

{{-- Standard PHP block inline --}}
<ul>
    <?php foreach ($items as $item): ?>
        <li><?= $item->name ?></li>
    <?php endforeach; ?>
</ul>

{{-- PHP mixed with Blade directives --}}
<?php $showHeader = true; ?>
@if($showHeader)
    <header>
        <h1><?= $title ?></h1>
    </header>
@endif

{{-- Multiple PHP blocks on same line --}}
<p><?= $first ?> - <?= $last ?></p>

{{-- Short tag inline --}}
<span class="badge"><? echo $count; ?></span>

{{-- PHP inside HTML attributes (unusual but valid) --}}
<div class="<?= $isActive ? 'active' : 'inactive' ?>">
    Content
</div>

{{-- PHP with Blade echo on same line --}}
<p><?= $prefix ?>{{ $suffix }}</p>
