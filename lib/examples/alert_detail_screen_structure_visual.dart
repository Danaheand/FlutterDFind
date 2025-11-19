/*
 * ESTRUCTURA VISUAL - AlertDetailScreenModern
 * 
 * Este archivo ilustra la estructura de capas Stack de la pantalla
 */

/*
┌────────────────────────────────────────────────┐
│                                                │
│         ┌──────────────────────┐               │ <- AppBar transparente
│         │    ← ALTA            │               │    (Positioned top)
│         └──────────────────────┘               │
│                                                │
│                                                │ CAPA 1: Hero Background
│            COLOR DE PRIORIDAD                  │ Container 35% altura
│              (Rojo/Amarillo/Azul/Verde)        │ Color dinámico
│                                                │
│   ┌────────────────────────────────────┐       │
│   │     ┌────────────────────────┐     │       │ CAPA 3: Floating Card
│   │     │      FALTAN            │     │       │ (Positioned 25% top)
│   │     │      29 min            │     │       │ Card con elevation 8
│   │     │  📅 mié, 19 nov, 18:08 │     │       │
│   │     └────────────────────────┘     │       │
│   │                                    │       │
│   │  ┌──────────────────────────────┐ │       │
│   │  │  Tomar Medicamento           │ │       │ CAPA 2: Content
│   │  └──────────────────────────────┘ │       │ SingleChildScrollView
│   │                                    │       │ Container blanco
│   │  DESCRIPCIÓN                       │       │ BorderRadius top 30
│   │  Pastilla de presión arterial...  │       │
│   │                                    │       │
│   │  📍 UBICACIÓN                      │       │
│   │  Casa                              │       │
│   │                                    │       │
│   │  🔄 FRECUENCIA                     │       │
│   │  Diario                            │       │
│   │                                    │       │
│   │  DÍAS                              │       │
│   │  ⚫ ⚫ ⚫ ⚫ ⚫ ⚪ ⚪               │       │ WeekdayIndicator
│   │  L  M  X  J  V  S  D              │       │
│   │                                    │       │
│   │                                    │       │
│   │                                    │       │
│   │        [Espaciado 100px]           │       │
│   └────────────────────────────────────┘       │
│                                                │
│   ┌─────────────────────────────────────┐      │ CAPA 4: Gradient
│   │         [Gradiente blanco]          │      │ (Positioned bottom)
│   │        Blanco → Transparente        │      │ IgnorePointer
│   │  ┌───┐  ┌────────────────┐  ┌───┐  │      │ LinearGradient
│   │  │🗑️│  │   ✓ Completar  │  │✏️│  │      │
│   │  └───┘  └────────────────┘  └───┘  │      │ CAPA 5: Action Dock
│   │  Elim.   Botón Principal    Edit   │      │ (Positioned bottom)
│   └─────────────────────────────────────┘      │ Row con 3 botones
│                                                │
└────────────────────────────────────────────────┘


COMPONENTES DE UI:

┌─────────────────────────────────────────────────────────────┐
│ 1. BOTÓN ELIMINAR/EDITAR (56x56)                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌───────────────┐                                         │
│   │               │  • Container 56x56                      │
│   │      🗑️      │  • BorderRadius 16                      │
│   │               │  • Color.withOpacity(0.1) de fondo      │
│   └───────────────┘  • Border con color.withOpacity(0.3)   │
│                      • InkWell con borderRadius             │
│                                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ 2. BOTÓN CENTRAL - Completar/Guardar (Expanded)             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌───────────────────────────────────────────┐             │
│   │                                           │             │
│   │    ✓  Completar / 💾 Guardar             │  • Altura 56 │
│   │                                           │  • Expanded  │
│   └───────────────────────────────────────────┘  • BorderR 16│
│                                                  • Color full│
│                                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ 3. CAMPO DE TEXTO EDITABLE (TextField)                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌───────────────────────────────────────────┐             │
│   │ Título de la alerta                      │             │
│   │                                           │             │
│   └───────────────────────────────────────────┘             │
│                                                             │
│   • filled: true                                            │
│   • fillColor: Colors.grey[50]                              │
│   • border: OutlineInputBorder                              │
│   • borderRadius: 12                                        │
│   • borderSide: Color(0xFFE2E8F0)                           │
│   • focusedBorder: Color(0xFF3B82F6), width: 2             │
│                                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ 4. INDICADOR DE DÍAS (WeekdayIndicator)                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│    ⚫  ⚫  ⚫  ⚫  ⚫  ⚪  ⚪                                  │
│    L   M   X   J   V   S   D                                │
│                                                             │
│   Seleccionado:        No seleccionado:                     │
│   • Color relleno      • Color transparente                 │
│   • Border slate-900   • Border slate-400                   │
│   • Texto blanco       • Texto slate-500                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘


FLUJO DE INTERACCIÓN:

1. MODO VISUALIZACIÓN:
   ┌─────────┐
   │ Vista   │
   │ Normal  │
   └────┬────┘
        │
        ├─→ Tap Completar → Marca como completado (verde)
        │                   └─→ Cambia contador a "✓ LISTO"
        │
        ├─→ Tap Editar ────→ Cambia a modo edición
        │                    └─→ Transición: Texto → TextField
        │
        └─→ Tap Eliminar ──→ Primera vez: "¿Seguro?"
                             └─→ Segunda vez: Elimina

2. MODO EDICIÓN:
   ┌─────────┐
   │ Edición │
   │ Activa  │
   └────┬────┘
        │
        ├─→ Modificar campos (título, descripción, ubicación)
        │
        ├─→ Tap días de semana → Toggle selección
        │
        ├─→ Tap Guardar (verde) ──→ Llama _saveChanges()
        │                            └─→ Actualiza Provider
        │                            └─→ Muestra SnackBar éxito
        │                            └─→ Vuelve a modo vista
        │
        └─→ Tap X (cancelar) ──→ Restaura valores originales
                                 └─→ Vuelve a modo vista


ESTADOS DE COLOR DEL HERO BACKGROUND:

┌────────────────────────────────────────────────────┐
│ ESTADO           │ COLOR          │ CÓDIGO        │
├──────────────────┼────────────────┼───────────────┤
│ Completado       │ Verde          │ #10B981       │
│ Inactivo         │ Gris           │ Grey.shade400 │
│ Prioridad Alta   │ Rojo           │ #EF4444       │
│ Prioridad Media  │ Ámbar          │ Amber.600     │
│ Prioridad Baja   │ Azul           │ Blue.400      │
│ Custom           │ Color propio   │ data.color    │
└────────────────────────────────────────────────────┘


RESPONSIVE BEHAVIOR:

Screen Height: 100%
├─ 0-25%:    Hero Background (Color)
├─ 25%:      Floating Card (Positioned)
├─ 30-95%:   White Content (Scrolleable)
└─ 95-100%:  Action Dock (Fixed buttons)

┌────────────────────────────────┐
│ Small Device (<600px height)  │
├────────────────────────────────┤
│ • Card puede superponerse     │
│ • Scroll necesario            │
│ • Botones siempre visibles    │
└────────────────────────────────┘

┌────────────────────────────────┐
│ Large Device (>600px height)  │
├────────────────────────────────┤
│ • Card flotante destacado     │
│ • Contenido visible completo  │
│ • Gradiente sutil             │
└────────────────────────────────┘

*/
