import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'mail_clone.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE emails(
        id INTEGER PRIMARY KEY,
        mail_account_id INTEGER,
        sender TEXT,
        subject TEXT,
        body TEXT,
        is_read INTEGER,
        folder TEXT,
        date TEXT,
        attachments TEXT
      )
    ''');
  }

  // Insert or Update emails
  Future<void> saveEmails(List<dynamic> emails) async {
    final db = await database;
    
    // We use a batch for performance
    Batch batch = db.batch();
    for (var email in emails) {
      batch.insert(
        'emails',
        {
          'id': email['id'],
          'mail_account_id': email['mail_account_id'],
          'sender': email['sender'],
          'subject': email['subject'],
          'body': email['body'],
          'is_read': email['is_read'] == true || email['is_read'] == 1 ? 1 : 0,
          'folder': email['folder'],
          'date': email['date'],
          'attachments': jsonEncode(email['attachments'] ?? []),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // Get emails for a specific account and folder
  Future<List<Map<String, dynamic>>> getEmails(int accountId, String folder) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'emails',
      where: 'mail_account_id = ? AND folder = ?',
      whereArgs: [accountId, folder],
      orderBy: 'date DESC',
    );

    return maps.map((map) {
      return {
        'id': map['id'],
        'mail_account_id': map['mail_account_id'],
        'sender': map['sender'],
        'subject': map['subject'],
        'body': map['body'],
        'is_read': map['is_read'] == 1,
        'folder': map['folder'],
        'date': map['date'],
        'attachments': map['attachments'] != null ? jsonDecode(map['attachments'] as String) : [],
      };
    }).toList();
  }

  // Delete email locally
  Future<void> deleteEmail(int id) async {
    final db = await database;
    await db.delete(
      'emails',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Move email locally (Archive)
  Future<void> moveEmail(int id, String folder) async {
    final db = await database;
    await db.update(
      'emails',
      {'folder': folder},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
