import 'package:excel_community/excel_community.dart' as xl;
import 'package:flutter_test/flutter_test.dart';
import 'package:takeone/data/app_data.dart';
import 'package:takeone/data/project_workbook.dart';

void main() {
  test('workbook contains production details and take history', () {
    final project = FilmProject(
      id: 'project-1',
      name: 'Test Production',
      productionDate: '2025-01-02',
      director: 'A. Director',
      scene: '3',
      shot: 'B',
      take: 2,
      notes: 'Production notes',
    );
    final take = TakeRecord(
      id: 1,
      projectId: project.id,
      scene: '3',
      shot: 'B',
      take: 1,
      timecode: '01:02:03:04',
      createdAt: DateTime(2025, 1, 2, 10, 30),
      rating: TakeRating.good,
      notes: 'Use this one',
    );

    final workbook = xl.Excel.decodeBytes(
      buildProjectWorkbook(project, [take]),
    );
    expect(workbook.tables.keys, containsAll(['Production', 'Take History']));

    final production = workbook['Production'];
    expect(
      production.cell(xl.CellIndex.indexByString('B2')).value,
      xl.TextCellValue('Test Production'),
    );
    expect(
      production.cell(xl.CellIndex.indexByString('B9')).value,
      xl.TextCellValue('B'),
    );
    expect(
      production.cell(xl.CellIndex.indexByString('B10')).value,
      xl.IntCellValue(2),
    );

    final history = workbook['Take History'];
    expect(
      history.cell(xl.CellIndex.indexByString('A1')).value,
      xl.TextCellValue('Scene'),
    );
    expect(
      history.cell(xl.CellIndex.indexByString('F2')).value,
      xl.TextCellValue('GOOD'),
    );
    expect(
      history.cell(xl.CellIndex.indexByString('G2')).value,
      xl.TextCellValue('Use this one'),
    );
  });
}
