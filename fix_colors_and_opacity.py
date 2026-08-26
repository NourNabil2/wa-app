import os
import re

dir_path = '/Users/yossefzaki/Desktop/ATW-Work/fastway/fastWay-mobile/lib'

replacements = {
    # .withOpacity
    r'\.withOpacity\((.*?)\)': r'.withValues(alpha: \1)',
    # Colors
    r'Color\(0xFF1E1E20\)': r'ColorsManager.surfaceDarkHeader',
    r'Color\(0xFF1C1C1E\)': r'ColorsManager.surfaceDarkCard',
    r'Color\(0xFF111111\)': r'ColorsManager.surfaceDarkElevated',
    r'Color\(0xFF0A0A0A\)': r'ColorsManager.surfaceDarkBase',
    r'Color\(0xFFF9FAFB\)': r'ColorsManager.gray50',
    r'Color\(0xFFF3F4F6\)': r'ColorsManager.gray100',
    r'Color\(0xFFE5E7EB\)': r'ColorsManager.gray200',
    r'Color\(0xFFD1D5DB\)': r'ColorsManager.gray300',
    r'Color\(0xFF9CA3AF\)': r'ColorsManager.gray400',
    r'Color\(0xFF6B7280\)': r'ColorsManager.gray500',
    r'Color\(0xFF4B5563\)': r'ColorsManager.gray600',
    r'Color\(0xFF374151\)': r'ColorsManager.gray700',
    r'Color\(0xFF1F2937\)': r'ColorsManager.gray800',
    r'Color\(0xFF111827\)': r'ColorsManager.gray900',
    r'BorderRadius\.circular\(0\)': r'BorderRadius.zero',
}

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for pattern, repl in replacements.items():
        new_content = re.sub(pattern, repl, new_content)
        
    if new_content != content:
        # Check if ColorsManager is needed
        if 'ColorsManager' in new_content and 'package:fastway/core/theme/colors.dart' not in new_content:
            # Need to add import. We'll just print it for now or try to auto-add
            # Usually better to rely on IDE, but we can prepend it
            if 'import' in new_content:
                new_content = re.sub(r'(import .*?;)', r"import 'package:fastway/core/theme/colors.dart';\n\1", new_content, count=1)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for root, dirs, files in os.walk(dir_path):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
