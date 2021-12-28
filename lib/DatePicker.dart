import 'package:flutter/material.dart';

class DatePicker extends StatelessWidget {
  const DatePicker(
      {Key? key,
      required this.selectDate,
      required this.selectTime,
      required this.selectedDate,
      required this.selectedTime,
      required this.timeOnly,
      required this.labelText})
      : super(key: key);
  final bool timeOnly;
  final String labelText;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final ValueChanged<DateTime> selectDate;
  final ValueChanged<TimeOfDay> selectTime;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime(DateTime.now().year + 100));
    print("teste1");
    if (picked != null && picked != selectedDate) selectDate(picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) selectTime(picked);
  }

  @override
  Widget build(BuildContext context) {
    String date = selectedDate.day.toString() +
        "-" +
        selectedDate.month.toString() +
        "-" +
        selectedDate.year.toString();
    return new Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        if (!this.timeOnly)
          Expanded(
            flex: 4,
            child: new _InputDropdown(
              labelText: labelText,
              valueText: date,
              onPressed: () {
                _selectDate(context);
              },
            ),
          ),
        if (!this.timeOnly) const SizedBox(width: 12.0),
        new Expanded(
          flex: 3,
          child: new _InputDropdown(
            labelText: labelText,
            valueText: selectedTime.format(context),
            onPressed: () {
              _selectTime(context);
            },
          ),
        ),
        const SizedBox(width: 0.0),
      ],
    );
  }
}

class _InputDropdown extends StatelessWidget {
  const _InputDropdown(
      {Key? key,
      this.child,
      this.labelText,
      this.valueText,
      this.valueStyle,
      required this.onPressed})
      : super(key: key);

  final String? labelText;
  final String? valueText;
  final TextStyle? valueStyle;
  final VoidCallback onPressed;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return new InkWell(
      onTap: onPressed,
      child: new InputDecorator(
        decoration: new InputDecoration(
          labelText: labelText,
        ),
        baseStyle: valueStyle,
        child: new Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Text(valueText ?? '', style: valueStyle),
            new Icon(Icons.arrow_drop_down,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey.shade700
                    : Colors.white70),
          ],
        ),
      ),
    );
  }
}
