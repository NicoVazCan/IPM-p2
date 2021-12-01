import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/*
var url = Uri.parse("http://10.0.2.2:8080/api/rest/facility_access_log/111/daterange%22);
var data = {
  'startdate': '2021-01-01T02:03:00+00:000',
  'enddate': '2021-12-01T02:03:00+00:000'
};
var request = http.Request("GET", url);
request.body = json.encode(data);
request.headers.addAll({"x-hasura-admin-secret": "myadminsecretkey"});
var client = http.Client();
var streamedResponse = await client.send(request);
var dataAsString = await streamedResponse.stream.bytesToString();
client.close();
var dataAsMap = json.decode(dataAsString) as Map;
En la práctica 2, para hacer las peticiones al servidor desde el emulador,
hay que cambiar en la url de la petición localhost:8080 por 10.0.2.2:8080
(para que el emulador pueda acceder al servidor que está desplegado en local).
 */

//{"id":130,"max_capacity":60,"name":"Centro comercial Patricia Cano","address":"1238 Calle de Arturo Soria","percentage_capacity_allowed":40}

Future<List> getFacilities() async{
  var url = Uri.parse("http://10.0.2.2:8080/api/rest/facilities");
  var request = http.Request("GET", url);
  request.headers.addAll({"x-hasura-admin-secret": "myadminsecretkey"});
  var client = http.Client();
  var streamedResponse = await client.send(request);
  var dataAsString = await streamedResponse.stream.bytesToString();
  client.close();
  await Future.delayed(Duration(seconds: 3));
  var dataAsMap = json.decode(dataAsString) as Map;
  return dataAsMap["facilities"];
}

Future<List> getEvent(Map facility ,DateTime desde, DateTime hasta) async{
  var url = Uri.parse("http://10.0.2.2:8080/api/rest/facility_access_log/${facility['id'].toString()}/daterange");
  var request = http.Request("GET", url);
  request.headers.addAll({"x-hasura-admin-secret": "myadminsecretkey"});
  //'{"startdate": "2021-01-01T02:03:00+00:000", "enddate": "2021-12-01T02:03:00+00:000"}'
  request.body = '{"startdate": "2021-01-01T02:03:00+00:000", "enddate": "2021-12-01T02:03:00+00:000"}';
  //'{ "startdate": ${desde.toIso8601String()}+00:000, "enddate": ${hasta.toIso8601String()}+00:000}';
  var client = http.Client();
  var streamedResponse = await client.send(request);
  var dataAsString = await streamedResponse.stream.bytesToString();
  print(request.body);
  print(dataAsString);
  client.close();
  await Future.delayed(Duration(seconds: 3));
  var dataAsMap = json.decode(dataAsString) as Map;
  return dataAsMap["access_log"];
}

class Alert extends StatefulWidget {
  String text;
  
  Alert(this.text);
  
  @override
  AlertState createState() => AlertState();

}

class AlertState extends State<Alert> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: new Text(widget.text),
      actions: <Widget>[
        ElevatedButton(
          child: new Text("OK"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue,),
      home: FacilitiesPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}


class FacilitiesPage extends StatefulWidget {
  const FacilitiesPage({Key? key}) : super(key: key);

  @override
  _FacilitiesPageState createState() => _FacilitiesPageState();
}


class _FacilitiesPageState extends State<FacilitiesPage> {
  late Future<List> _value;

  @override
  initState() {
    super.initState();
    _value = getFacilities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Selecione un centro"),
      ),
      body: SizedBox(
        width: double.infinity,
        child: Center(
            child: FutureBuilder<List>(
            future: _value,
            builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return CircularProgressIndicator();
                case ConnectionState.done:
                  if (snapshot.hasError) {
                    return Alert("Fallo al conectar con la base de datos");
                  } else if (snapshot.hasData) {
                    List facilities = snapshot.data as List;

                    if (facilities.isEmpty) {
                      return const Text("En este momento no se encuntra"
                          "ningún centro disponible, pruebe más tarde.");
                    }

                    return ListView.builder(
                      itemCount: facilities.length,
                      itemBuilder: (context, index) {
                        Map facility = facilities[index];

                        return ListTile(
                          title: Text(facility["name"]),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      OpcionesPage(facility: facility)),
                            );
                          },
                        );
                      },
                    );
                  } else {
                    return const Text('Empty data');
                  }
                default:
                  return Text('State: ${snapshot.connectionState}');
              }
            },
          ),
        ),
      ),
    );
  }
}


/*
class DebugPage extends StatelessWidget {
  const DebugPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Debug'),
        ),
        body: TextFormField(
          decoration: InputDecoration(
              hintText: "x.x.x.x", labelText: "Introduzca la IP de la BBDD"),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter some text';
            }
          },
        )
    );
  }
}*/

class OpcionesPage extends StatelessWidget {
  Map facility;

  OpcionesPage({Key? key, required this.facility}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Selecione una opción"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              // Within the SecondRoute widget
              onPressed: () {
                Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OpcionesPage(facility: facility)),
                );
              },
              child: const Text('Registrar',
                  textScaleFactor: 2
              ),
            ),
            ElevatedButton(
              // Within the SecondRoute widget
              onPressed: () {
                Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EventPage(facility: facility)),
                );
              },
              child: const Text('Eventos',
                  textScaleFactor: 2
              ),
            )
          ]
        ),
      )
    );
  }
}

class DateTimePicker{
  late DateTime current;

  DateTimePicker(this.current);

  Future<void> selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: current,
        firstDate: DateTime(2021),
        lastDate: DateTime(2076)
    );
    if (pickedDate != null && pickedDate != current) {
        current = pickedDate;
    }
  }

  String dateToString() =>
      current.toIso8601String().substring(0, 10);

  Future<void> selectTime(BuildContext context) async {
    TimeOfDay time = TimeOfDay(hour: current.hour, minute: current.minute);

    final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: time
    );
    if (pickedTime != null && pickedTime != time) {
        current = DateTime(current.year, current.month, current.day,
            pickedTime.hour, pickedTime.minute);
    }
  }

  String timeToString() =>
      current.toString().substring(11, 16);
}

class EventPage extends StatefulWidget {
  Map facility;

  EventPage({Key? key, required this.facility}) : super(key: key);

  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  late DateTimePicker fechaDesde;
  late DateTimePicker fechaHasta;
  late Future<List> _future;

  @override
  initState() {
    super.initState();
    fechaHasta = DateTimePicker(DateTime.now());
    int year = fechaHasta.current.year,
        month = fechaHasta.current.month,
        day = fechaHasta.current.day - 28;
    if (day <= 0) {
      day = day % 28 + 1;
      if (month-- == 0) {
        year--;
        month = 12;
      }
    }
    fechaDesde = DateTimePicker(DateTime(year, month, day,
        fechaHasta.current.hour, fechaHasta.current.minute));

    _future = getEvent(widget.facility, fechaDesde.current, fechaHasta.current);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Eventos"),
        ),
        body: /*Column(
            children: <Widget>[
              Row(
                  children: <Widget>[
                    const Text(" Inicio ",
                        textScaleFactor: 2
                    ),
                    Container(
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: Border.all(
                            color: Colors.black,
                            width: 1.0,
                          ),
                        ),
                        child: Text(fechaDesde.dateToString(),
                            textScaleFactor: 2
                        )
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      iconSize: 25,
                      tooltip: 'Austar la fecha de inicio del evento',
                      onPressed: () =>
                          fechaDesde.selectDate(context)
                              .then((value) => setState(() => null)),
                    ),
                    Container(
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: Border.all(
                          color: Colors.black,
                          width: 1.0,
                        ),
                      ),
                      child: Text(fechaDesde.timeToString(),
                          textScaleFactor: 2
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      iconSize: 25,
                      color: Colors.brown,
                      tooltip: 'Austar la hora de inicio del evento',
                      onPressed: () =>
                          fechaDesde.selectTime(context)
                              .then((value) => setState(() => null)),
                    ),
                  ]
              ),
              Row(
                children: <Widget>[
                  const Text(" Final  ",
                      textScaleFactor: 2
                  ),
                  Container(
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: Border.all(
                        color: Colors.black,
                        width: 1.0,
                      ),
                    ),
                    child: Text(fechaHasta.dateToString(),
                        textScaleFactor: 2
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    iconSize: 25,
                    tooltip: 'Austar la fecha de inicio del evento',
                    onPressed: () =>
                        fechaHasta.selectDate(context)
                            .then((value) => setState(() => null)),
                  ),
                  Container(
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: Border.all(
                          color: Colors.black,
                          width: 1.0,
                        ),
                      ),
                      child: Text(fechaHasta.timeToString(),
                          textScaleFactor: 2
                      )
                  ),
                  IconButton(
                    icon: const Icon(Icons.access_time),
                    iconSize: 25,
                    tooltip: 'Austar la fecha de inicio del evento',
                    onPressed: () =>
                        fechaHasta.selectTime(context)
                            .then((value) => setState(() => null)),
                  ),
                ],
              ),
              IconButton(
                alignment: Alignment.topRight,
                icon: const Icon(Icons.search),
                iconSize: 25,
                tooltip: 'Austar la fecha de inicio del evento',
                onPressed: () => setState(() {
                    _future = getEvent(widget.facility,
                        fechaDesde.current, fechaHasta.current);
                  }
                ),
              ),*/
              FutureBuilder<List>(
                future: _future,
                builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      return CircularProgressIndicator();
                    case ConnectionState.done:
                      if (snapshot.hasError) {
                        return Alert("Fallo al conectar con la base de datos");
                      } else if (snapshot.hasData) {
                        //{"temperature":"35.6","timestamp":"2021-08-27T16:09:58.277923+00:00","type":"OUT","user":{"name":"Beatriz","surname":"Marquez","uuid":"6bd49b45-d916-414d-a1e4-2f0ca04553a0","is_vaccinated":false,"phone":"971-779-685","email":"beatriz.marquez@example.com"}}
                        List accesos = snapshot.data as List;

                        if (accesos.isEmpty) {
                          return const Text("En este momento no se encuntra"
                              "ningún acceso, pruebe más tarde.");
                        }

                        return DataTable(
                          columns: const <DataColumn>[
                            DataColumn(
                              label: Text(
                                'Tipo',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Fecha',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Hora',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Usuario',
                                style: TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                          rows: List<DataRow>.generate(
                            accesos.length,
                            (idx) {
                              Map acceso = accesos[idx] as Map;
                              Map user = acceso['user'] as Map;
                              return DataRow(
                                  cells: <DataCell>[
                                    DataCell(Text(acceso['type'])),
                                    DataCell(Text(acceso['timestamp']
                                        .toString().substring(0,11))),
                                    DataCell(Text(acceso['timestamp']
                                        .toString().substring(11,16))),
                                    DataCell(Text(
                                        '${user['name']} '
                                            '${user['surname']}')),
                                  ]
                              );
                            }
                          ),
                        );
                      } else {
                        return const Text('Empty data');
                      }
                    default:
                      return Text('State: ${snapshot.connectionState}');
                  }
                },
              ),
            /*]
        )*/
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
