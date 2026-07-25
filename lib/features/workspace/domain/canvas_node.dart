import 'dart:ui' show Offset;

class NodePort {
  final String id;
  final String label;
  final bool isInput;

  const NodePort({required this.id, required this.label, required this.isInput});

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'isInput': isInput};

  factory NodePort.fromJson(Map<String, dynamic> json) => NodePort(
        id: json['id'] as String,
        label: json['label'] as String,
        isInput: json['isInput'] as bool? ?? true,
      );
}

abstract class CanvasNode {
  String get id;
  String get type;
  String get label;
  Offset get position;
  List<NodePort> get inputs;
  List<NodePort> get outputs;
  Map<String, dynamic> get properties;

  CanvasNode copyWith({
    String? id,
    String? label,
    Offset? position,
    Map<String, dynamic>? properties,
  });

  Map<String, dynamic> toJson();

  static CanvasNode fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final registry = _NodeRegistryInternal.instance;
    final factory = registry.getFactory(type);
    if (factory != null) return factory(json);
    return GenericCanvasNode.fromJson(json);
  }
}

class GenericCanvasNode extends CanvasNode {
  @override
  final String id;
  @override
  final String type;
  @override
  final String label;
  @override
  final Offset position;
  @override
  final List<NodePort> inputs;
  @override
  final List<NodePort> outputs;
  @override
  final Map<String, dynamic> properties;

  const GenericCanvasNode({
    required this.id,
    required this.type,
    required this.label,
    this.position = Offset.zero,
    this.inputs = const [],
    this.outputs = const [],
    this.properties = const {},
  });

  @override
  GenericCanvasNode copyWith({
    String? id,
    String? label,
    Offset? position,
    Map<String, dynamic>? properties,
  }) =>
      GenericCanvasNode(
        id: id ?? this.id,
        type: type,
        label: label ?? this.label,
        position: position ?? this.position,
        inputs: inputs,
        outputs: outputs,
        properties: properties ?? this.properties,
      );

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'label': label,
        'positionX': position.dx,
        'positionY': position.dy,
        'inputs': inputs.map((p) => p.toJson()).toList(),
        'outputs': outputs.map((p) => p.toJson()).toList(),
        'properties': properties,
      };

  factory GenericCanvasNode.fromJson(Map<String, dynamic> json) => GenericCanvasNode(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? 'generic',
        label: json['label'] as String? ?? '',
        position: Offset(
          (json['positionX'] as num?)?.toDouble() ?? 0,
          (json['positionY'] as num?)?.toDouble() ?? 0,
        ),
        inputs: (json['inputs'] as List<dynamic>?)
                ?.map((e) => NodePort.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        outputs: (json['outputs'] as List<dynamic>?)
                ?.map((e) => NodePort.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        properties: Map<String, dynamic>.from(json['properties'] as Map? ?? {}),
      );
}

class _NodeRegistryInternal {
  static final _NodeRegistryInternal instance = _NodeRegistryInternal._();
  final Map<String, _NodeFactory> _factories = {};

  _NodeRegistryInternal._();

  void register(String type, _NodeFactory factory) => _factories[type] = factory;
  _NodeFactory? getFactory(String type) => _factories[type];
}

typedef _NodeFactory = CanvasNode Function(Map<String, dynamic> json);
