import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'firebase_options.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:showcaseview/showcaseview.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Arka planda mesaj: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Başlatma
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Arka Plan Mesajlarını Dinle
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // AdMob Başlatma
  await MobileAds.instance.initialize();

  // Saat Dilimlerini Başlatma
  tz.initializeTimeZones();

  // --- BİLDİRİM AYARLARI (CRASH FIX BURADA) ---

  // 1. Android Ayarı
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // 2. iOS Ayarı (BU EKSİKTİ, EKLENDİ)
  // iOS 10+ için izinleri buradan istiyoruz
  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

  // 3. Genel Başlatma Ayarı
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS:
        initializationSettingsIOS, // <-- ARTIK iOS AYARI VAR, BEYAZ EKRAN VERMEZ
  );

  // 4. Plugin Başlatma
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Bildirime tıklanınca yapılacak işlemler (Gerekirse burası doldurulur)
      debugPrint('Bildirime tıklandı: ${response.payload}');
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Akıllı Abonelik',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          secondary: Colors.tealAccent,
        ),
      ),
      home: ShowCaseWidget(
        builder: (context) => const MainScreen(),
        blurValue: 1,
        autoPlay: false,
      ),
    );
  }
}

class Subscription {
  final String id;
  final String name;
  final double price;
  final int renewalDay;
  final String? logoUrl;

  Subscription({
    required this.id,
    required this.name,
    required this.price,
    required this.renewalDay,
    this.logoUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'renewalDay': renewalDay,
    'logoUrl': logoUrl,
  };

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      renewalDay: json['renewalDay'],
      logoUrl: json['logoUrl'],
    );
  }
}

Color getBrandColor(String name) {
  String lowerName = name.toLowerCase();
  if (lowerName.contains('netflix')) return const Color(0xFFE50914);
  if (lowerName.contains('spotify')) return const Color(0xFF1DB954);
  if (lowerName.contains('youtube')) return const Color(0xFFFF0000);
  if (lowerName.contains('amazon') || lowerName.contains('prime'))
    return const Color(0xFF00A8E1);
  if (lowerName.contains('disney')) return const Color(0xFF113CCF);
  if (lowerName.contains('exxen')) return const Color(0xFFFFCC00);
  if (lowerName.contains('icloud') || lowerName.contains('apple'))
    return const Color(0xFF999999);
  if (lowerName.contains('blu')) return const Color(0xFF00ADED);
  if (lowerName.contains('hbo')) return const Color(0xFF5F259F);
  return Colors.deepPurpleAccent;
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<_HomeScreenState> _homeKey = GlobalKey();

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isTutorialCompleted = false;

  final String _adUnitId = 'ca-app-pub-3940256099942544/6300978111';
  final GlobalKey _three = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();
  }

  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool seen = prefs.getBool('has_seen_tutorial_v4') ?? false;

    setState(() {
      _isTutorialCompleted = seen;
    });

    if (seen) {
      _loadBannerAd();
    }
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  void onTutorialComplete() {
    _loadBannerAd();
    setState(() {
      _isTutorialCompleted = true;
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Widget _customTooltip({
    required String title,
    required String description,
    required VoidCallback onNext,
    VoidCallback? onBack,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurpleAccent, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (onBack != null)
                TextButton(
                  onPressed: onBack,
                  child: const Text(
                    "Geri",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                const SizedBox(width: 40),

              Row(
                children: [
                  if (!isLast)
                    TextButton(
                      onPressed: () {
                        ShowCaseWidget.of(context).dismiss();
                        onTutorialComplete();
                      },
                      child: const Text(
                        "Atla",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      isLast ? "Başla" : "İleri",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: _selectedIndex == 0
                ? HomeScreen(
                    key: _homeKey,
                    onTutorialComplete: onTutorialComplete,
                    tooltipBuilder: _customTooltip,
                  )
                : StatsScreen(
                    subscriptions: _homeKey.currentState?._subs ?? [],
                  ),
          ),
          if (_isTutorialCompleted && _isAdLoaded && _bannerAd != null)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: Colors.deepPurpleAccent.withOpacity(0.5),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.list_alt_rounded),
            label: 'Abonelikler',
          ),
          NavigationDestination(
            icon: Showcase.withWidget(
              key: _three,
              targetShapeBorder: const CircleBorder(),
              container: _customTooltip(
                title: 'Harcama Analizi',
                description: 'Paranızın nereye gittiğini grafikle görün.',
                onNext: () {
                  ShowCaseWidget.of(context).dismiss();
                  onTutorialComplete();
                },
                onBack: () {
                  ShowCaseWidget.of(context).previous();
                },
                isLast: true,
              ),
              child: const Icon(Icons.pie_chart_outline_rounded),
            ),
            label: 'Analiz',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback? onTutorialComplete;
  final Widget Function({
    required String title,
    required String description,
    required VoidCallback onNext,
    VoidCallback? onBack,
    bool isLast,
  })?
  tooltipBuilder;

  const HomeScreen({super.key, this.onTutorialComplete, this.tooltipBuilder});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Subscription> _subs = [];
  StreamSubscription? _priceListener;
  bool _showYearly = false;

  final GlobalKey _one = GlobalKey();
  final GlobalKey _two = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initApp();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkAndShowTutorial(),
    );
  }

  Future<void> _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeen = prefs.getBool('has_seen_tutorial_v4') ?? false;

    if (!hasSeen) {
      // ignore: use_build_context_synchronously
      ShowCaseWidget.of(context).startShowCase([_one, _two]);
      await prefs.setBool('has_seen_tutorial_v4', true);

      if (widget.onTutorialComplete != null) {}
    }
  }

  @override
  void dispose() {
    _priceListener?.cancel();
    super.dispose();
  }

  Future<void> _initApp() async {
    await _loadData();
    _startRealtimeSync();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    // iOS için FCM izni
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Android için Yerel Bildirim İzni
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    // iOS için Yerel Bildirim İzni (GEREKSİZ OLABİLİR AMA GARANTİ OLSUN)
    final iosImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void _startRealtimeSync() {
    _priceListener = FirebaseFirestore.instance
        .collection('platforms')
        .snapshots()
        .listen((snapshot) {
          _syncPricesWithSnapshot(snapshot.docs);
        });
  }

  Future<void> _syncPricesWithSnapshot(List<QueryDocumentSnapshot> docs) async {
    bool anyChange = false;
    List<Subscription> updatedSubs = List.from(_subs);

    for (int i = 0; i < updatedSubs.length; i++) {
      var localSub = updatedSubs[i];
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        final plans = data['plans'] as List;
        for (var plan in plans) {
          if (plan['name'] == localSub.name) {
            double serverPrice = double.parse(plan['price'].toString());
            if (localSub.price != serverPrice) {
              updatedSubs[i] = Subscription(
                id: localSub.id,
                name: localSub.name,
                price: serverPrice,
                renewalDay: localSub.renewalDay,
                logoUrl: localSub.logoUrl,
              );
              anyChange = true;
            }
          }
        }
      }
    }

    if (anyChange) {
      setState(() {
        _subs = updatedSubs;
      });
      await _saveData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Fiyatlar güncellendi 💸"),
            backgroundColor: Colors.teal,
          ),
        );
      }
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('subscriptions');
    if (data != null) {
      final List<dynamic> decodedList = json.decode(data);
      setState(() {
        _subs = decodedList.map((item) => Subscription.fromJson(item)).toList();
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(
      _subs.map((e) => e.toJson()).toList(),
    );
    await prefs.setString('subscriptions', encodedData);
  }

  Future<void> _scheduleNotification(Subscription sub) async {
    int idBase = sub.name.hashCode;
    await flutterLocalNotificationsPlugin.cancel(idBase);
    await flutterLocalNotificationsPlugin.cancel(idBase + 1);

    // Android Detayları
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'payment_channel',
          'Ödeme Hatırlatıcı',
          importance: Importance.max,
          priority: Priority.high,
        );

    // iOS Detayları (BASİT BİR ŞEKİLDE EKLENDİ)
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails, // <-- iOS İÇİN BUNU EKLEMEK ŞART
    );

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduledDate2Days = _nextInstanceOfDay(
      sub.renewalDay,
      now,
    ).subtract(const Duration(days: 2));
    if (scheduledDate2Days.isBefore(now)) {
      scheduledDate2Days = _nextInstanceOfDay(
        sub.renewalDay,
        now,
        nextMonth: true,
      ).subtract(const Duration(days: 2));
    }

    tz.TZDateTime scheduledDate1Day = _nextInstanceOfDay(
      sub.renewalDay,
      now,
    ).subtract(const Duration(days: 1));
    if (scheduledDate1Day.isBefore(now)) {
      scheduledDate1Day = _nextInstanceOfDay(
        sub.renewalDay,
        now,
        nextMonth: true,
      ).subtract(const Duration(days: 1));
    }

    scheduledDate2Days = tz.TZDateTime(
      tz.local,
      scheduledDate2Days.year,
      scheduledDate2Days.month,
      scheduledDate2Days.day,
      20,
      0,
    );
    scheduledDate1Day = tz.TZDateTime(
      tz.local,
      scheduledDate1Day.year,
      scheduledDate1Day.month,
      scheduledDate1Day.day,
      20,
      0,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      idBase,
      'Hazırlıklı Ol! (${sub.name})',
      '${sub.name} ödemene 2 gün kaldı. Tutar: ${sub.price} ₺',
      scheduledDate2Days,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      idBase + 1,
      'Yarın Ödeme Var! (${sub.name})',
      '${sub.name} yarın yenileniyor. Hesabını kontrol et.',
      scheduledDate1Day,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  tz.TZDateTime _nextInstanceOfDay(
    int day,
    tz.TZDateTime now, {
    bool nextMonth = false,
  }) {
    int targetMonth = nextMonth ? now.month + 1 : now.month;
    int targetYear = now.year;
    if (targetMonth > 12) {
      targetMonth = 1;
      targetYear++;
    }
    int maxDays = DateTime(targetYear, targetMonth + 1, 0).day;
    int targetDay = day > maxDays ? maxDays : day;
    return tz.TZDateTime(tz.local, targetYear, targetMonth, targetDay);
  }

  void _showPlanSelection(
    BuildContext context,
    Map<String, dynamic> appData,
    Function(String name, double price) onSelect,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        final plans = appData['plans'] as List;
        return SimpleDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: Text(
            "${appData['name']} Planı Seç",
            style: const TextStyle(color: Colors.white),
          ),
          children: plans.map<Widget>((plan) {
            return SimpleDialogOption(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              onPressed: () {
                onSelect(plan['name'], double.parse(plan['price'].toString()));
                Navigator.pop(ctx);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    plan['name'],
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    "${plan['price']} ₺",
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _addOrUpdateSubscription({Subscription? existingSub}) {
    final nameController = TextEditingController(text: existingSub?.name ?? '');
    final priceController = TextEditingController(
      text: existingSub?.price.toString() ?? '',
    );
    final dayController = TextEditingController(
      text: existingSub?.renewalDay.toString() ?? '',
    );
    String? selectedLogo = existingSub?.logoUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Hızlı Seçim",
                    style: TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 70,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('platforms')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        final docs = snapshot.data!.docs;
                        docs.sort(
                          (a, b) => (a['name'] as String).compareTo(
                            b['name'] as String,
                          ),
                        );
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final app =
                                docs[index].data() as Map<String, dynamic>;
                            final isSelected = selectedLogo == app['logo'];
                            return GestureDetector(
                              onTap: () {
                                final plans = app['plans'] as List;
                                Function(String, double) select = (n, p) {
                                  nameController.text = n;
                                  priceController.text = p.toString();
                                  setModalState(() {
                                    selectedLogo = app['logo'];
                                  });
                                };
                                if (plans.length == 1) {
                                  select(
                                    plans.first['name'],
                                    double.parse(
                                      plans.first['price'].toString(),
                                    ),
                                  );
                                } else {
                                  _showPlanSelection(context, app, select);
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 15),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.deepPurpleAccent
                                        : Colors.white12,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? Colors.deepPurpleAccent.withOpacity(
                                              0.4,
                                            )
                                          : Colors.transparent,
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Image.network(
                                  app['logo'],
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, o, s) =>
                                      const Icon(Icons.error),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 25),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Abonelik Adı',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: priceController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Aylık Ücret',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: dayController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Yenilenme Günü (1-31)',
                      labelStyle: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      if (existingSub != null)
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _subs.removeWhere(
                                  (s) => s.id == existingSub.id,
                                );
                                _saveData();
                              });
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Sil",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            final name = nameController.text;
                            final price =
                                double.tryParse(priceController.text) ?? 0.0;
                            final day = int.tryParse(dayController.text) ?? 1;
                            if (name.isEmpty || price <= 0) return;

                            final newSub = Subscription(
                              id: existingSub?.id ?? DateTime.now().toString(),
                              name: name,
                              price: price,
                              renewalDay: day,
                              logoUrl: selectedLogo,
                            );

                            setState(() {
                              if (existingSub != null) {
                                final index = _subs.indexWhere(
                                  (s) => s.id == existingSub.id,
                                );
                                _subs[index] = newSub;
                              } else {
                                _subs.add(newSub);
                              }
                              _saveData();
                            });

                            _scheduleNotification(newSub);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurpleAccent,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Text(
                            existingSub != null ? 'Güncelle' : 'Ekle',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double total = _subs.fold(0, (sum, item) => sum + item.price);
    if (_showYearly) total *= 12;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Aboneliklerim",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Showcase.withWidget(
              key: _one,
              targetShapeBorder: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              container: widget.tooltipBuilder != null
                  ? widget.tooltipBuilder!(
                      title: 'Özet Durum',
                      description:
                          'Aylık veya yıllık toplam giderini buradan takip et.',
                      onNext: () {
                        ShowCaseWidget.of(context).next();
                      },
                    )
                  : Container(),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showYearly = !_showYearly;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  height: 160,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _showYearly
                          ? [Colors.orange.shade800, Colors.deepOrange.shade900]
                          : [
                              Colors.deepPurpleAccent.shade400,
                              Colors.deepPurple.shade900,
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_showYearly
                                    ? Colors.orange
                                    : Colors.deepPurpleAccent)
                                .withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 120,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _showYearly
                                ? "Yıllık Tahmini Gider"
                                : "Aylık Toplam Gider",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              NumberFormat.currency(
                                locale: 'tr_TR',
                                symbol: '₺',
                              ).format(total),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: _subs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_card_rounded,
                              size: 80,
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Henüz Abonelik Yok",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Sağ alttaki + butonuna basarak\nhemen eklemeye başla!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _subs.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final sub = _subs[index];
                        final color = getBrandColor(sub.name);
                        return GestureDetector(
                          onTap: () =>
                              _addOrUpdateSubscription(existingSub: sub),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border(
                                left: BorderSide(color: color, width: 6),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              leading: Container(
                                width: 50,
                                height: 50,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: sub.logoUrl != null
                                    ? Image.network(
                                        sub.logoUrl!,
                                        fit: BoxFit.contain,
                                      )
                                    : Center(
                                        child: Text(
                                          sub.name[0],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                              ),
                              title: Text(
                                sub.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 12,
                                      color: Colors.white38,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Her ayın ${sub.renewalDay}. günü",
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Text(
                                "${sub.price.toStringAsFixed(2)} ₺",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: color.withOpacity(0.9),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Showcase.withWidget(
        key: _two,
        targetShapeBorder: const CircleBorder(),
        container: widget.tooltipBuilder != null
            ? widget.tooltipBuilder!(
                title: 'Abonelik Ekle',
                description: 'Buradan yeni bir abonelik ekleyebilirsin.',
                onNext: () {
                  ShowCaseWidget.of(context).dismiss();
                  if (widget.onTutorialComplete != null)
                    widget.onTutorialComplete!();
                },
                onBack: () {
                  ShowCaseWidget.of(context).previous();
                },
                isLast: true,
              )
            : Container(),
        child: FloatingActionButton(
          onPressed: () => _addOrUpdateSubscription(),
          backgroundColor: Colors.deepPurpleAccent,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class StatsScreen extends StatelessWidget {
  final List<Subscription> subscriptions;
  const StatsScreen({super.key, required this.subscriptions});
  @override
  Widget build(BuildContext context) {
    double total = subscriptions.fold(0, (sum, item) => sum + item.price);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Harcama Analizi"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: subscriptions.isEmpty
          ? const Center(
              child: Text(
                "Henüz veri yok",
                style: TextStyle(color: Colors.white54),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 60,
                            sections: subscriptions.map((sub) {
                              final color = getBrandColor(sub.name);
                              return PieChartSectionData(
                                color: color,
                                value: sub.price,
                                showTitle: false,
                                radius: 50,
                              );
                            }).toList(),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Toplam",
                              style: TextStyle(color: Colors.white54),
                            ),
                            Text(
                              "${total.toStringAsFixed(0)} ₺",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: subscriptions.length,
                      itemBuilder: (context, index) {
                        final sub = subscriptions[index];
                        final color = getBrandColor(sub.name);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                sub.name,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Spacer(),
                              Text(
                                "${sub.price.toStringAsFixed(2)} ₺",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "(%${((sub.price / total) * 100).toStringAsFixed(0)})",
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
