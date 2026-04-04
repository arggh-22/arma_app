import 'package:equatable/equatable.dart';

/// Base failure class using sealed class hierarchy.
///
/// All domain-level failures extend this class. Each failure carries a
/// human-readable [message] describing what went wrong.
sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Failure when parsing a server configuration link or JSON.
class ParseFailure extends Failure {
  const ParseFailure(super.message);
}

/// Failure when reading from or writing to local storage (Hive).
class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

/// Failure when accessing the system clipboard.
class ClipboardFailure extends Failure {
  const ClipboardFailure(super.message);
}
