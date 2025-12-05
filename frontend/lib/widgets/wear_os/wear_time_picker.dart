import 'package:flutter/material.dart';

/// Compact time picker dialog for WearOS
class WearTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final bool use24HourFormat;

  const WearTimePicker({
    super.key,
    required this.initialTime,
    this.use24HourFormat = true,
  });

  @override
  State<WearTimePicker> createState() => _WearTimePickerState();

  static Future<TimeOfDay?> show(
    BuildContext context, {
    required TimeOfDay initialTime,
    bool use24HourFormat = true,
  }) {
    return showDialog<TimeOfDay>(
      context: context,
      builder: (context) => WearTimePicker(
        initialTime: initialTime,
        use24HourFormat: use24HourFormat,
      ),
    );
  }
}

class _WearTimePickerState extends State<WearTimePicker> {
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.hour;
    _minute = widget.initialTime.minute;
  }

  void _adjustHour(int delta) {
    setState(() {
      _hour = (_hour + delta) % 24;
      if (_hour < 0) _hour = 23;
    });
  }

  void _adjustMinute(int delta) {
    setState(() {
      _minute = (_minute + delta) % 60;
      if (_minute < 0) _minute = 59;
    });
  }

  String _formatHour() {
    if (widget.use24HourFormat) {
      return _hour.toString().padLeft(2, '0');
    } else {
      final displayHour = _hour == 0 ? 12 : (_hour > 12 ? _hour - 12 : _hour);
      return displayHour.toString();
    }
  }

  String _getAmPm() {
    return _hour < 12 ? 'AM' : 'PM';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(8),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      content: SizedBox(
        width: 120,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Zeit wählen',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hour picker
                _buildPickerColumn(
                  value: _formatHour(),
                  onIncrement: () => _adjustHour(1),
                  onDecrement: () => _adjustHour(-1),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text(':', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                // Minute picker
                _buildPickerColumn(
                  value: _minute.toString().padLeft(2, '0'),
                  onIncrement: () => _adjustMinute(1),
                  onDecrement: () => _adjustMinute(-1),
                ),
                // AM/PM indicator for 12h format
                if (!widget.use24HourFormat) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _adjustHour(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getAmPm(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Abbruch', style: TextStyle(fontSize: 9)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, TimeOfDay(hour: _hour, minute: _minute)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onIncrement,
          child: Container(
            padding: const EdgeInsets.all(4),
            child: const Icon(Icons.keyboard_arrow_up, size: 16),
          ),
        ),
        Container(
          width: 32,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        GestureDetector(
          onTap: onDecrement,
          child: Container(
            padding: const EdgeInsets.all(4),
            child: const Icon(Icons.keyboard_arrow_down, size: 16),
          ),
        ),
      ],
    );
  }
}

