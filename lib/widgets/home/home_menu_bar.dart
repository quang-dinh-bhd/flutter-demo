import 'package:flutter/material.dart';

class HomeMenuBar extends StatelessWidget {
  final List<dynamic> menuItems;
  final ValueChanged<dynamic> onSelectItem;

  const HomeMenuBar({
    super.key,
    required this.menuItems,
    required this.onSelectItem,
  });

  @override
  Widget build(BuildContext context) {
    final items = menuItems.take(2).toList();
    final remainingItems = menuItems.skip(2).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ...items.map(
            (item) => Expanded(
              child: InkWell(
                onTap: () => onSelectItem(item),
                child: Center(
                  child: Text(
                    (item is Map ? (item['name'] ?? '') : '').toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (remainingItems.isNotEmpty)
            Expanded(
              child: Center(
                child: UnconstrainedBox(
                  child: PopupMenuButton<dynamic>(
                    position: PopupMenuPosition.under,
                    offset: const Offset(0, 6),
                    padding: EdgeInsets.zero,
                    onSelected: onSelectItem,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "Khác",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                    itemBuilder: (context) => remainingItems
                        .map(
                          (it) => PopupMenuItem<dynamic>(
                            value: it,
                            child: Text(
                              (it is Map ? (it['name'] ?? '') : '').toString(),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
