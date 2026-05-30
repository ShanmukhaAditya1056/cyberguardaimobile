import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/date_formatter.dart';
import '../models/alert_model.dart';
import '../models/scan_result_model.dart';
import '../models/score_entry_model.dart';
import '../models/settings_model.dart';
import 'hive_service.dart';

/// Builds a branded CyberGuard AI security report (PDF or CSV) from the
/// data already cached in Hive, writes it to a temp file, and hands it to
/// the system share sheet.
class ReportExportService {
  static const _brandBlue = PdfColor.fromInt(0xFF1A73E8);
  static const _textDark = PdfColor.fromInt(0xFF3D3D3D);
  static const _textMed = PdfColor.fromInt(0xFF696969);
  static const _safeColor = PdfColor.fromInt(0xFF1EA672);
  static const _dangerColor = PdfColor.fromInt(0xFFE23744);
  static const _warningColor = PdfColor.fromInt(0xFFF4831F);

  /// Build the PDF, save to temp, and open the share sheet.
  static Future<File> exportPdf() async {
    final settings = HiveService.getSettings();
    final alerts = HiveService.getAlerts();
    final scanResults = HiveService.getScanResults();
    final scoreHistory = HiveService.getScoreHistory();

    final doc = pw.Document(
      title: 'CyberGuard AI Security Report',
      author: 'CyberGuard AI',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          _header(settings),
          pw.SizedBox(height: 24),
          _scoreCard(settings),
          pw.SizedBox(height: 20),
          _moduleBreakdown(settings),
          pw.SizedBox(height: 20),
          _threatsSection(alerts),
          pw.SizedBox(height: 20),
          _scanHistorySection(scanResults),
          pw.SizedBox(height: 20),
          _scoreTrendSection(scoreHistory),
          pw.SizedBox(height: 28),
          _recommendations(settings),
          pw.SizedBox(height: 24),
          _footer(),
        ],
      ),
    );

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .substring(0, 19)
        .replaceAll(':', '-');
    final file = File('${dir.path}/cyberguard_report_$stamp.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'CyberGuard AI Security Report',
    );
    return file;
  }

  /// CSV export: one row per scan result. Useful for spreadsheet review.
  static Future<File> exportCsv() async {
    final scans = HiveService.getScanResults();
    final alerts = HiveService.getAlerts();

    final rows = <List<dynamic>>[
      ['type', 'input', 'verdict', 'confidence', 'reasons', 'timestamp'],
      ...scans.map((s) => [
            s.type,
            s.input,
            s.verdict,
            s.confidence,
            s.shapReasons.join(' | '),
            s.timestamp.toIso8601String(),
          ]),
      [],
      ['alert_id', 'type', 'module', 'title', 'description', 'timestamp'],
      ...alerts.map((a) => [
            a.id,
            a.type,
            a.module,
            a.title,
            a.description,
            a.timestamp.toIso8601String(),
          ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .substring(0, 19)
        .replaceAll(':', '-');
    final file = File('${dir.path}/cyberguard_report_$stamp.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'CyberGuard AI Security Data',
    );
    return file;
  }

  // ─── PDF section builders ────────────────────────────────────────────────

  static pw.Widget _header(SettingsModel s) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 44,
          height: 44,
          decoration: pw.BoxDecoration(
            color: _brandBlue,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          alignment: pw.Alignment.center,
          child: pw.Text(
            'CG',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'CyberGuard AI',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: _textDark,
                ),
              ),
              pw.Text(
                'Security Report · Generated ${DateFormatter.fullDate(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 11, color: _textMed),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _scoreCard(SettingsModel s) {
    final score = s.unifiedScore;
    final status = score >= 70
        ? 'PROTECTED'
        : score >= 40
            ? 'AT RISK'
            : 'CRITICAL';
    final color = score >= 70
        ? _safeColor
        : score >= 40
            ? _warningColor
            : _dangerColor;

    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromInt(0xFFE8E8E8)),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Overall Security Score',
                  style: const pw.TextStyle(color: _textMed, fontSize: 12)),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(color.toInt() & 0x33FFFFFF),
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(status,
                    style: pw.TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold)),
              ),
              if (s.lastScanDate != null) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                    'Last scanned ${DateFormatter.timeAgo(s.lastScanDate!)}',
                    style:
                        const pw.TextStyle(color: _textMed, fontSize: 11)),
              ],
            ],
          ),
          pw.Spacer(),
          pw.Text(
            '$score',
            style: pw.TextStyle(
              fontSize: 56,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 26),
            child: pw.Text('/100',
                style: const pw.TextStyle(color: _textMed, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _moduleBreakdown(SettingsModel s) {
    final modules = [
      ('Phishing detection', s.phishingScore),
      ('Malware scanner', s.malwareScore),
      ('Breach monitor', s.breachScore),
      ('Wi-Fi security', s.wifiScore),
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Module breakdown',
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _textDark)),
        pw.SizedBox(height: 10),
        ...modules.map((m) {
          // A4 minus 32pt margins ≈ 530pt of usable width. After the
          // 140pt label and 12+24pt for the right-side score we have
          // ~354pt for the bar — pick a clean fixed width that fits.
          const barTotal = 320.0;
          final fillWidth =
              (barTotal * (m.$2 / 100)).clamp(0.0, barTotal).toDouble();
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 5),
            child: pw.Row(
              children: [
                pw.SizedBox(
                    width: 140,
                    child: pw.Text(m.$1,
                        style: const pw.TextStyle(
                            fontSize: 11, color: _textDark))),
                pw.Container(
                  width: barTotal,
                  height: 6,
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFF0F0F0),
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Container(
                      width: fillWidth,
                      height: 6,
                      decoration: pw.BoxDecoration(
                        color: m.$2 >= 70
                            ? _safeColor
                            : m.$2 >= 40
                                ? _warningColor
                                : _dangerColor,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Text('${m.$2}',
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: _textDark)),
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _threatsSection(List<AlertModel> alerts) {
    final unread = alerts.where((a) => !a.isRead).toList();
    final critical = alerts.where((a) => a.type == 'critical').take(5).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
            'Threats & alerts (${alerts.length} total · ${unread.length} unread)',
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _textDark)),
        pw.SizedBox(height: 8),
        if (alerts.isEmpty)
          pw.Text('No threats detected.',
              style: const pw.TextStyle(color: _textMed, fontSize: 11))
        else ...[
          for (final a in critical.isEmpty ? alerts.take(5) : critical)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 6),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFFAFAFA),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border(
                    left: pw.BorderSide(
                        color: a.type == 'critical'
                            ? _dangerColor
                            : _warningColor,
                        width: 3)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(a.title,
                            style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: _textDark)),
                      ),
                      pw.Text(
                        '${a.module.toUpperCase()} · ${DateFormatter.timeAgo(a.timestamp)}',
                        style: const pw.TextStyle(
                            color: _textMed, fontSize: 9),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(a.description,
                      style:
                          const pw.TextStyle(color: _textMed, fontSize: 10)),
                ],
              ),
            ),
        ],
      ],
    );
  }

  static pw.Widget _scanHistorySection(List<ScanResultModel> scans) {
    final recent = scans.take(8).toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Recent scans',
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _textDark)),
        pw.SizedBox(height: 8),
        if (recent.isEmpty)
          pw.Text('No scans yet.',
              style: const pw.TextStyle(color: _textMed, fontSize: 11))
        else
          pw.Table(
            border: pw.TableBorder.symmetric(
              inside: pw.BorderSide(
                  color: PdfColor.fromInt(0xFFF0F0F0), width: 0.5),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(4),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFAFAFA)),
                children: [
                  _th('Type'),
                  _th('Input'),
                  _th('Verdict'),
                  _th('When'),
                ],
              ),
              for (final s in recent)
                pw.TableRow(children: [
                  _td(s.type),
                  _td(s.input.length > 40
                      ? '${s.input.substring(0, 40)}…'
                      : s.input),
                  _td(
                    s.verdict,
                    color: s.verdict == 'safe' ? _safeColor : _dangerColor,
                    bold: true,
                  ),
                  _td(DateFormatter.timeAgo(s.timestamp)),
                ]),
            ],
          ),
      ],
    );
  }

  static pw.Widget _scoreTrendSection(List<ScoreEntryModel> history) {
    if (history.isEmpty) return pw.SizedBox.shrink();
    final last7 = history.take(7).toList().reversed.toList();
    final scores = last7.map((e) => e.unifiedScore).toList();
    final avg = scores.reduce((a, b) => a + b) ~/ scores.length;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('7-day score trend',
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _textDark)),
        pw.SizedBox(height: 4),
        pw.Text(
            'Average: $avg/100 · Best: ${scores.reduce((a, b) => a > b ? a : b)} · Worst: ${scores.reduce((a, b) => a < b ? a : b)}',
            style: const pw.TextStyle(color: _textMed, fontSize: 11)),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            for (final e in last7)
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                  child: pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Container(
                        height: 50,
                        alignment: pw.Alignment.bottomCenter,
                        child: pw.Container(
                          height: (e.unifiedScore * 0.5),
                          decoration: pw.BoxDecoration(
                            color: e.unifiedScore >= 70
                                ? _safeColor
                                : e.unifiedScore >= 40
                                    ? _warningColor
                                    : _dangerColor,
                            borderRadius: pw.BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('${e.unifiedScore}',
                          style: const pw.TextStyle(
                              fontSize: 9, color: _textMed)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _recommendations(SettingsModel s) {
    final tips = <String>[];
    if (s.phishingScore < 60) {
      tips.add(
          'Run a phishing scan on all suspicious links before opening them.');
    }
    if (s.malwareScore < 60) {
      tips.add(
          'Review high-risk apps in the Malware Scanner and uninstall unknown ones.');
    }
    if (s.breachScore < 60) {
      tips.add(
          'Change passwords on every breached account and enable two-factor auth.');
    }
    if (s.wifiScore < 60) {
      tips.add(
          'Disconnect from public Wi-Fi or use a VPN when banking or shopping.');
    }
    if (tips.isEmpty) {
      tips.add('Keep your apps and Android system updated.');
      tips.add('Enable biometric / PIN screen lock on every device.');
      tips.add('Use a password manager and unique passwords per account.');
    }
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFE8F0FE),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Recommendations',
              style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: _brandBlue)),
          pw.SizedBox(height: 6),
          for (final tip in tips)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('• ',
                      style: const pw.TextStyle(
                          color: _brandBlue, fontSize: 11)),
                  pw.Expanded(
                    child: pw.Text(tip,
                        style: const pw.TextStyle(
                            color: _textDark, fontSize: 11)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _footer() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: PdfColor.fromInt(0xFFE8E8E8)),
        pw.SizedBox(height: 6),
        pw.Text(
          'Generated on-device by CyberGuard AI · No data was sent to any server.',
          style: const pw.TextStyle(color: _textMed, fontSize: 9),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  static pw.Widget _th(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _textDark)),
      );

  static pw.Widget _td(String text, {PdfColor? color, bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 9.5,
                color: color ?? _textDark,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );
}
