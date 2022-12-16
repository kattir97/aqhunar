import 'package:aqhas/collections/todo_isar.dart';
import 'package:aqhas/providers/isar_provider.dart';
import 'package:aqhas/providers/todos_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as dev;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // final dir = await getApplicationSupportDirectory();
  // print('Printing DIR: ${dir.path}');
  // final isar = await Isar.open([TodoIsarSchema], directory: dir.path);
  runApp(const ProviderScope(child: TodoApp()));
}

class TodoApp extends StatelessWidget {
  const TodoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Karar',
      theme: ThemeData.dark(),
      darkTheme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Karar')),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final todo = await createTodoDialog(context);
          if (todo != null) {
            ref.watch(todosStateProvider.notifier).addTodo(todo);
          } else {
            todo;
          }
        },
      ),
      body: const RenderList(),
    );
  }
}

List<Todo> todoList = [
  Todo(title: 'English', description: 'Read Book'),
  Todo(title: 'German', description: 'Listen Podcast')
];

@immutable
class Todo {
  final String id;
  final String title;
  final String description;
  final bool isDone;

  Todo({
    id,
    required this.title,
    required this.description,
    isDone,
  })  : id = id ?? const Uuid().v4(),
        isDone = isDone ?? false;

  Todo copy({String? id, String? title, String? description, bool? isDone}) {
    return Todo(
        id: id ?? const Uuid().v4(),
        title: title ?? this.title,
        description: description ?? this.description,
        isDone: isDone ?? this.isDone);
  }

  Todo update([String? title, String? description, bool? isDone]) => Todo(
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      id: id);

  @override
  String toString() {
    return 'id: $id, title: $title, description: $description, isDone: $isDone';
  }

  @override
  bool operator ==(covariant Todo other) =>
      other.id == id && other.isDone == isDone;

  @override
  int get hashCode => Object.hash(id, isDone);
}

class TodosNotifier extends StateNotifier<List<Todo>> {
  Isar? isar;
  TodosNotifier() : super([]) {
    init();
  }

  void init() async {
    final dir = await getApplicationSupportDirectory();
    // print('Printing DIR: ${dir.path}');
    isar = await Isar.open([TodoIsarSchema], directory: dir.path);

    final allTodos = await isar?.todoIsars.where().findAll();
    List<int?>? ids = allTodos?.map((e) {
      return e.id;
    }).toList();

    print('IDS: $ids');

    if (allTodos != null) {
      List<Todo> arr = allTodos.map((e) {
        Todo todo = Todo(
            title: e.title ?? '',
            description: e.description ?? '',
            id: e.uuid,
            isDone: e.isDone);
        print(todo);
        return todo;
      }).toList();

      state = [...arr];
    }
  }

  void addTodo(Todo todo) async {
    final aqhun = TodoIsar()
      ..title = todo.title
      ..description = todo.description
      ..isDone = todo.isDone
      ..uuid = todo.id;

    await isar?.writeTxn(() async {
      await isar?.todoIsars.put(aqhun);
    });
    state = [...state, todo];
  }

  void removeTodo(Todo todo) async {
    state = state.where((e) => e.id != todo.id).toList();
    await isar?.writeTxn(() async {
      final success = await isar?.todoIsars.deleteByUuid(todo.id);
      print('Todo is deleted: $success');
    });
  }

  void toggle(Todo todo) async {
    state = state.map((e) {
      if (e.id == todo.id) {
        print('TODOID: ${todo.id}');
        return todo.copy(isDone: !todo.isDone, id: todo.id);
      } else {
        return e;
      }
    }).toList();

    final aqhun = TodoIsar()
      ..title = todo.title
      ..description = todo.description
      ..isDone = todo.isDone
      ..uuid = todo.id;

    await isar?.writeTxn(() async {
      aqhun.isDone = !todo.isDone;
      print(aqhun.isDone);
      await isar?.todoIsars.put(aqhun);
    });
  }

  void updateTodo(Todo updatedTodo) async {
    final index = state.indexOf(updatedTodo);
    final oldTodo = state[index];

    if (oldTodo.title != updatedTodo.title ||
        oldTodo.description != updatedTodo.description) {
      state[index] = oldTodo.update(updatedTodo.title, updatedTodo.description);
    }

    state = state.map((e) => e).toList();

    final aqhun = TodoIsar()
      ..title = updatedTodo.title
      ..description = updatedTodo.description
      ..isDone = updatedTodo.isDone
      ..uuid = updatedTodo.id;

    await isar?.writeTxn(() async {
      await isar?.todoIsars.put(aqhun);
    });
  }
}

class RenderList extends ConsumerWidget {
  const RenderList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Todo> todos = ref.watch(todosStateProvider);

    return ListView.builder(
      padding: const EdgeInsets.only(top: 5),
      itemCount: todos.length,
      itemBuilder: ((context, index) {
        final todo = todos.elementAt(index);
        final isDone = todo.isDone;
        return Card(
          color: isDone ? Colors.grey : const Color(0xFF4F8FC0),
          child: ListTile(
            title: Text(todos[index].title),
            subtitle: Text(todos[index].description),
            trailing: Wrap(
              spacing: 12,
              children: <Widget>[
                IconButton(
                  icon: isDone
                      ? const Icon(Icons.check_box)
                      : const Icon(Icons.check_box_outline_blank),
                  onPressed: () {
                    ref.watch(todosStateProvider.notifier).toggle(todo);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    // final todo = todos[index];
                    ref.watch(todosStateProvider.notifier).removeTodo(todo);
                  },
                ),
              ],
            ),
            onTap: () async {
              final Todo updatedTodo =
                  await updateTodoDialog(context, todo, ref);
              ref.read(todosStateProvider.notifier).updateTodo(updatedTodo);

              print(ref.watch(todosStateProvider));
            },
          ),
        );
      }),
    );
  }
}

final _titleController = TextEditingController();
final _descriptionController = TextEditingController();

Future createTodoDialog(BuildContext context, [Todo? todo]) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Create Todo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(hintText: 'title'),
              controller: _titleController,
            ),
            TextField(
              decoration: const InputDecoration(hintText: 'description'),
              controller: _descriptionController,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: const ButtonStyle(
              backgroundColor: MaterialStatePropertyAll<Color>(Colors.red),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final todo = Todo(
                title: _titleController.text,
                description: _descriptionController.text,
              );

              Navigator.of(context).pop(todo);
              _descriptionController.clear();
              _titleController.clear();
            },
            child: const Text('Add'),
          ),
        ],
      );
    },
  );
}

Future updateTodoDialog(BuildContext context,
    [Todo? todo, WidgetRef? ref]) async {
  String? title = todo?.title;
  String? description = todo?.description;
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Update Todo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(hintText: 'title'),
              initialValue: title,
              onChanged: ((value) => title = value),
            ),
            TextFormField(
              decoration: const InputDecoration(hintText: 'description'),
              initialValue: description,
              onChanged: ((value) => description = value),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: const ButtonStyle(
              backgroundColor: MaterialStatePropertyAll<Color>(Colors.red),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedTodo = todo?.update(title, description);
              Navigator.of(context).pop(updatedTodo);
            },
            child: const Text('Update'),
          ),
        ],
      );
    },
  );
}
