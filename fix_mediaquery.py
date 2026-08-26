import os
import re

dir_path = '/Users/yossefzaki/Desktop/ATW-Work/fastway/fastWay-mobile/lib'

replacements = {
    r'MediaQuery\.of\(context\)\.size\.width': r'MediaQuery.sizeOf(context).width',
    r'MediaQuery\.of\(context\)\.size\.height': r'MediaQuery.sizeOf(context).height',
    r'MediaQuery\.of\(context\)\.size': r'MediaQuery.sizeOf(context)',
    r'MediaQuery\.of\(context\)\.padding\.bottom': r'MediaQuery.paddingOf(context).bottom',
    r'MediaQuery\.of\(context\)\.padding\.top': r'MediaQuery.paddingOf(context).top',
    r'MediaQuery\.of\(context\)\.padding': r'MediaQuery.paddingOf(context)',
    r'MediaQuery\.of\(context\)\.viewInsets\.bottom': r'MediaQuery.viewInsetsOf(context).bottom',
    r'MediaQuery\.of\(context\)\.viewInsets': r'MediaQuery.viewInsetsOf(context)',
}

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for pattern, repl in replacements.items():
        new_content = re.sub(pattern, repl, new_content)
        
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for root, dirs, files in os.walk(dir_path):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
