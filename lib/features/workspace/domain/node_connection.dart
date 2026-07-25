import 'dart:ui' show Offset;

class NodeConnection {
  final String id;
  final String sourceNodeId;
  final String sourcePortId;
  final String targetNodeId;
  final String targetPortId;
  final String? label;

  const NodeConnection({
    required this.id,
    required this.sourceNodeId,
    required this.sourcePortId,
    required this.targetNodeId,
    required this.targetPortId,
    this.label,
  });

  Offset? get sourceOffset => null;
  Offset? get targetOffset => null;

  NodeConnection copyWith({
    String? id,
    String? sourceNodeId,
    String? sourcePortId,
    String? targetNodeId,
    String? targetPortId,
    String? label,
  }) =>
      NodeConnection(
        id: id ?? this.id,
        sourceNodeId: sourceNodeId ?? this.sourceNodeId,
        sourcePortId: sourcePortId ?? this.sourcePortId,
        targetNodeId: targetNodeId ?? this.targetNodeId,
        targetPortId: targetPortId ?? this.targetPortId,
        label: label ?? this.label,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceNodeId': sourceNodeId,
        'sourcePortId': sourcePortId,
        'targetNodeId': targetNodeId,
        'targetPortId': targetPortId,
        if (label != null) 'label': label,
      };

  factory NodeConnection.fromJson(Map<String, dynamic> json) => NodeConnection(
        id: json['id'] as String,
        sourceNodeId: json['sourceNodeId'] as String,
        sourcePortId: json['sourcePortId'] as String,
        targetNodeId: json['targetNodeId'] as String,
        targetPortId: json['targetPortId'] as String,
        label: json['label'] as String?,
      );
}
