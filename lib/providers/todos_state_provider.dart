import 'package:aqhas/main.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final todosStateProvider =
    StateNotifierProvider<TodosNotifier, List<Todo>>((ref) {
  return TodosNotifier();
});
