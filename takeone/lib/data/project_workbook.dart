import 'package:excel_community/excel_community.dart' as xl;
import 'package:intl/intl.dart';

import 'app_data.dart';

List<int> buildProjectWorkbook(FilmProject project, List<TakeRecord> takes) {
  final workbook = xl.Excel.createExcel();
  workbook.rename('Sheet1', 'Production');
  final production = workbook['Production'];
  production.appendRow([xl.TextCellValue('TAKEONE PRODUCTION REPORT')]);
  production.appendRow([
    xl.TextCellValue('Project'),
    xl.TextCellValue(project.name),
  ]);
  production.appendRow([
    xl.TextCellValue('Production date'),
    xl.TextCellValue(project.productionDate),
  ]);
  production.appendRow([
    xl.TextCellValue('Director'),
    xl.TextCellValue(project.director),
  ]);
  production.appendRow([
    xl.TextCellValue('Director of photography'),
    xl.TextCellValue(project.dop),
  ]);
  production.appendRow([
    xl.TextCellValue('Location'),
    xl.TextCellValue(project.location),
  ]);
  production.appendRow([
    xl.TextCellValue('Roll'),
    xl.TextCellValue(project.roll),
  ]);
  production.appendRow([
    xl.TextCellValue('Current scene'),
    xl.TextCellValue(project.scene),
  ]);
  production.appendRow([
    xl.TextCellValue('Current shot'),
    xl.TextCellValue(project.shot),
  ]);
  production.appendRow([
    xl.TextCellValue('Current take'),
    xl.IntCellValue(project.take),
  ]);
  production.appendRow([
    xl.TextCellValue('Production notes'),
    xl.TextCellValue(project.notes),
  ]);
  production.appendRow([
    xl.TextCellValue('Recorded takes'),
    xl.IntCellValue(takes.length),
  ]);

  final history = workbook['Take History'];
  history.appendRow([
    xl.TextCellValue('Scene'),
    xl.TextCellValue('Shot'),
    xl.TextCellValue('Take'),
    xl.TextCellValue('Timecode'),
    xl.TextCellValue('Date / Time'),
    xl.TextCellValue('Rating'),
    xl.TextCellValue('Notes'),
  ]);
  for (final take in takes) {
    history.appendRow([
      xl.TextCellValue(take.scene),
      xl.TextCellValue(take.shot),
      xl.IntCellValue(take.take),
      xl.TextCellValue(take.timecode),
      xl.TextCellValue(
        DateFormat('MMM d, yyyy  h:mm a').format(take.createdAt),
      ),
      xl.TextCellValue(_ratingLabel(take.rating)),
      xl.TextCellValue(take.notes),
    ]);
  }

  final bytes = workbook.save();
  if (bytes == null) {
    throw StateError('The Excel workbook could not be generated.');
  }
  return bytes;
}

String _ratingLabel(TakeRating rating) => switch (rating) {
  TakeRating.good => 'GOOD',
  TakeRating.movingOn => 'MOVED ON',
  TakeRating.bad => 'BAD',
  TakeRating.test => 'TEST',
};
