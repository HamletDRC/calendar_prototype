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

  final icsFiles = ['assets/bvd.ics', 'assets/wspd.ics'];

  icsFiles.forEach((fileName) async {
    // read the .ics file out of the /assets folder
    final icsAsString = await rootBundle.loadString(fileName);
    final iCalendar = ICalendar.fromString(icsAsString);

    // try to find the summary field and calendar start
    final summary = iCalendar.data.firstWhere((e) => e.containsKey('summary'))['summary'];
    final calendarStartTime = iCalendar.data.firstWhere((e) => e.containsKey('dtstart'))['dtstart'];

    // make sure the data is not missing!
    if (summary == null) {
      print('could not find summary for $fileName');
    } else if (calendarStartTime == null) {
      print('could not find start time for $fileName');
    } else {
      // convert the date from the iCalendar format into a standard Flutter DateTime
      final startTime = calendarStartTime.toDateTime();
      final event = Event(summary);
      ALL_EVENTS[startTime] = [event];
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
      home: TableEventsExample(),
    );
  }
}
