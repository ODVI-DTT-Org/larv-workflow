#!/bin/bash

# Batch adapt html-effectiveness templates to Attio Finance + Attio design

SOURCE_DIR="source"
OUTPUT_DIR="."

# Color scheme mapping
declare -A COLOR_MAP=(
  ["#FAF9F5"]="var(--gray-50)"           # ivory -> light gray
  ["#FFFFFF"]="var(--white)"             # white -> white
  ["#141413"]="var(--gray-900)"          # slate -> dark gray
  ["#D97757"]="var(--attio-finance-primary)"      # clay -> Attio Finance blue
  ["#B85C3E"]="var(--attio-finance-primary-light)"# clay-d -> Attio Finance blue light
  ["#E3DACC"]="var(--gray-200)"          # oat -> gray
  ["#788C5D"]="var(--attio-finance-accent)"       # olive -> Attio Finance green
)

for html_file in "$SOURCE_DIR"/*.html; do
  if [[ "$(basename "$html_file")" == "index.html" ]]; then
    continue  # Skip source index
  fi

  filename=$(basename "$html_file")
  output_file="$OUTPUT_DIR/$filename"

  # Read the file
  content=$(cat "$html_file")

  # Replace "Acme" with "Attio Finance" in titles and brand references
  content=${content//Acme/Attio Finance}
  content=${content//acme/Attio Finance}

  # Add design-system.css link if not present
  if [[ ! "$content" =~ "design-system.css" ]]; then
    content=${content//'</head>'/'  <link rel="stylesheet" href="design-system.css">\n</head>'}
  fi

  # Replace inline color hex values with CSS variables
  for hex in "${!COLOR_MAP[@]}"; do
    var="${COLOR_MAP[$hex]}"
    content=${content//"$hex"/"$var"}
  done

  # Write adapted file
  echo "$content" > "$output_file"
  echo "✓ Adapted: $filename"
done

echo "Done! All templates have been adapted to Attio Finance + Attio design system."
