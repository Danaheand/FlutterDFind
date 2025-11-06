# Sistema de Colores - FlutterDFind

## 📋 Resumen

Este documento describe el sistema centralizado de colores implementado en la aplicación, que soporta tanto **modo claro** como **modo oscuro** con excelente contraste y legibilidad.

## 🎨 Paleta de Colores

### Colores Primarios y Secundarios

| Propósito | Modo Claro | Modo Oscuro |
|-----------|------------|-------------|
| **Primary** | `#1976D2` (Azul medio) | `#42A5F5` (Azul claro) |
| **Secondary** | `#FF9800` (Naranja) | `#FFB74D` (Naranja claro) |

### Colores de Superficie

| Elemento | Modo Claro | Modo Oscuro |
|----------|------------|-------------|
| **Surface** | `#FFFFFF` (Blanco) | `#121212` (Negro profundo) |
| **Card** | `#FFFFFF` (Blanco) | `#1E1E1E` (Gris oscuro) |
| **Background** | `#F5F5F5` (Gris muy claro) | `#121212` (Negro profundo) |

### Colores de Texto

| Tipo | Modo Claro | Modo Oscuro |
|------|------------|-------------|
| **Primary** | `#212121` (Negro casi puro) | `#FFFFFF` (Blanco) |
| **Secondary** | `#757575` (Gris medio) | `#B0B0B0` (Gris claro) |

### Colores de Sugerencias

| Elemento | Modo Claro | Modo Oscuro |
|----------|------------|-------------|
| **Background** | `#FFF8E1` (Amarillo muy claro) | `#3E2723` (Marrón oscuro) |
| **Border** | `#FFD54F` (Amarillo) | `#FFA726` (Naranja) |
| **Icon** | `#F57C00` (Naranja oscuro) | `#FFB74D` (Naranja claro) |

### Colores de Estado

| Estado | Modo Claro | Modo Oscuro |
|--------|------------|-------------|
| **Success** | `#4CAF50` (Verde) | `#66BB6A` (Verde claro) |
| **Error** | `#F44336` (Rojo) | `#EF5350` (Rojo claro) |
| **Warning** | `#FF9800` (Naranja) | `#FFB74D` (Naranja claro) |

### Colores de Agrupación (Lista de Compras)

| Elemento | Modo Claro | Modo Oscuro |
|----------|------------|-------------|
| **Place Icon** | `#1976D2` (Azul) | `#42A5F5` (Azul claro) |
| **Place Badge Background** | `#BBDEFB` (Azul muy claro) | `#1565C0` (Azul medio) |
| **Category Header** | `#F5F5F5` (Gris muy claro) | `#2C2C2C` (Gris oscuro) |
| **Category Icon** | `#616161` (Gris medio) | `#9E9E9E` (Gris claro) |

### Colores de Modo Compras

| Elemento | Modo Claro | Modo Oscuro |
|----------|------------|-------------|
| **Background** | `#E3F2FD` (Azul muy claro) | `#0D47A1` (Azul oscuro) |
| **Tile** | `#BBDEFB` (Azul muy claro) | `#1565C0` (Azul medio) |

### Otros Colores

| Elemento | Modo Claro | Modo Oscuro |
|----------|------------|-------------|
| **Purchased Items** | `#9E9E9E` (Gris) | `#616161` (Gris medio) |
| **Divider** | `#E0E0E0` (Gris claro) | `#424242` (Gris oscuro) |

## 🔧 Uso en el Código

### 1. Obtener Colores Contextuales

El tema proporciona **métodos helper** para obtener el color correcto según el modo actual:

```dart
// En cualquier widget con BuildContext
AppTheme.getSuggestionBackground(context)
AppTheme.getSuggestionBorder(context)
AppTheme.getSuggestionIcon(context)
AppTheme.getPlaceIcon(context)
AppTheme.getPlaceBadgeBackground(context)
AppTheme.getCategoryHeader(context)
AppTheme.getCategoryIcon(context)
AppTheme.getShoppingModeBackground(context)
AppTheme.getShoppingModeTile(context)
AppTheme.getPurchasedColor(context)
AppTheme.getTextSecondary(context)
```

### 2. Acceder a Colores Directamente

Para casos donde necesitas un color específico:

```dart
// Modo claro
AppTheme.primaryLight
AppTheme.textPrimaryLight
AppTheme.suggestionBackgroundLight

// Modo oscuro
AppTheme.primaryDark
AppTheme.textPrimaryDark
AppTheme.suggestionBackgroundDark
```

### 3. Usar Colores del Theme de Material

El sistema también configura automáticamente el `ThemeData` de Flutter:

```dart
// Estos colores se configuran automáticamente
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.secondary
Theme.of(context).colorScheme.surface
Theme.of(context).colorScheme.error
Theme.of(context).scaffoldBackgroundColor
```

## 📱 Ejemplos de Uso

### Ejemplo 1: Sección de Sugerencias

```dart
Container(
  decoration: BoxDecoration(
    color: AppTheme.getSuggestionBackground(context),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: AppTheme.getSuggestionBorder(context),
      width: 1,
    ),
  ),
  child: Icon(
    Icons.lightbulb,
    color: AppTheme.getSuggestionIcon(context),
  ),
)
```

### Ejemplo 2: Agrupación por Lugar

```dart
Row(
  children: [
    Icon(Icons.store, color: AppTheme.getPlaceIcon(context)),
    Container(
      decoration: BoxDecoration(
        color: AppTheme.getPlaceBadgeBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$totalItems',
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.light
              ? AppTheme.placeIconLight
              : AppTheme.textPrimaryDark,
        ),
      ),
    ),
  ],
)
```

### Ejemplo 3: Items Comprados

```dart
Text(
  item.name,
  style: TextStyle(
    decoration: TextDecoration.lineThrough,
    color: AppTheme.getPurchasedColor(context),
  ),
)
```

## ✨ Ventajas del Sistema

1. **Centralización**: Todos los colores en un solo archivo (`app_theme.dart`)
2. **Consistencia**: Los mismos colores en toda la aplicación
3. **Modo Oscuro**: Soporte completo con colores optimizados
4. **Contraste**: Ratios de contraste que cumplen con WCAG 2.1 AA
5. **Mantenibilidad**: Fácil de actualizar todos los colores desde un lugar
6. **Helpers**: Métodos convenientes para obtener colores contextuales
7. **Material 3**: Integración con el sistema de temas de Material Design 3

## 🎯 Principios de Diseño

- **Contraste suficiente**: Ratio mínimo de 4.5:1 para texto normal
- **Jerarquía visual**: Colores primarios para elementos importantes
- **Feedback visual**: Colores de estado claros (success, error, warning)
- **Accesibilidad**: Colores distinguibles para usuarios con daltonismo
- **Consistencia**: Paleta limitada y coherente en toda la app

## 🔄 Cómo Cambiar el Modo

La aplicación detecta automáticamente el tema del sistema, pero puedes configurarlo manualmente en `main.dart`:

```dart
MaterialApp(
  theme: AppTheme.lightTheme,      // Modo claro
  darkTheme: AppTheme.darkTheme,    // Modo oscuro
  themeMode: ThemeMode.system,      // Automático según el sistema
  // themeMode: ThemeMode.light,    // Forzar modo claro
  // themeMode: ThemeMode.dark,     // Forzar modo oscuro
)
```

## 📝 Archivos Actualizados

Los siguientes archivos fueron actualizados para usar el sistema de colores centralizado:

1. ✅ `lib/theme/app_theme.dart` - Definición del tema completo
2. ✅ `lib/screens/inventory_screen.dart` - Pantalla principal
3. ✅ `lib/screens/category_focus_screen.dart` - Vista de foco
4. ✅ `lib/screens/widgets/suggestions_section.dart` - Sugerencias
5. ✅ `lib/screens/widgets/shopping_mode_view.dart` - Modo compras
6. ✅ `lib/screens/widgets/update_inventory_modal_v2.dart` - Modal de inventario
7. ✅ `lib/screens/widgets/add_item_modal_v2.dart` - Modal añadir (usa tema automáticamente)

## 🚀 Próximos Pasos

Para expandir el sistema de colores:

1. Añadir más colores temáticos según necesidades
2. Implementar variantes de colores para estados (hover, pressed, disabled)
3. Crear paletas personalizadas para eventos especiales
4. Añadir animaciones de transición entre temas
