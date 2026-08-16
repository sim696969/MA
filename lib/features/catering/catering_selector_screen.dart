import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/catering_order_model.dart';
import '../../services/catering_cart_provider.dart';
import '../../services/database_service.dart';
import '../../services/wedding_project_provider.dart';
import 'checkout_screen.dart';

class CateringSelectorScreen extends ConsumerStatefulWidget {
  const CateringSelectorScreen({super.key});

  @override
  ConsumerState<CateringSelectorScreen> createState() =>
      _CateringSelectorScreenState();
}

class _CateringSelectorScreenState
    extends ConsumerState<CateringSelectorScreen> {
  final DatabaseService _dbService = DatabaseService();
  String _selectedCategory = "Chinese Cuisine";
  bool _isLoadingOrder = false;

  /// Snapshot of the cart as loaded from Firestore (or empty if no prior order).
  /// Used to detect whether the user actually changed anything before leaving.
  Map<String, int> _initialCartSnapshot = {};

  final List<String> _categories = const ["Chinese Cuisine", "Western Food"];

  bool _isNewEmptyProject() {
    final project = ref.read(weddingProjectProvider);
    return !project.isInitialized;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingProjectOrder();
    });
  }

  /// Query Firebase Firestore for existing catering orders linked to this project.
  /// After loading, snapshots the initial state so hasCartChanged() can compare.
  Future<void> _loadExistingProjectOrder() async {
    // Brand new / canceled project → start with an empty cart, no Firestore load.
    // Prevents stale previous catering items from appearing in a fresh booking.
    if (_isNewEmptyProject()) {
      ref.read(cateringCartProvider.notifier).clearCart();
      if (mounted) {
        setState(() {
          _initialCartSnapshot = {};
          _isLoadingOrder = false;
        });
      }
      return;
    }

    final cart = ref.read(cateringCartProvider);
    if (cart.isNotEmpty) {
      // Cart was already populated in memory — treat it as the baseline
      _initialCartSnapshot = Map<String, int>.from(cart);
      return;
    }

    final projectId = ref
        .read(weddingProjectProvider.notifier)
        .firestoreProjectDocId;

    setState(() => _isLoadingOrder = true);
    try {
      final existingOrder = await _dbService.getLatestCateringOrder(
        projectId: projectId,
      );
      if (existingOrder != null && existingOrder.items.isNotEmpty && mounted) {
        ref
            .read(cateringCartProvider.notifier)
            .loadExistingOrder(existingOrder.items);
      }
    } catch (_) {
      // Offline fallback — snapshot stays empty, which is fine
    } finally {
      if (mounted) {
        // Snapshot whatever ended up in the cart right after load
        _initialCartSnapshot = Map<String, int>.from(
          ref.read(cateringCartProvider),
        );
        setState(() => _isLoadingOrder = false);
      }
    }
  }

  // ── Back-navigation guard ──────────────────────────────────────────────────

  /// Deep comparison: returns true only if the user changed item quantities
  /// or added/removed items compared to what was loaded from Firestore.
  bool _hasCartChanged() {
    final current = ref.read(cateringCartProvider);

    // Different number of distinct items → definitely changed
    if (current.length != _initialCartSnapshot.length) return true;

    // Check every entry: same keys and same quantities
    for (final entry in current.entries) {
      final snapshotQty = _initialCartSnapshot[entry.key];
      if (snapshotQty == null || snapshotQty != entry.value) return true;
    }
    return false;
  }

  /// Shows the "Save Your Order?" dialog only when the cart has actually
  /// changed since the page was opened. Otherwise pops immediately.
  Future<void> _showBackDialog() async {
    if (!_hasCartChanged()) {
      Navigator.of(context).pop();
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.save_alt_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Save Your Order?",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          "You have unsaved items in your catering cart. Would you like to save your progress before leaving?",
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        actions: [
          // ── Horizontal button row: [Discard]  ···  [Cancel] [Save & Exit] ──
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                // Far-left: Discard (subtle, muted)
                TextButton(
                  onPressed: () async {
                    Navigator.of(dialogCtx).pop();
                    ref.read(cateringCartProvider.notifier).clearCart();
                    _initialCartSnapshot = {};
                    await ref
                        .read(weddingProjectProvider.notifier)
                        .updateCatering(
                          cateringPackage: 'No items selected',
                          fee: 0.0,
                          isCompleted: false,
                        );
                    if (mounted) {
                      Navigator.of(context).pop(<String, dynamic>{
                        'cateringPackage': 'No items selected',
                        'fee': 0.0,
                      });
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black45,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    "Discard",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black45,
                    ),
                  ),
                ),

                const Spacer(),

                // Right group: Cancel + Save & Exit
                OutlinedButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black, width: 1.5),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(dialogCtx).pop();
                    final project = ref.read(weddingProjectProvider);
                    final projectId = project.id.isNotEmpty
                        ? project.id
                        : 'project_1';
                    final notifier = ref.read(cateringCartProvider.notifier);
                    final totalAmount = notifier.calculateTotal();
                    final orderedItems = notifier.getOrderedItemsList();
                    final categories = orderedItems
                        .map((e) => e['category'] as String)
                        .toSet()
                        .toList();
                    final categorySummary = categories.join(' & ');
                    final summary = orderedItems.isNotEmpty
                        ? "${orderedItems.length} items ($categorySummary)"
                        : "No items selected";
                    try {
                      final order = CateringOrderModel(
                        orderId: '',
                        category: categorySummary,
                        additionalNotes: '',
                        items: orderedItems
                            .map((m) => Map<String, dynamic>.from(m))
                            .toList(),
                        totalAmount: totalAmount,
                        createdAt: DateTime.now(),
                      );
                      await _dbService.saveCateringOrder(
                        projectId: projectId,
                        order: order,
                      );
                    } catch (_) {
                      // Silently fail — data stays in provider
                    }
                    await ref
                        .read(weddingProjectProvider.notifier)
                        .updateCatering(
                          cateringPackage: summary,
                          fee: totalAmount,
                          isCompleted: orderedItems.isNotEmpty,
                        );
                    if (mounted) {
                      Navigator.of(context).pop(<String, dynamic>{
                        'cateringPackage': summary,
                        'fee': totalAmount,
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Save & Exit",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Item removal confirmation ───────────────────────────────────────────────

  /// Shows "Remove Item?" confirmation before deleting [itemName] from cart.
  Future<void> _showRemoveItemDialog({
    required BuildContext sheetContext,
    required CateringCartNotifier cartNotifier,
    required String itemId,
    required String itemName,
  }) async {
    await showDialog<void>(
      context: sheetContext,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Remove Item?",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.black87,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: "Are you sure you want to remove "),
              TextSpan(
                text: itemName,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const TextSpan(text: " from your order?"),
            ],
          ),
        ),
        actions: [
          // Cancel
          OutlinedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.black, width: 1.5),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.black,
              ),
            ),
          ),
          // Remove — bold red warning text on white button
          ElevatedButton(
            onPressed: () {
              cartNotifier.removeItem(itemId);
              Navigator.of(dialogCtx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.redAccent,
              elevation: 0,
              side: const BorderSide(color: Colors.redAccent, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Remove",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCurrentOrderBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Colors.black, width: 2),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            ref.watch(cateringCartProvider); // watch for reactive rebuilds
            final cartNotifier = ref.read(cateringCartProvider.notifier);
            final orderedItems = cartNotifier.getOrderedItemsList();
            final totalAmount = cartNotifier.calculateTotal();
            final totalCount = cartNotifier.totalItemsCount;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "CURRENT ORDER ($totalCount)",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.black, thickness: 1.5),
                  const SizedBox(height: 10),

                  if (orderedItems.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.remove_shopping_cart_outlined,
                              size: 48,
                              color: Colors.black54,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Your cart is empty",
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Add items from the menu to see them here.",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: orderedItems.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Colors.black12, height: 20),
                        itemBuilder: (context, index) {
                          final item = orderedItems[index];
                          final itemId = item['id'] as String;
                          final qty = item['quantity'] as int;
                          final unitPrice = item['unitPrice'] as double;
                          final subtotal = item['subtotal'] as double;

                          return Row(
                            children: [
                              // Item Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${item['category']} • RM ${unitPrice.toStringAsFixed(2)} / ${item['unit']}",
                                      style: GoogleFonts.inter(
                                        color: Colors.black54,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Subtotal: RM ${subtotal.toStringAsFixed(2)}",
                                      style: GoogleFonts.inter(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quick Incremental Stepper in Modal
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAFAFA),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: () =>
                                          cartNotifier.decrement(itemId),
                                      borderRadius:
                                          const BorderRadius.horizontal(
                                            left: Radius.circular(6),
                                          ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(6.0),
                                        child: Icon(
                                          Icons.remove,
                                          size: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: const BoxDecoration(
                                        border: Border.symmetric(
                                          vertical: BorderSide(
                                            color: Colors.black,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        "$qty",
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () =>
                                          cartNotifier.increment(itemId),
                                      borderRadius:
                                          const BorderRadius.horizontal(
                                            right: Radius.circular(6),
                                          ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(6.0),
                                        child: Icon(
                                          Icons.add,
                                          size: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Trash / Remove Item Icon — with confirmation dialog
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 22,
                                ),
                                tooltip: "Remove item",
                                onPressed: () => _showRemoveItemDialog(
                                  sheetContext: context,
                                  cartNotifier: cartNotifier,
                                  itemId: itemId,
                                  itemName: item['name'] as String,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 12),
                  const Divider(color: Colors.black, thickness: 1.5),
                  const SizedBox(height: 8),

                  // Total Amount Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "TOTAL AMOUNT",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.5,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        "RM ${totalAmount.toStringAsFixed(2)}",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Clear Cart (moved inside bottom sheet)
                  if (orderedItems.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          cartNotifier.clearCart();
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.delete_sweep_outlined,
                          size: 16,
                          color: Colors.black,
                        ),
                        label: Text(
                          "CLEAR CART",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.8,
                            color: Colors.black,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.black,
                            width: 1.5,
                          ),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cateringCartProvider);
    final cartNotifier = ref.read(cateringCartProvider.notifier);
    final totalAmount = cartNotifier.calculateTotal();
    final totalItemsCount = cartNotifier.totalItemsCount;

    final filteredItems = kAllCateringMenuItems
        .where((item) => item.category == _selectedCategory)
        .toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showBackDialog();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 20,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.5),
            child: Container(color: AppColors.blush, height: 1.5),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _showBackDialog,
          ),
          title: Text(
            "F&B CATERING MENU",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 1.0,
            ),
          ),
        ),
        body: SafeArea(
          child: _isLoadingOrder
              ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.blush),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category Selector Header
                            _buildCategoryHeader(),
                            const SizedBox(height: 16),

                            // Primary Category Options (Two large monochrome buttons)
                            _buildCategoryTabs(),
                            const SizedBox(height: 24),

                            // Section Title
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedCategory.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  "${filteredItems.length} Items Available",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Colors.black, thickness: 1.5),
                            const SizedBox(height: 16),

                            // Itemized Food Menu Cards
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredItems.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                final qty = cartState[item.id] ?? 0;
                                return _buildFoodItemCard(
                                  item,
                                  qty,
                                  cartNotifier,
                                );
                              },
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Sticky Checkout Bar
                    _buildBottomCheckoutBar(totalItemsCount, totalAmount),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pinkBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SELECT BANQUET CUISINE",
                  style: GoogleFonts.inter(
                    color: AppColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  "Choose category and adjust item quantities freely.",
                  style: GoogleFonts.inter(
                    color: AppColors.slate600,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Row(
      children: _categories.map((cat) {
        final isSelected = _selectedCategory == cat;
        final isFirst = cat == _categories.first;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: isFirst ? 6.0 : 0.0,
              left: !isFirst ? 6.0 : 0.0,
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.navy : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.navy : AppColors.pinkBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      cat == "Chinese Cuisine"
                          ? Icons.ramen_dining_outlined
                          : Icons.lunch_dining_outlined,
                      color: isSelected ? Colors.white : AppColors.navy,
                      size: 26,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.white : AppColors.navy,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFoodItemCard(
    CateringItem item,
    int quantity,
    CateringCartNotifier cartNotifier,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pinkBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Image Header
          Stack(
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(item.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                  color: AppColors.navy,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    "RM ${item.unitPrice.toStringAsFixed(2)} / ${item.unit}",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Content & Quantity Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: GoogleFonts.inter(
                    color: AppColors.charcoal,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.black12, thickness: 1),
                const SizedBox(height: 10),

                // Price and Quantity Selector Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SUBTOTAL",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          "RM ${(item.unitPrice * quantity).toStringAsFixed(2)}",
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),

                    // B&W Interactive Quantity Selector (With explicitly visible text & white background)
                    _buildQuantitySelector(item, quantity, cartNotifier),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(
    CateringItem item,
    int quantity,
    CateringCartNotifier cartNotifier,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pinkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement Button
          InkWell(
            onTap: () => cartNotifier.decrement(item.id),
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.pinkLight,
                border: Border(right: BorderSide(color: AppColors.pinkBorder)),
              ),
              child: const Icon(Icons.remove, size: 16, color: AppColors.navy),
            ),
          ),

          // Explicit White Background & Bold Black Text Input Field
          Container(
            width: 54,
            color: Colors.white,
            alignment: Alignment.center,
            child: _ItemQuantityInputField(
              initialValue: quantity,
              onChanged: (newQty) {
                cartNotifier.setQuantity(item.id, newQty);
              },
            ),
          ),

          // Increment Button
          InkWell(
            onTap: () => cartNotifier.increment(item.id),
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.blush,
                border: Border(left: BorderSide(color: AppColors.pinkBorder)),
              ),
              child: const Icon(Icons.add, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCheckoutBar(int totalItemsCount, double totalAmount) {
    final hasItems = totalItemsCount > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        border: Border(top: BorderSide(color: AppColors.navy)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1 — Cart label + VIEW ORDER button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "CART SUMMARY ($totalItemsCount ITEMS)",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Colors.white70,
                ),
              ),
              if (hasItems)
                SizedBox(
                  height: 30,
                  child: OutlinedButton(
                    onPressed: _showCurrentOrderBottomSheet,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      side: const BorderSide(color: Colors.white),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      "VIEW ORDER",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.8,
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),

          // Row 2 — Total price, full width left-aligned
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "RM ${totalAmount.toStringAsFixed(2)}",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Row 3 — Full-width PROCEED TO CHECKOUT button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: hasItems
                  ? () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CateringCheckoutScreen(),
                        ),
                      );
                      if (mounted && result != null) {
                        Navigator.of(context).pop(result);
                      }
                    }
                  : null,
              icon: const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.white,
                size: 20,
              ),
              label: Text(
                "PROCEED TO CHECKOUT",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blush,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[600],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper widget with explicitly styled white background and high-contrast black text
class _ItemQuantityInputField extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onChanged;

  const _ItemQuantityInputField({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_ItemQuantityInputField> createState() =>
      _ItemQuantityInputFieldState();
}

class _ItemQuantityInputFieldState extends State<_ItemQuantityInputField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toString());
  }

  @override
  void didUpdateWidget(covariant _ItemQuantityInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      if (_controller.text != widget.initialValue.toString()) {
        _controller.text = widget.initialValue.toString();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TextFormField(
        controller: _controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        cursorColor: Colors.black,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w900,
          fontSize: 15,
          color: const Color(0xFF000000), // Explicit Jet Black Text
        ),
        decoration: const InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white, // Explicit Pure White Input Fill
          contentPadding: EdgeInsets.symmetric(vertical: 8),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onChanged: (text) {
          final parsed = int.tryParse(text) ?? 0;
          widget.onChanged(parsed);
        },
      ),
    );
  }
}
