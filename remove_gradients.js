const fs = require('fs');
const path = require('path');

function processFile(filePath) {
    let content = fs.readFileSync(filePath, 'utf8');
    const originalContent = content;

    while (true) {
        const idx = content.indexOf('gradient: LinearGradient(');
        if (idx === -1) break;

        const startParen = content.indexOf('(', idx);
        let parenCount = 1;
        let endIdx = startParen + 1;

        while (endIdx < content.length && parenCount > 0) {
            if (content[endIdx] === '(') {
                parenCount++;
            } else if (content[endIdx] === ')') {
                parenCount--;
            }
            endIdx++;
        }

        // skip trailing spaces and comma
        while (endIdx < content.length && [' ', '\n', '\r', '\t'].includes(content[endIdx])) {
            endIdx++;
        }
        if (endIdx < content.length && content[endIdx] === ',') {
            endIdx++;
        }

        content = content.slice(0, idx) + content.slice(endIdx);
    }

    if (content !== originalContent) {
        // clean up empty decorations
        content = content.replace(/decoration:\s*(const\s*)?BoxDecoration\(\s*\),?/g, '');
        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`Updated ${filePath}`);
    }
}

function walkDir(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        const stat = fs.statSync(fullPath);
        if (stat.isDirectory()) {
            walkDir(fullPath);
        } else if (file.endsWith('.dart') && file !== 'gradient_menu.dart') {
            processFile(fullPath);
        }
    }
}

walkDir('lib');
console.log('Done!');
