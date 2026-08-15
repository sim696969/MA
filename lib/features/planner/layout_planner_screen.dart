import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/database_service.dart';

// ─────────────────────────────────────────────
//  Models
// ─────────────────────────────────────────────

class PlannerTool {
  final String name;
  final IconData icon;
  final Color color;

  const PlannerTool({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class PlannerItem {
  final String id;
  final PlannerTool tool;
  Offset position;
  bool isLocked;

  PlannerItem({
    required this.id,
    required this.tool,
    required this.position,
    this.isLocked = false,
  });
}

// ─────────────────────────────────────────────
//  Screen
// ─────────────────────────────────────────────

class LayoutPlannerScreen extends StatefulWidget {
  const LayoutPlannerScreen({super.key});

  @override
  State<LayoutPlannerScreen> createState() => _LayoutPlannerScreenState();
}

class _LayoutPlannerScreenState extends State<LayoutPlannerScreen>
    with TickerProviderStateMixin {
  // ── Services ──────────────────────────────
  final DatabaseService _dbService = DatabaseService();

  // ── Canvas key for offset math ────────────
  final GlobalKey _canvasKey = GlobalKey();

  // ── State ─────────────────────────────────
  final List<PlannerItem> _workspaceItems = [];
  bool _isDockVisible = true;
  bool _isSaving = false;

  /// Non-null while a PLACED item is being dragged (shows trash zone).
  PlannerItem? _draggingItem;

  /// Tracks whether drag is hovering over trash zone.
  bool _isHoveringTrash = false;

  // ── Tool definitions ──────────────────────
  static const List<PlannerTool> _tools = [
    PlannerTool(
      name: 'Round\nTable',
      icon: Icons.circle_outlined,
      color: Color(0xFF5B8DEF),
    ),
    PlannerTool(
      name: 'Rect\nTable',
      icon: Icons.rectangle_outlined,
      color: Color(0xFF43C59E),
    ),
    PlannerTool(
      name: 'Stage',
      icon: Icons.view_compact_outlined,
      color: Color(0xFFFF9645),
    ),
    PlannerTool(
      name: 'Floral\nArch',
      icon: Icons.filter_vintage_outlined,
      color: Color(0xFFE879A0),
    ),
  ];

  // ── Dock height ───────────────────────────
  static const double _dockCollapsedHeight = 0;
  static const double _dockExpandedHeight = 136;

  // ─────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────

  String _uniqueId() => UniqueKey().toString();

  /// Convert a global screen offset to a local position within the canvas.
  Offset _toCanvasLocal(Offset globalOffset) {
    final RenderBox? box =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return globalOffset;
    return box.globalToLocal(globalOffset);
  }

  @override
  void initState() {
    super.initState();
    _loadLayoutFromFirebase();
  }

  Future<void> _loadLayoutFromFirebase() async {
    try {
      final doc = await _dbService.getDocument(
        collectionPath: 'layouts',
        docId: 'main_layout',
      );
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['items'] != null && data['items'] is List) {
          final List rawItems = data['items'] as List;
          final loadedItems = <PlannerItem>[];
          for (var itemMap in rawItems) {
            if (itemMap is Map) {
              final toolName = itemMap['name'] as String?;
              final tool = _tools.firstWhere(
                (t) => t.name == toolName,
                orElse: () => _tools.first,
              );
              final dx = (itemMap['dx'] as num?)?.toDouble() ?? 100.0;
              final dy = (itemMap['dy'] as num?)?.toDouble() ?? 100.0;
              final isLocked = (itemMap['isLocked'] as bool?) ?? false;

              loadedItems.add(PlannerItem(
                id: _uniqueId(),
                tool: tool,
                position: Offset(dx, dy),
                isLocked: isLocked,
              ));
            }
          }
          if (mounted) {
            setState(() {
              _workspaceItems.clear();
              _workspaceItems.addAll(loadedItems);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading layout: $e');
    }
  }

  void _addItemFromTool(PlannerTool tool, Offset globalOffset) {
    final localPos = _toCanvasLocal(globalOffset);
    setState(() {
      _workspaceItems.add(PlannerItem(
        id: _uniqueId(),
        tool: tool,
        position: localPos,
      ));
    });
    _autoSaveLayout();
  }

  void _moveItem(PlannerItem item, Offset globalOffset) {
    if (item.isLocked) return;
    final localPos = _toCanvasLocal(globalOffset);
    setState(() {
      item.position = localPos;
    });
    _autoSaveLayout();
  }

  void _deleteItem(PlannerItem item) {
    setState(() {
      _workspaceItems.removeWhere((e) => e.id == item.id);
      if (_draggingItem?.id == item.id) _draggingItem = null;
      _isHoveringTrash = false;
    });
    _autoSaveLayout();
  }

  void _duplicateItem(PlannerItem item) {
    setState(() {
      _workspaceItems.add(PlannerItem(
        id: _uniqueId(),
        tool: item.tool,
        position: Offset(item.position.dx + 25, item.position.dy + 25),
        isLocked: false,
      ));
    });
    _autoSaveLayout();
  }

  void _toggleLockItem(PlannerItem item) {
    setState(() {
      item.isLocked = !item.isLocked;
    });
    _autoSaveLayout();
  }

  Future<void> _autoSaveLayout() async {
    try {
      final itemsData = _workspaceItems
          .map((item) => {
                'name': item.tool.name,
                'dx': item.position.dx,
                'dy': item.position.dy,
                'isLocked': item.isLocked,
              })
          .toList();

      await _dbService.saveLayoutItems(
        layoutId: 'main_layout',
        items: itemsData,
      );
    } catch (e) {
      debugPrint('Auto-save error: $e');
    }
  }

  void _toggleDock() {
    setState(() => _isDockVisible = !_isDockVisible);
  }

  // ─────────────────────────────────────────
  //  Firestore save (Manual Trigger)
  // ─────────────────────────────────────────

  Future<void> _saveLayout() async {
    setState(() => _isSaving = true);
    try {
      final itemsData = _workspaceItems
          .map((item) => {
                'name': item.tool.name,
                'dx': item.position.dx,
                'dy': item.position.dy,
                'isLocked': item.isLocked,
              })
          .toList();

      await _dbService.saveLayoutItems(
        layoutId: 'main_layout',
        items: itemsData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Layout saved!',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: const Color(0xFF43C59E),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─────────────────────────────────────────
  //  Item context menu (Long press & Right Click)
  // ─────────────────────────────────────────

  void _showItemContextMenu(BuildContext context, PlannerItem item,
      Offset tapPosition) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        tapPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      items: [
        PopupMenuItem<String>(
          value: 'lock',
          child: Row(
            children: [
              Icon(
                item.isLocked
                    ? Icons.lock_open_rounded
                    : Icons.lock_outline_rounded,
                color: const Color(0xFF5B8DEF),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                item.isLocked ? 'Unlock Position' : 'Lock Position',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'duplicate',
          child: Row(
            children: [
              const Icon(Icons.copy_rounded,
                  color: Color(0xFF43C59E), size: 20),
              const SizedBox(width: 10),
              Text(
                'Duplicate',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline, color: Colors.redAccent,
                  size: 20),
              const SizedBox(width: 10),
              Text('Remove',
                  style: GoogleFonts.inter(
                      color: Colors.redAccent, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );

    if (result == 'lock') {
      _toggleLockItem(item);
    } else if (result == 'duplicate') {
      _duplicateItem(item);
    } else if (result == 'delete') {
      _deleteItem(item);
    }
  }

  // ─────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isDraggingPlacedItem = _draggingItem != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // ── 1. Full-screen canvas ─────────
          _buildCanvas(),

          // ── 2. Trash zone (slides in when dragging a placed item) ──
          AnimatedSlide(
            offset: isDraggingPlacedItem ? Offset.zero : const Offset(0, -1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: isDraggingPlacedItem ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: _buildTrashZone(),
            ),
          ),

          // ── 3. Bottom dock ────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomDock(),
          ),

          // ── 4. Dock toggle FAB-style handle ──
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: _isDockVisible
                ? _dockExpandedHeight
                : _dockCollapsedHeight,
            child: _buildDockHandle(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  //  AppBar
  // ─────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A1A2E), size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2D Layout Planner',
            style: GoogleFonts.inter(
              color: const Color(0xFF1A1A2E),
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          Text(
            '${_workspaceItems.length} item${_workspaceItems.length == 1 ? '' : 's'} placed',
            style: GoogleFonts.inter(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined,
              color: Color(0xFF1A1A2E)),
          tooltip: 'Clear All',
          onPressed: _workspaceItems.isEmpty
              ? null
              : () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: Text('Clear Canvas',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700)),
                      content: Text('Remove all placed items?',
                          style: GoogleFonts.inter()),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel')),
                        TextButton(
                          onPressed: () {
                            setState(() => _workspaceItems.clear());
                            Navigator.pop(ctx);
                          },
                          child: const Text('Clear',
                              style:
                                  TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF5B8DEF)))
                : const Icon(Icons.save_rounded,
                    color: Color(0xFF5B8DEF)),
            tooltip: 'Save Layout',
            onPressed: _isSaving ? null : _saveLayout,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  //  Canvas
  // ─────────────────────────────────────────

  Widget _buildCanvas() {
    return Positioned.fill(
      child: DragTarget<PlannerTool>(
        onAcceptWithDetails: (details) {
          _addItemFromTool(details.data, details.offset);
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return DragTarget<PlannerItem>(
            onAcceptWithDetails: (details) {
              _moveItem(details.data, details.offset);
            },
            builder: (context, itemCandidateData, itemRejectedData) {
              return Stack(
                key: _canvasKey,
                children: [
                  // Grid background
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GridPainter(
                        lineColor: const Color(0xFFDDE3EE),
                        highlightColor: (isHovering || itemCandidateData.isNotEmpty)
                            ? const Color(0xFF5B8DEF).withValues(alpha: 0.06)
                            : null,
                      ),
                    ),
                  ),

                  // Empty state hint
                  if (_workspaceItems.isEmpty)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.drag_indicator_rounded,
                              size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            'Drag items from the\nbottom dock to start',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.grey[400],
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Placed items
                  ..._workspaceItems.map((item) => _buildPlacedItemWidget(item)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────
  //  Placed item widget
  // ─────────────────────────────────────────

  Widget _buildPlacedItemWidget(PlannerItem item) {
    const double itemSize = 56;

    final itemWidget = GestureDetector(
      onLongPressStart: (details) {
        _showItemContextMenu(context, item, details.globalPosition);
      },
      onSecondaryTapUp: (details) {
        _showItemContextMenu(context, item, details.globalPosition);
      },
      child: _ItemChip(
        tool: item.tool,
        size: itemSize,
        isLocked: item.isLocked,
      ),
    );

    return Positioned(
      left: item.position.dx - itemSize / 2,
      top: item.position.dy - itemSize / 2,
      child: item.isLocked
          ? itemWidget
          : Draggable<PlannerItem>(
              data: item,
              onDragStarted: () {
                setState(() {
                  _draggingItem = item;
                  _isHoveringTrash = false;
                });
              },
              onDragEnd: (details) {
                if (!details.wasAccepted) {
                  _moveItem(item, details.offset);
                }
                setState(() {
                  _draggingItem = null;
                  _isHoveringTrash = false;
                });
              },
              feedback: Material(
                color: Colors.transparent,
                child: _ItemChip(
                  tool: item.tool,
                  size: itemSize,
                  isDragging: true,
                  isLocked: item.isLocked,
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.25,
                child: _ItemChip(
                  tool: item.tool,
                  size: itemSize,
                  isLocked: item.isLocked,
                ),
              ),
              child: itemWidget,
            ),
    );
  }

  // ─────────────────────────────────────────
  //  Trash zone
  // ─────────────────────────────────────────

  Widget _buildTrashZone() {
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: DragTarget<PlannerItem>(
            onWillAcceptWithDetails: (_) {
              setState(() => _isHoveringTrash = true);
              return true;
            },
            onLeave: (_) => setState(() => _isHoveringTrash = false),
            onAcceptWithDetails: (details) => _deleteItem(details.data),
            builder: (context, candidateData, _) {
              final bool hovering = _isHoveringTrash;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 160,
                height: 60,
                decoration: BoxDecoration(
                  color: hovering
                      ? Colors.redAccent
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: hovering
                        ? Colors.redAccent
                        : Colors.red[200]!,
                    width: hovering ? 0 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.2),
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_rounded,
                      color: hovering ? Colors.white : Colors.redAccent,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Drop to delete',
                      style: GoogleFonts.inter(
                        color: hovering ? Colors.white : Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  //  Canvas drop target for moving placed items
  // ─────────────────────────────────────────
  // NOTE: The LongPressDraggable's onDragEnd handles repositioning via
  // `details.offset` when not accepted by trash. No extra DragTarget needed
  // for movement — the ghost stays and the item moves on drag end.

  // ─────────────────────────────────────────
  //  Dock handle
  // ─────────────────────────────────────────

  Widget _buildDockHandle() {
    return GestureDetector(
      onTap: _toggleDock,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -200 && !_isDockVisible) {
            _toggleDock(); // swipe up → expand
          } else if (details.primaryVelocity! > 200 && _isDockVisible) {
            _toggleDock(); // swipe down → collapse
          }
        }
      },
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedRotation(
                turns: _isDockVisible ? 0.0 : -0.5,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20, color: Color(0xFF5B8DEF)),
              ),
              const SizedBox(width: 6),
              Text(
                _isDockVisible ? 'Hide Tools' : 'Show Tools',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5B8DEF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  //  Bottom dock
  // ─────────────────────────────────────────

  Widget _buildBottomDock() {
    return AnimatedSlide(
      offset:
          _isDockVisible ? Offset.zero : const Offset(0, 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _isDockVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 280),
        child: Container(
          height: _dockExpandedHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag pill indicator
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Tool chips
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _tools
                        .map((tool) => _buildDockToolChip(tool))
                        .toList(),
                  ),
                ),
              ),
              // Safe area padding
              SizedBox(
                  height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  //  Dock tool chip (Draggable)
  // ─────────────────────────────────────────

  Widget _buildDockToolChip(PlannerTool tool) {
    return Draggable<PlannerTool>(
      data: tool,
      onDragStarted: () {
        // Auto-collapse dock when user starts dragging
        if (_isDockVisible) setState(() => _isDockVisible = false);
      },
      onDragCompleted: () => setState(() => _isDockVisible = true),
      onDraggableCanceled: (_, __) => setState(() => _isDockVisible = true),
      feedback: Material(
        color: Colors.transparent,
        child: _ToolChip(tool: tool, isDragging: true),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _ToolChip(tool: tool),
      ),
      child: _ToolChip(tool: tool),
    );
  }
}

// ─────────────────────────────────────────────
//  Reusable chip widgets
// ─────────────────────────────────────────────

class _ToolChip extends StatelessWidget {
  final PlannerTool tool;
  final bool isDragging;

  const _ToolChip({required this.tool, this.isDragging = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isDragging ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: tool.color.withValues(alpha: isDragging ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      tool.color.withValues(alpha: isDragging ? 0.8 : 0.25),
                  width: isDragging ? 2 : 1,
                ),
                boxShadow: isDragging
                    ? [
                        BoxShadow(
                          color: tool.color.withValues(alpha: 0.35),
                          blurRadius: 16,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: Icon(tool.icon, color: tool.color, size: 26),
            ),
            const SizedBox(height: 5),
            Text(
              tool.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF4A5568),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  final PlannerTool tool;
  final double size;
  final bool isDragging;
  final bool isLocked;

  const _ItemChip({
    required this.tool,
    this.size = 56,
    this.isDragging = false,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRound = tool.name.contains('Round');
    return AnimatedScale(
      scale: isDragging ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: tool.color.withValues(alpha: isDragging ? 0.25 : 0.15),
              borderRadius: BorderRadius.circular(isRound ? size : 10),
              border: Border.all(
                color: tool.color.withValues(alpha: isDragging ? 0.9 : 0.5),
                width: isDragging ? 2.5 : 1.5,
              ),
              boxShadow: isDragging
                  ? [
                      BoxShadow(
                        color: tool.color.withValues(alpha: 0.40),
                        blurRadius: 20,
                        spreadRadius: 3,
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Icon(tool.icon, color: tool.color, size: size * 0.45),
          ),
          if (isLocked)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Color(0xFF5B8DEF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Grid Painter
// ─────────────────────────────────────────────

class GridPainter extends CustomPainter {
  final Color lineColor;
  final Color? highlightColor;

  const GridPainter({
    this.lineColor = const Color(0xFFDDE3EE),
    this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Highlight overlay when hovering
    if (highlightColor != null) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = highlightColor!,
      );
    }

    // Minor grid (20px)
    final minorPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    const double step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorPaint);
    }

    // Major grid (100px)
    final majorPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += 100) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), majorPaint);
    }
    for (double y = 0; y < size.height; y += 100) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), majorPaint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor ||
      oldDelegate.highlightColor != highlightColor;
}
