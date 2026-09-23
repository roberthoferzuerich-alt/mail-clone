import re

def update_calendar():
    with open('lib/screens/calendar_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    new_calendar = """
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_calendar/device_calendar.dart';
import '../main.dart'; 

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  bool _syncCalendar = false;
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  List<Calendar> _calendars = [];
  Map<DateTime, List<Event>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadSettingsAndEvents();
  }

  Future<void> _loadSettingsAndEvents() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _syncCalendar = prefs.getBool('sync_calendar') ?? false;
    });

    if (_syncCalendar) {
      final permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.isSuccess && permissionsGranted.data!) {
        final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
        if (calendarsResult.isSuccess && calendarsResult.data != null) {
          _calendars = calendarsResult.data as List<Calendar>;
          _loadEventsForMonth(_focusedDay);
        }
      }
    }
  }

  Future<void> _loadEventsForMonth(DateTime month) async {
    if (!_syncCalendar || _calendars.isEmpty) return;

    final startDate = DateTime(month.year, month.month - 1, 1);
    final endDate = DateTime(month.year, month.month + 2, 0);

    Map<DateTime, List<Event>> newEvents = {};

    for (var calendar in _calendars) {
      if (calendar.id == null) continue;
      
      final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
        calendar.id,
        RetrieveEventsParams(startDate: startDate, endDate: endDate),
      );

      if (eventsResult.isSuccess && eventsResult.data != null) {
        for (var event in eventsResult.data!) {
          if (event.start != null) {
            // LocalTime to DateTime
            final startDt = event.start!; 
            final dateKey = DateTime(startDt.year, startDt.month, startDt.day);
            if (newEvents[dateKey] == null) newEvents[dateKey] = [];
            newEvents[dateKey]!.add(event);
          }
        }
      }
    }

    setState(() {
      _events = newEvents;
    });
  }

  List<Event> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : <Event>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender', style: TextStyle(color: Colors.white)),
        backgroundColor: outlookBlue,
        leading: Builder(
          builder: (context) => IconButton(
            icon: CircleAvatar(
              backgroundColor: isDark ? Colors.grey[800] : Colors.white,
              child: Icon(Icons.home, color: isDark ? Colors.white : outlookBlue),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.monday,
            eventLoader: _getEventsForDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadEventsForMonth(focusedDay);
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: outlookBlue.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: outlookBlue,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
            ),
          ),
          const Divider(),
          Expanded(
            child: _selectedDay == null 
              ? const Center(child: Text('Wähle ein Datum')) 
              : selectedEvents.isEmpty 
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Termine am ${_selectedDay!.day}.${_selectedDay!.month}.${_selectedDay!.year}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Text(
                              'Keine Termine für diesen Tag',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: selectedEvents.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              'Termine am ${_selectedDay!.day}.${_selectedDay!.month}.${_selectedDay!.year}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          );
                        }
                        final event = selectedEvents[index - 1];
                        final startHour = event.start?.hour.toString().padLeft(2, '0') ?? '00';
                        final startMin = event.start?.minute.toString().padLeft(2, '0') ?? '00';
                        return ListTile(
                          leading: const Icon(Icons.event, color: outlookBlue),
                          title: Text(event.title ?? 'Ohne Titel', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            event.allDay == true ? 'Ganztägig' : '$startHour:$startMin Uhr',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Neuer Termin (noch nicht implementiert)')),
          );
        },
        backgroundColor: outlookBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
"""

    with open('lib/screens/calendar_screen.dart', 'w', encoding='utf-8') as f:
        f.write(new_calendar.strip())
        
update_calendar()
print("Updated CalendarScreen")
