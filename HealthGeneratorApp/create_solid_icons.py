#!/usr/bin/env python3
"""
Create solid app icons for Health Data Generator without any transparency
"""

from PIL import Image, ImageDraw
import os
import shutil

def create_solid_app_icon(size, output_path):
    """Create a solid health-themed app icon with no transparency"""
    # Create image with solid white background
    img = Image.new('RGB', (size, size), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    
    # Create a solid gradient background
    for y in range(size):
        progress = y / size
        # Health-themed gradient: light blue to darker blue
        r = int(100 * (1 - progress) + 50 * progress)
        g = int(150 * (1 - progress) + 100 * progress)
        b = int(200 * (1 - progress) + 150 * progress)
        draw.line([(0, y), (size, y)], fill=(r, g, b))
    
    # Draw a simple health cross in the center
    center_x, center_y = size // 2, size // 2
    cross_size = size // 3
    cross_width = max(4, size // 20)
    
    # White cross
    # Horizontal bar
    draw.rectangle([
        center_x - cross_size//2, center_y - cross_width//2,
        center_x + cross_size//2, center_y + cross_width//2
    ], fill=(255, 255, 255))
    
    # Vertical bar
    draw.rectangle([
        center_x - cross_width//2, center_y - cross_size//2,
        center_x + cross_width//2, center_y + cross_size//2
    ], fill=(255, 255, 255))
    
    # Ensure we save as RGB without alpha
    if img.mode != 'RGB':
        img = img.convert('RGB')
    
    img.save(output_path, 'PNG')
    print(f"Created solid icon: {output_path} ({size}x{size})")

def main():
    # Paths
    base_path = "/Users/aminbenarieb/repo/welltory/ios-3/HealthGeneratorApp/HealthGeneratorApp"
    icons_dir = os.path.join(base_path, "HealthGeneratorApp/Resources")
    appiconset_dir = os.path.join(base_path, "HealthGeneratorApp/Resources/Assets.xcassets/AppIcon.appiconset")
    
    os.makedirs(icons_dir, exist_ok=True)
    os.makedirs(appiconset_dir, exist_ok=True)
    
    # All required icon sizes
    icon_configs = [
        # iPhone
        (40, "AppIcon-40.png"),
        (60, "AppIcon-60.png"),
        (58, "AppIcon-58.png"),
        (87, "AppIcon-87.png"),
        (80, "AppIcon-80.png"),
        (120, "AppIcon-120.png"),
        (180, "AppIcon-180.png"),
        # iPad
        (20, "AppIcon-20.png"),
        (29, "AppIcon-29.png"),
        (76, "AppIcon-76.png"),
        (152, "AppIcon-152.png"),
        (167, "AppIcon-167.png"),
        # App Store - This is the critical one
        (1024, "AppIcon-1024.png")
    ]
    
    for size, filename in icon_configs:
        # Create in resources directory
        output_path = os.path.join(icons_dir, filename)
        create_solid_app_icon(size, output_path)
        
        # Copy to appiconset
        appiconset_path = os.path.join(appiconset_dir, filename)
        shutil.copy2(output_path, appiconset_path)
    
    print(f"\nAll solid icons created successfully!")
    print(f"Resources: {icons_dir}")
    print(f"AppIcon set: {appiconset_dir}")

if __name__ == "__main__":
    main()
