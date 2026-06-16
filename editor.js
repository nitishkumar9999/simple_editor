import init, { parse_full_document, EditorRope, debug_rope, parse_inline_fragments, build_table_scaffold } from './pkg/simple_editor.js';

await init();

const input   = document.getElementById('input');
const preview = document.getElementById('preview');
let rope = null;
let saveTimer = null;

async function boot() {
    try {
        const res  = await fetch('/load');
        const text = await res.text();
        rope = new EditorRope(text);
	input.value = rope.get_text();
    } catch {
        rope = new EditorRope('');
	input.value = '';
    }
    renderBlocks(JSON.parse(rope.get_all()));
}

await boot();

function scheduleSave() {
    clearTimeout(saveTimer);
    saveTimer = setTimeout(async () => {
        await fetch('/save', {
            method: 'POST',
	    headers: { 'Content-Type': 'text/plain; charset=utf-8' },
            body: new Blob([rope.get_text()], { type: 'text/plain' }),
        });
    }, 1000);
}

document.addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key === 'z' && !e.shiftKey) {
        e.preventDefault();
        if (!rope?.can_undo()) return;
        const blocks = JSON.parse(rope.undo());
        input.value = rope.get_text();
        renderBlocks(blocks);
        scheduleSave();
        return;
    }
    if ((e.ctrlKey || e.metaKey) && (e.key === 'y' || (e.key === 'z' && e.shiftKey))) {
        e.preventDefault();
        if (!rope?.can_redo()) return;
        const blocks = JSON.parse(rope.redo());
        input.value = rope.get_text();
        renderBlocks(blocks);
        scheduleSave();
        return;
    }
});

function applyAndVerify() {
    const ropeText = rope.get_text();
    if (ropeText !== input.value) {
        console.warn('rope/textarea mismatch — rebuilding');
        rope = new EditorRope(input.value);
    }
    renderBlocks(JSON.parse(rope.get_all()));
    scheduleSave();
}

input.addEventListener('input', (e) => {
    const inputType = e.inputType;
    const data      = e.data;
    const selStart  = input.selectionStart;

    if (!rope) return;

    if (inputType === 'insertText' && data) {
        const charCount = [...data].length;
	const byteStart = rope.offset_at_char(selStart - charCount);
        rope.insert(byteStart, data);
        applyAndVerify();

    } else if (inputType === 'deleteContentBackward') {
        const byteStart = rope.offset_at_char(selStart);
        const byteEnd   = rope.offset_at_char(selStart + 1);
        if (byteEnd > byteStart) {
            rope.delete(byteStart, byteEnd);
        }
        applyAndVerify();

    } else if (inputType === 'deleteContentForward') {
        const byteStart = rope.offset_at_char(selStart);
        const byteEnd   = rope.offset_at_char(selStart + 1);
        if (byteEnd > byteStart) {
            rope.delete(byteStart, byteEnd);
        }
        applyAndVerify();

    } else {
        rope = new EditorRope(input.value);
        renderBlocks(JSON.parse(rope.get_all()));
        scheduleSave();
    }
});

input.addEventListener('scroll', () => {
    const ratio = input.scrollTop / (input.scrollHeight - input.clientHeight);
    const previewPane = document.getElementById('preview-pane');
    previewPane.scrollTop = ratio * (previewPane.scrollHeight - previewPane.clientHeight);
});

input.addEventListener('keyup', syncCursorToPreview);
input.addEventListener('click', syncCursorToPreview);

function syncCursorToPreview() {
    if (!rope) return;
    const pos    = input.selectionStart;
    const cursor = JSON.parse(rope.cursor_pos(pos));
    const previewChildren = document.getElementById('preview').children;
    if (previewChildren[cursor.block_index]) {
        previewChildren[cursor.block_index].scrollIntoView({
            behavior: 'smooth',
            block: 'nearest',
        });
    }
}

input.addEventListener('keydown', (e) => {
    const value       = input.value;
    const pos         = input.selectionStart;
    const lineStart   = value.lastIndexOf('\n', pos - 1) + 1;
    const currentLine = value.slice(lineStart, pos);
    const trimmedLine = currentLine.trim();

    if (e.key === 'Tab') {
        if (trimmedLine.startsWith('|')) {
            e.preventDefault();
            if (e.shiftKey) moveToPrevCell(value, pos);
            else            moveToNextCell(value, pos);
            return;
        }
        e.preventDefault();
        const before = value.slice(0, pos);
        const after  = value.slice(pos);
        input.value  = before + '    ' + after;
        input.selectionStart = pos + 4;
        input.selectionEnd   = pos + 4;
        // sync rope to new value
        rope = new EditorRope(input.value);
        renderBlocks(JSON.parse(rope.get_all()));
        scheduleSave();
        return;
    }

    if (e.key === 'Enter') {
        const tbMatch = trimmedLine.match(/^\$TB(?:\s+(\d+)\|(\d+))?$/);
        if (tbMatch) {
            e.preventDefault();
            const cols     = parseInt(tbMatch[1] ?? '3');
            const rows     = parseInt(tbMatch[2] ?? '3');
            const scaffold = build_table_scaffold(cols, rows);
            const before   = value.slice(0, lineStart);
            const after    = value.slice(pos);
            input.value    = before + '$TB\n' + scaffold + after;
            const firstCellPos = before.length + '$TB\n'.length + '    | '.length;
            input.selectionStart = firstCellPos;
            input.selectionEnd   = firstCellPos + 'Header 1'.length;
            rope = new EditorRope(input.value);
            renderBlocks(JSON.parse(rope.get_all()));
            scheduleSave();
            return;
        }

        const bareCmd = trimmedLine.match(/^\$[A-Z:]+$/) && !trimmedLine.includes(' ');
        if (bareCmd) {
            e.preventDefault();
            const before = value.slice(0, pos);
            const after  = value.slice(pos);
            input.value  = before + '\n    ' + after;
            input.selectionStart = pos + 5;
            input.selectionEnd   = pos + 5;
            rope = new EditorRope(input.value);
            renderBlocks(JSON.parse(rope.get_all()));
            scheduleSave();
            return;
        }

        const indentMatch = currentLine.match(/^(    +)/);
        if (indentMatch) {
            e.preventDefault();
            const before  = value.slice(0, pos);
            const after   = value.slice(pos);
            input.value   = before + '\n' + indentMatch[1] + after;
            const newPos  = pos + 1 + indentMatch[1].length;
            input.selectionStart = newPos;
            input.selectionEnd   = newPos;
            rope = new EditorRope(input.value);
            renderBlocks(JSON.parse(rope.get_all()));
            scheduleSave();
            return;
        }
    }
});

function moveToNextCell(value, pos) {
    const nextPipe = value.indexOf('|', pos);
    if (nextPipe === -1) return;
    const cellStart = nextPipe + 1;
    const cellEnd   = value.indexOf('|', cellStart);
    if (cellEnd === -1) return;
    const cellContent = value.slice(cellStart, cellEnd);
    if (cellContent.trim().match(/^-+$/)) { moveToNextCell(value, cellEnd); return; }
    const trimmed  = cellContent.trim();
    const trimStart = cellStart + cellContent.indexOf(trimmed);
    input.selectionStart = trimStart;
    input.selectionEnd   = trimStart + trimmed.length;
    input.focus();
}

function moveToPrevCell(value, pos) {
    const beforeCursor  = value.slice(0, pos);
    const prevPipe      = beforeCursor.lastIndexOf('|');
    if (prevPipe === -1) return;
    const beforePrev    = value.slice(0, prevPipe);
    const prevPrevPipe  = beforePrev.lastIndexOf('|');
    if (prevPrevPipe === -1) return;
    const cellContent   = value.slice(prevPrevPipe + 1, prevPipe);
    if (cellContent.trim().match(/^-+$/)) { moveToPrevCell(value, prevPrevPipe); return; }
    const trimmed  = cellContent.trim();
    const trimStart = prevPrevPipe + 1 + cellContent.indexOf(trimmed);
    input.selectionStart = trimStart;
    input.selectionEnd   = trimStart + trimmed.length;
    input.focus();
}


function renderBlocks(blocks) {
    try {
        preview.innerHTML = '';
        const headings  = [];
        const footnotes = [];
        let fnCounter   = 0;

        blocks.forEach(block => {
            if (typeof block.kind === 'object' && block.kind.Heading) {
                const level = block.kind.Heading;
                if (level === 1) return;
                const t  = block.content.Text ?? '';
                const id = 'h-' + t.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
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
    } catch (e) {
        console.error('render error:', e);
    }
}

function renderInline(text, container) {
   const fragments = JSON.parse(parse_inline_fragments(text));
    for (const frag of fragments) {
        let el;
        switch (frag.type) {
            case 'Text':        container.appendChild(document.createTextNode(frag.value)); break;
            case 'Bold':        el = document.createElement('strong'); el.textContent = frag.value; container.appendChild(el); break;
		case 'Italic':      el = document.createElement('em');     el.textContent = frag.value; container.appendChild(el); break;
            case 'InlineCode':  el = document.createElement('code');   el.className = 'preview-icode'; el.textContent = frag.value; container.appendChild(el); break;
            case 'Link':        el = document.createElement('a'); el.className = 'preview-link'; el.textContent = frag.value.label; el.href = frag.value.url; container.appendChild(el); break;
            case 'Strike':      el = document.createElement('s');      el.textContent = frag.value; container.appendChild(el); break;
            case 'BoldItalic':  el = document.createElement('span');   el.style.cssText = 'font-weight:700;font-style:italic'; el.textContent = frag.value; container.appendChild(el); break;
            case 'ItalicStrike':el = document.createElement('span');   el.style.cssText = 'font-style:italic;text-decoration:line-through'; el.textContent = frag.value; container.appendChild(el); break;
            case 'BoldStrike':  el = document.createElement('span');   el.style.cssText = 'font-weight:700;text-decoration:line-through'; el.textContent = frag.value; container.appendChild(el); break;
            default:            container.appendChild(document.createTextNode(frag.value ?? '')); break;
        }
    }
}

function renderBlock(block, headings, footnotes, fnIndex) {
    const kind    = block.kind;
    const content = block.content;

    if (kind === 'TableOfContents') {
        const nav   = document.createElement('nav');
        nav.className = 'preview-toc';
        const title = document.createElement('p');
        title.className = 'preview-toc-title';
        title.textContent = 'Contents';
        nav.appendChild(title);
        const ul = document.createElement('ul');
        headings.forEach(h => {
            const li = document.createElement('li');
            li.style.paddingLeft = `${(h.level - 2) * 16}px`;
            const a  = document.createElement('a');
            a.href   = `#${h.id}`;
            a.className = 'preview-toc-link';
            a.textContent = h.text;
            a.addEventListener('click', (e) => {
                e.preventDefault();
                document.getElementById(h.id)?.scrollIntoView({ behavior: 'smooth' });
            });
            li.appendChild(a); ul.appendChild(li);
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
        const p   = document.createElement('p');
        p.className = 'preview-fn-ref';
        const sup = document.createElement('sup');
        sup.textContent = `[${fn.index}]`;
        sup.style.cursor = 'pointer';
        sup.style.color  = '#7ab8f5';
        sup.addEventListener('click', () => {
            document.getElementById(`fn-${fn.index}`)?.scrollIntoView({ behavior: 'smooth' });
        });
        p.appendChild(sup);
        return p;
    }

    if (typeof kind === 'object' && kind.Heading) {
        const el   = document.createElement(`h${kind.Heading}`);
        el.className = `preview-h${kind.Heading}`;
        const text = content.Text ?? '';
        el.id = 'h-' + text.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
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
        a.className   = 'preview-link';
        a.href        = kind.Link.url;
        a.textContent = kind.Link.label;
        return a;
    }

    if (typeof kind === 'object' && kind.Image) {
        const wrapper = document.createElement('div');
        const img     = document.createElement('img');
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
            renderInline(content.Text ?? '', el); return el;
        }
        case 'Bold': {
            const el = document.createElement('p');
            el.className = 'preview-b';
            renderInline(content.Text ?? '', el); return el;
        }
        case 'Italic': {
            const el = document.createElement('p');
            el.className = 'preview-i';
            renderInline(content.Text ?? '', el); return el;
        }
        case 'BoldItalic': {
            const el = document.createElement('p');
            el.style.fontWeight = '700'; el.style.fontStyle = 'italic';
            renderInline(content.Text ?? '', el); return el;
        }
        case 'Strikethrough': {
            const el = document.createElement('p');
            el.className = 'preview-st';
            renderInline(content.Text ?? '', el); return el;
        }
        case 'ItalicStrike': {
            const el = document.createElement('p');
            el.style.fontStyle = 'italic'; el.style.textDecoration = 'line-through';
            renderInline(content.Text ?? '', el); return el;
        }
        case 'BoldStrike': {
            const el = document.createElement('p');
            el.style.fontWeight = '700'; el.style.textDecoration = 'line-through';
            renderInline(content.Text ?? '', el); return el;
        }
        case 'BoldItalicStrike': {
            const el = document.createElement('p');
            el.style.fontWeight = '700'; el.style.fontStyle = 'italic';
            el.style.textDecoration = 'line-through';
            renderInline(content.Text ?? '', el); return el;
        }
        case 'BlockQuote': {
            const figure = document.createElement('figure');
            figure.className = 'preview-bq-wrapper';
            const bq = document.createElement('blockquote');
            bq.className = 'preview-bq';
            renderInline(content.Text ?? '', bq);
            figure.appendChild(bq); return figure;
        }
        case 'InlineCode': {
            const el = document.createElement('code');
            el.className = 'preview-icode';
            renderInline(content.Text ?? '', el); return el;
        }
        case 'HorizontalRule':
            return document.createElement('hr');
        case 'UnorderedList': {
            const ul = document.createElement('ul');
            ul.className = 'preview-ul';
            (content.Items ?? []).forEach(item => {
                const li = document.createElement('li');
                renderInline(item, li); ul.appendChild(li);
            });
            return ul;
        }
        case 'OrderedList': {
            const ol = document.createElement('ol');
            ol.className = 'preview-ol';
            (content.Items ?? []).forEach(item => {
                const li = document.createElement('li');
                renderInline(item, li); ol.appendChild(li);
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
                    td.textContent = cell; tr.appendChild(td);
                });
                table.appendChild(tr);
            });
            return table;
        }
        default:
            return null;
    }
}

window.getRope = () => rope;
window.debugRope = () => {
    const result = debug_rope(rope.get_text());
    console.log(JSON.parse(result));
};

window.benchRope = async function(ops = 1000) {
    const chars = 'abcdefghijklmnopqrstuvwxyz \n$BIP- ';
    const results = {
        insert: [],
        delete: [],
        get_all: [],
        cursor_pos: [],
        offset_at_char: [],
    };

    const docLen = () => rope.total();

    function randomPos() {
        const len = docLen();
        return Math.floor(Math.random() * len);
    }

    function randomChar() {
        return chars[Math.floor(Math.random() * chars.length)];
    }

    console.log(`Running ${ops} random operations...`);

    for (let i = 0; i < ops; i++) {
        const op = Math.random();

        if (op < 0.4) {
            // insert
            const pos  = randomPos();
            const char = randomChar();
            const t0   = performance.now();
            rope.insert(rope.offset_at_char(pos), char);
            results.insert.push(performance.now() - t0);

        } else if (op < 0.7) {
            // delete
            const len = docLen();
            if (len > 1) {
                const pos = Math.floor(Math.random() * (len - 1));
                const t0  = performance.now();
                rope.delete(
                    rope.offset_at_char(pos),
                    rope.offset_at_char(pos + 1)
                );
                results.delete.push(performance.now() - t0);
            }

        } else if (op < 0.8) {
            // get_all (re-parse + serialize)
            const t0 = performance.now();
            rope.get_all();
            results.get_all.push(performance.now() - t0);

        } else if (op < 0.9) {
            // cursor_pos
            const pos = randomPos();
            const t0  = performance.now();
            rope.cursor_pos(pos);
            results.cursor_pos.push(performance.now() - t0);

        } else {
            // offset_at_char
            const pos = randomPos();
            const t0  = performance.now();
            rope.offset_at_char(pos);
            results.offset_at_char.push(performance.now() - t0);
        }
    }

    // compute stats
    function stats(arr) {
        if (arr.length === 0) return { n: 0 };
        const sorted = [...arr].sort((a, b) => a - b);
        const sum    = arr.reduce((a, b) => a + b, 0);
        return {
            n:      arr.length,
            min:    sorted[0].toFixed(4),
            max:    sorted[sorted.length - 1].toFixed(4),
            avg:    (sum / arr.length).toFixed(4),
            p50:    sorted[Math.floor(arr.length * 0.50)].toFixed(4),
            p95:    sorted[Math.floor(arr.length * 0.95)].toFixed(4),
            p99:    sorted[Math.floor(arr.length * 0.99)].toFixed(4),
        };
    }

    console.table({
        insert:         stats(results.insert),
        delete:         stats(results.delete),
        get_all:        stats(results.get_all),
        cursor_pos:     stats(results.cursor_pos),
        offset_at_char: stats(results.offset_at_char),
    });

    // sync textarea to rope after bench
    input.value = rope.get_text();
    renderBlocks(JSON.parse(rope.get_all()));
    console.log(`Doc size after bench: ${docLen()} bytes`);
};

// generate a ~500KB document directly into the rope
window.stressGen = function(blocks = 2000) {
    const kinds = [
        () => `$P - This is paragraph number ${Math.random().toString(36).slice(2)} with some content to fill up space and test the editor performance under load.`,
        () => `$B - This is bold block number ${Math.floor(Math.random()*1000)} testing rendering performance.`,
        () => `$H2 - Section ${Math.floor(Math.random()*1000)}`,
        () => `$UL\n    item one of list ${Math.floor(Math.random()*100)}\n    item two of list ${Math.floor(Math.random()*100)}\n    item three of list ${Math.floor(Math.random()*100)}`,
        () => `$BQ\n    this is blockquote number ${Math.floor(Math.random()*100)} with some longer content to pad the document size\n    -- author ${Math.floor(Math.random()*100)}`,
        () => `$CODE - rust\n    fn function_${Math.floor(Math.random()*100)}() {\n        println!("hello from function ${Math.floor(Math.random()*100)}");\n    }`,
    ];

    let doc = '';
    for (let i = 0; i < blocks; i++) {
        const kind = kinds[Math.floor(Math.random() * kinds.length)];
        doc += kind() + '\n';
    }

    rope = new EditorRope(doc);
    input.value = rope.get_text();
    renderBlocks(JSON.parse(rope.get_all()));
    console.log(`Generated ${doc.length} bytes, ${blocks} blocks`);
}
