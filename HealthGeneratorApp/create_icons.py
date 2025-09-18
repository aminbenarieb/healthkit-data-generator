#!/usr/bin/env python3
"""
Create app icons for Health Data Generator
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_app_icon(size, output_path):
    """Create a health-themed app icon"""
    # Create a new image with solid white background (no transparency)
    img = Image.new('RGB', (size, size), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    
    # Create gradient background (blue to green - health theme)
    for y in range(size):
        progress = y / size
        r = int(52 * (1 - progress) + 34 * progress)  # 52 -> 34
        g = int(199 * (1 - progress) + 139 * progress)  # 199 -> 139
        b = int(89 * (1 - progress) + 34 * progress)   # 89 -> 34
        color = (r, g, b)
        draw.line([(0, y), (size, y)], fill=color)
    
    # Add rounded corners by drawing a solid rounded rectangle
    corner_radius = size // 6
    
    # Create a mask for rounded corners
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, size, size], corner_radius, fill=255)
    
    # Create the final image with rounded corners
    final_img = Image.new('RGB', (size, size), (255, 255, 255))
    final_img.paste(img, mask=mask)
    
    # Draw heart icon in the center on the final image
    draw = ImageDraw.Draw(final_img)
    center_x, center_y = size // 2, size // 2
    heart_size = size // 3
    
    # Heart shape coordinates (simplified)
    heart_points = []
    for angle in range(0, 360, 5):
        import math
        # Heart equation
        t = math.radians(angle)
        x = 16 * (math.sin(t) ** 3)
        y = -(13 * math.cos(t) - 5 * math.cos(2*t) - 2 * math.cos(3*t) - math.cos(4*t))
        
        # Scale and center
        x = center_x + (x * heart_size / 32)
        y = center_y + (y * heart_size / 32)
        heart_points.append((x, y))
    
    # Draw heart shadow first (solid color, no alpha)
    shadow_points = [(x + 2, y + 2) for x, y in heart_points]
    draw.polygon(shadow_points, fill=(0, 0, 0))
    
    # Draw the heart on top (solid white)
    draw.polygon(heart_points, fill=(255, 255, 255))
    
    # Add small plus sign for "generator" concept
    plus_size = size // 8
    plus_thickness = max(2, size // 40)
    plus_x = center_x + heart_size // 2 + plus_size // 2
    plus_y = center_y - heart_size // 2 - plus_size // 2
    
    # Plus sign background circle (solid white)
    draw.ellipse([plus_x - plus_size, plus_y - plus_size, 
                  plus_x + plus_size, plus_y + plus_size], 
                 fill=(255, 255, 255))
    
    # Plus sign lines (solid green)
    draw.rectangle([plus_x - plus_thickness//2, plus_y - plus_size + 2,
                    plus_x + plus_thickness//2, plus_y + plus_size - 2], 
                   fill=(52, 199, 89))
    draw.rectangle([plus_x - plus_size + 2, plus_y - plus_thickness//2,
                    plus_x + plus_size - 2, plus_y + plus_thickness//2], 
                   fill=(52, 199, 89))
    
    # Save the image as PNG without alpha channel
    final_img.save(output_path, 'PNG')
    print(f"Created solid icon: {output_path} ({size}x{size})")

def main():
    # Create icons directory
    icons_dir = "/Users/aminbenarieb/repo/welltory/ios-3/HealthGeneratorApp/HealthGeneratorApp/HealthGeneratorApp/Resources"
    appiconset_dir = "/Users/aminbenarieb/repo/welltory/ios-3/HealthGeneratorApp/HealthGeneratorApp/HealthGeneratorApp/Resources/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(icons_dir, exist_ok=True)
    
    # Required icon sizes for iOS (all possible sizes)
    icon_sizes = [
        # iPhone app icons
        (40, "AppIcon-40.png"),    # iPhone notification @2x (20x20@2x)
        (60, "AppIcon-60.png"),    # iPhone notification @3x (20x20@3x)
        (58, "AppIcon-58.png"),    # iPhone settings @2x (29x29@2x)
        (87, "AppIcon-87.png"),    # iPhone settings @3x (29x29@3x)
        (80, "AppIcon-80.png"),    # iPhone spotlight @2x (40x40@2x)
        (120, "AppIcon-120.png"),  # iPhone spotlight @3x (40x40@3x) & app icon @2x (60x60@2x)
        (180, "AppIcon-180.png"),  # iPhone app icon @3x (60x60@3x)
        
        # iPad app icons
        (20, "AppIcon-20.png"),    # iPad notification @1x (20x20@1x)
        (40, "AppIcon-40-ipad.png"), # iPad notification @2x (20x20@2x)
        (29, "AppIcon-29.png"),    # iPad settings @1x (29x29@1x)
        (58, "AppIcon-58-ipad.png"), # iPad settings @2x (29x29@2x)
        (76, "AppIcon-76.png"),    # iPad app icon @1x (76x76@1x)
        (152, "AppIcon-152.png"),  # iPad app icon @2x (76x76@2x)
        (167, "AppIcon-167.png"),  # iPad Pro app icon @2x (83.5x83.5@2x)
        
        # Apple Watch
        (154, "AppIcon-154.png"),  # Apple Watch app icon
        
        # App Store
        (1024, "AppIcon-1024.png") # App Store icon
    ]
    
    for size, filename in icon_sizes:
        output_path = os.path.join(icons_dir, filename)
        create_app_icon(size, output_path)
        
        # Also copy to appiconset directory
        appiconset_path = os.path.join(appiconset_dir, filename)
        import shutil
        shutil.copy2(output_path, appiconset_path)
    
    print(f"\nAll icons created in: {icons_dir}")
    print(f"Icons also copied to: {appiconset_dir}")
    print("Next: Update the project to reference these icons")

if __name__ == "__main__":
    main()
