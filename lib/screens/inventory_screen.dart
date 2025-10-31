import 'package:flutter/material.dart';

typedef AddToShoppingList = void Function(String name);

class _ShoppingItem {
  String name;
  bool done;
  _ShoppingItem(this.name, {this.done = false});
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  static AddToShoppingList? addFromAlertGlobal;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final List<_ShoppingItem> _items = [];
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    InventoryScreen.addFromAlertGlobal = addFromAlert;
  }

  @override
  void dispose() {
    InventoryScreen.addFromAlertGlobal = null;
    super.dispose();
  }

  void _addItem() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() => _items.add(_ShoppingItem(text)));
      _controller.clear();
    }
  }

  void _toggleDone(int i) {
    setState(() => _items[i].done = !_items[i].done);
  }

  void _removeItem(int i) {
    setState(() => _items.removeAt(i));
  }

  // Lógica para agregar desde alertas (ejemplo, llamada desde otra pantalla)
  void addFromAlert(String name) {
    if (_items.any((e) => e.name == name)) return;
    setState(() => _items.add(_ShoppingItem(name)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de compras')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '¿Qué necesitas comprar?',
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addItem,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('Agrega productos a tu lista'))
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, i) => Dismissible(
                        key: ValueKey(_items[i].name + i.toString()),
                        background: Container(color: Colors.red[100]),
                        onDismissed: (_) => _removeItem(i),
                        child: ListTile(
                          leading: Checkbox(
                            value: _items[i].done,
                            onChanged: (_) => _toggleDone(i),
                          ),
                          title: Text(
                            _items[i].name,
                            style: TextStyle(
                              decoration: _items[i].done ? TextDecoration.lineThrough : null,
                              color: _items[i].done ? Colors.grey : null,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removeItem(i),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
