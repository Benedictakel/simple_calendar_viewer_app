import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

void main() => runApp(CalendarNotesApp());

class CalendarNotesApp extends StatelessWidget {
  const CalendarNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendar Notes',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: CalendarHomePage(),
    );
  }
}

class CalendarHomePage extends StatefulWidget {
  const CalendarHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CalendarHomePageState createState() => _CalendarHomePageState();
}

class _CalendarHomePageState extends State<CalendarHomePage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDate = DateTime.now();
  Map<String, List<String>> _notes = {};

  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('notes') ?? '{}';
    setState(() {
      _notes = Map<String, List<String>>.from(
        json
            .decode(data)
            .map((key, value) => MapEntry(key, List<String>.from(value))),
      );
    });
  }

  void _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('notes', json.encode(_notes));
  }

  void _addNote() {
    String key = _selectedDate.toIso8601String().split('T')[0];
    if (_noteController.text.trim().isEmpty) return;

    setState(() {
      if (_notes[key] == null) {
        _notes[key] = [_noteController.text.trim()];
      } else {
        _notes[key]!.add(_noteController.text.trim());
      }
      _noteController.clear();
      _saveNotes();
    });
  }

  void _deleteNote(int index) {
    String key = _selectedDate.toIso8601String().split('T')[0];
    setState(() {
      _notes[key]!.removeAt(index);
      if (_notes[key]!.isEmpty) _notes.remove(key);
      _saveNotes();
    });
  }

  List<String> _getNotesForSelectedDate() {
    String key = _selectedDate.toIso8601String().split('T')[0];
    return _notes[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Calendar Notes'), centerTitle: true),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _selectedDate,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.indigo.shade300,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.indigo,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText:
                    'Add note for ${_selectedDate.toLocal().toString().split(' ')[0]}',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addNote,
                ),
              ),
              onSubmitted: (_) => _addNote(),
            ),
          ),
          Expanded(
            child:
                _getNotesForSelectedDate().isEmpty
                    ? Center(child: Text('No notes for this date.'))
                    : ListView.builder(
                      itemCount: _getNotesForSelectedDate().length,
                      itemBuilder: (context, index) {
                        final note = _getNotesForSelectedDate()[index];
                        return ListTile(
                          leading: Icon(Icons.note, color: Colors.indigo),
                          title: Text(note),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _deleteNote(index),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
