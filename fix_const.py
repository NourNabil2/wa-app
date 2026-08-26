import os
import re

def process_file(path):
    with open(path, 'r') as f:
        content = f.read()
    
    orig = content
    content = re.sub(r'const\s+BorderRadius\.zero', 'BorderRadius.zero', content)
    content = re.sub(r'const\s+Radius\.zero', 'Radius.zero', content)
    
    if orig != content:
        with open(path, 'w') as f:
            f.write(content)
        print(f"Fixed const in {path}")

for root, _, files in os.walk('lib'):
    for f in files:
        if f.endswith('.dart'):
            process_file(os.path.join(root, f))
