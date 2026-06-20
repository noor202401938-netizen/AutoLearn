const fs = require('fs');
const path = require('path');

function checkFile(filePath) {
    const code = fs.readFileSync(filePath, 'utf-8');
    let stack = [];
    let i = 0;
    while (i < code.length) {
        // skip multiline strings '''
        if (code.substr(i, 3) === "'''") {
            i += 3;
            while (i < code.length && code.substr(i, 3) !== "'''") {
                if (code[i] === '\\') i += 2;
                else i++;
            }
            i += 3;
            continue;
        }
        // skip multiline strings """
        if (code.substr(i, 3) === '"""') {
            i += 3;
            while (i < code.length && code.substr(i, 3) !== '"""') {
                if (code[i] === '\\') i += 2;
                else i++;
            }
            i += 3;
            continue;
        }
        // skip single line comments
        if (code[i] === '/' && code[i+1] === '/') {
            while (i < code.length && code[i] !== '\n') i++;
            continue;
        }
        // skip block comments
        if (code[i] === '/' && code[i+1] === '*') {
            i += 2;
            while (i < code.length - 1 && !(code[i] === '*' && code[i+1] === '/')) i++;
            i += 2;
            continue;
        }
        // skip strings
        if (code[i] === '"' || code[i] === "'") {
            const quote = code[i];
            i++;
            while (i < code.length && code[i] !== quote) {
                if (code[i] === '\\') i += 2; // skip escaped
                else i++;
            }
            i++;
            continue;
        }
        // check brackets
        if (code[i] === '(') stack.push({char: '(', line: getLine(code, i)});
        if (code[i] === '{') stack.push({char: '{', line: getLine(code, i)});
        if (code[i] === '[') stack.push({char: '[', line: getLine(code, i)});

        if (code[i] === ')') {
            if (stack.length === 0 || stack[stack.length-1].char !== '(') {
                console.log(`Unmatched ')' at ${filePath}:${getLine(code, i)}`);
                return;
            }
            stack.pop();
        }
        if (code[i] === '}') {
            if (stack.length === 0 || stack[stack.length-1].char !== '{') {
                console.log(`Unmatched '}' at ${filePath}:${getLine(code, i)}`);
                return;
            }
            stack.pop();
        }
        if (code[i] === ']') {
            if (stack.length === 0 || stack[stack.length-1].char !== '[') {
                console.log(`Unmatched ']' at ${filePath}:${getLine(code, i)}`);
                return;
            }
            stack.pop();
        }
        i++;
    }
    if (stack.length > 0) {
        console.log(`Unclosed ${stack[stack.length-1].char} in ${filePath} from line ${stack[stack.length-1].line}`);
    }
}

function getLine(str, index) {
    let count = 1;
    for(let i=0; i<index; i++) {
        if(str[i] === '\n') count++;
    }
    return count;
}

function walk(dir) {
    const list = fs.readdirSync(dir);
    for (let file of list) {
        file = path.resolve(dir, file);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) walk(file);
        else if (file.endsWith('.dart')) checkFile(file);
    }
}

walk(path.join(__dirname, 'lib'));
