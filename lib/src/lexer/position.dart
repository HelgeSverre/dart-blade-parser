/// Represents a position in the source code.
class Position {
  /// 1-based line number
  final int line;

  /// 1-based column number
  final int column;

  /// 0-based character offset from file start
  final int offset;

  Position({
    required this.line,
    required this.column,
    required this.offset,
  }) {
    if (line < 1) throw ArgumentError('line must be >= 1');
    if (column < 1) throw ArgumentError('column must be >= 1');
    if (offset < 0) throw ArgumentError('offset must be >= 0');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          line == other.line &&
          column == other.column &&
          offset == other.offset;

  @override
  int get hashCode => Object.hash(line, column, offset);

  @override
  String toString() => 'Position(line: $line, column: $column, offset: $offset)';

  Map<String, dynamic> toJson() => {
        'line': line,
        'column': column,
        'offset': offset,
      };
}
