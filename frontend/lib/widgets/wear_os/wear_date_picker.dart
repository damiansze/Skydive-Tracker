import 'package:flutter/material.dart';

/// Compact date picker dialog for WearOS
class WearDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const WearDatePicker({
    super.key,
    required this.initialDate,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<WearDatePicker> createState() => _WearDatePickerState();

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return showDialog<DateTime>(
      context: context,
      builder: (context) => WearDatePicker(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
  }
}

class _WearDatePickerState extends State<WearDatePicker> {
  late int _day;
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    _day = widget.initialDate.day;
    _month = widget.initialDate.month;
    _year = widget.initialDate.year;
  }

  int _daysInMonth(int month, int year) {
    return DateTime(year, month + 1, 0).day;
  }

  void _adjustDay(int delta) {
    setState(() {
      final maxDays = _daysInMonth(_month, _year);
      _day = ((_day - 1 + delta) % maxDays) + 1;
      if (_day < 1) _day = maxDays;
    });
    _validateDate();
  }

  void _adjustMonth(int delta) {
    setState(() {
      _month = ((_month - 1 + delta) % 12) + 1;
      if (_month < 1) _month = 12;
      // Adjust day if it exceeds the new month's days
      final maxDays = _daysInMonth(_month, _year);
      if (_day > maxDays) _day = maxDays;
    });
    _validateDate();
  }

  void _adjustYear(int delta) {
    setState(() {
      _year += delta;
      // Adjust day if Feb 29 and not leap year
      final maxDays = _daysInMonth(_month, _year);
      if (_day > maxDays) _day = maxDays;
    });
    _validateDate();
  }

  void _validateDate() {
    final selected = DateTime(_year, _month, _day);
    if (widget.firstDate != null && selected.isBefore(widget.firstDate!)) {
      setState(() {
        _year = widget.firstDate!.year;
        _month = widget.firstDate!.month;
        _day = widget.firstDate!.day;
      });
    }
    if (widget.lastDate != null && selected.isAfter(widget.lastDate!)) {
      setState(() {
        _year = widget.lastDate!.year;
        _month = widget.lastDate!.month;
        _day = widget.lastDate!.day;
      });
    }
  }

  static const List<String> _monthNames = [
    'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
    'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(8),
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      content: SizedBox(
        width: 140,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Datum wählen',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Day picker
                _buildPickerColumn(
                  value: _day.toString().padLeft(2, '0'),
                  width: 28,
                  onIncrement: () => _adjustDay(1),
                  onDecrement: () => _adjustDay(-1),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 1),
                  child: Text('.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                // Month picker
                _buildPickerColumn(
                  value: _monthNames[_month - 1],
                  width: 32,
                  onIncrement: () => _adjustMonth(1),
                  onDecrement: () => _adjustMonth(-1),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 1),
                  child: Text('.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                // Year picker
                _buildPickerColumn(
                  value: _year.toString(),
                  width: 40,
                  onIncrement: () => _adjustYear(1),
                  onDecrement: () => _adjustYear(-1),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Abbruch', style: TextStyle(fontSize: 9)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, DateTime(_year, _month, _day)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('OK', style: TextStyle(fontSize: 9)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerColumn({
    required String value,
    required double width,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onIncrement,
          child: Container(
            padding: const EdgeInsets.all(2),
            child: const Icon(Icons.keyboard_arrow_up, size: 14),
          ),
        ),
        Container(
          width: width,
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        GestureDetector(
          onTap: onDecrement,
          child: Container(
            padding: const EdgeInsets.all(2),
            child: const Icon(Icons.keyboard_arrow_down, size: 14),
          ),
        ),
      ],
    );
  }
}

