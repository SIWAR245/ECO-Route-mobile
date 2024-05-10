import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarWidget extends StatefulWidget {
  @override
  _CalendarWidgetState createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _selectedDate=DateTime.now();
  late int _currentDateSelectedIndex; // For Horizontal Date
  late ScrollController _scrollController; // To Track Scroll of ListView

  final List<String> _listOfMonths = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];
  final List<String> _listOfDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _currentDateSelectedIndex = _selectedDate.weekday - 1;
    _scrollController = ScrollController(initialScrollOffset: _currentDateSelectedIndex * 60.0);
  }

  void scrollNextWeek() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 7));
      _currentDateSelectedIndex += 7;
      _scrollController.animateTo(_currentDateSelectedIndex * 60.0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    });
  }

  void scrollPrevWeek() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 7));
      _currentDateSelectedIndex -= 7;
      _scrollController.animateTo(_currentDateSelectedIndex * 60.0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 1),
          ),
    ],
        color: Colors.white,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: const TextStyle(
                    fontSize: 20,
                  fontWeight: FontWeight.bold
                ),
                ),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.chevron_back,
                  color: Colors.grey,
                ),
                onPressed: scrollPrevWeek,
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.chevron_forward,
                  color: Colors.grey,
                ),
                onPressed: scrollNextWeek,
              ),
            ],
          ),
          Expanded(
            child: ListView.separated(
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(width: 5);
              },
              itemCount: 7,
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemBuilder: (BuildContext context, int index) {
                DateTime date = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1)).add(Duration(days: index));
                return Container(
                  height: 76,
                  width: 40,
                  margin: EdgeInsets.all(5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year
                        ? Colors.teal
                        : Colors.white,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _listOfMonths[date.month - 1],
                        style: TextStyle(
                          fontSize: 15,
                          color: date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year
                              ? Colors.white
                              : Colors.grey,
                        ),
                      ),
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year
                              ? Colors.white
                              : Colors.grey,
                        ),
                      ),
                      Text(
                        _listOfDays[date.weekday - 1],
                        style: TextStyle(
                          fontSize: 15,
                          color: date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year
                              ? Colors.white
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }
}
