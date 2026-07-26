import 'dart:convert';

class SheetBlock {
  static const String typeValue = 'sheet';

  List<String> columns;
  List<List<String>> rows;

  SheetBlock({List<String>? columns, List<List<String>>? rows})
      : columns = columns ?? ['A', 'B', 'C'],
        rows = rows ?? [
          ['', '', ''],
          ['', '', ''],
          ['', '', ''],
        ];

  int get colCount => columns.length;
  int get rowCount => rows.length;

  void addRow() => rows.add(List.filled(columns.length, ''));
  void removeRow(int index) {
    if (rows.length <= 1) return;
    rows.removeAt(index);
  }

  void addColumn() {
    columns.add('');
    for (final row in rows) row.add('');
  }

  void removeColumn(int index) {
    if (columns.length <= 1) return;
    columns.removeAt(index);
    for (final row in rows) row.removeAt(index);
  }

  void renameColumn(int index, String name) => columns[index] = name;
  void updateCell(int row, int col, String value) => rows[row][col] = value;

  String encode() => jsonEncode(toJson());

  Map<String, dynamic> toJson() => {
        '__norm_type__': typeValue,
        'columns': columns,
        'rows': rows,
      };

  factory SheetBlock.fromJson(Map<String, dynamic> json) => SheetBlock(
        columns: List<String>.from(json['columns'] ?? []),
        rows: List<List<String>>.from(
            (json['rows'] ?? []).map((r) => List<String>.from(r))),
      );

  static bool isSheet(String contentJson) {
    try {
      final data = jsonDecode(contentJson);
      return data is Map && data['__norm_type__'] == typeValue;
    } catch (_) {
      return false;
    }
  }

  factory SheetBlock.decode(String contentJson) {
    final data = jsonDecode(contentJson);
    return SheetBlock.fromJson(data as Map<String, dynamic>);
  }
}
