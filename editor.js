import init, { parse_full_document, EditorRope, debug_rope } from './pkg/simple_editor.js';

await init();

const input = document.getElementById('input');
const preview = document.getElementById('preview');
let debounceTimer;
let rope = null;

const STORAGE_KEY = 'simple_editor_content';
const saved = localStorage.getItem(STORAGE_KEY);
if (saved) {
    input.value = saved;
    rope = new EditorRope(saved);
    render(saved);
} else {
	rope = new EditorRope('');
}

input.addEventListener('input', (e) => {
    localStorage.setItem(STORAGE_KEY, input.value);
    const pos = input.selectionStart;
    
    if (e.inputType === 'insertText' && e.data && rope) {
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(() => {
            rope.insert(pos - e.data.length, e.data);
            renderBlocks(JSON.parse(rope.get_all()));
        }, 300);
    } else {
        clearTimeout(debounceTimer);
        debounceTimer = setTimeout(() => {
            rope = new EditorRope(input.value);
            renderBlocks(JSON.parse(rope.get_all()));
        }, 300);
    }
});

input.addEventListener('scroll', () => {
    const ratio = input.scrollTop / (input.scrollHeight - input.clientHeight);
    const previewPane = document.getElementById('preview-pane');
    previewPane.scrollTop = ratio * (previewPane.scrollHeight - previewPane.clientHeight);
});

input.addEventListener('keyup', syncCursorToPreview);
input.addEventListener('click', syncCursorToPreview);

input.addEventListener('keydown', (e) => {
    const value = input.value;
    const pos = input.selectionStart;
    const lineStart = value.lastIndexOf('\n', pos - 1) + 1;
    const currentLine = value.slice(lineStart, pos);
    const trimmedLine = currentLine.trim();

   
    if (e.key === 'Tab') {
        if (trimmedLine.startsWith('|')) {
            e.preventDefault();
            if (e.shiftKey) {
                moveToPrevCell(value, pos);
            } else {
                moveToNextCell(value, pos);
            }
            return;
        }

        
        e.preventDefault();
        const before = value.slice(0, pos);
        const after = value.slice(pos);
        input.value = before + '    ' + after;
        input.selectionStart = pos + 4;
        input.selectionEnd = pos + 4;
        highlight(input.value);
        return;
    }

    if (e.key === 'Enter') {
        const tbMatch = trimmedLine.match(/^\$TB(?:\s+(\d+)\|(\d+))?$/);
        if (tbMatch) {
            e.preventDefault();
            const cols = parseInt(tbMatch[1] ?? '3');
            const rows = parseInt(tbMatch[2] ?? '3');
            const scaffold = buildTableScaffold(cols, rows);
            const before = value.slice(0, lineStart);
            const after = value.slice(pos);
            input.value = before + `$TB\n` + scaffold + after;
            const firstCellPos = before.length + '$TB\n'.length + '    | '.length;
            input.selectionStart = firstCellPos;
            input.selectionEnd = firstCellPos + 'Header 1'.length;
            highlight(input.value);
            clearTimeout(debounceTimer);
            debounceTimer = setTimeout(() => render(input.value), 300);
            return;
        }

        
        const bareCmd = trimmedLine.match(/^\$[A-Z:]+$/)
            && !trimmedLine.includes(' ');
        if (bareCmd) {
            e.preventDefault();
            const before = value.slice(0, pos);
            const after = value.slice(pos);
            input.value = before + '\n    ' + after;
            input.selectionStart = pos + 5; 
	    input.selectionEnd = pos + 5;
            highlight(input.value);
            return;
        }

        const indentMatch = currentLine.match(/^(    +)/);
        if (indentMatch) {
            e.preventDefault();
            const before = value.slice(0, pos);
            const after = value.slice(pos);
            input.value = before + '\n' + indentMatch[1] + after;
            const newPos = pos + 1 + indentMatch[1].length;
            input.selectionStart = newPos;
            input.selectionEnd = newPos;
            highlight(input.value);
            return;
        }
    }
});

function moveToNextCell(value, pos) {
    const nextPipe = value.indexOf('|', pos);
    if (nextPipe === -1) return;
    const cellStart = nextPipe + 1;
    const cellEnd = value.indexOf('|', cellStart);
    if (cellEnd === -1) return;
    const cellContent = value.slice(cellStart, cellEnd);
    if (cellContent.trim().match(/^-+$/)) {
        moveToNextCell(value, cellEnd);
        return;
    }
    const trimmed = cellContent.trim();
    const trimStart = cellStart + cellContent.indexOf(trimmed);
    input.selectionStart = trimStart;
    input.selectionEnd = trimStart + trimmed.length;
    input.focus();
}

function moveToPrevCell(value, pos) {
    const beforeCursor = value.slice(0, pos);
    const prevPipe = beforeCursor.lastIndexOf('|');
    if (prevPipe === -1) return;
    const beforePrev = value.slice(0, prevPipe);
    const prevPrevPipe = beforePrev.lastIndexOf('|');
    if (prevPrevPipe === -1) return;
    const cellContent = value.slice(prevPrevPipe + 1, prevPipe);
    if (cellContent.trim().match(/^-+$/)) {
        moveToPrevCell(value, prevPrevPipe);
        return;
    }
    const trimmed = cellContent.trim();
    const trimStart = prevPrevPipe + 1 + cellContent.indexOf(trimmed);
    input.selectionStart = trimStart;
    input.selectionEnd = trimStart + trimmed.length;
    input.focus();
}

function buildTableScaffold(cols, rows) {
    const headers = Array.from({ length: cols }, (_, i) => `Header ${i + 1}`);
    const headerRow = '    | ' + headers.join(' | ') + ' |';
    const sep = '    |' + Array.from({ length: cols }, () => '----------|').join('');
    const dataRow = '    | ' + Array.from({ length: cols }, () => 'cell     ').join('| ') + '|';
    const dataRows = Array.from({ length: rows }, () => dataRow);
    return [headerRow, sep, ...dataRows].join('\n') + '\n';
}

function syncCursorToPreview() {
    const value = input.value;
    const pos = input.selectionStart;
    const textBeforeCursor = value.slice(0, pos);
    const lines = textBeforeCursor.split('\n');
    let blockIndex = 0;
    lines.forEach(line => {
        if (line.trim().startsWith('$') && !line.startsWith('    ')) {
            blockIndex++;
        }
    });
    const previewChildren = document.getElementById('preview').children;
    if (previewChildren[blockIndex]) {
        previewChildren[blockIndex].scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
}

function render(text) {
    try {
        const blocks = JSON.parse(parse_full_document(text));
        renderBlocks(blocks);
    } catch(e) {
        console.error('parse error:', e);
    }
}

function renderBlocks(blocks) {
    try {
        preview.innerHTML = '';
        const headings = [];
        const footnotes = [];
        let fnCounter = 0;

        blocks.forEach(block => {
            if (typeof block.kind === 'object' && block.kind.Heading) {
                const level = block.kind.Heading;
                if (level === 1) return;
                const t = block.content.Text ?? '';
                const id = 'h-' + t.toLowerCase()
                    .replace(/\s+/g, '-')
                    .replace(/[^a-z0-9-]/g, '');
                headings.push({ level, text: t, id });
            }
            if (block.kind === 'Footnote') {
                fnCounter++;
                footnotes.push({ index: fnCounter, text: block.content.Text ?? '' });
            }
        });

        let fnIndex = 0;
        blocks.forEach(block => {
            const el = renderBlock(block, headings, footnotes, fnIndex);
            if (block.kind === 'Footnote') fnIndex++;
            if (el) preview.appendChild(el);
        });

        if (footnotes.length > 0) {
            const hr = document.createElement('hr');
            hr.className = 'preview-hr';
            preview.appendChild(hr);
            const fnList = document.createElement('ol');
            fnList.className = 'preview-fn-list';
            footnotes.forEach(fn => {
                const li = document.createElement('li');
                li.id = `fn-${fn.index}`;
                renderInline(fn.text, li);
                fnList.appendChild(li);
            });
            preview.appendChild(fnList);
        }
    } catch(e) {
        console.error('render error:', e);
    }
}

function renderInline(text, container) {
    const re = /"([^"]+)"/g;
    let last = 0;
    let match;
    while ((match = re.exec(text)) !== null) {
        if (match.index > last) {
            container.appendChild(document.createTextNode(text.slice(last, match.index)));
        }
        const inside = match[1];

        if (inside.startsWith('!!')) {
            container.appendChild(document.createTextNode('"' + inside.slice(2) + '"'));
            last = re.lastIndex;
            continue;
        }

        if (inside.startsWith('!')) {
            container.appendChild(document.createTextNode(inside.slice(1)));
            last = re.lastIndex;
            continue;
        }

        const sep = inside.indexOf(' - ');
        if (sep === -1) {
            container.appendChild(document.createTextNode(`"${inside}"`));
            last = re.lastIndex;
            continue;
        }

        const cmd = inside.slice(0, sep).trim();
        const content = inside.slice(sep + 3);

        switch (cmd) {
            case '$I': {
                const el = document.createElement('em');
                el.textContent = content;
                container.appendChild(el);
                break;
            }
            case '$B': {
                const el = document.createElement('strong');
                el.textContent = content;
                container.appendChild(el);
                break;
            }
            case '$BI': {
                const el = document.createElement('span');
                el.style.fontWeight = '700';
                el.style.fontStyle = 'italic';
                el.textContent = content;
                container.appendChild(el);
                break;
            }
            case '$ST': {
                const el = document.createElement('s');
                el.textContent = content;
                container.appendChild(el);
                break;
            }
            case '$I:ST':
            case '$ST:I': {
                const el = document.createElement('span');
                el.style.fontStyle = 'italic';
                el.style.textDecoration = 'line-through';
                el.textContent = content;
                container.appendChild(el);
                break;
            }
            case '$B:ST':
            case '$ST:B': {
                const el = document.createElement('span');
                el.style.fontWeight = '700';
                el.style.textDecoration = 'line-through';
                el.textContent = content;
                container.appendChild(el);
                break;
            }
            case '$BI:ST':
            case '$ST:BI': {
                const el = document.createElement('span');
                el.style.fontWeight = '700';
                el.style.fontStyle = 'italic';
                el.style.textDecoration = 'line-through';
                el.textContent = content;
                container.appendChild(el);
                break;
            }
            case '$ICODE': {
                const el = document.createElement('code');
                el.className = 'preview-icode';
                el.textContent = content;
                container.appendChild(el);
                break;
            }
            case '$LINK': {
                const pipe = content.indexOf(' | ');
                if (pipe !== -1) {
                    const a = document.createElement('a');
                    a.className = 'preview-link';
                    a.textContent = content.slice(0, pipe).trim();
                    a.href = content.slice(pipe + 3).trim();
                    container.appendChild(a);
                } else {
                    container.appendChild(document.createTextNode(content));
                }
                break;
            }
            default:
                container.appendChild(document.createTextNode(`"${inside}"`));
        }
        last = re.lastIndex;
    }
    if (last < text.length) {
        container.appendChild(document.createTextNode(text.slice(last)));
    }
}

function renderBlock(block, headings, footnotes, fnIndex) {
    const kind = block.kind;
    const content = block.content;

    if (kind === 'TableOfContents') {
        const nav = document.createElement('nav');
        nav.className = 'preview-toc';
        const title = document.createElement('p');
        title.className = 'preview-toc-title';
        title.textContent = 'Contents';
        nav.appendChild(title);
        const ul = document.createElement('ul');
        headings.forEach(h => {
            const li = document.createElement('li');
            li.style.paddingLeft = `${(h.level - 2) * 16}px`;
            const a = document.createElement('a');
            a.href = `#${h.id}`;
            a.className = 'preview-toc-link';
            a.textContent = h.text;
            a.addEventListener('click', (e) => {
                e.preventDefault();
                document.getElementById(h.id)?.scrollIntoView({ behavior: 'smooth' });
            });
            li.appendChild(a);
            ul.appendChild(li);
        });
        nav.appendChild(ul);
        return nav;
    }

    if (typeof kind === 'object' && kind.BlockQuote !== undefined) {
        const figure = document.createElement('figure');
        figure.className = 'preview-bq-wrapper';
        const bq = document.createElement('blockquote');
        bq.className = 'preview-bq';
        renderInline(content.Text ?? '', bq);
        figure.appendChild(bq);
        if (kind.BlockQuote.attribution) {
            const caption = document.createElement('figcaption');
            caption.className = 'preview-bq-attr';
            caption.textContent = `— ${kind.BlockQuote.attribution}`;
            figure.appendChild(caption);
        }
        return figure;
    }

    if (kind === 'Footnote') {
        const fn = footnotes[fnIndex];
        if (!fn) return null;
        const p = document.createElement('p');
        p.className = 'preview-fn-ref';
        const sup = document.createElement('sup');
        sup.textContent = `[${fn.index}]`;
        sup.style.cursor = 'pointer';
        sup.style.color = '#7ab8f5';
        sup.addEventListener('click', () => {
            document.getElementById(`fn-${fn.index}`)?.scrollIntoView({ behavior: 'smooth' });
        });
        p.appendChild(sup);
        return p;
    }

    if (typeof kind === 'object' && kind.Heading) {
        const el = document.createElement(`h${kind.Heading}`);
        el.className = `preview-h${kind.Heading}`;
        const text = content.Text ?? '';
        el.id = 'h-' + text.toLowerCase()
            .replace(/\s+/g, '-')
            .replace(/[^a-z0-9-]/g, '');
        renderInline(text, el);
        return el;
    }

    if (typeof kind === 'object' && kind.Code !== undefined) {
        const wrapper = document.createElement('div');
        wrapper.className = 'preview-code';
        const pre = document.createElement('pre');
        pre.textContent = content.Text ?? '';
        wrapper.appendChild(pre);
        return wrapper;
    }

    if (typeof kind === 'object' && kind.Link) {
        const a = document.createElement('a');
        a.className = 'preview-link';
        a.href = kind.Link.url;
        a.textContent = kind.Link.label;
        return a;
    }

    if (typeof kind === 'object' && kind.Image) {
        const wrapper = document.createElement('div');
        const img = document.createElement('img');
        img.className = 'preview-img';
        img.src = kind.Image.src;
        img.alt = kind.Image.alt;
        img.onerror = () => {
            wrapper.removeChild(img);
            const fallback = document.createElement('div');
            fallback.style.cssText = 'padding:12px;background:#1a1a1a;border:1px dashed #444;border-radius:6px;color:#666;font-size:13px;';
            fallback.textContent = `[IMG: ${kind.Image.alt}] ${kind.Image.src}`;
            wrapper.appendChild(fallback);
        };
        wrapper.appendChild(img);
        return wrapper;
    }

    switch (kind) {
        case 'Paragraph': {
            const el = document.createElement('p');
            el.className = 'preview-p';
            renderInline(content.Text ?? '', el);
            return el;
        }
        case 'Bold': {
            const el = document.createElement('p');
            el.className = 'preview-b';
            renderInline(content.Text ?? '', el);
            return el;
        }
        case 'Italic': {
            const el = document.createElement('p');
            el.className = 'preview-i';
            renderInline(content.Text ?? '', el);
            return el;
        }
        case 'BoldItalic': {
            const el = document.createElement('p');
            el.style.fontWeight = '700';
            el.style.fontStyle = 'italic';
            renderInline(content.Text ?? '', el);
            return el;
        }
        case 'Strikethrough': {
            const el = document.createElement('p');
            el.className = 'preview-st';
            renderInline(content.Text ?? '', el);
            return el;
        }
        case 'ItalicStrike': {
            const el = document.createElement('p');
            el.style.fontStyle = 'italic';
            el.style.textDecoration = 'line-through';
            renderInline(content.Text ?? '', el);
            return el;
        }
        case 'BoldStrike': {
            const el = document.createElement('p');
            el.style.fontWeight = '700';
            el.style.textDecoration = 'line-through';
            renderInline(content.Text ?? '', el);
            return el;
        }
        case 'BoldItalicStrike': {
            const el = document.createElement('p');
            el.style.fontWeight = '700';
            el.style.fontStyle = 'italic';
            el.style.textDecoration = 'line-through';
            renderInline(content.Text ?? '', el);
            return el;
        }
        case 'BlockQuote': {
            const figure = document.createElement('figure');
            figure.className = 'preview-bq-wrapper';
            const bq = document.createElement('blockquote');
            bq.className = 'preview-bq';
            renderInline(content.Text ?? '', bq);
            figure.appendChild(bq);
            return figure;
        }
        case 'InlineCode': {
            const el = document.createElement('code');
            el.className = 'preview-icode';
            renderInline(content.Text ?? '', el);
            return el;
        }
        case 'HorizontalRule': {
            return document.createElement('hr');
        }
        case 'UnorderedList': {
            const ul = document.createElement('ul');
            ul.className = 'preview-ul';
            (content.Items ?? []).forEach(item => {
                const li = document.createElement('li');
                renderInline(item, li);
                ul.appendChild(li);
            });
            return ul;
        }
        case 'OrderedList': {
            const ol = document.createElement('ol');
            ol.className = 'preview-ol';
            (content.Items ?? []).forEach(item => {
                const li = document.createElement('li');
                renderInline(item, li);
                ol.appendChild(li);
            });
            return ol;
        }
        case 'Table': {
            const table = document.createElement('table');
            table.className = 'preview-table';
            (content.Rows ?? []).forEach((row, i) => {
                const tr = document.createElement('tr');
                row.forEach(cell => {
                    const td = document.createElement(i === 0 ? 'th' : 'td');
                    td.textContent = cell;
                    tr.appendChild(td);
                });
                table.appendChild(tr);
            });
            return table;
        }
        default:
            return null;
    }
}

window.debugRope = () => {
    const result = debug_rope(input.value);
    console.log(JSON.parse(result));
};
