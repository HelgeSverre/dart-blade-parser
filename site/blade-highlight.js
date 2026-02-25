(() => {
  function tokenizeBlade(code) {
    const tokens = [];
    let i = 0;
    while (i < code.length) {
      // Blade comments {{-- --}}
      if (code.startsWith('{{--', i)) {
        const end = code.indexOf('--}}', i + 4);
        const stop = end === -1 ? code.length : end + 4;
        tokens.push({ type: 'comment', text: code.slice(i, stop) });
        i = stop;
      }
      // Raw echo {!! !!}
      else if (code.startsWith('{!!', i)) {
        const end = code.indexOf('!!}', i + 3);
        const stop = end === -1 ? code.length : end + 3;
        tokens.push({ type: 'echo', text: code.slice(i, stop) });
        i = stop;
      }
      // Escaped echo {{ }}
      else if (code.startsWith('{{', i) && !code.startsWith('{{{', i)) {
        const end = code.indexOf('}}', i + 2);
        const stop = end === -1 ? code.length : end + 2;
        tokens.push({ type: 'echo', text: code.slice(i, stop) });
        i = stop;
      }
      // Blade directives @word or @word(...)
      else if (code[i] === '@' && i + 1 < code.length && /[a-zA-Z]/.test(code[i + 1])) {
        const start = i;
        i++; // skip @
        while (i < code.length && /[a-zA-Z_]/.test(code[i])) i++;
        const nameEnd = i;
        // Include parenthesized expression if present
        if (i < code.length && code[i] === '(') {
          let depth = 1; i++;
          while (i < code.length && depth > 0) {
            if (code[i] === '(') depth++;
            else if (code[i] === ')') depth--;
            if (code[i] === "'" || code[i] === '"') {
              const q = code[i]; i++;
              while (i < code.length && code[i] !== q) { if (code[i] === '\\') i++; i++; }
            }
            i++;
          }
          // Split into @name and (expression)
          tokens.push({ type: 'directive', text: code.slice(start, nameEnd) });
          tokens.push({ type: 'directive-expr', text: code.slice(nameEnd, i) });
        } else {
          tokens.push({ type: 'directive', text: code.slice(start, i) });
        }
      }
      // HTML tags <...>
      else if (code[i] === '<' && i + 1 < code.length && (code[i+1] === '/' || code[i+1] === '!' || /[a-zA-Z]/.test(code[i+1]))) {
        const start = i;
        // Simple tag scan — find closing >
        let inQuote = null;
        i++;
        while (i < code.length) {
          if (inQuote) {
            if (code[i] === inQuote) inQuote = null;
            else if (code[i] === '\\') i++;
          } else {
            if (code[i] === '"' || code[i] === "'") inQuote = code[i];
            else if (code[i] === '>') { i++; break; }
          }
          i++;
        }
        const tagText = code.slice(start, i);
        // Tokenize tag internals
        tokenizeTag(tagText, tokens);
      }
      // Plain text
      else {
        const start = i;
        while (i < code.length && code[i] !== '<' && code[i] !== '@' && !code.startsWith('{{', i) && !code.startsWith('{!!', i)) i++;
        if (i > start) tokens.push({ type: 'text', text: code.slice(start, i) });
      }
    }
    return tokens;
  }

  function tokenizeTag(tag, tokens) {
    // Split tag into: <tagname, attributes, >
    // Simple approach: highlight the whole tag with nested spans
    const m = tag.match(/^(<\/?)([\w:.-]+)/);
    if (!m) { tokens.push({ type: 'tag', text: tag }); return; }
    tokens.push({ type: 'tag', text: m[1] + m[2] });
    let rest = tag.slice(m[0].length);
    // Parse attributes
    let j = 0;
    while (j < rest.length) {
      // Whitespace
      if (/\s/.test(rest[j])) {
        const s = j;
        while (j < rest.length && /\s/.test(rest[j])) j++;
        tokens.push({ type: 'text', text: rest.slice(s, j) });
      }
      // Closing > or />
      else if (rest[j] === '>' || rest.startsWith('/>', j)) {
        tokens.push({ type: 'tag', text: rest.slice(j) });
        break;
      }
      // Attribute name
      else if (/[\w@:.x-]/.test(rest[j])) {
        const s = j;
        while (j < rest.length && /[\w@:.\-]/.test(rest[j])) j++;
        const attrName = rest.slice(s, j);
        tokens.push({ type: 'attr', text: attrName });
        // = and value
        if (j < rest.length && rest[j] === '=') {
          tokens.push({ type: 'text', text: '=' });
          j++;
          if (j < rest.length && (rest[j] === '"' || rest[j] === "'")) {
            const q = rest[j]; const vs = j; j++;
            while (j < rest.length && rest[j] !== q) {
              if (rest[j] === '\\') j++;
              j++;
            }
            if (j < rest.length) j++;
            const val = rest.slice(vs, j);
            // Check if value contains Blade echo
            if (val.includes('{{') || val.includes('{!!')) {
              tokenizeAttrValue(val, tokens);
            } else {
              tokens.push({ type: 'string', text: val });
            }
          }
        }
      }
      else { j++; }
    }
  }

  function tokenizeAttrValue(val, tokens) {
    // Split on {{ }} and {!! !!} inside attribute values
    let i = 0;
    const q = val[0];
    tokens.push({ type: 'string', text: q });
    i = 1;
    const inner = val.slice(1, -1);
    let k = 0;
    while (k < inner.length) {
      if (inner.startsWith('{{', k)) {
        const end = inner.indexOf('}}', k + 2);
        const stop = end === -1 ? inner.length : end + 2;
        tokens.push({ type: 'echo', text: inner.slice(k, stop) });
        k = stop;
      } else if (inner.startsWith('{!!', k)) {
        const end = inner.indexOf('!!}', k + 3);
        const stop = end === -1 ? inner.length : end + 3;
        tokens.push({ type: 'echo', text: inner.slice(k, stop) });
        k = stop;
      } else {
        const s = k;
        while (k < inner.length && !inner.startsWith('{{', k) && !inner.startsWith('{!!', k)) k++;
        tokens.push({ type: 'string', text: inner.slice(s, k) });
      }
    }
    tokens.push({ type: 'string', text: val[val.length - 1] });
  }

  function escapeHtml(s) {
    return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  function highlightBlade(code) {
    if (!code) return '\n';
    const tokens = tokenizeBlade(code);
    let html = '';
    for (const t of tokens) {
      const e = escapeHtml(t.text);
      if (t.type === 'text') html += e;
      else html += `<span class="hl-${t.type}">${e}</span>`;
    }
    if (code.endsWith('\n')) html += ' ';
    return html;
  }

  globalThis.BladeHighlight = { escapeHtml, tokenizeBlade, highlightBlade };
})();
