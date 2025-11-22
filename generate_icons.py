from PIL import Image, ImageDraw
import os

# Crear ícono base de 1024x1024 con el logo DFind (casa con D)
size = 1024
img = Image.new('RGB', (size, size), color='#F5EFE7')
draw = ImageDraw.Draw(img)

# Colores
dark = '#2C3E50'  # Oscuro similar a la imagen
light = '#F5EFE7'  # Fondo claro

# Margen
m = 80

# Techo triangular
roof = [(size//2, m), (m, size//2-80), (size-m, size//2-80)]
draw.polygon(roof, fill=dark)

# Paredes
draw.rectangle([m, size//2-80, size-m, size-m], fill=dark)

# Interior blanco
draw.rectangle([m+60, size//2-50, size-m-60, size-m-60], fill=light)

# Línea vertical izquierda de la D
draw.rectangle([m+150, size//2+50, m+230, size-m-80], fill=dark)

# Semicírculo derecho (D)
cx = m + 350
cy = (size//2-50 + size-m-80) // 2
r = 200
draw.arc([cx-r, cy-r, cx+r, cy+r], 270, 90, fill=dark, width=100)
draw.line([(m+230, size//2+50), (m+230, size-m-80)], fill=dark, width=100)

img.save('dfind_icon_1024.png')
print('✓ Ícono base 1024x1024 creado')

# Crear íconos para cada resolución de Android
base_path = 'android/app/src/main/res'
sizes = {
    'xxxhdpi': 192,
    'xxhdpi': 144,
    'xhdpi': 96,
    'hdpi': 72,
    'mdpi': 48
}

for dpi, px in sizes.items():
    resized = img.resize((px, px), Image.Resampling.LANCZOS)
    dir_path = os.path.join(base_path, f'mipmap-{dpi}')
    os.makedirs(dir_path, exist_ok=True)
    file_path = os.path.join(dir_path, 'ic_launcher.png')
    resized.save(file_path)
    print(f'✓ {dpi}: {px}x{px} guardado en {file_path}')

print('✓ Todos los íconos de Android creados exitosamente')

# Crear también para iOS
ios_path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
os.makedirs(ios_path, exist_ok=True)

# iOS sizes
ios_sizes = {
    'AppIcon-20x20@1x.png': 20,
    'AppIcon-20x20@2x.png': 40,
    'AppIcon-20x20@3x.png': 60,
    'AppIcon-29x29@1x.png': 29,
    'AppIcon-29x29@2x.png': 58,
    'AppIcon-29x29@3x.png': 87,
    'AppIcon-40x40@1x.png': 40,
    'AppIcon-40x40@2x.png': 80,
    'AppIcon-40x40@3x.png': 120,
    'AppIcon-60x60@2x.png': 120,
    'AppIcon-60x60@3x.png': 180,
    'AppIcon-76x76@1x.png': 76,
    'AppIcon-76x76@2x.png': 152,
    'AppIcon-83.5x83.5@2x.png': 167,
    'AppIcon-1024x1024@1x.png': 1024
}

for filename, size in ios_sizes.items():
    resized = img.resize((size, size), Image.Resampling.LANCZOS)
    file_path = os.path.join(ios_path, filename)
    resized.save(file_path)
    print(f'✓ iOS {filename}: {size}x{size}')

print('✓ Todos los íconos de iOS creados exitosamente')
