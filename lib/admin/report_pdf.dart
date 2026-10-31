import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/grievance.dart';
import '../data/poll_month.dart';

/// A reviewed photo for the report.
class ReportPhoto {
  const ReportPhoto(this.jpeg, this.caption, this.choice);

  final Uint8List jpeg;
  final String caption;

  /// 0 GOOD, 1 BAD.
  final int choice;
}

/// Counts for the report (totals only, no personal data).
class ReportCounts {
  const ReportCounts({required this.good, required this.bad, required this.goodPhoto, required this.badPhoto});

  final int good, bad, goodPhoto, badPhoto;

  int get total => good + bad;
  int get publicOpinion => total - goodPhoto - badPhoto;
  String pct(int n) => total == 0 ? '0%' : '${(n * 100 / total).toStringAsFixed(1)}%';
}

const _orange = PdfColor.fromInt(0xFFF47A1F);
const _green = PdfColor.fromInt(0xFF1FA34A);
const _red = PdfColor.fromInt(0xFFDC2626);
const _ink = PdfColor.fromInt(0xFF0F172A);
const _muted = PdfColor.fromInt(0xFF64748B);

/// The built-in PDF font covers Latin text only; other scripts are dropped.
String _latin(String s) => s.replaceAll(RegExp(r'[^\x20-\x7E -ÿ]'), '').trim();

/// A neutral, factual summary of the feedback.
String reportSummary(String constituency, String category, String month, ReportCounts c) {
  if (c.total == 0) return 'No feedback was recorded for $category in $constituency in $month.';
  final view = c.bad > c.good
      ? 'A majority of participants (${c.pct(c.bad)}) rated it BAD'
      : c.good > c.bad
          ? 'A majority of participants (${c.pct(c.good)}) rated it GOOD'
          : 'Participants were evenly divided';
  return 'In $month, ${c.total} VoteWala participants from $constituency gave feedback on $category. '
      '$view. ${c.badPhoto} of the BAD responses were accompanied by a photograph submitted by the participant. '
      'These figures reflect the opinions of participating users and are shared to bring a collective public '
      'concern to the attention of the representative.';
}

Future<Uint8List> buildGrievanceReport({
  required Grievance grievance,
  required String constituencyName,
  required String categoryName,
  required ReportCounts counts,
  required List<ReportPhoto> photos,
  DateTime? now,
}) async {
  final logo = pw.MemoryImage((await rootBundle.load('assets/brand/logo.png')).buffer.asUint8List());
  final generated = now ?? DateTime.now();
  final month = PollMonth.parse(grievance.monthKey).label(false);
  final constituency = _latin(constituencyName);
  final category = _latin(categoryName);
  final doc = pw.Document(title: 'VoteWala grievance report - $constituency - $category', author: 'VoteWala');

  pw.Widget row(String label, String value, {PdfColor? color}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Row(children: [
          pw.Expanded(child: pw.Text(label, style: const pw.TextStyle(color: _muted, fontSize: 11))),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: color ?? _ink)),
        ]),
      );

  pw.Widget bar(ReportCounts c) => c.total == 0
      ? pw.SizedBox()
      : pw.ClipRRect(
          horizontalRadius: 4,
          verticalRadius: 4,
          child: pw.SizedBox(
            height: 12,
            child: pw.Row(children: [
              if (c.good > 0) pw.Expanded(flex: c.good, child: pw.Container(color: _green)),
              if (c.bad > 0) pw.Expanded(flex: c.bad, child: pw.Container(color: _red)),
            ]),
          ),
        );

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
    header: (ctx) => pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      margin: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _orange, width: 2))),
      child: pw.Row(children: [
        pw.Image(logo, height: 30),
        pw.Spacer(),
        pw.Text('Public Grievance Report', style: pw.TextStyle(fontSize: 12, color: _muted, fontWeight: pw.FontWeight.bold)),
      ]),
    ),
    footer: (ctx) => pw.Column(children: [
      pw.Divider(color: PdfColors.grey300),
      pw.Text(
        'Collected through the VoteWala public opinion platform from participating users. Not an official survey, '
        'election result or government record. Photographs are submitted by participants and reviewed by VoteWala; '
        'they are not independently verified. No personal information is included.',
        style: const pw.TextStyle(fontSize: 7.5, color: _muted),
      ),
      pw.SizedBox(height: 4),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: _muted)),
      ),
    ]),
    build: (ctx) => [
      pw.Text(category, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: _ink)),
      pw.SizedBox(height: 4),
      pw.Text('$constituency Assembly Constituency, Andhra Pradesh', style: const pw.TextStyle(fontSize: 13, color: _muted)),
      pw.SizedBox(height: 14),
      pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
        child: pw.Column(children: [
          row('Feedback period', month),
          row('Report generated', '${generated.day}/${generated.month}/${generated.year}'),
          row('Reference', grievance.id),
        ]),
      ),
      pw.SizedBox(height: 18),
      pw.Text('Public feedback', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      bar(counts),
      pw.SizedBox(height: 8),
      row('Total responses', '${counts.total}'),
      row('GOOD', '${counts.good} (${counts.pct(counts.good)})', color: _green),
      row('BAD', '${counts.bad} (${counts.pct(counts.bad)})', color: _red),
      row('Evidence supported (with photograph)', '${counts.goodPhoto + counts.badPhoto}  (BAD: ${counts.badPhoto}, GOOD: ${counts.goodPhoto})'),
      row('Public opinion (without photograph)', '${counts.publicOpinion}'),
      pw.SizedBox(height: 16),
      pw.Text('Summary', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6),
      pw.Text(reportSummary(constituency, category, month, counts), style: const pw.TextStyle(fontSize: 11, lineSpacing: 3)),
      if (photos.isNotEmpty) ...[
        pw.SizedBox(height: 18),
        pw.Text('Reviewed photographs (${photos.length})', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Wrap(spacing: 10, runSpacing: 10, children: [
          for (final p in photos)
            pw.SizedBox(
              width: 160,
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.ClipRRect(
                  horizontalRadius: 6,
                  verticalRadius: 6,
                  child: pw.Image(pw.MemoryImage(p.jpeg), width: 160, height: 120, fit: pw.BoxFit.cover),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  [p.choice == 1 ? 'Rated BAD' : 'Rated GOOD', if (_latin(p.caption).isNotEmpty) _latin(p.caption)].join(' - '),
                  style: const pw.TextStyle(fontSize: 8.5, color: _muted),
                ),
              ]),
            ),
        ]),
      ],
    ],
  ));
  return doc.save();
}
