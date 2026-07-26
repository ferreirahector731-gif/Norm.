import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import '../../notes/domain/note_document_codec.dart';
import '../../notes/domain/note_model.dart';
import '../../notes/presentation/editor_blocks/audio_block.dart';
import '../../notes/presentation/editor_blocks/custom_block_keys.dart';
import '../../notes/presentation/editor_blocks/placeholder_block.dart';
import '../../../core/database/database_service.dart';
import 'painters/canvas_edge_painter.dart';
import 'painters/canvas_grid_painter.dart';

class CanvasNodeData {
  String id;
  double x;
  double y;
  double width;
  double height;
  String title;
  String documentJson;

  CanvasNodeData({
    required this.id,
    required this.x,
    required this.y,
    this.width = 260,
    this.height = 160,
    this.title = 'Nodo',
    String? documentJson,
  }) : documentJson = documentJson ?? NoteDocumentCodec.encode(EditorState.blank(withInitialText: true).document);

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'title': title,
        'documentJson': documentJson,
      };

  factory CanvasNodeData.fromJson(Map<String, dynamic> json) => CanvasNodeData(
        id: json['id'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num?)?.toDouble() ?? 260,
        height: (json['height'] as num?)?.toDouble() ?? 160,
        title: json['title'] as String? ?? 'Nodo',
        documentJson: json['documentJson'] as String?,
      );
}

class NodeConnection {
  final String id;
  final String sourceNodeId;
  final String targetNodeId;

  const NodeConnection({
    required this.id,
    required this.sourceNodeId,
    required this.targetNodeId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceNodeId': sourceNodeId,
        'targetNodeId': targetNodeId,
      };

  factory NodeConnection.fromJson(Map<String, dynamic> json) => NodeConnection(
        id: json['id'] as String,
        sourceNodeId: json['sourceNodeId'] as String,
        targetNodeId: json['targetNodeId'] as String,
      );
}

class InfiniteCanvasScreen extends StatefulWidget {
  final NoteModel note;

  const InfiniteCanvasScreen({super.key, required this.note});

  @override
  State<InfiniteCanvasScreen> createState() => _InfiniteCanvasScreenState();
}

class _InfiniteCanvasScreenState extends State<InfiniteCanvasScreen> {
  final TransformationController _transformCtrl = TransformationController();
  List<CanvasNodeData> _nodes = [];
  List<NodeConnection> _edges = [];
  Timer? _saveTimer;
  int _saveGen = 0;
  String? _connectingFrom;
  Offset? _dragEdgeTarget;

  @override
  void initState() {
    super.initState();
    _loadGraph();
    _resetTransform();
  }

  void _loadGraph() {
    try {
      final decoded = jsonDecode(widget.note.contentJson);
      if (decoded is Map) {
        if (decoded['nodes'] is List) {
          _nodes = (decoded['nodes'] as List)
              .map((e) => CanvasNodeData.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (decoded['edges'] is List) {
          _edges = (decoded['edges'] as List)
              .map((e) => NodeConnection.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    if (_nodes.isEmpty) {
      _nodes.add(CanvasNodeData(
        id: _nextId(),
        x: 100,
        y: 100,
        title: 'Nodo 1',
      ));
    }
  }

  String _nextId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _scheduleSave() {
    _saveGen++;
    final gen = _saveGen;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () async {
      if (gen != _saveGen) return;
      final data = jsonEncode({
        'nodes': _nodes.map((n) => n.toJson()).toList(),
        'edges': _edges.map((e) => e.toJson()).toList(),
      });
      widget.note.contentJson = data;
      widget.note.updatedAt = DateTime.now();
      widget.note.isDirty = true;
      await DatabaseService.saveNote(widget.note);
    });
  }

  void _resetTransform() {
    _transformCtrl.value = Matrix4.identity()..translate(100, 100);
  }

  void _addNode(Offset canvasPos) {
    setState(() {
      _nodes.add(CanvasNodeData(
        id: _nextId(),
        x: canvasPos.dx - 130,
        y: canvasPos.dy - 80,
        title: 'Nodo ${_nodes.length + 1}',
      ));
    });
    _scheduleSave();
  }

  void _updateNodePosition(String id, Offset pos) {
    final idx = _nodes.indexWhere((n) => n.id == id);
    if (idx < 0) return;
    _nodes[idx].x = pos.dx;
    _nodes[idx].y = pos.dy;
    _scheduleSave();
  }

  void _updateNodeSize(String id, double w, double h) {
    final idx = _nodes.indexWhere((n) => n.id == id);
    if (idx < 0) return;
    _nodes[idx].width = max(180, w);
    _nodes[idx].height = max(120, h);
    _scheduleSave();
  }

  void _updateNodeTitle(String id, String title) {
    final idx = _nodes.indexWhere((n) => n.id == id);
    if (idx < 0) return;
    _nodes[idx].title = title;
    _scheduleSave();
  }

  void _updateNodeDocument(String id, String docJson) {
    final idx = _nodes.indexWhere((n) => n.id == id);
    if (idx < 0) return;
    _nodes[idx].documentJson = docJson;
    _scheduleSave();
  }

  void _deleteNode(String id) {
    setState(() {
      _nodes.removeWhere((n) => n.id == id);
      _edges.removeWhere((e) => e.sourceNodeId == id || e.targetNodeId == id);
    });
    _scheduleSave();
  }

  void _startConnection(String nodeId) {
    setState(() {
      _connectingFrom = nodeId;
    });
  }

  void _finishConnection(String targetNodeId) {
    if (_connectingFrom == null || _connectingFrom == targetNodeId) {
      setState(() => _connectingFrom = null);
      return;
    }
    final exists = _edges.any((e) =>
        e.sourceNodeId == _connectingFrom && e.targetNodeId == targetNodeId);
    if (!exists) {
      setState(() {
        _edges.add(NodeConnection(
          id: _nextId(),
          sourceNodeId: _connectingFrom!,
          targetNodeId: targetNodeId,
        ));
        _connectingFrom = null;
      });
      _scheduleSave();
    } else {
      setState(() => _connectingFrom = null);
    }
  }

  void _cancelConnection() {
    setState(() => _connectingFrom = null);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _transformCtrl.dispose();
    super.dispose();
  }

  Offset _nodeOutputPos(CanvasNodeData node) {
    final matrix = _transformCtrl.value;
    final scale = matrix.getMaxScaleOnAxis();
    return Offset(
      (node.x + node.width / 2) * scale + matrix.getTranslation().x,
      (node.y + node.height) * scale + matrix.getTranslation().y,
    );
  }

  Offset _nodeInputPos(CanvasNodeData node) {
    final matrix = _transformCtrl.value;
    final scale = matrix.getMaxScaleOnAxis();
    return Offset(
      (node.x + node.width / 2) * scale + matrix.getTranslation().x,
      node.y * scale + matrix.getTranslation().y,
    );
  }

  Rect _computeViewportRect(Size screenSize) {
    const margin = 200.0;
    final matrix = _transformCtrl.value;
    final inverse = Matrix4.inverted(matrix);
    final topLeft = MatrixUtils.transformPoint(inverse, Offset.zero);
    final bottomRight =
        MatrixUtils.transformPoint(inverse, Offset(screenSize.width, screenSize.height));
    return Rect.fromLTRB(
      topLeft.dx - margin,
      topLeft.dy - margin,
      bottomRight.dx + margin,
      bottomRight.dy + margin,
    );
  }

  List<CanvasNodeData> _visibleNodes(Rect viewport) {
    return _nodes.where((n) {
      final rect = Rect.fromLTWH(n.x, n.y, n.width, n.height);
      return viewport.overlaps(rect);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Stack(
        children: [
          GestureDetector(
            onDoubleTapDown: (details) {
              if (_connectingFrom != null) {
                _cancelConnection();
                return;
              }
              final matrix = _transformCtrl.value;
              final inverse = Matrix4.inverted(matrix);
              final canvasPos =
                  MatrixUtils.transformPoint(inverse, details.localPosition);
              _addNode(canvasPos);
            },
            onTapDown: (_) {
              if (_connectingFrom != null) _cancelConnection();
            },
            child: InteractiveViewer(
              transformationController: _transformCtrl,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              minScale: 0.1,
              maxScale: 4.0,
                child: ListenableBuilder(
                listenable: _transformCtrl,
                builder: (context, _) {
                  final size = MediaQuery.of(context).size;
                  final viewport = _computeViewportRect(size);
                  final visible = _visibleNodes(viewport);

                  final edgeRenders = <EdgeRenderData>[];
                  for (final edge in _edges) {
                    final src =
                        _nodes.where((n) => n.id == edge.sourceNodeId).firstOrNull;
                    final tgt =
                        _nodes.where((n) => n.id == edge.targetNodeId).firstOrNull;
                    if (src != null && tgt != null) {
                      edgeRenders.add(EdgeRenderData(
                        id: edge.id,
                        source: _nodeOutputPos(src),
                        target: _nodeInputPos(tgt),
                      ));
                    }
                  }
                  if (_connectingFrom != null && _dragEdgeTarget != null) {
                    final src = _nodes
                        .where((n) => n.id == _connectingFrom)
                        .firstOrNull;
                    if (src != null) {
                      edgeRenders.add(EdgeRenderData(
                        id: '_drag',
                        source: _nodeOutputPos(src),
                        target: _dragEdgeTarget!,
                        color: const Color(0xFFA78BFA),
                      ));
                    }
                  }

                  return SizedBox(
                    width: 30000,
                    height: 30000,
                    child: CustomPaint(
                      painter: CanvasGridPainter(
                          transform: _transformCtrl.value),
                      foregroundPainter: CanvasEdgePainter(edges: edgeRenders),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: visible.map((node) {
                          return Positioned(
                            left: node.x,
                            top: node.y,
                            child: RepaintBoundary(
                              child: _NodeCard(
                                node: node,
                                isConnecting: _connectingFrom == node.id,
                                onCommitPosition: (pos) =>
                                    _updateNodePosition(node.id, pos),
                                onCommitSize: (w, h) =>
                                    _updateNodeSize(node.id, w, h),
                                onCommitTitle: (t) =>
                                    _updateNodeTitle(node.id, t),
                                onDocumentChanged: (doc) =>
                                    _updateNodeDocument(node.id, doc),
                                onDelete: () => _deleteNode(node.id),
                                onStartConnection: () =>
                                    _startConnection(node.id),
                                onFinishConnection: () =>
                                    _finishConnection(node.id),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_connectingFrom != null)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA78BFA).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Toca otro nodo para conectar',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: const Color(0xFF3B82F6),
        onPressed: () {
          final matrix = _transformCtrl.value;
          final center = MatrixUtils.transformPoint(
              Matrix4.inverted(matrix),
              MediaQuery.of(context).size / 2);
          _addNode(center);
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _NodeCard extends StatefulWidget {
  final CanvasNodeData node;
  final bool isConnecting;
  final ValueChanged<Offset> onCommitPosition;
  final void Function(double w, double h) onCommitSize;
  final ValueChanged<String> onCommitTitle;
  final ValueChanged<String> onDocumentChanged;
  final VoidCallback onDelete;
  final VoidCallback onStartConnection;
  final VoidCallback onFinishConnection;

  const _NodeCard({
    super.key,
    required this.node,
    required this.isConnecting,
    required this.onCommitPosition,
    required this.onCommitSize,
    required this.onCommitTitle,
    required this.onDocumentChanged,
    required this.onDelete,
    required this.onStartConnection,
    required this.onFinishConnection,
  });

  @override
  State<_NodeCard> createState() => _NodeCardState();
}

class _NodeCardState extends State<_NodeCard> {
  late TextEditingController _titleCtrl;
  late EditorState _editorState;
  Offset _dragOffset = Offset.zero;
  double _resizeDW = 0;
  double _resizeDH = 0;
  bool _showPorts = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.node.title);
    final document = NoteDocumentCodec.decode(widget.node.documentJson);
    _editorState = EditorState(document: document)
      ..transactionStream.listen((_) {
        _onDocChanged();
      });
  }

  @override
  void didUpdateWidget(_NodeCard old) {
    super.didUpdateWidget(old);
    if (old.node.id != widget.node.id) {
      _titleCtrl.text = widget.node.title;
      _dragOffset = Offset.zero;
      _resizeDW = 0;
      _resizeDH = 0;
      final document = NoteDocumentCodec.decode(widget.node.documentJson);
      _editorState.dispose();
      _editorState = EditorState(document: document)
        ..transactionStream.listen((_) {
          _onDocChanged();
        });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _editorState.dispose();
    super.dispose();
  }

  void _onDocChanged() {
    widget.onDocumentChanged(
        NoteDocumentCodec.encode(_editorState.document));
  }

  void _onDragEnd() {
    if (_dragOffset == Offset.zero) return;
    widget.onCommitPosition(widget.node.position + _dragOffset);
    setState(() => _dragOffset = Offset.zero);
  }

  void _onResizeEnd() {
    if (_resizeDW == 0 && _resizeDH == 0) return;
    widget.onCommitSize(
        widget.node.width + _resizeDW, widget.node.height + _resizeDH);
    setState(() {
      _resizeDW = 0;
      _resizeDH = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayW = max(180, widget.node.width + _resizeDW);
    final displayH = max(120, widget.node.height + _resizeDH);

    return Transform(
      transform: Matrix4.translationValues(_dragOffset.dx, _dragOffset.dy, 0),
      child: SizedBox(
        width: displayW,
        child: GestureDetector(
          onPanStart: (_) => setState(() => _showPorts = true),
          onPanUpdate: (details) {
            setState(() => _dragOffset += details.delta);
          },
          onPanEnd: (_) {
            _onDragEnd();
            setState(() => _showPorts = false);
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _showPorts = true),
            onExit: (_) => setState(() => _showPorts = false),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: displayW,
                  decoration: BoxDecoration(
                    color: widget.isConnecting
                        ? const Color(0xFFA78BFA).withOpacity(0.15)
                        : const Color(0xFF131B2E).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isConnecting
                          ? const Color(0xFFA78BFA)
                          : Colors.white.withOpacity(0.10),
                      width: widget.isConnecting ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.isConnecting
                            ? const Color(0xFFA78BFA).withOpacity(0.2)
                            : Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      const Divider(
                          height: 1,
                          color: Colors.white10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          child: AppFlowyEditor(
                            editorState: _editorState,
                            blockComponentBuilders: {
                              ...standardBlockComponentBuilderMap,
                              ImagePlaceholderKeys.type:
                                  PlaceholderBlockComponentBuilder(
                                blockType: ImagePlaceholderKeys.type,
                                iconData: Icons.image_outlined,
                                label: 'Imagen',
                              ),
                              VideoPlaceholderKeys.type:
                                  PlaceholderBlockComponentBuilder(
                                blockType: VideoPlaceholderKeys.type,
                                iconData: Icons.videocam_outlined,
                                label: 'Video',
                              ),
                              AudioBlockKeys.type:
                                  AudioBlockComponentBuilder(),
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showPorts) ...[
                  Positioned(
                    top: -6,
                    left: displayW / 2 - 6,
                    child: GestureDetector(
                      onTap: widget.onFinishConnection,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -6,
                    left: displayW / 2 - 6,
                    child: GestureDetector(
                      onTap: widget.onStartConnection,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ),
                ],
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: widget.onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.close,
                          size: 12, color: Colors.white70),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onPanStart: (_) => setState(() {}),
                    onPanUpdate: (details) {
                      setState(() {
                        _resizeDW += details.delta.dx;
                        _resizeDH += details.delta.dy;
                      });
                    },
                    onPanEnd: (_) => _onResizeEnd(),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.8),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(12),
                          topLeft: Radius.circular(4),
                        ),
                      ),
                      child: const Icon(Icons.drag_handle,
                          size: 10, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _titleCtrl,
              style: const TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) => widget.onCommitTitle(v),
            ),
          ),
        ],
      ),
    );
  }
}

extension on CanvasNodeData {
  Offset get position => Offset(x, y);
}
