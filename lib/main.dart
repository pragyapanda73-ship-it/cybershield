import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

const String backendUrl = 'http://127.0.0.1:5000';

void main() {
  runApp(const CyberShieldApp());
}

// ============================================================
// APP
// ============================================================

class CyberShieldApp extends StatelessWidget {
  const CyberShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CYBERSHIELD',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
      ),
      home: const HomeScreen(),
    );
  }
}

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> recentScans = [];
  bool isLoadingHistory = true;
  String? historyError;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      print('Loading scan history...');

      final response = await http.get(
        Uri.parse('$backendUrl/api/history'),
      );

      print('HISTORY STATUS: ${response.statusCode}');
      print('HISTORY RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          recentScans = data['history'] is List
              ? List<Map<String, dynamic>>.from(
                  data['history'],
                )
              : [];

          isLoadingHistory = false;
          historyError = null;
        });
      } else {
        setState(() {
          isLoadingHistory = false;
          historyError =
              'Server returned ${response.statusCode}';
        });
      }
    } catch (e) {
      print('HISTORY ERROR: $e');

      setState(() {
        isLoadingHistory = false;
        historyError = e.toString();
      });
    }
  }

  Future<void> openScanner(String type) async {
    if (type == 'URL') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const UrlScannerScreen(),
        ),
      );
    } else if (type == 'TEXT') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const TextScannerScreen(),
        ),
      );
    } else if (type == 'SCREENSHOT') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ScreenshotAnalyzerScreen(),
        ),
      );
    }

    loadHistory();
  }

  int getHighCount() {
    return recentScans
        .where((scan) => scan['risk_level'] == 'HIGH RISK')
        .length;
  }

  int getMediumCount() {
    return recentScans
        .where((scan) => scan['risk_level'] == 'MEDIUM RISK')
        .length;
  }

  int getLowCount() {
    return recentScans
        .where((scan) => scan['risk_level'] == 'LOW RISK')
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),

      // --------------------------------------------------------
      // APP BAR
      // --------------------------------------------------------

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Row(
          children: const [
            Icon(
              Icons.shield_rounded,
              color: Colors.blue,
              size: 30,
            ),
            SizedBox(width: 10),
            Text(
              'CYBERSHIELD',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: loadHistory,
          ),
        ],
      ),

      // --------------------------------------------------------
      // BODY
      // --------------------------------------------------------

      body: RefreshIndicator(
        onRefresh: loadHistory,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            30,
          ),
          children: [

            // ==================================================
            // HERO
            // ==================================================

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1565C0),
                    Color(0xFF42A5F5),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.20),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Your Digital\nSafety Guard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Detect suspicious links, messages '
                          'and screenshots before you interact '
                          'with them.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // SCANNER TITLE
            // ==================================================

            const Text(
              'Security Scanner',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Choose what you want to check',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // SCANNER BUTTONS
            // ==================================================

            Row(
              children: [
                Expanded(
                  child: HomeScannerCard(
                    icon: Icons.link_rounded,
                    title: 'URL',
                    subtitle: 'Check links',
                    color: Colors.blue,
                    onTap: () => openScanner('URL'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: HomeScannerCard(
                    icon: Icons.message_rounded,
                    title: 'Message',
                    subtitle: 'Check text',
                    color: Colors.deepPurple,
                    onTap: () => openScanner('TEXT'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: HomeScannerCard(
                    icon: Icons.image_rounded,
                    title: 'Screenshot',
                    subtitle: 'Scan image',
                    color: Colors.teal,
                    onTap: () => openScanner('SCREENSHOT'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ==================================================
            // SECURITY OVERVIEW
            // ==================================================

            const Text(
              'Security Overview',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OverviewCard(
                    title: 'Total',
                    value: recentScans.length,
                    icon: Icons.analytics_rounded,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: OverviewCard(
                    title: 'High',
                    value: getHighCount(),
                    icon: Icons.warning_rounded,
                    color: Colors.red,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: OverviewCard(
                    title: 'Medium',
                    value: getMediumCount(),
                    icon: Icons.error_outline_rounded,
                    color: Colors.orange,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: OverviewCard(
                    title: 'Low',
                    value: getLowCount(),
                    icon: Icons.check_circle_rounded,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ==================================================
            // SAFETY TIP
            // ==================================================

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.10),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lightbulb_rounded,
                      color: Colors.blue,
                    ),
                  ),

                  const SizedBox(width: 14),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stay Safe Online',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Never share OTPs, passwords or banking '
                          'details with suspicious sources.',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // RECENT SCANS
            // ==================================================

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Scans',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                if (recentScans.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const HistoryScreen(),
                        ),
                      );

                      loadHistory();
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            if (isLoadingHistory)
              const Padding(
                padding: EdgeInsets.all(25),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )

            else if (historyError != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        color: Colors.red,
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Unable to load scan history',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: loadHistory,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )

            else if (recentScans.isEmpty)
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 42,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'No scans yet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your security checks will appear here.',
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              )

            else
              ...recentScans
                  .take(5)
                  .map(
                    (scan) => RecentScanCard(
                      scan: scan,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HOME SCANNER CARD
// ============================================================

class HomeScannerCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const HomeScannerCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 6,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 27,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// OVERVIEW CARD
// ============================================================

class OverviewCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const OverviewCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),
          const SizedBox(height: 7),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// RECENT SCAN CARD
// ============================================================

class RecentScanCard extends StatelessWidget {
  final Map<String, dynamic> scan;

  const RecentScanCard({
    super.key,
    required this.scan,
  });

  Color riskColor(String risk) {
    if (risk.contains('HIGH')) {
      return Colors.red;
    }

    if (risk.contains('MEDIUM')) {
      return Colors.orange;
    }

    if (risk.contains('LOW')) {
      return Colors.green;
    }

    return Colors.grey;
  }

  IconData scanIcon(String type) {
    if (type == 'URL') {
      return Icons.link;
    }

    if (type == 'MESSAGE') {
      return Icons.message_outlined;
    }

    if (type == 'SCREENSHOT') {
      return Icons.image_outlined;
    }

    return Icons.security;
  }

  @override
  Widget build(BuildContext context) {
    final String type =
        scan['scan_type']?.toString() ?? 'UNKNOWN';

    final String input =
        scan['input_text']?.toString() ?? '';

    final String risk =
        scan['risk_level']?.toString() ?? 'UNKNOWN';

    final String score =
        scan['risk_score']?.toString() ?? '0';

    final String createdAt =
        scan['created_at']?.toString() ?? '';

    final color = riskColor(risk);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  scanIcon(type),
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  type,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    risk,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              input,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Text(
                  'Risk Score: $score/100',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    createdAt,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HISTORY SCREEN
// ============================================================

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() =>
      _HistoryScreenState();
}

class _HistoryScreenState
    extends State<HistoryScreen> {
  List<Map<String, dynamic>> scans = [];

  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/history'),
      );

      print(
        'HISTORY SCREEN STATUS: '
        '${response.statusCode}',
      );

      print(
        'HISTORY SCREEN RESPONSE: '
        '${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          scans = data['history'] is List
              ? List<Map<String, dynamic>>.from(
                  data['history'],
                )
              : [];

          isLoading = false;
          error = null;
        });
      } else {
        setState(() {
          isLoading = false;
          error =
              'Server returned ${response.statusCode}';
        });
      }
    } catch (e) {
      print('HISTORY SCREEN ERROR: $e');

      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  int countRisk(String level) {
    return scans
        .where(
          (scan) =>
              scan['risk_level']?.toString() == level,
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final high = countRisk('HIGH RISK');
    final medium = countRisk('MEDIUM RISK');
    final low = countRisk('LOW RISK');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadHistory,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 45,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Unable to load history',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: loadHistory,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadHistory,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: HistoryStatCard(
                              title: 'Total',
                              value: scans.length,
                              icon: Icons.history,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: HistoryStatCard(
                              title: 'High',
                              value: high,
                              icon: Icons.warning,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: HistoryStatCard(
                              title: 'Medium',
                              value: medium,
                              icon: Icons.error_outline,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: HistoryStatCard(
                              title: 'Low',
                              value: low,
                              icon: Icons.check_circle_outline,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      if (scans.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(30),
                            child: Text(
                              'No scans available.',
                            ),
                          ),
                        )
                      else
                        ...scans.map(
                          (scan) => RecentScanCard(
                            scan: scan,
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

// ============================================================
// HISTORY STAT CARD
// ============================================================

class HistoryStatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;

  const HistoryStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// URL SCANNER
// ============================================================

class UrlScannerScreen extends StatefulWidget {
  const UrlScannerScreen({super.key});

  @override
  State<UrlScannerScreen> createState() =>
      _UrlScannerScreenState();
}

class _UrlScannerScreenState
    extends State<UrlScannerScreen> {
  final TextEditingController urlController =
      TextEditingController();

  bool isLoading = false;

  String riskLevel = '';
  int riskScore = 0;
  List<String> warnings = [];
  String recommendation = '';

  Future<void> analyzeUrl() async {
    final url = urlController.text.trim();

    if (url.isEmpty) {
      showError('Please enter a URL');
      return;
    }

    setState(() {
      isLoading = true;
      riskLevel = '';
      warnings = [];
      recommendation = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/analyze-url'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'url': url,
        }),
      );

      print('URL STATUS: ${response.statusCode}');
      print('URL RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          riskLevel =
              data['risk_level']?.toString() ?? '';
          riskScore =
              data['risk_score'] ?? 0;
          warnings = List<String>.from(
            data['warnings'] ?? [],
          );
          recommendation =
              data['recommendation']?.toString() ?? '';
        });
      } else {
        showError(
          'URL analysis failed: '
          '${response.statusCode}',
        );
      }
    } catch (e) {
      showError(
        'Could not connect to backend.\n$e',
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScannerPage(
      title: 'Scan URL',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          TextField(
            controller: urlController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: 'https://example.com',
              labelText: 'Enter URL',
              prefixIcon:
                  const Icon(Icons.link),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
                  isLoading ? null : analyzeUrl,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(
                isLoading
                    ? 'Analyzing...'
                    : 'Analyze URL',
              ),
            ),
          ),

          const SizedBox(height: 25),

          if (riskLevel.isNotEmpty)
            SecurityResultCard(
              riskLevel: riskLevel,
              riskScore: riskScore,
              warnings: warnings,
              recommendation:
                  recommendation,
            ),
        ],
      ),
    );
  }
}

// ============================================================
// TEXT SCANNER
// ============================================================

class TextScannerScreen extends StatefulWidget {
  const TextScannerScreen({super.key});

  @override
  State<TextScannerScreen> createState() =>
      _TextScannerScreenState();
}

class _TextScannerScreenState
    extends State<TextScannerScreen> {
  final TextEditingController messageController =
      TextEditingController();

  bool isLoading = false;

  String riskLevel = '';
  int riskScore = 0;
  List<String> warnings = [];
  String recommendation = '';

  Future<void> analyzeMessage() async {
    final message =
        messageController.text.trim();

    if (message.isEmpty) {
      showError('Please enter a message');
      return;
    }

    setState(() {
      isLoading = true;
      riskLevel = '';
      warnings = [];
      recommendation = '';
    });

    try {
      final response = await http.post(
        Uri.parse(
          '$backendUrl/api/analyze-message',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
        }),
      );

      print(
        'MESSAGE STATUS: '
        '${response.statusCode}',
      );

      print(
        'MESSAGE RESPONSE: '
        '${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          riskLevel =
              data['risk_level']?.toString() ?? '';
          riskScore =
              data['risk_score'] ?? 0;
          warnings = List<String>.from(
            data['warnings'] ?? [],
          );
          recommendation =
              data['recommendation']?.toString() ?? '';
        });
      } else {
        showError(
          'Message analysis failed: '
          '${response.statusCode}',
        );
      }
    } catch (e) {
      showError(
        'Could not connect to backend.\n$e',
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScannerPage(
      title: 'Scan Message',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          TextField(
            controller: messageController,
            maxLines: 8,
            decoration: InputDecoration(
              hintText:
                  'Paste a suspicious SMS, email or message...',
              labelText: 'Message',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding:
                    EdgeInsets.only(bottom: 120),
                child: Icon(
                  Icons.message_outlined,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isLoading
                  ? null
                  : analyzeMessage,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(
                isLoading
                    ? 'Analyzing...'
                    : 'Analyze Message',
              ),
            ),
          ),

          const SizedBox(height: 25),

          if (riskLevel.isNotEmpty)
            SecurityResultCard(
              riskLevel: riskLevel,
              riskScore: riskScore,
              warnings: warnings,
              recommendation:
                  recommendation,
            ),
        ],
      ),
    );
  }
}

// ============================================================
// SCREENSHOT ANALYZER
// ============================================================

class ScreenshotAnalyzerScreen
    extends StatefulWidget {
  const ScreenshotAnalyzerScreen({
    super.key,
  });

  @override
  State<ScreenshotAnalyzerScreen> createState() =>
      _ScreenshotAnalyzerScreenState();
}

class _ScreenshotAnalyzerScreenState
    extends State<ScreenshotAnalyzerScreen> {
  final ImagePicker picker = ImagePicker();

  XFile? selectedImage;

  bool isLoading = false;

  String extractedText = '';

  String riskLevel = '';
  int riskScore = 0;
  List<String> warnings = [];
  String recommendation = '';

  Future<void> pickScreenshot() async {
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) {
        return;
      }

      setState(() {
        selectedImage = image;
        extractedText = '';
        riskLevel = '';
        riskScore = 0;
        warnings = [];
        recommendation = '';
      });
    } catch (e) {
      showError(
        'Could not select image.\n$e',
      );
    }
  }

  Future<void> analyzeScreenshot() async {
    if (selectedImage == null) {
      showError(
        'Please select a screenshot first',
      );
      return;
    }

    setState(() {
      isLoading = true;
      riskLevel = '';
      warnings = [];
      recommendation = '';
    });

    try {
      // OCR
      final String text =
          await FlutterTesseractOcr.extractText(
        selectedImage!.path,
        language: 'eng',
      );

      final cleanText = text.trim();

      setState(() {
        extractedText = cleanText;
      });

      if (cleanText.isEmpty) {
        showError(
          'No readable text was found in the screenshot.',
        );
        return;
      }

      // Backend analysis
      final response = await http.post(
        Uri.parse(
          '$backendUrl/api/analyze-screenshot',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': cleanText,
        }),
      );

      print(
        'SCREENSHOT STATUS: '
        '${response.statusCode}',
      );

      print(
        'SCREENSHOT RESPONSE: '
        '${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          riskLevel =
              data['risk_level']?.toString() ?? '';
          riskScore =
              data['risk_score'] ?? 0;
          warnings = List<String>.from(
            data['warnings'] ?? [],
          );
          recommendation =
              data['recommendation']?.toString() ?? '';
        });
      } else {
        showError(
          'Screenshot analysis failed: '
          '${response.statusCode}',
        );
      }
    } catch (e) {
      showError(
        'Screenshot analysis failed.\n$e',
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScannerPage(
      title: 'Analyze Screenshot',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed:
                  isLoading
                      ? null
                      : pickScreenshot,
              icon: const Icon(
                Icons.upload_file,
              ),
              label: const Text(
                'Select Screenshot',
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (selectedImage != null)
            Card(
              clipBehavior:
                  Clip.antiAlias,
              child: SizedBox(
                height: 300,
                width: double.infinity,
                child: Image.network(
                  selectedImage!.path,
                  fit: BoxFit.contain,
                  errorBuilder:
                      (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.image,
                        size: 80,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),

          if (selectedImage != null)
            const SizedBox(height: 15),

          if (selectedImage != null)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    isLoading
                        ? null
                        : analyzeScreenshot,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.security,
                      ),
                label: Text(
                  isLoading
                      ? 'Analyzing Screenshot...'
                      : 'Analyze Screenshot',
                ),
              ),
            ),

          const SizedBox(height: 20),

          if (extractedText.isNotEmpty)
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Extracted Text',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      extractedText,
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 15),

          if (riskLevel.isNotEmpty)
            SecurityResultCard(
              riskLevel: riskLevel,
              riskScore: riskScore,
              warnings: warnings,
              recommendation:
                  recommendation,
            ),
        ],
      ),
    );
  }
}

// ============================================================
// SCANNER PAGE
// ============================================================

class ScannerPage extends StatelessWidget {
  final String title;
  final Widget child;

  const ScannerPage({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

// ============================================================
// SECURITY RESULT CARD
// ============================================================

class SecurityResultCard extends StatelessWidget {
  final String riskLevel;
  final int riskScore;
  final List<String> warnings;
  final String recommendation;

  const SecurityResultCard({
    super.key,
    required this.riskLevel,
    required this.riskScore,
    required this.warnings,
    required this.recommendation,
  });

  Color getRiskColor() {
    if (riskLevel.contains('HIGH')) {
      return Colors.red;
    }

    if (riskLevel.contains('MEDIUM')) {
      return Colors.orange;
    }

    if (riskLevel.contains('LOW')) {
      return Colors.green;
    }

    return Colors.grey;
  }

  IconData getRiskIcon() {
    if (riskLevel.contains('HIGH')) {
      return Icons.dangerous_outlined;
    }

    if (riskLevel.contains('MEDIUM')) {
      return Icons.warning_amber_outlined;
    }

    if (riskLevel.contains('LOW')) {
      return Icons.check_circle_outline;
    }

    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    final color = getRiskColor();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // Risk header
            Row(
              children: [
                Icon(
                  getRiskIcon(),
                  color: color,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    riskLevel,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Text(
              'Risk Score: $riskScore/100',
              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            // Warning signs
            if (warnings.isNotEmpty) ...[
              const Text(
                'Warning Signs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              ...warnings.map(
                (warning) => Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 8,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 20,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Recommendation
            if (recommendation.isNotEmpty) ...[
              const SizedBox(height: 15),

              const Text(
                'Safety Recommendation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue
                      .withOpacity(0.08),
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child: Text(
                  recommendation,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}