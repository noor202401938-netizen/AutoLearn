import os
import sys

def check_brackets(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    lines = content.split('\n')
    stack = []
    
    for i, line in enumerate(lines):
        for j, char in enumerate(line):
            if char in '({[':
                stack.append((char, i + 1, j + 1))
            elif char in ')}]':
                if not stack:
                    return f"Unmatched {char} at line {i+1}:{j+1}"
                
                last_char, last_line, last_col = stack.pop()
                if (char == ')' and last_char != '(') or \
                   (char == '}' and last_char != '{') or \
                   (char == ']' and last_char != '['):
                    return f"Mismatched {char} at line {i+1}:{j+1}. Expected to close {last_char} from line {last_line}"
                    
    if stack:
        last_char, last_line, last_col = stack.pop()
        return f"Unclosed {last_char} starting at line {last_line}:{last_col}"
        
    return None

def main():
    root_dir = r"d:\economics-learner-app-main\economics-learner-app-main\lib"
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith('.dart'):
                filepath = os.path.join(dirpath, filename)
                try:
                    result = check_brackets(filepath)
                    if result:
                        print(f"File: {filepath} -> {result}")
                except Exception as e:
                    pass

if __name__ == '__main__':
    main()
