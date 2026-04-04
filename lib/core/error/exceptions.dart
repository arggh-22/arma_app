/// Exception thrown when parsing a server configuration link or JSON fails.
class ParseException implements Exception {
  final String message;
  const ParseException(this.message);

  @override
  String toString() => 'ParseException: $message';
}

/// Exception thrown when a local storage (Hive) operation fails.
class StorageException implements Exception {
  final String message;
  const StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
