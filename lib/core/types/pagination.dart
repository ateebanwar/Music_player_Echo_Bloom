import 'package:equatable/equatable.dart';

/// Specification for paginated queries (lazy loading large collections).
class PageQuery extends Equatable {
  final int offset;
  final int limit;
  final String? sortBy;
  final bool ascending;

  const PageQuery({
    this.offset = 0,
    this.limit = 50,
    this.sortBy,
    this.ascending = true,
  }) : assert(offset >= 0, 'Offset must be non-negative'),
       assert(limit > 0, 'Limit must be positive');

  @override
  List<Object?> get props => [offset, limit, sortBy, ascending];
}

/// Generic container for a paginated result slice with metadata.
class PaginatedList<T> extends Equatable {
  final List<T> items;
  final int totalCount;
  final int offset;
  final int limit;

  const PaginatedList({
    required this.items,
    required this.totalCount,
    required this.offset,
    required this.limit,
  });

  const PaginatedList.empty()
      : items = const [],
        totalCount = 0,
        offset = 0,
        limit = 50;

  bool get hasMore => (offset + items.length) < totalCount;
  int get nextPageOffset => offset + items.length;

  @override
  List<Object?> get props => [items, totalCount, offset, limit];
}
