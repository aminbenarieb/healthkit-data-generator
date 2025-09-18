#!/usr/bin/env python3
"""
Create beautiful app icons for Health Data Generator with green heart and generator theme
"""

from PIL import Image, ImageDraw, ImageFont
import os
import math

def create_beautiful_app_icon(size, output_path):
    """Create a beautiful health-themed app icon with green heart and generator elements"""
    # Create a new image with solid background
    img = Image.new('RGB', (size, size), (255, 255, 255))
    draw = ImageDraw.Draw(img)
    
    # Create a beautiful gradient background (white to light green)
    for y in range(size):
        progress = y / size
        # Soft gradient from white to very light green
        r = int(255 * (1 - progress * 0.1))
        g = int(255 * (1 - progress * 0.05))
        b = int(255 * (1 - progress * 0.1))
        color = (r, g, b)
        draw.line([(0, y), (size, y)], fill=color)
    
    # Add subtle rounded corners with white background
    corner_radius = size // 8
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, size, size], corner_radius, fill=255)
    
    # Create the final image with rounded corners
    final_img = Image.new('RGB', (size, size), (248, 249, 250))  # Very light gray
    final_img.paste(img, mask=mask)
    draw = ImageDraw.Draw(final_img)
    
    # Draw a beautiful green heart in the center
    center_x, center_y = size // 2, size // 2
    heart_size = size // 3
    
    # Create heart shape using parametric equations for a smooth heart
    heart_points = []
    for t in range(0, 628, 5):  # 0 to 2π * 100
        t_rad = t / 100.0
        # Parametric heart equation
        x = 16 * (math.sin(t_rad) ** 3)
        y = -(13 * math.cos(t_rad) - 5 * math.cos(2*t_rad) - 2 * math.cos(3*t_rad) - math.cos(4*t_rad))
        
        # Scale and center the heart
        scale = heart_size / 20
        x = center_x + x * scale
        y = center_y + y * scale
        heart_points.append((x, y))
    
    # Draw heart shadow for depth
    shadow_offset = max(2, size // 200)
    shadow_points = [(x + shadow_offset, y + shadow_offset) for x, y in heart_points]
    draw.polygon(shadow_points, fill=(200, 200, 200))
    
    # Draw the beautiful green heart
    heart_color = (52, 199, 89)  # iOS green
    draw.polygon(heart_points, fill=heart_color)
    
    # Add highlight to the heart for 3D effect
    highlight_points = [(x - shadow_offset//2, y - shadow_offset//2) for x, y in heart_points[:len(heart_points)//3]]
    if highlight_points:
        draw.polygon(highlight_points, fill=(82, 229, 119))  # Lighter green
    
    # Add generator elements - gear/cog symbol in top right
    gear_size = size // 6
    gear_x = center_x + heart_size//2 + gear_size//2
    gear_y = center_y - heart_size//2 - gear_size//2
    
    # Draw gear background circle
    gear_radius = gear_size // 2
    draw.ellipse([gear_x - gear_radius, gear_y - gear_radius,
                  gear_x + gear_radius, gear_y + gear_radius], 
                 fill=(255, 255, 255))
    
    # Draw gear teeth
    num_teeth = 8
    for i in range(num_teeth):
        angle = (2 * math.pi * i) / num_teeth
        # Outer point of tooth
        outer_x = gear_x + (gear_radius + 3) * math.cos(angle)
        outer_y = gear_y + (gear_radius + 3) * math.sin(angle)
        # Inner points of tooth
        angle1 = angle - 0.2
        angle2 = angle + 0.2
        inner_x1 = gear_x + gear_radius * math.cos(angle1)
        inner_y1 = gear_y + gear_radius * math.sin(angle1)
        inner_x2 = gear_x + gear_radius * math.cos(angle2)
        inner_y2 = gear_y + gear_radius * math.sin(angle2)
        
        # Draw tooth triangle
        draw.polygon([(outer_x, outer_y), (inner_x1, inner_y1), (inner_x2, inner_y2)], 
                     fill=(100, 100, 100))
    
    # Draw inner gear circle
    inner_radius = gear_radius // 2
    draw.ellipse([gear_x - inner_radius, gear_y - inner_radius,
                  gear_x + inner_radius, gear_y + inner_radius], 
                 fill=(150, 150, 150))
    
    # Add plus sign in bottom right for "add/generate" concept
    plus_size = size // 8
    plus_x = center_x + heart_size//2
    plus_y = center_y + heart_size//2
    plus_thickness = max(3, size // 60)
    
    # Plus sign background circle
    plus_bg_radius = plus_size // 2 + 2
    draw.ellipse([plus_x - plus_bg_radius, plus_y - plus_bg_radius,
                  plus_x + plus_bg_radius, plus_y + plus_bg_radius], 
                 fill=(255, 255, 255))
    
    # Draw plus sign
    # Horizontal line
    draw.rectangle([plus_x - plus_size//2, plus_y - plus_thickness//2,
                    plus_x + plus_size//2, plus_y + plus_thickness//2], 
                   fill=heart_color)
    # Vertical line
    draw.rectangle([plus_x - plus_thickness//2, plus_y - plus_size//2,
                    plus_x + plus_thickness//2, plus_y + plus_size//2], 
                   fill=heart_color)
    
    # Add small data dots around the heart to represent "data generation"
    dot_radius = max(2, size // 100)
    num_dots = 6
    dot_distance = heart_size + 20
    for i in range(num_dots):
        angle = (2 * math.pi * i) / num_dots
        dot_x = center_x + dot_distance * math.cos(angle)
        dot_y = center_y + dot_distance * math.sin(angle)
        draw.ellipse([dot_x - dot_radius, dot_y - dot_radius,
                      dot_x + dot_radius, dot_y + dot_radius], 
                     fill=(heart_color[0], heart_color[1], heart_color[2], 180))
    
    # Save the image without alpha channel
    final_img.save(output_path, 'PNG')
    print(f"Created beautiful icon: {output_path} ({size}x{size})")

def main():
    # Create icons directory
    icons_dir = "/Users/aminbenarieb/repo/welltory/ios-3/HealthGeneratorApp/HealthGeneratorApp/HealthGeneratorApp/Resources"
    appiconset_dir = "/Users/aminbenarieb/repo/welltory/ios-3/HealthGeneratorApp/HealthGeneratorApp/HealthGeneratorApp/Resources/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(icons_dir, exist_ok=True)
    os.makedirs(appiconset_dir, exist_ok=True)
    
    # Required icon sizes for iOS
    icon_sizes = [
        # iPhone app icons
        (40, "AppIcon-40.png"),    # iPhone notification @2x
        (60, "AppIcon-60.png"),    # iPhone notification @3x
        (58, "AppIcon-58.png"),    # iPhone settings @2x
        (87, "AppIcon-87.png"),    # iPhone settings @3x
        (80, "AppIcon-80.png"),    # iPhone spotlight @2x
        (120, "AppIcon-120.png"),  # iPhone spotlight @3x & app @2x
        (180, "AppIcon-180.png"),  # iPhone app @3x
        
        # iPad app icons
        (20, "AppIcon-20.png"),    # iPad notification @1x
        (40, "AppIcon-40-ipad.png"), # iPad notification @2x
        (29, "AppIcon-29.png"),    # iPad settings @1x
        (58, "AppIcon-58-ipad.png"), # iPad settings @2x
        (76, "AppIcon-76.png"),    # iPad app @1x
        (152, "AppIcon-152.png"),  # iPad app @2x
        (167, "AppIcon-167.png"),  # iPad Pro app @2x
        
        # App Store
        (1024, "AppIcon-1024.png") # App Store icon
    ]
    
    for size, filename in icon_sizes:
        output_path = os.path.join(icons_dir, filename)
        create_beautiful_app_icon(size, output_path)
        
        # Also copy to appiconset directory
        appiconset_path = os.path.join(appiconset_dir, filename)
        import shutil
        shutil.copy2(output_path, appiconset_path)
    
    print(f"\nAll beautiful icons created in: {icons_dir}")
    print(f"Icons also copied to: {appiconset_dir}")

if __name__ == "__main__":
    main()
