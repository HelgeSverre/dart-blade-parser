<div @class(['active' => $isActive, 'text-danger' => $hasError]) @click="toggle" @style(['color: red' => $isError])>
    <input type="checkbox" @checked($isChecked) @disabled($isDisabled)>
    <select>
        <option @selected($isSelected)>Option 1</option>
    </select>
    <input @readonly($isReadonly) @required($isRequired)>
</div>
