import 'package:flutter/material.dart';

// import 'data/repository/stock_repository.dart';
// import 'data/api/naver_stock_api.dart';
// import 'screens/watchlist/watchlist_screen.dart';
import 'screens/main_shell.dart';
import 'theme/theme.dart';

void main() {
  runApp(const EdencrewAssignmentApp());
}
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final api = NaverStockApi();

//   try {
//     final result = await api.fetchDailyCandles(
//       symbol: '005930',
//       startDateTime: '202609010000',
//       endDateTime: '202610050000',
//     );

//     debugPrint(result.take(3).toList().toString());
//   } catch (e) {
//     debugPrint('DAILY API ERROR: $e');
//   } finally {
//     api.dispose();
//   }

//   runApp(const EdencrewAssignmentApp());
// }

class EdencrewAssignmentApp extends StatelessWidget {
  const EdencrewAssignmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '국내 주식 관심종목',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainShell(),
    );
  }
}
