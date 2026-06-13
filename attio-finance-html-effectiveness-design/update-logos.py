#!/usr/bin/env python3
import os
import re

# HTML header template with logo
HEADER_WITH_LOGO = '''  <!-- Header with Attio Finance Logo -->
  <header class="header">
    <div class="container">
      <div class="logo">
        <img src="attio-finance-logo.png" alt="Attio Finance Logo" style="height: 48px; width: auto; border-radius: var(--radius-md);">
        <div>
          <div style="font-size: 14px; color: var(--gray-600);">Attio Finance Studio</div>
          <div style="font-weight: 700; color: var(--attio-finance-primary);">Finance Co. Inc.</div>
        </div>
      </div>
    </div>
  </header>
'''

# Find all HTML files
html_files = [f for f in os.listdir('.') if f.endswith('.html') and f != 'index.html' and not f.startswith('.')]

for filename in sorted(html_files):
    with open(filename, 'r') as f:
        content = f.read()

    # Skip if already has logo
    if 'attio-finance-logo.png' in content:
        print(f"⊘ Skipped (already has logo): {filename}")
        continue

    # Add logo header after <body> tag
    if '<body>' in content:
        content = content.replace('<body>', f'<body>\n{HEADER_WITH_LOGO}', 1)

        with open(filename, 'w') as f:
            f.write(content)
        print(f"✓ Updated: {filename}")
    else:
        print(f"⊘ Skipped (no <body> tag): {filename}")

print("\n✅ Logo integration complete!")
