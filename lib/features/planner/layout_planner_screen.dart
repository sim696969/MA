import 'package:flutter/material.dart';
import '../../widgets/wedify_card.dart';

class LayoutPlannerScreen extends StatefulWidget {
  const LayoutPlannerScreen({super.key});

  @override
  State<LayoutPlannerScreen> createState() => _LayoutPlannerScreenState();
}

class _LayoutPlannerScreenState extends State<LayoutPlannerScreen> {
  final List<PlannerItem> _workspaceItems = [];

  final List<PlannerTool> _tools = [
    PlannerTool(name: "Round Table", icon: Icons.circle_outlined, color: Colors.blue),
    PlannerTool(name: "Rect Table", icon: Icons.rectangle_outlined, color: Colors.green),
    PlannerTool(name: "Stage", icon: Icons.view_compact_outlined, color: Colors.orange),
    PlannerTool(name: "Floral Arch", icon: Icons.filter_vintage_outlined, color: Colors.pink),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("2D Layout Planner"),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: () {}),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Tools
          Container(
            width: 100,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: _tools.length,
              itemBuilder: (context, index) {
                return Draggable<PlannerTool>(
                  data: _tools[index],
                  feedback: Material(
                    color: Colors.transparent,
                    child: _buildToolIcon(_tools[index], isDragging: true),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.5,
                    child: _buildToolIcon(_tools[index]),
                  ),
                  child: _buildToolIcon(_tools[index]),
                );
              },
            ),
          ),
          // Canvas
          Expanded(
            child: DragTarget<PlannerTool>(
              onAcceptWithDetails: (details) {
                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                final localOffset = renderBox.globalToLocal(details.offset);
                setState(() {
                  _workspaceItems.add(PlannerItem(
                    tool: details.data,
                    position: localOffset,
                  ));
                });
              },
              builder: (context, candidateData, rejectedData) {
                return Stack(
                  children: [
                    // Grid background
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GridPainter(),
                      ),
                    ),
                    if (_workspaceItems.isEmpty)
                      const Center(
                        child: Text("Drag items here to start planning", style: TextStyle(color: Colors.grey)),
                      ),
                    ..._workspaceItems.map((item) => Positioned(
                      left: item.position.dx - 100, // Adjust for sidebar
                      top: item.position.dy - 56, // Adjust for appbar
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            item.position += details.delta;
                          });
                        },
                        onTap: () => _showItemInspector(item),
                        child: _buildPlacedItem(item),
                      ),
                    )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolIcon(PlannerTool tool, {bool isDragging = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tool.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tool.color.withOpacity(0.3)),
            ),
            child: Icon(tool.icon, color: tool.color),
          ),
          const SizedBox(height: 4),
          Text(tool.name, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPlacedItem(PlannerItem item) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: item.tool.color.withOpacity(0.2),
        border: Border.all(color: item.tool.color),
        borderRadius: BorderRadius.circular(item.tool.name.contains("Round") ? 100 : 4),
      ),
      child: Icon(item.tool.icon, color: item.tool.color),
    );
  }

  void _showItemInspector(PlannerItem item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Edit ${item.tool.name}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: "Name / Table Number")),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: "Guest Assignments")),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() => _workspaceItems.remove(item));
                      Navigator.pop(context);
                    },
                    child: const Text("Delete", style: TextStyle(color: Colors.red)),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Apply"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PlannerTool {
  final String name;
  final IconData icon;
  final Color color;

  PlannerTool({required this.name, required this.icon, required this.color});
}

class PlannerItem {
  final PlannerTool tool;
  Offset position;

  PlannerItem({required this.tool, required this.position});
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;

    const step = 20.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
