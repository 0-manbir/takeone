import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

enum TakeRating { bad, good, movingOn, test }

class SlateField {
  const SlateField({
    required this.id,
    required this.label,
    this.value = '',
    this.visible = true,
    this.size = 1,
  });

  final String id;
  final String label;
  final String value;
  final bool visible;
  final double size;

  SlateField copyWith(
          {String? label, String? value, bool? visible, double? size}) =>
      SlateField(
        id: id,
        label: label ?? this.label,
        value: value ?? this.value,
        visible: visible ?? this.visible,
        size: size ?? this.size,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'label': label,
        'value': value,
        'visible': visible,
        'size': size,
      };

  factory SlateField.fromMap(Map<String, dynamic> map) => SlateField(
        id: map['id'] as String,
        label: map['label'] as String,
        value: map['value'] as String? ?? '',
        visible: map['visible'] as bool? ?? true,
        size: (map['size'] as num?)?.toDouble() ?? 1,
      );
}

class FilmProject {
  const FilmProject({
    required this.id,
    required this.name,
    required this.productionDate,
    this.director = '',
    this.dop = '',
    this.location = '',
    this.notes = '',
    this.roll = 'A001',
    this.scene = '1',
    this.shot = '1',
    this.take = 1,
    this.frameRate = 24,
    this.soundEnabled = true,
    this.fields = defaultSlateFields,
  });

  final String id;
  final String name;
  final String productionDate;
  final String director;
  final String dop;
  final String location;
  final String notes;
  final String roll;
  final String scene;
  final String shot;
  final int take;
  final double frameRate;
  final bool soundEnabled;
  final List<SlateField> fields;

  static const defaultSlateFields = [
    SlateField(id: 'roll', label: 'ROLL'),
    SlateField(id: 'scene', label: 'SCENE'),
    SlateField(id: 'shot', label: 'SHOT'),
    SlateField(id: 'take', label: 'TAKE'),
  ];

  FilmProject copyWith({
    String? name,
    String? productionDate,
    String? director,
    String? dop,
    String? location,
    String? notes,
    String? roll,
    String? scene,
    String? shot,
    int? take,
    double? frameRate,
    bool? soundEnabled,
    List<SlateField>? fields,
  }) =>
      FilmProject(
        id: id,
        name: name ?? this.name,
        productionDate: productionDate ?? this.productionDate,
        director: director ?? this.director,
        dop: dop ?? this.dop,
        location: location ?? this.location,
        notes: notes ?? this.notes,
        roll: roll ?? this.roll,
        scene: scene ?? this.scene,
        shot: shot ?? this.shot,
        take: take ?? this.take,
        frameRate: frameRate ?? this.frameRate,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        fields: fields ?? this.fields,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'productionDate': productionDate,
        'director': director,
        'dop': dop,
        'location': location,
        'notes': notes,
        'roll': roll,
        'scene': scene,
        'shot': shot,
        'take': take,
        'frameRate': frameRate,
        'soundEnabled': soundEnabled,
        'fields': fields.map((field) => field.toMap()).toList(),
      };

  factory FilmProject.fromMap(Map<String, dynamic> map) => FilmProject(
        id: map['id'] as String,
        name: map['name'] as String,
        productionDate: map['productionDate'] as String,
        director: map['director'] as String? ?? '',
        dop: map['dop'] as String? ?? '',
        location: map['location'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
        roll: map['roll'] as String? ?? 'A001',
        scene: map['scene'] as String? ?? '1',
        shot: map['shot'] as String? ?? '1',
        take: map['take'] as int? ?? 1,
        frameRate: (map['frameRate'] as num?)?.toDouble() ?? 24,
        soundEnabled: map['soundEnabled'] as bool? ?? true,
        fields: (map['fields'] as List<dynamic>?)
                ?.map((item) =>
                    SlateField.fromMap(Map<String, dynamic>.from(item as Map)))
                .toList() ??
            defaultSlateFields,
      );
}

class TakeRecord {
  const TakeRecord({
    required this.id,
    required this.projectId,
    required this.scene,
    required this.shot,
    required this.take,
    required this.timecode,
    required this.createdAt,
    required this.rating,
    this.notes = '',
  });

  final int? id;
  final String projectId;
  final String scene;
  final String shot;
  final int take;
  final String timecode;
  final DateTime createdAt;
  final TakeRating rating;
  final String notes;

  TakeRecord copyWith({
    String? scene,
    String? shot,
    int? take,
    String? timecode,
    TakeRating? rating,
    String? notes,
  }) =>
      TakeRecord(
        id: id,
        projectId: projectId,
        scene: scene ?? this.scene,
        shot: shot ?? this.shot,
        take: take ?? this.take,
        timecode: timecode ?? this.timecode,
        createdAt: createdAt,
        rating: rating ?? this.rating,
        notes: notes ?? this.notes,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'projectId': projectId,
        'scene': scene,
        'shot': shot,
        'take': take,
        'timecode': timecode,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'rating': rating.name,
        'notes': notes,
      };

  factory TakeRecord.fromMap(Map<String, Object?> map) => TakeRecord(
        id: map['id'] as int,
        projectId: map['projectId'] as String,
        scene: map['scene'] as String,
        shot: map['shot'] as String,
        take: map['take'] as int,
        timecode: map['timecode'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        rating: TakeRating.values.firstWhere(
          (rating) => rating.name == map['rating'],
          orElse: () => TakeRating.good,
        ),
        notes: map['notes'] as String? ?? '',
      );
}

class LocalStore {
  LocalStore._();

  static final LocalStore instance = LocalStore._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final directory = await getDatabasesPath();
    _database = await openDatabase(
      p.join(directory, 'takeone.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE projects (id TEXT PRIMARY KEY, data TEXT NOT NULL)',
        );
        await db.execute('''
          CREATE TABLE takes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            projectId TEXT NOT NULL,
            scene TEXT NOT NULL,
            shot TEXT NOT NULL,
            take INTEGER NOT NULL,
            timecode TEXT NOT NULL,
            createdAt INTEGER NOT NULL,
            rating TEXT NOT NULL,
            notes TEXT NOT NULL DEFAULT ''
          )
        ''');
        await db.execute(
          'CREATE INDEX takes_project_created ON takes(projectId, createdAt DESC)',
        );
      },
    );
    return _database!;
  }

  Future<List<FilmProject>> getProjects() async {
    final rows = await (await database).query('projects');
    return rows
        .map((row) => FilmProject.fromMap(
            jsonDecode(row['data']! as String) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> saveProject(FilmProject project) async {
    await (await database).insert(
      'projects',
      {'id': project.id, 'data': jsonEncode(project.toMap())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteProject(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('takes', where: 'projectId = ?', whereArgs: [id]);
      await txn.delete('projects', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<TakeRecord>> getTakes(String projectId) async {
    final rows = await (await database).query(
      'takes',
      where: 'projectId = ?',
      whereArgs: [projectId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(TakeRecord.fromMap).toList();
  }

  Future<void> saveTake(TakeRecord take) async {
    await (await database).insert('takes', take.toMap());
  }

  Future<void> updateTake(TakeRecord take) async {
    await (await database).update(
      'takes',
      take.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [take.id],
    );
  }

  Future<void> deleteTake(int id) async {
    await (await database).delete('takes', where: 'id = ?', whereArgs: [id]);
  }
}

class UserPreferences {
  UserPreferences._();

  static final UserPreferences instance = UserPreferences._();
  static const _themeKey = 'app_theme';
  static const _accentKey = 'app_accent';
  static const _fontKey = 'app_font_style';

  Future<String> getTheme() async =>
      (await SharedPreferences.getInstance()).getString(_themeKey) ?? 'cinema';

  Future<void> setTheme(String value) async {
    await (await SharedPreferences.getInstance()).setString(_themeKey, value);
  }

  Future<int> getAccent() async =>
      (await SharedPreferences.getInstance()).getInt(_accentKey) ?? 0xFFC9A56A;

  Future<void> setAccent(int value) async {
    await (await SharedPreferences.getInstance()).setInt(_accentKey, value);
  }

  Future<String> getFontStyle() async =>
      (await SharedPreferences.getInstance()).getString(_fontKey) ?? 'modern';

  Future<void> setFontStyle(String value) async {
    await (await SharedPreferences.getInstance()).setString(_fontKey, value);
  }
}
