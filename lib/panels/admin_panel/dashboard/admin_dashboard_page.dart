// lib/admin_panel/dashboard/admin_dashboard_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_languageapplicationmycourse_2/models/user_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:html' as html;
import 'package:flutter/services.dart' show rootBundle;

// --- НОВЫЕ ИМПОРТЫ ДЛЯ ФУНКЦИИ ПОДДЕРЖКИ ---
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_languageapplicationmycourse_2/database/auth/chatservice.dart';
import 'package:flutter_languageapplicationmycourse_2/database/collections/users_collections.dart';
import 'package:flutter_languageapplicationmycourse_2/pages/chatPage/MessagePage.dart';
// --- КОНЕЦ НОВЫХ ИМПОРТОВ ---

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScreenshotController _chartScreenshotController =
      ScreenshotController();

  // --- НОВЫЕ ПЕРЕМЕННЫЕ ДЛЯ ФУНКЦИИ ПОДДЕРЖКИ ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatService _chatService = ChatService();
  final UsersCollection _usersCollection = UsersCollection();
  // UID аккаунта поддержки, скопированный из ProfilePage
  static const String SUPPORT_TEAM_UID = "V9hSE7mZldWy23FDNob0cS4F22G3";
  // --- КОНЕЦ НОВЫХ ПЕРЕМЕННЫХ ---

  int _totalUsers = 0;
  int _newUsersToday = 0;
  Map<String, int> _usersByRole = {};
  int _totalLearningModules = 0;
  List<FlSpot> _newUsersChartData = [];
  int _maxNewUsersForChart = 5;

  bool _isLoading = true;
  bool _isGeneratingPdf = false;
  pw.Font? _pdfFont;

  @override
  void initState() {
    super.initState();
    _loadPdfFont();
    _fetchStatistics();
  }

  Future<void> _loadPdfFont() async {
    try {
      final fontData = await rootBundle.load("fonts/ofont.ru_Roboto.ttf");
      _pdfFont = pw.Font.ttf(fontData);
      print("PDF font loaded successfully.");
    } catch (e) {
      print("Error loading PDF font: $e");
    }
  }

  Future<void> _fetchStatistics() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final usersSnap = await _firestore.collection('users').get();
      _totalUsers = usersSnap.size;

      Map<int, int> dailyNewUsers = {};
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);

      for (int i = 6; i >= 0; i--) {
        final day = todayDate.subtract(Duration(days: i));
        dailyNewUsers[day.millisecondsSinceEpoch] = 0;
      }

      int tempNewUsersToday = 0;
      Map<String, int> roleCounts = {
        UserRoles.user: 0,
        UserRoles.admin: 0,
        UserRoles.support: 0,
        'unknown': 0,
      };

      for (var doc in usersSnap.docs) {
        final data = doc.data();
        final regDateTimestamp = data['registrationDate'] as Timestamp?;
        if (regDateTimestamp != null) {
          final regDate = regDateTimestamp.toDate();
          final regDayOnly = DateTime(regDate.year, regDate.month, regDate.day);

          if (regDayOnly.isAtSameMomentAs(todayDate)) {
            tempNewUsersToday++;
          }
          if (dailyNewUsers.containsKey(regDayOnly.millisecondsSinceEpoch)) {
            dailyNewUsers[regDayOnly.millisecondsSinceEpoch] =
                dailyNewUsers[regDayOnly.millisecondsSinceEpoch]! + 1;
          }
        }
        String role = data['role'] as String? ?? 'unknown';
        roleCounts[role] = (roleCounts[role] ?? 0) + 1;
      }
      _newUsersToday = tempNewUsersToday;
      _usersByRole = roleCounts;

      _newUsersChartData = [];
      int chartXIndex = 0;
      _maxNewUsersForChart = 5;
      for (int i = 6; i >= 0; i--) {
        final day = todayDate.subtract(Duration(days: i));
        final count = dailyNewUsers[day.millisecondsSinceEpoch] ?? 0;
        _newUsersChartData
            .add(FlSpot(chartXIndex.toDouble(), count.toDouble()));
        if (count > _maxNewUsersForChart) {
          _maxNewUsersForChart = count;
        }
        chartXIndex++;
      }
      if (_newUsersChartData.isNotEmpty && _maxNewUsersForChart < 5)
        _maxNewUsersForChart = 5;

      final modulesSnap = await _firestore.collection('learning_modules').get();
      _totalLearningModules = modulesSnap.size;
    } catch (e) {
      print("Error fetching statistics: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка загрузки статистики: $e'),
              backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // --- НОВЫЙ МЕТОД ДЛЯ НАЧАЛА ЧАТА С ПОДДЕРЖКОЙ (логика из ProfilePage) ---
  Future<void> _startChatWithSupport() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Для начала чата необходимо войти в систему.")));
      return;
    }
    if (currentUser.uid == SUPPORT_TEAM_UID) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text("Вы не можете начать чат с самим собой (поддержкой).")));
      return;
    }

    try {
      DocumentSnapshot chatDocSnapshot = await _chatService
          .getOrCreateChatWithSupport(currentUser.uid, SUPPORT_TEAM_UID);

      String chatId = chatDocSnapshot.id;
      String supportUserName = "Поддержка";

      try {
        UserModel? supportUserModel =
            await _usersCollection.getUserModel(SUPPORT_TEAM_UID);
        if (supportUserModel != null) {
          supportUserName =
              "${supportUserModel.firstName} ${supportUserModel.lastName}"
                  .trim();
          if (supportUserName.isEmpty) {
            supportUserName = supportUserModel.email;
          }
        }
      } catch (e) {
        print("Could not fetch support user name: $e");
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagesPage(
              chatId: chatId,
              initialOtherUserName: supportUserName,
            ),
          ),
        );
      }
    } catch (e) {
      print("Error starting/getting chat with support: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Не удалось начать чат с поддержкой: $e"),
            backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, color: color, size: 22),
                )
              ],
            ),
            Text(
              _isLoading ? "..." : value,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleDistributionCard() {
    if (_isLoading && _usersByRole.isEmpty)
      return const Center(child: Text("Загрузка распределения ролей..."));

    List<Widget> roleWidgets = _usersByRole.entries
        .where((entry) => entry.value > 0)
        .map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(UserRoles.displayRole(entry.key),
                      style: const TextStyle(fontSize: 15)),
                  Text(entry.value.toString(),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ))
        .toList();

    if (roleWidgets.isEmpty && !_isLoading)
      return const Text("Нет данных по ролям.");

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Распределение по ролям",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColorDark),
            ),
            const Divider(height: 20),
            if (_isLoading && roleWidgets.isEmpty)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else
              ...roleWidgets,
          ],
        ),
      ),
    );
  }

  Widget _buildNewUsersChartCard() {
    if (_isLoading && _newUsersChartData.isEmpty) {
      return const SizedBox(
          height: 250, child: Center(child: CircularProgressIndicator()));
    }
    if (_newUsersChartData.isEmpty && !_isLoading) {
      return const SizedBox(
          height: 250,
          child: Center(
              child: Text("Нет данных для графика новых пользователей.")));
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 24, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Новые пользователи (за 7 дней)",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColorDark),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: (_maxNewUsersForChart / 4)
                        .clamp(1.0, _maxNewUsersForChart.toDouble()),
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: Colors.grey.shade300, strokeWidth: 0.5),
                    getDrawingVerticalLine: (value) =>
                        FlLine(color: Colors.grey.shade300, strokeWidth: 0.5),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: (_maxNewUsersForChart / 4)
                                .roundToDouble()
                                .clamp(1.0, _maxNewUsersForChart.toDouble()),
                            getTitlesWidget: _leftTitleWidgets)),
                    bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: _bottomTitleWidgets)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.shade400)),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: _maxNewUsersForChart.toDouble() == 0
                      ? 5
                      : _maxNewUsersForChart.toDouble() +
                          (_maxNewUsersForChart * 0.2).ceilToDouble(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _newUsersChartData,
                      isCurved: true,
                      color: Colors.teal,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                          show: true, color: Colors.teal.withOpacity(0.2)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== ИСПРАВЛЕНИЕ ЗДЕСЬ =====================
  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    if (value == meta.max || value == meta.min) {
      return Container();
    }
    return SideTitleWidget(
      space: 4,
      angle: 0,
      child:
          Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
      meta: meta, // ИСПРАВЛЕНИЕ: Добавлен обязательный параметр 'meta'
    );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10);
    String text;
    final day = DateTime.now().subtract(Duration(days: (6 - value).toInt()));
    text = "${day.day}/${day.month}";
    return SideTitleWidget(
      space: 4,
      angle: 0,
      child: Text(text, style: style),
      meta: meta, // ИСПРАВЛЕНИЕ: Добавлен обязательный параметр 'meta'
    );
  }
  // ===================== КОНЕЦ ИСПРАВЛЕНИЯ =====================

  Future<void> _generatePdfReport() async {
    if (_isLoading) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Данные еще загружаются. Пожалуйста, подождите.')),
      );
      return;
    }
    if (_pdfFont == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Шрифт для PDF не загружен. Кириллица может не отображаться корректно.'),
            backgroundColor: Colors.orange),
      );
    }
    setState(() => _isGeneratingPdf = true);

    final pdf = pw.Document();

    final pw.ThemeData pdfTheme = pw.ThemeData.withFont(
      base: _pdfFont ?? pw.Font.helvetica(),
      bold: _pdfFont ?? pw.Font.helveticaBold(),
      italic: _pdfFont ?? pw.Font.helveticaOblique(),
      boldItalic: _pdfFont ?? pw.Font.helveticaBoldOblique(),
    );

    Uint8List? chartImageBytes;
    try {
      chartImageBytes = await _chartScreenshotController.capture(
          delay: const Duration(milliseconds: 200), pixelRatio: 1.5);
    } catch (e) {
      print("Error capturing chart screenshot: $e");
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: pdfTheme,
          margin: const pw.EdgeInsets.all(30),
        ),
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            return pw.Column(children: [
              pw.Text("Отчет администратора LingoQuest",
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                  "Сформировано: ${DateTime.now().toLocal().toString().substring(0, 16)}"),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 10)
            ]);
          }
          return pw.Container();
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
            child: pw.Text(
              'Страница ${context.pageNumber} из ${context.pagesCount}',
              style: pw.Theme.of(context)
                  .defaultTextStyle
                  .copyWith(color: PdfColors.grey),
            ),
          );
        },
        build: (pw.Context context) => [
          pw.Header(level: 1, text: "Общая статистика"),
          pw.SizedBox(height: 5),
          pw.Bullet(text: "Всего пользователей: $_totalUsers"),
          pw.Bullet(text: "Новых пользователей сегодня: $_newUsersToday"),
          pw.Bullet(text: "Всего учебных модулей: $_totalLearningModules"),
          pw.SizedBox(height: 10),
          pw.Header(level: 1, text: "Распределение пользователей по ролям"),
          pw.SizedBox(height: 5),
          ..._usersByRole.entries.where((entry) => entry.value > 0).map(
              (entry) => pw.Bullet(
                  text: "${UserRoles.displayRole(entry.key)}: ${entry.value}")),
          pw.SizedBox(height: 20),
          if (chartImageBytes != null) ...[
            pw.Header(level: 1, text: "Новые пользователи (график за 7 дней)"),
            pw.SizedBox(height: 5),
            pw.Center(
              child: pw.Image(pw.MemoryImage(chartImageBytes),
                  width: 450, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
                "Примечание: График отображает количество новых регистраций за каждый из последних 7 дней.",
                style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey600,
                    fontSize: 9)),
          ] else ...[
            pw.Header(level: 1, text: "Новые пользователи (график за 7 дней)"),
            pw.Text("Не удалось захватить изображение графика."),
          ],
          pw.SizedBox(height: 20),
          pw.Paragraph(
              text: "--- Конец отчета ---",
              style: pw.TextStyle(color: PdfColors.grey)),
        ],
      ),
    );

    try {
      final Uint8List bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download",
            "LingoQuest_Admin_Report_${DateTime.now().toIso8601String().substring(0, 10)}.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('PDF отчет сформирован и скачивается.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка генерации или сохранения PDF: $e'),
              backgroundColor: Colors.red),
        );
      }
      print("Error generating or saving PDF: $e");
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Widget _buildComplaintsSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Последние жалобы",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColorDark,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchStatistics,
                ),
              ],
            ),
            const Divider(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('complaints')
                  .orderBy('timestamp', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Ошибка: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Нет жалоб'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var complaint = snapshot.data!.docs[index];
                    var data = complaint.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          'Категория: ${_getCategoryName(data['category'])}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['description']),
                            const SizedBox(height: 4),
                            Text(
                              'От: ${data['userEmail'] ?? 'Неизвестный пользователь'}',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                            Text(
                              'Статус:',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                            _getStatusBadge(data['status'] ?? 'new'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () {
                            _showComplaintDetails(context, complaint.id, data);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ComplaintsListPage(),
                    ),
                  );
                },
                child: const Text('Просмотреть все жалобы'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchStatistics,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Дашборд администратора",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: "Обновить статистику",
                    onPressed: _isLoading || _isGeneratingPdf
                        ? null
                        : _fetchStatistics,
                  )
                ],
              ),
              const SizedBox(height: 20),
              if (_isLoading && _totalUsers == 0)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ))
              else
                LayoutBuilder(builder: (context, constraints) {
                  int crossAxisCount = 3;
                  double childAspectRatio = 2.2;
                  if (constraints.maxWidth < 900) {
                    crossAxisCount = 2;
                    childAspectRatio = 1.8;
                  }
                  if (constraints.maxWidth < 550) {
                    crossAxisCount = 1;
                    childAspectRatio = 2.8;
                  }
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: childAspectRatio,
                    children: [
                      _buildStatCard(
                          "Всего пользователей",
                          _totalUsers.toString(),
                          Icons.people_alt_outlined,
                          Colors.blue.shade700),
                      _buildStatCard(
                          "Новых сегодня",
                          _newUsersToday.toString(),
                          Icons.person_add_alt_1_outlined,
                          Colors.green.shade700),
                      _buildStatCard(
                          "Учебных модулей",
                          _totalLearningModules.toString(),
                          Icons.library_books_outlined,
                          Colors.orange.shade800),
                    ],
                  );
                }),
              const SizedBox(height: 24),
              Screenshot(
                controller: _chartScreenshotController,
                child: _buildNewUsersChartCard(),
              ),
              _buildComplaintsSection(),
              const SizedBox(height: 24),
              const SizedBox(height: 24),
              _buildRoleDistributionCard(),
              const SizedBox(height: 24),
              Center(
                child: _isGeneratingPdf
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text("Сформировать PDF отчет"),
                        onPressed: _isLoading || _isGeneratingPdf
                            ? null
                            : _generatePdfReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                        ),
                      ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startChatWithSupport,
        label: const Text('Поддержка',
            style: TextStyle(fontWeight: FontWeight.w600)),
        icon: const Icon(Icons.support_agent_rounded),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 4.0,
        tooltip: 'Связаться с поддержкой',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

String _getCategoryName(String category) {
  switch (category) {
    case 'technical':
      return 'Техническая проблема';
    case 'content':
      return 'Ошибка в контенте';
    case 'behavior':
      return 'Проблема с пользователем';
    case 'other':
      return 'Другое';
    default:
      return category;
  }
}

// В методе _getStatusBadge (который должен возвращать Widget)
Widget _getStatusBadge(String status) {
  // Определяем текст статуса
  String statusText;
  switch (status) {
    case 'new':
      statusText = 'Новая';
      break;
    case 'in_progress':
      statusText = 'В работе';
      break;
    case 'resolved':
      statusText = 'Решена';
      break;
    default:
      statusText = status;
  }

  // Определяем цвет статуса
  Color statusColor;
  switch (status) {
    case 'new':
      statusColor = Colors.orange;
      break;
    case 'in_progress':
      statusColor = Colors.blue;
      break;
    case 'resolved':
      statusColor = Colors.green;
      break;
    default:
      statusColor = Colors.grey;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    decoration: BoxDecoration(
      color: statusColor.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12.0),
    ),
    child: Text(
      statusText,
      style: TextStyle(
        color: statusColor,
        fontSize: 12,
      ),
    ),
  );
}

Color _getStatusColor(String status) {
  switch (status) {
    case 'new':
      return Colors.orange;
    case 'in_progress':
      return Colors.blue;
    case 'resolved':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

void _showComplaintDetails(
    BuildContext context, String complaintId, Map<String, dynamic> data) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Жалоба #${complaintId.substring(0, 8)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Категория: ${_getCategoryName(data['category'])}'),
              const SizedBox(height: 10),
              Text('Пользователь: ${data['userEmail'] ?? 'Неизвестный'}'),
              const SizedBox(height: 10),
              Text('Дата: ${(data['timestamp'] as Timestamp).toDate()}'),
              const SizedBox(height: 10),
              const Text('Описание:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(data['description']),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: data['status'],
                items: const [
                  DropdownMenuItem(value: 'new', child: Text('Новая')),
                  DropdownMenuItem(
                      value: 'in_progress', child: Text('В работе')),
                  DropdownMenuItem(value: 'resolved', child: Text('Решена')),
                ],
                onChanged: (value) async {
                  if (value != null) {
                    await FirebaseFirestore.instance
                        .collection('complaints')
                        .doc(complaintId)
                        .update({'status': value});
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      );
    },
  );
}

// Добавьте этот новый виджет в ваш проект
class ComplaintsListPage extends StatelessWidget {
  const ComplaintsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Все жалобы'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Нет жалоб'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var complaint = snapshot.data!.docs[index];
              var data = complaint.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    'Категория: ${_getCategoryName(data['category'])}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['description'].length > 100
                          ? '${data['description'].substring(0, 100)}...'
                          : data['description']),
                      const SizedBox(height: 4),
                      Text(
                        'От: ${data['userEmail'] ?? 'Неизвестный пользователь'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        'Дата: ${(data['timestamp'] as Timestamp).toDate()}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      _getStatusBadge(data['status']),
                    ],
                  ),
                  onTap: () {
                    _showComplaintDetails(context, complaint.id, data);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
