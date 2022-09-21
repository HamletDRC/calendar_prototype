// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;

import 'pages/events_example.dart';

void main() async {
  await initializeDateFormatting();
  await initializeCalendar();
  runApp(MyApp());
}

Future<void> initializeCalendar() async {
  WidgetsFlutterBinding.ensureInitialized();

  final fileName = 'assets/baumlihof_calendar.ics';

  // read the .ics file out of the /assets folder
  final icsAsString = await rootBundle.loadString(fileName);
  final iCalendar = ICalendar.fromString(icsAsString);

  // try to find the summary field and calendar start
  final allCalendarEntries = iCalendar.data.where((e) {
    return e.containsKey('summary') && e.containsKey('dtstart');
  });

  allCalendarEntries.forEach((calendarEntry) {
    final summary = calendarEntry['summary'];
    final calendarStartTime = calendarEntry['dtstart'];

    // make sure the data is not missing!
    if (summary == null) {
      stderr.writeln('could not find summary for $fileName');
    } else if (calendarStartTime == null) {
      stderr.writeln('could not find start time for $fileName');
    } else {
      // convert the date from the iCalendar format into a standard Flutter DateTime
      var startTime = calendarStartTime.toDateTime();
      final recurRule = calendarEntry['rrule'];
      final event = Event(summary);

      if (recurRule == null) {
        // calendar event is not recurring (i.e. weekly). Just add it.
        if (ALL_EVENTS[startTime] == null) {
          ALL_EVENTS[startTime] = []; // there can be multiple events on a single day
        }
        ALL_EVENTS[startTime]?.add(event);
      } else if (recurRule.contains("FREQ=WEEKLY")) {
        // calendar event is recurring weekly, so add event multiple times.
        while (startTime.isBefore(endOfCalendar)) {
          if (startTime.isAfter(startOfCalendar)) {
            if (ALL_EVENTS[startTime] == null) {
              ALL_EVENTS[startTime] = []; // there can be multiple events on a single day
            }
            ALL_EVENTS[startTime]?.add(event);
          }
          startTime = startTime.add(Duration(days: 7)); // move forward a week in time.
        }
      } else {
        // calendar event is recurring monthly or something that we don't know how to handle
        stderr.writeln("Unknown rrule: $recurRule");
      }
    }
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TableCalendar Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('TableCalendar - Events'),
        ),
        body: TableEventsExample(),
      ),
    );
  }
}
