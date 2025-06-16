import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sk_connect/borrow_request_class.dart';
import 'package:sk_connect/database_helper.dart';
import 'package:sk_connect/item_class.dart';
import 'package:sk_connect/utils.dart';
import 'package:sk_connect/widgets/confirm_cancel_dialog.dart';
import 'package:sk_connect/widgets/view_item_dialog.dart';
import 'package:sk_connect/returned_tab.dart';
import 'package:sk_connect/items_tab.dart';
import 'package:sk_connect/request.dart';
import 'package:sk_connect/borrowed.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final Color primary = const Color(0xFF0A2463);
  final Color accent = const Color(0xFF3E92CC);
  final Color bg = const Color(0xFFF8F9FA);
  final Color error = const Color(0xFFD62839);
  final Color pending = const Color(0xFFFFA000);
  final Color approved = const Color(0xFF4CAF50);
  final Color returnedC = const Color(0xFF1976D2);

  int _selected = 0;
  late PageController _controller;
  List<Item> _items = [];
  List<BorrowRequest> _requests = [];

  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _search = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _jump(int idx) {
    setState(() => _selected = idx);
    _controller.animateToPage(
      idx,
      duration: const Duration(milliseconds: 200),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: primary,
        scaffoldBackgroundColor: bg,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          prefixIconColor: primary,
        ),
      ),
      child: Scaffold(
        body: SafeArea(
          child: StreamBuilder<List<Item>>(
            stream: getAllItemsStream(),
            builder: (context, snap1) {
              _items = snap1.data ?? [];
              return StreamBuilder<List<BorrowRequest>>(
                stream: getBorrowRequestsByUidStream(curClient.uid),
                builder: (context, snap2) {
                  _requests = snap2.data ?? [];
                  final pCount = _requests.where((r) => r.status == 'Pending').length;
                  final aCount = _requests.where((r) => r.status == 'Approved').length;
                  final rCount = _requests.where((r) => r.status == 'Returned').length;

                  final display = _selected == 0
                      ? _items.where((i) => i.name.toLowerCase().contains(_search)).toList()
                      : _items;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _searchCtrl,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(Icons.search, color: primary),
                                      hintText: 'Search items...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _tabBtn(Icons.list_alt, 'Items', _items.length, accent, 0),
                                    _tabBtn(Icons.request_page, 'Requests', pCount, pending, 1),
                                    _tabBtn(Icons.inventory_2, 'Borrowed', aCount, approved, 2),
                                    _tabBtn(Icons.assignment_return, 'Returned', rCount, returnedC, 3),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: PageView(
                          controller: _controller,
                          physics: const BouncingScrollPhysics(),
                          onPageChanged: (i) => setState(() => _selected = i),
                          children: [
                            ItemsTab(
                              items: display,
                              primaryColor: primary,
                              accentColor: accent,
                              cardGradientStart: bg,
                              cardGradientEnd: Colors.grey[200]!,
                              onView: _showItem,
                            ),
                            RequestsTab(
                              requests: _requests,
                              items: _items,
                              onCancelRequest: _cancelReq,
                              pendingColor: pending,
                              approvedColor: approved,
                              rejectedColor: error,
                              primaryColor: primary,
                              accentColor: accent,
                              cardGradientStart: bg,
                              cardGradientEnd: Colors.grey[200]!,
                            ),
                            BorrowedTab(
                              requests: _requests,
                              items: _items,
                              primaryColor: primary,
                              accentColor: accent,
                              cardGradientStart: bg,
                              cardGradientEnd: Colors.grey[200]!,
                            ),
                            ReturnedTab(
                              requests: _requests,
                              items: _items,
                              primaryColor: primary,
                              accentColor: accent,
                              cardGradientStart: bg,
                              cardGradientEnd: Colors.grey[200]!,
                              returnedColor: returnedC,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(IconData icon, String label, int count, Color color, int idx) {
    final sel = _selected == idx;
    return GestureDetector(
      onTap: () => _jump(idx),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sel ? color.withOpacity(0.2) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 28, color: sel ? color : Colors.grey[600]),
                if (count > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: 12,
              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              color: sel ? color : Colors.grey[600],
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }

  void _cancelReq(String key) {
    showDialog(
      context: context,
      builder: (_) => ConfirmCancelDialog(
        primaryColor: primary,
        cardGradientStart: bg,
        cardGradientEnd: Colors.grey[200]!,
        errorColor: error,
        onConfirm: () => deleteBorrowRequest(key),
      ),
    );
  }

  void _showItem(Item item) {
    showDialog(
      context: context,
      builder: (_) => ViewItemPage(
        item: item,
        primaryColor: primary,
        accentColor: accent,
        cardGradientStart: bg,
        cardGradientEnd: Colors.grey[200]!,
      ),
    );
  }
}
