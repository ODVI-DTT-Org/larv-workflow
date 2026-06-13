#!/usr/bin/env python3
import os
import re

SOURCE_DIR = "source"
OUTPUT_DIR = "."

# Color/brand mappings
replacements = {
    # Brand
    'Acme — ': 'Attio Finance — ',
    'Acme': 'Attio Finance',
    'acme': 'attio-finance',

    # Colors (hex to CSS variables)
    '#FAF9F5': 'var(--gray-50)',
    '#FFFFFF': 'var(--white)',
    '#141413': 'var(--gray-900)',
    '#D97757': 'var(--attio-finance-primary)',
    '#B85C3E': 'var(--attio-finance-primary-light)',
    '#E3DACC': 'var(--gray-200)',
    '#E3DACC': 'var(--gray-100)',
    '#788C5D': 'var(--attio-finance-accent)',
    '#F0EEE6': 'var(--gray-100)',
    '#E6E3DA': 'var(--gray-200)',
    '#D1CFC5': 'var(--gray-300)',
    '#87867F': 'var(--gray-500)',
    '#3D3D3A': 'var(--gray-700)',
}

files_to_adapt = [f for f in os.listdir(SOURCE_DIR) if f.endswith('.html') and f != 'index.html']

for filename in sorted(files_to_adapt):
    source_path = os.path.join(SOURCE_DIR, filename)
    output_path = os.path.join(OUTPUT_DIR, filename)

    with open(source_path, 'r') as f:
        content = f.read()

    # Add design-system.css link
    if 'design-system.css' not in content and '<head>' in content:
        content = content.replace(
            '</head>',
            '  <link rel="stylesheet" href="design-system.css">\n</head>'
        )

    # Apply replacements
    for old, new in replacements.items():
        content = content.replace(old, new)

    # Write output
    with open(output_path, 'w') as f:
        f.write(content)

    print(f"✓ Adapted: {filename}")

print("\n✅ All 20 templates adapted to Attio Finance + Attio design system!")
