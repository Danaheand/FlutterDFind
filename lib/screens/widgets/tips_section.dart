import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/font_size_provider.dart';
import '../../providers/tips_provider.dart';
import '../../theme/app_theme.dart';

class TipsSection extends StatefulWidget {
  final VoidCallback? onCreatePendiente;
  final VoidCallback? onOrganizeByPlace;
  final VoidCallback? onDeleteCategories;

  const TipsSection({
    super.key,
    this.onCreatePendiente,
    this.onOrganizeByPlace,
    this.onDeleteCategories,
  });

  @override
  State<TipsSection> createState() => _TipsSectionState();
}

class _TipsSectionState extends State<TipsSection> {
  bool _expandNewItems = false;
  bool _expandTips = false; // Tips expandidos por defecto
  final List<String> _newItems = [];

  @override
  Widget build(BuildContext context) {
    // Leer el provider sin Consumer para verificar el estado
    final tipsProvider = Provider.of<TipsProvider>(context, listen: true);
    
    print('🔍 TipsSection - showTips: ${tipsProvider.showTips}');
    
    // Si los tips están deshabilitados, no mostrar nada
    if (!tipsProvider.showTips) {
      print('❌ Tips deshabilitados - retornando SizedBox.shrink()');
      return const SizedBox.shrink();
    }
    
    print('✅ Tips habilitados - mostrando contenido');
    return _buildTipsContent();
  }

  Widget _buildTipsContent() {
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    final tips = [
      TipItem(
        icon: Icons.add_circle_outline,
        title: 'Crear un pendiente',
        description:
            'Toca el botón "+" para añadir un nuevo artículo a tu lista',
        color: isLight ? AppTheme.primaryLight : AppTheme.primaryDark,
      ),
      TipItem(
        icon: Icons.store,
        title: 'Organiza por lugar',
        description: 'Los artículos se agrupan automáticamente por tienda',
        color: isLight ? AppTheme.successLight : AppTheme.successDark,
      ),
      TipItem(
        icon: Icons.check_box_outline_blank,
        title: 'Eliminar categorías',
        description:
            'Toca el icono de selección en la barra, marca las categorías y presiona eliminar',
        color: isLight ? AppTheme.primaryLight : AppTheme.primaryDark,
      ),
    ];

    return _buildContainer(isLight, tips);
  }

  Widget _buildContainer(bool isLight, List<TipItem> tips) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight
              ? [
                  AppTheme.primaryLight.withOpacity(0.1),
                  AppTheme.secondaryLight.withOpacity(0.1),
                ]
              : [
                  AppTheme.primaryDark.withOpacity(0.15),
                  AppTheme.secondaryDark.withOpacity(0.15),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight
              ? AppTheme.primaryLight.withOpacity(0.3)
              : AppTheme.primaryDark.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? AppTheme.primaryLight.withOpacity(0.1)
                : Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Clickeable para expandir/contraer
          GestureDetector(
            onTap: () => setState(() => _expandTips = !_expandTips),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLight
                    ? AppTheme.surfaceLight.withOpacity(0.8)
                    : AppTheme.cardDark.withOpacity(0.5),
                borderRadius: _expandTips
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      )
                    : BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isLight
                          ? AppTheme.primaryLight.withOpacity(0.15)
                          : AppTheme.primaryDark.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.lightbulb_rounded,
                      color: isLight
                          ? AppTheme.primaryLight
                          : AppTheme.primaryDark,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<FontSizeProvider>(
                          builder: (context, fontSizeProvider, _) => Text(
                            'Tips en Pendientes',
                            style: TextStyle(
                              fontSize: fontSizeProvider.fontSize + 4,
                              fontWeight: FontWeight.bold,
                              color: isLight
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Consumer<FontSizeProvider>(
                          builder: (context, fontSizeProvider, _) => Text(
                            'Gestiona tu lista de compras fácilmente',
                            style: TextStyle(
                              fontSize: fontSizeProvider.fontSize - 2,
                              color: AppTheme.getTextSecondary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expandTips ? Icons.expand_less : Icons.expand_more,
                    color:
                        isLight ? AppTheme.primaryLight : AppTheme.primaryDark,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Tips List - Se expande/contrae
          if (_expandTips)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children:
                    tips.map((tip) => _buildTipCard(context, tip)).toList(),
              ),
            ),

          // Nueva sección: Items añadidos
          if (_newItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  const Divider(height: 0),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _expandNewItems = !_expandNewItems),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isLight ? AppTheme.cardLight : AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLight
                              ? AppTheme.dividerLight
                              : AppTheme.dividerDark,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.new_releases_rounded,
                                  color: isLight
                                      ? AppTheme.successLight
                                      : AppTheme.successDark,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Consumer<FontSizeProvider>(
                                    builder: (context, fontSizeProvider, _) =>
                                        Text(
                                      'Nuevos items (${_newItems.length})',
                                      style: TextStyle(
                                        fontSize: fontSizeProvider.fontSize,
                                        fontWeight: FontWeight.bold,
                                        color: isLight
                                            ? AppTheme.textPrimaryLight
                                            : AppTheme.textPrimaryDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _expandNewItems
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: AppTheme.getTextSecondary(context),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_expandNewItems)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: Column(
                        children: _newItems
                            .map((item) => _buildNewItemCard(context, item))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNewItemCard(BuildContext context, String item) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLight
            ? AppTheme.successLight.withOpacity(0.1)
            : AppTheme.successDark.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isLight ? AppTheme.successLight : AppTheme.successDark)
              .withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isLight ? AppTheme.successLight : AppTheme.successDark)
                  .withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_circle_outline,
              color: isLight ? AppTheme.successLight : AppTheme.successDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Consumer<FontSizeProvider>(
              builder: (context, fontSizeProvider, _) => Text(
                item,
                style: TextStyle(
                  fontSize: fontSizeProvider.fontSize - 1,
                  color: isLight
                      ? AppTheme.textPrimaryLight
                      : AppTheme.textPrimaryDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void addNewItem(String item) {
    setState(() {
      _newItems.insert(0, item);
      if (!_expandNewItems) {
        _expandNewItems = true;
      }
    });
  }

  Widget _buildTipCard(BuildContext context, TipItem tip) {
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    // Determinar callback según el título del tip
    VoidCallback? callback;
    if (tip.title == 'Crear un pendiente') {
      callback = widget.onCreatePendiente;
    } else if (tip.title == 'Organiza por lugar') {
      callback = widget.onOrganizeByPlace;
    } else if (tip.title == 'Eliminar categorías') {
      callback = widget.onDeleteCategories;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: callback,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono con diseño más elegante
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tip.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: tip.color.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    tip.icon,
                    color: tip.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<FontSizeProvider>(
                        builder: (context, fontSizeProvider, _) => Text(
                          tip.title,
                          style: TextStyle(
                            fontSize: fontSizeProvider.fontSize + 1,
                            fontWeight: FontWeight.w700,
                            color: isLight
                                ? AppTheme.textPrimaryLight
                                : AppTheme.textPrimaryDark,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Consumer<FontSizeProvider>(
                        builder: (context, fontSizeProvider, _) => Text(
                          tip.description,
                          style: TextStyle(
                            fontSize: fontSizeProvider.fontSize - 1.5,
                            color: AppTheme.getTextSecondary(context),
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (callback != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.touch_app_rounded,
                      color: tip.color.withOpacity(0.6),
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TipItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  TipItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
