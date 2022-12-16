import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'todo_isar.g.dart';

@collection
class TodoIsar {
  Id? id;
  @Index(unique: true, replace: true)
  String? uuid;
  String? title;
  String? description;
  bool? isDone;
}
