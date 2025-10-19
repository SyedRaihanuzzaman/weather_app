import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:jiffy/jiffy.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? position;

  determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    position = await Geolocator.getCurrentPosition();

    getWeatherData();
  }

  @override
  void initState() {
    determinePosition();
    super.initState();
  }

  Map<String, dynamic>? weatherMap;
  Map<String, dynamic>? foreCastMap;

  getWeatherData() async {
    var weather = await http.get(
      Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=${position!.latitude}&lon=${position!.longitude}&appid=c4b785b9f64173df868d0cf5065d9b9c',
      ),
    );
    var weatherData = jsonDecode(weather.body);

    var forecast = await http.get(
      Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=${position!.latitude}&lon=${position!.longitude}&appid=c4b785b9f64173df868d0cf5065d9b9c',
      ),
    );

    var forecastData = jsonDecode(forecast.body);

    setState(() {
      weatherMap = Map<String, dynamic>.from(weatherData);
      foreCastMap = Map<String, dynamic>.from(forecastData);

      // print(weatherMap);
      // print("=========================================");
      // print(foreCastMap);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: weatherMap != null
            ? Container(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Column(
                          children: [
                            Text(
                              "${Jiffy.parse('${DateTime.now()}').format(pattern: 'MMMM do yyyy, h:mm:ss a')}",
                            ),

                            Text("${weatherMap!['name']}"),
                          ],
                        ),
                      ),

                      SizedBox(height: 30),
                      Image.network(
                        'https://openweathermap.org/img/wn/${weatherMap!['weather'][0]['icon']}@2x.png',
                      ),
                      SizedBox(height: 3),
                      Text(
                        "${(weatherMap!['main']['temp'] - 273.15).toStringAsFixed(1)} °C",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 40),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          children: [
                            Text(
                              "Feels Like ${(weatherMap!['main']['feels_like'] - 273.15).toStringAsFixed(1)} °C",
                            ),
                            Text("${weatherMap!['weather'][0]['description']}"),
                          ],
                        ),
                      ),

                      SizedBox(height: 30),

                      Text(
                        "Humidity ${weatherMap!['main']['humidity']}, Pressure ${weatherMap!['main']['pressure']}",
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Sunrise: ${Jiffy.parseFromDateTime(DateTime.fromMillisecondsSinceEpoch(weatherMap!['sys']['sunrise'] * 1000, isUtc: true).add(Duration(seconds: weatherMap!['timezone']))).format(pattern: 'hh:mm a')}, "
                        "Sunset: ${Jiffy.parseFromDateTime(DateTime.fromMillisecondsSinceEpoch(weatherMap!['sys']['sunset'] * 1000, isUtc: true).add(Duration(seconds: weatherMap!['timezone']))).format(pattern: 'hh:mm a')}",
                      ),
                      SizedBox(height: 220),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Forecast of 5 Days: ",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      Column(
                        children: [
                          SizedBox(
                            height: 250,

                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,

                              // The itemCount should be foreCastMap!['list'].length for the forecast list
                              itemCount: foreCastMap!['list'].length,

                              itemBuilder: (context, index) {
                                final item = foreCastMap!['list'][index];
                                final unixTimestamp = item['dt'] * 1000;
                                final tempC = (item['main']['temp'] - 273.15)
                                    .toStringAsFixed(1);
                                final iconCode = item['weather'][0]['icon'];

                                return Container(
                                  color: Colors.amber,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  margin: EdgeInsets.only(right: 5),
                                  child: Column(
                                    children: [
                                      // 1. Day of Week and Time (using Jiffy)
                                      Text(
                                        // Use a pattern that combines day and time, like "Mon 9:00 AM"
                                        Jiffy.parseFromDateTime(
                                          DateTime.fromMillisecondsSinceEpoch(
                                            unixTimestamp,
                                          ),
                                        ).format(pattern: 'EEE h:mm a'),
                                        style: TextStyle(fontSize: 16),
                                      ),

                                      SizedBox(height: 20),

                                      // 2. Weather Icon
                                      Image.network(
                                        'https://openweathermap.org/img/wn/$iconCode.png',
                                        width: 80,
                                        height: 80,
                                      ),

                                      SizedBox(height: 40),

                                      // 3. Temperature in Celsius
                                      Text(
                                        '$tempC °C',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      Text(
                                        "${item['weather'][0]['description']}",
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            : Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
