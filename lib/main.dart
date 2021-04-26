import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hijri/hijri_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:date_format/date_format.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var initializationSettingsAndroid = AndroidInitializationSettings("clock");
  var initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String payload) async {
    if (payload != null) debugPrint("notification payload: " + payload);
  });

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map<String, String> prayerTime;
  String city;
  var currentDate = DateTime.now();
  var hijriDate;
  bool _isLoading = true;
  bool _apiLoadError = false;

  // Future getCoordinates() async {
  //   final response = await http.get(
  //       'https://api.ipdata.co/?api-key=1937da454640dce5472f915e4d9de2edaf256e5e4a16a33af2e20e44');
  //   if (response.statusCode == 200) {
  //     var data = jsonDecode(response.body);
  //     city = data['city'];
  //     return [
  //       data['latitude'],
  //       data['longitude'],
  //     ];
  //   } else {
  //     // If the server did not return a 200 OK response,
  //     // then throw an exception.=
  //     _isLoading = false;
  //     throw Exception("Failed to load API");
  //   }
  // }

  Future getPrayerTimes([var date]) async {
    // final coordinates = await getCoordinates();
    final todayDate = DateTime.now();
    // final response = await http.get(
    //   'http://api.aladhan.com/v1/calendar?latitude=${coordinates[0]}&longitude=${coordinates[1]}&method=2&month=${todayDate
    //       .month}&year=${todayDate.year}',
    // );
    final response = await http.get(
      'http://api.aladhan.com/v1/calendar?latitude=30.3753&longitude=69.3451&method=2&month=${todayDate
          .month}&year=${todayDate.year}',
    );
    final userDate = (date == null) ? todayDate.day - 1 : date.day - 1;
    final Map<String, String> prayerTimings = {};
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      prayerTimings["Fajr"] =
          data["data"][userDate]["timings"]["Fajr"].substring(0, 5);
      prayerTimings["Sun"] =
          data["data"][userDate]["timings"]["Sunrise"].substring(0, 5);
      prayerTimings["Zuhr"] =
          data["data"][userDate]["timings"]["Dhuhr"].substring(0, 5);
      prayerTimings["Asr"] = data["data"][0]["timings"]["Asr"].substring(0, 5);
      prayerTimings["Magrib"] =
          data["data"][userDate]["timings"]["Maghrib"].substring(0, 5);
      prayerTimings["Ishaa"] =
          data["data"][userDate]["timings"]["Isha"].substring(0, 5);
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      _isLoading = false;
      throw Exception('Failed to load API');
    }
    return prayerTimings;
  }

  Future start() async {
    try {
      _apiLoadError = false;
      prayerTime = await getPrayerTimes();
      var hDate = new HijriCalendar.fromDate(new DateTime.now());
      city = "Karachi";
      setState(() {
        currentDate = DateTime.now();
        hijriDate = hDate.toFormat("dd MMMM yyyy");
        _isLoading = false;
      });
    } catch (ex) {
      setState(() {
        _apiLoadError = true;
      });
    }
  }

  Future userDate(DateTime date) async {
    var hDate = new HijriCalendar.fromDate(date);
    prayerTime = await getPrayerTimes(date);
    setState(() {
      hijriDate = hDate.toFormat("dd MMMM yyyy");
      currentDate = date;
    });
  }


  void notificationTimeChecker() {
    int checkFirst = int.parse(prayerTime["Fajr"].substring(0, 2));
    int checkSecond = int.parse(prayerTime["Fajr"].substring(3, 5));
  }


  @override
  void initState() {
    super.initState();
    start();
  }

  @override
  Widget build(BuildContext context) {
    notificationTimeChecker();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Prayer Timings',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
          backgroundColor: Colors.cyan[800],
          actions: [
            IconButton(
              padding: EdgeInsets.only(right: 10),
              alignment: Alignment.center,
              icon: Icon(
                Icons.refresh,
                size: 30,
              ),
              onPressed: () {
                start();
              },
            ),
          ],
        ),
        body: (_isLoading)
            ? Center(child: CircularProgressIndicator())
            : (_apiLoadError == true)
                ? Center(
                    child: Container(
                      child: Center(
                        child: Column(
                          children: [
                            Padding(padding: EdgeInsets.all(150)),
                            Text("Refresh Your Page The API Didnt Work"),
                            IconButton(
                              icon: Icon(Icons.refresh),
                              iconSize: 40,
                              onPressed: () {
                                start();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Body(
                    city: city,
                    hijriDate: hijriDate,
                    prayerTime: prayerTime,
                    currentDate: currentDate,
                    userDate: userDate,
                  ),
      ),
    );
  }
}

class Body extends StatelessWidget {
  const Body({
    @required this.city,
    @required this.hijriDate,
    @required this.prayerTime,
    @required this.currentDate,
    @required this.userDate,
  });

  final String city;
  final String hijriDate;
  final DateTime currentDate;
  final Map<String, String> prayerTime;
  final Function userDate;

  // void scheduleAlarm() async {
  //   var scheduledNotificationDateTime = double.parse(prayerTime["Fajr"]) - DateTime.now();
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/Image.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      padding: EdgeInsets.all(16),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 40),
                    child: Text(
                      DateFormat("dd MMM yyyy").format(currentDate),
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                                // bottomLeft
                                offset: Offset(-1.5, -1.5),
                                color: Colors.black),
                            Shadow(
                                // bottomRight
                                offset: Offset(1.5, -1.5),
                                color: Colors.black),
                            Shadow(
                                // topRight
                                offset: Offset(1.5, 1.5),
                                color: Colors.black),
                            Shadow(
                                // topLeft
                                offset: Offset(-1.5, 1.5),
                                color: Colors.black),
                          ]),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    child: Text(
                      city == null ? "Fetching..." : city,
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                                // bottomLeft
                                offset: Offset(-1.5, -1.5),
                                color: Colors.black),
                            Shadow(
                                // bottomRight
                                offset: Offset(1.5, -1.5),
                                color: Colors.black),
                            Shadow(
                                // topRight
                                offset: Offset(1.5, 1.5),
                                color: Colors.black),
                            Shadow(
                                // topLeft
                                offset: Offset(-1.5, 1.5),
                                color: Colors.black),
                          ]),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    child: Text(
                      hijriDate,
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                                // bottomLeft
                                offset: Offset(-1.5, -1.5),
                                color: Colors.black),
                            Shadow(
                                // bottomRight
                                offset: Offset(1.5, -1.5),
                                color: Colors.black),
                            Shadow(
                                // topRight
                                offset: Offset(1.5, 1.5),
                                color: Colors.black),
                            Shadow(
                                // topLeft
                                offset: Offset(-1.5, 1.5),
                                color: Colors.black),
                          ]),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(35),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Container(
                              margin: EdgeInsets.only(top: 10),
                              child: Text(
                                "Fajar",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 10),
                              child: Text(
                                "Sunrise",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 10),
                              child: Text(
                                "Zuhr",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 10),
                              child: Text(
                                "Asr",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 10),
                              child: Text(
                                "Magrib",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 10),
                              child: Text(
                                "Ishaa",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Container(
                              margin: EdgeInsets.only(top: 10),
                              child: Text(
                                (prayerTime == null)
                                    ? "Fetching..."
                                    : prayerTime["Fajr"],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 10),
                              child: Text(
                                (prayerTime == null)
                                    ? "Fetching..."
                                    : prayerTime["Sun"],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 10),
                              child: Text(
                                (prayerTime == null)
                                    ? "Fetching..."
                                    : prayerTime["Zuhr"],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 10),
                              child: Text(
                                (prayerTime == null)
                                    ? "Fetching..."
                                    : prayerTime["Asr"],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 10),
                              child: Text(
                                (prayerTime == null)
                                    ? "Fetching..."
                                    : prayerTime["Magrib"],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 10),
                              child: Text(
                                (prayerTime == null)
                                    ? "Fetching..."
                                    : prayerTime["Ishaa"],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              child: RaisedButton.icon(
                  onPressed: () => {
                        showDatePicker(
                          context: context,
                          initialDate: currentDate,
                          firstDate: DateTime(2021, currentDate.month),
                          lastDate: DateTime(2021, currentDate.month + 1),
                        ).then((date) {
                          if (date != null) userDate(date);
                        })
                      },
                  color: Colors.cyan[800],
                  icon: Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                  ),
                  label: Text(
                    "Calendar",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
