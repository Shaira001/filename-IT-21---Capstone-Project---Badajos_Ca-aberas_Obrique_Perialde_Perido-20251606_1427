import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:sk_connect/item_class.dart';

/// A widget that displays items in a 2-column grid with image, name, and availability.
class ItemsTab extends StatelessWidget {
  final List<Item> items;
  final Color primaryColor;
  final Color accentColor;
  final Color cardGradientStart;
  final Color cardGradientEnd;
  final void Function(Item) onView;

  const ItemsTab({
    super.key,
    required this.items,
    required this.primaryColor,
    required this.accentColor,
    required this.cardGradientStart,
    required this.cardGradientEnd,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inventory, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No items available',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItemBox(context, item);
      },
    );
  }

  Widget _buildItemBox(BuildContext context, Item item) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onView(item),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cardGradientStart, cardGradientEnd],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Image section
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: item.image.isNotEmpty
                          ? FutureBuilder<Uint8List>(
                              future: _decodeBase64(item.image),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2));
                                } else if (snapshot.hasError || !snapshot.hasData) {
                                  return Center(
                                    child: Icon(Icons.broken_image,
                                        size: 40, color: Colors.grey.shade400),
                                  );
                                } else {
                                  return Center(
                                    child: SizedBox(
                                      width: 100,
                                      height: 120,
                                      child: Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.contain,
                                        gaplessPlayback: true,
                                      ),
                                    ),
                                  );
                                }
                              },
                            )
                          : Center(
                              child: Icon(
                                Icons.inventory,
                                color: Colors.grey.shade400,
                                size: 40,
                              ),
                            ),
                    ),
                  ),
                ),

                // Item details
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.layers, size: 14, color: accentColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${item.available}/${item.totalQuantity}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Icon(Icons.chevron_right, size: 18, color: accentColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Decodes a base64 image string into Uint8List safely
  Future<Uint8List> _decodeBase64(String base64String) async {
    try {
      return base64Decode(base64String);
    } catch (e) {
      return Uint8List(0);
    }
  }
}
