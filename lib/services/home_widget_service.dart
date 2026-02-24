import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class HomeWidgetService {
  static const String androidWidgetName = 'OinkWidget';
  static const String iosWidgetName = 'OinkWidget';

  static Future<void> updateBalance(double balance) async {
    try {
      await HomeWidget.saveWidgetData<String>('balance', '\$${balance.toStringAsFixed(0)}');
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: iosWidgetName,
      );
    } catch (e) {
      debugPrint('Error updating home widget: $e');
    }
  }
}
