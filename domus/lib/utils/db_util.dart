import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbUtil {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tasks.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createTables(db);
      },
      onOpen: (db) async {
        await _createTables(db);
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        time TEXT NOT NULL,
        complete INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'Outros',
        value REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS expense_types(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS bills(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        value REAL NOT NULL,
        due_date TEXT NOT NULL,
        recurring INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'open',
        expense_id TEXT,
        recurring_source_id TEXT,
        paid_date TEXT
      )
    ''');

    await _ensureColumn(
      db,
      table: 'transactions',
      column: 'category',
      definition: "TEXT NOT NULL DEFAULT 'Outros'",
    );
    await _ensureColumn(
      db,
      table: 'bills',
      column: 'expense_id',
      definition: 'TEXT',
    );
    await _ensureColumn(
      db,
      table: 'bills',
      column: 'recurring_source_id',
      definition: 'TEXT',
    );
    await _ensureColumn(
      db,
      table: 'bills',
      column: 'paid_date',
      definition: 'TEXT',
    );
    await _seedExpenseTypes(db);
  }

  static Future<void> _ensureColumn(
    Database db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((item) => item['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  static Future<void> _seedExpenseTypes(Database db) async {
    const defaults = [
      'Alimentacao',
      'Transporte',
      'Moradia',
      'Saude',
      'Lazer',
      'Contas',
    ];
    for (final name in defaults) {
      await db.insert('expense_types', {
        'id': name.toLowerCase(),
        'name': name,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  static Future<List<Map<String, dynamic>>> getData([
    String table = 'tasks',
  ]) async {
    final db = await database;
    return db.query(table);
  }

  static Future<String> insertData(
    Map<String, dynamic> data, [
    String table = 'tasks',
  ]) async {
    final db = await database;
    final id =
        data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert(
      table,
      _normalizeData(table, {...data, 'id': id}),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return id;
  }

  static Future<void> updateData(
    Map<String, dynamic> data, [
    String table = 'tasks',
  ]) async {
    final db = await database;
    await db.update(
      table,
      _normalizeData(table, data),
      where: 'id = ?',
      whereArgs: [data['id']],
    );
  }

  static Future<void> deleteData(String id, [String table = 'tasks']) async {
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updateComplete(String taskId, bool complete) async {
    final db = await database;
    await db.update(
      'tasks',
      {'complete': complete ? 1 : 0},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  static Map<String, Object?> _normalizeData(
    String table,
    Map<String, dynamic> data,
  ) {
    if (table == 'transactions') {
      return {
        'id': data['id'],
        'title': data['title'],
        'category': data['category'] ?? 'Outros',
        'value': data['value'],
        'date': data['date'],
      };
    }

    if (table == 'expense_types') {
      return {
        'id': data['id'],
        'name': data['name'],
      };
    }

    if (table == 'bills') {
      return {
        'id': data['id'],
        'title': data['title'],
        'value': data['value'],
        'due_date': data['due_date'],
        'recurring': (data['recurring'] == true || data['recurring'] == 1) ? 1 : 0,
        'status': data['status'] ?? 'open',
        'expense_id': data['expense_id'],
        'recurring_source_id': data['recurring_source_id'],
        'paid_date': data['paid_date'],
      };
    }

    return {
      'id': data['id'],
      'title': data['title'],
      'description': data['description'] ?? '',
      'time': data['time'],
      'complete': (data['complete'] == true || data['complete'] == 1) ? 1 : 0,
    };
  }
}
