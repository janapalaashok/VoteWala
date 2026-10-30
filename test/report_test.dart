import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:votewala/admin/report_pdf.dart';
import 'package:votewala/data/grievance.dart';
import 'package:votewala/services/photo_prep.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final photo = img.encodeJpg(img.Image(width: 3000, height: 2000));
  const counts = ReportCounts(good: 35, bad: 115, goodPhoto: 2, badPhoto: 80);

  test('evidence photos are resized and re-encoded; other files are refused', () {
    final out = prepareEvidencePhoto(Uint8List.fromList(photo));
    final decoded = img.decodeJpg(out)!;
    expect(decoded.width, 1280);
    expect(decoded.exif.isEmpty, isTrue);
    expect(() => prepareEvidencePhoto(Uint8List.fromList('not an image'.codeUnits)), throwsA(isA<PhotoRejected>()));
  });

  test('grievance report is a PDF with totals and a neutral summary', () async {
    final g = Grievance(
      id: Grievance.idFor('issues-2026-10', 'mla-21', 'c0'),
      pollId: 'issues-2026-10',
      constituencyId: 'mla-21',
      slot: 'c0',
      good: counts.good,
      bad: counts.bad,
      badWithPhoto: counts.badPhoto,
      steps: const [],
    );
    final pdf = await buildGrievanceReport(
      grievance: g,
      constituencyName: 'Visakhapatnam East',
      categoryName: 'Roads & Infrastructure',
      counts: counts,
      photos: [ReportPhoto(prepareEvidencePhoto(Uint8List.fromList(photo)), 'Potholes near బస్ stand', 1)],
    );
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
    expect(counts.pct(counts.bad), '76.7%');
    expect(counts.publicOpinion, 68);
    final summary = reportSummary('Visakhapatnam East', 'Roads & Infrastructure', 'October 2026', counts);
    expect(summary, contains('150 VoteWala participants'));
    expect(summary, contains('80 of the BAD responses'));
    expect(summary, isNot(contains('verified')));
  });
}
