import 'package:flutter/material.dart';

/// Widget for managing unit equipment list
/// Supports add, edit, and remove functionality
class EquipmentListEditor extends StatefulWidget {
  final List<String> initialEquipment;
  final ValueChanged<List<String>>? onEquipmentChanged;

  const EquipmentListEditor({
    super.key,
    this.initialEquipment = const [],
    this.onEquipmentChanged,
  });

  @override
  State<EquipmentListEditor> createState() => _EquipmentListEditorState();
}

class _EquipmentListEditorState extends State<EquipmentListEditor> {
  late List<String> _equipment;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _equipment = List.from(widget.initialEquipment);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Check for duplicates (case insensitive)
    if (_equipment.any((e) => e.toLowerCase() == text.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cet équipement existe déjà'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _equipment.add(text);
      _textController.clear();
    });

    widget.onEquipmentChanged?.call(_equipment);
  }

  void _removeItem(int index) {
    setState(() {
      _equipment.removeAt(index);
    });

    widget.onEquipmentChanged?.call(_equipment);
  }

  void _editItem(int index) async {
    final editController = TextEditingController(text: _equipment[index]);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier l\'équipement'),
        content: TextField(
          controller: editController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Nom de l\'équipement',
          ),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, editController.text.trim()),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );

    editController.dispose();

    if (result != null && result.isNotEmpty && result != _equipment[index]) {
      // Check for duplicates (case insensitive)
      if (_equipment.any((e) => e.toLowerCase() == result.toLowerCase() && _equipment.indexOf(e) != index)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cet équipement existe déjà'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      setState(() {
        _equipment[index] = result;
      });

      widget.onEquipmentChanged?.call(_equipment);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.kitchen,
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Équipements (${_equipment.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Add equipment input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ajouter un équipement...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onSubmitted: (_) => _addItem(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addItem,
              icon: Icon(
                Icons.add_circle,
                color: Theme.of(context).primaryColor,
              ),
              tooltip: 'Ajouter',
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Equipment list
        if (_equipment.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Aucun équipement ajouté',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _equipment.asMap().entries.map((entry) {
              return _buildEquipmentChip(entry.key, entry.value);
            }).toList(),
          ),

        // Suggested equipment
        if (_equipment.length < 10) ...[
          const SizedBox(height: 16),
          Text(
            'Suggestions :',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _getSuggestions().map((suggestion) {
              return ActionChip(
                label: Text(
                  suggestion,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.grey[100],
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  if (!_equipment.any((e) => e.toLowerCase() == suggestion.toLowerCase())) {
                    setState(() {
                      _equipment.add(suggestion);
                    });
                    widget.onEquipmentChanged?.call(_equipment);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildEquipmentChip(int index, String item) {
    return GestureDetector(
      onTap: () => _editItem(index),
      child: Chip(
        label: Text(item),
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        side: BorderSide.none,
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: () => _removeItem(index),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  List<String> _getSuggestions() {
    final allSuggestions = [
      'Climatisation',
      'Chauffage',
      'Cuisine équipée',
      'Réfrigérateur',
      'Machine à laver',
      'Micro-ondes',
      'Télévision',
      'Internet/Wifi',
      'Parking',
      'Balcon',
      'Terrasse',
      'Jardin',
      'Ascenseur',
      'Gardien',
      'Interphone',
    ];

    // Filter out already added items
    return allSuggestions
        .where((s) => !_equipment.any((e) => e.toLowerCase() == s.toLowerCase()))
        .take(5)
        .toList();
  }
}
