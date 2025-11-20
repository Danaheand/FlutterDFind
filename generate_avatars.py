#!/usr/bin/env python3
"""
Script para generar avatares divertidos en PNG
"""
from PIL import Image, ImageDraw, ImageFont
import os

# Crear directorio si no existe
os.makedirs('assets/avatars', exist_ok=True)

# Definir avatares con emojis Unicode (convertidos a símbolos)
avatars = [
    {
        'name': 'avatar1',
        'emoji': '😎',  # Cool guy
        'bg_color': (255, 107, 107),  # Red
        'description': 'Cool Boy'
    },
    {
        'name': 'avatar2',
        'emoji': '🤩',  # Star eyes
        'bg_color': (255, 195, 113),  # Orange
        'description': 'Star Eyes'
    },
    {
        'name': 'avatar3',
        'emoji': '😸',  # Grinning cat
        'bg_color': (255, 235, 59),  # Yellow
        'description': 'Happy Cat'
    },
    {
        'name': 'avatar4',
        'emoji': '🐶',  # Dog
        'bg_color': (102, 187, 106),  # Green
        'description': 'Puppy'
    },
    {
        'name': 'avatar5',
        'emoji': '🦄',  # Unicorn
        'bg_color': (156, 39, 176),  # Purple
        'description': 'Unicorn'
    }
]

# Tamaño de la imagen
SIZE = 256
PADDING = 20

for avatar in avatars:
    # Crear imagen con fondo de color
    img = Image.new('RGB', (SIZE, SIZE), avatar['bg_color'])
    draw = ImageDraw.Draw(img)
    
    # Intentar usar una fuente disponible o usar la por defecto
    try:
        # Para emojis, necesitamos una fuente que soporte Unicode
        # Intentaremos usar una fuente del sistema
        font = ImageFont.truetype("C:/Windows/Fonts/seguiemj.ttf", 180)
    except:
        try:
            # Alternativa en Linux/Mac
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 180)
        except:
            # Fallback
            font = ImageFont.load_default()
    
    # Dibujar el emoji en el centro
    emoji = avatar['emoji']
    bbox = draw.textbbox((0, 0), emoji, font=font)
    emoji_width = bbox[2] - bbox[0]
    emoji_height = bbox[3] - bbox[1]
    
    x = (SIZE - emoji_width) // 2
    y = (SIZE - emoji_height) // 2 - 10
    
    draw.text((x, y), emoji, fill=(255, 255, 255), font=font)
    
    # Guardar imagen
    img.save(f'assets/avatars/{avatar["name"]}.png')
    print(f'✓ Creado: {avatar["name"]}.png - {avatar["description"]}')

print(f'\n✅ Se han generado {len(avatars)} avatares en assets/avatars/')
