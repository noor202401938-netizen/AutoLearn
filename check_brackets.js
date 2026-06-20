const fs = require('fs');
const path = require('path');

function checkBrackets(filepath) {
    const content = fs.readFileSync(filepath, 'utf8');
    const lines = content.split('\n');
    const stack = [];
    
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        for (let j = 0; j < line.length; j++) {
            const char = line[j];
            if (['(', '{', '['].includes(char)) {
                stack.push({ char, line: i + 1, col: j + 1 });
            } else if ([')', '}', ']'].includes(char)) {
                if (stack.length === 0) {
                    return `Unmatched ${char} at line ${i + 1}:${j + 1}`;
                }
                const last = stack.pop();
                if ((char === ')' && last.char !== '(') ||
                    (char === '}' && last.char !== '{') ||
                    (char === ']' && last.char !== '[')) {
                    return `Mismatched ${char} at line ${i + 1}:${j + 1}. Expected to close ${last.char} from line ${last.line}`;
                }
            }
        }
    }
    
    if (stack.length > 0) {
        const last = stack.pop();
        return `Unclosed ${last.char} starting at line ${last.line}:${last.col}`;
    }
    return null;
}

function walkDir(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            walkDir(fullPath);
        } else if (fullPath.endsWith('.dart')) {
            try {
                const result = checkBrackets(fullPath);
                if (result) {
                    console.log(`File: ${fullPath} -> ${result}`);
                }
            } catch (e) {}
        }
    }
}

walkDir('lib');
