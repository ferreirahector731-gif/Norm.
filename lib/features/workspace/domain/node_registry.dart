import 'dart:convert';
import 'dart:io';

import 'canvas_node.dart';

class NodeSchema {
  final String type;
  final String displayName;
  final String description;
  final List<NodePortSchema> inputs;
  final List<NodePortSchema> outputs;
  final Map<String, dynamic> defaultProperties;

  const NodeSchema({
    required this.type,
    required this.displayName,
    this.description = '',
    this.inputs = const [],
    this.outputs = const [],
    this.defaultProperties = const {},
  });

  factory NodeSchema.fromJson(Map<String, dynamic> json) => NodeSchema(
        type: json['type'] as String,
        displayName: json['displayName'] as String? ?? json['type'] as String,
        description: json['description'] as String? ?? '',
        inputs: (json['inputs'] as List<dynamic>?)
                ?.map((e) => NodePortSchema.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        outputs: (json['outputs'] as List<dynamic>?)
                ?.map((e) => NodePortSchema.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        defaultProperties: Map<String, dynamic>.from(json['properties'] as Map? ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'displayName': displayName,
        'description': description,
        'inputs': inputs.map((e) => e.toJson()).toList(),
        'outputs': outputs.map((e) => e.toJson()).toList(),
        'properties': defaultProperties,
      };
}

class NodePortSchema {
  final String id;
  final String label;
  final bool isInput;
  final String? valueType;

  const NodePortSchema({
    required this.id,
    required this.label,
    this.isInput = true,
    this.valueType,
  });

  factory NodePortSchema.fromJson(Map<String, dynamic> json) => NodePortSchema(
        id: json['id'] as String,
        label: json['label'] as String? ?? json['id'] as String,
        isInput: json['isInput'] as bool? ?? true,
        valueType: json['valueType'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'isInput': isInput,
        if (valueType != null) 'valueType': valueType,
      };
}

class NodeRegistry {
  static final NodeRegistry _instance = NodeRegistry._();
  static NodeRegistry get instance => _instance;

  final Map<String, NodeSchema> _schemas = {};
  final Map<String, CanvasNode Function(Map<String, dynamic>)> _factories = {};
  final List<String> _loadedSources = [];

  NodeRegistry._();

  void registerSchema(NodeSchema schema) {
    _schemas[schema.type] = schema;
  }

  void registerFactory(
    String type,
    CanvasNode Function(Map<String, dynamic>) factory,
  ) {
    _factories[type] = factory;
  }

  NodeSchema? getSchema(String type) => _schemas[type];
  List<NodeSchema> get allSchemas => _schemas.values.toList();
  List<String> get loadedSources => List.unmodifiable(_loadedSources);

  CanvasNode createNode(String type, {String? id, String? label, Map<String, dynamic>? properties}) {
    final schema = _schemas[type];
    if (schema == null) throw Exception('Schema not found: $type');
    final factory = _factories[type];
    if (factory != null) {
      return factory({
        'id': id ?? '',
        'type': type,
        'label': label ?? schema.displayName,
        'properties': {...schema.defaultProperties, ...?properties},
        'inputs': schema.inputs
            .map((s) => {'id': s.id, 'label': s.label, 'isInput': s.isInput})
            .toList(),
        'outputs': schema.outputs
            .map((s) => {'id': s.id, 'label': s.label, 'isInput': s.isInput})
            .toList(),
      });
    }
    return GenericCanvasNode(
      id: id ?? '',
      type: type,
      label: label ?? schema.displayName,
      properties: {...schema.defaultProperties, ...?properties},
      inputs: schema.inputs
          .map((s) => NodePort(id: s.id, label: s.label, isInput: s.isInput))
          .toList(),
      outputs: schema.outputs
          .map((s) => NodePort(id: s.id, label: s.label, isInput: s.isInput))
          .toList(),
    );
  }

  Future<void> loadFromJsonFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) throw Exception('File not found: $filePath');
    final contents = await file.readAsString();
    final json = jsonDecode(contents);
    if (json is List) {
      for (final item in json) {
        _registerFromJson(item as Map<String, dynamic>);
      }
    } else if (json is Map<String, dynamic>) {
      _registerFromJson(json);
    }
    _loadedSources.add(filePath);
  }

  void loadFromJsonString(String jsonString, {String source = 'memory'}) {
    final json = jsonDecode(jsonString);
    if (json is List) {
      for (final item in json) {
        _registerFromJson(item as Map<String, dynamic>);
      }
    } else if (json is Map<String, dynamic>) {
      _registerFromJson(json);
    }
    _loadedSources.add(source);
  }

  void _registerFromJson(Map<String, dynamic> json) {
    final schema = NodeSchema.fromJson(json);
    _schemas[schema.type] = schema;
  }
}
