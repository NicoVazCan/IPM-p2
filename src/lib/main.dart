import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

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

// MODELO

Future<List> getFacilities() async{
  const ipMovil = "10.0.2.2";
  var url = Uri.parse("http://$ipMovil:8080/api/rest/facilities");
  var request = http.Request("GET", url);
  request.headers.addAll({"x-hasura-admin-secret": "myadminsecretkey"});
  var client = http.Client();
  var streamedResponse = await client.send(request);
  var dataAsString = await streamedResponse.stream.bytesToString();
  client.close();
  await Future.delayed(Duration(seconds: 2));
  var dataAsMap = json.decode(dataAsString) as Map;
  return dataAsMap["facilities"];
}

Future<List> getEvent(int facility_id ,DateTime desde, DateTime hasta) async{
  const ipMovil = "10.0.2.2";
  var url = Uri.parse("http://$ipMovil:8080/api/rest/facility_access_log/$facility_id/daterange");
  var request = http.Request("GET", url);
  request.headers.addAll({"x-hasura-admin-secret": "myadminsecretkey"});
  request.body = '{ "startdate": "${desde.toIso8601String()}+00:000", "enddate": "${hasta.toIso8601String()}+00:000"}';
  var client = http.Client();
  var streamedResponse = await client.send(request);
  var dataAsString = await streamedResponse.stream.bytesToString();
  client.close();
  await Future.delayed(Duration(seconds: 2));
  var dataAsMap = json.decode(dataAsString) as Map;
  return dataAsMap["access_log"];
}

Future<List> getUsers(String name, String surname) async {
  const ipMovil = "10.0.2.2";
  name = name.trim();
  surname = surname.trim();

  if (!name.isEmpty && !surname.isEmpty) {
    var url = Uri.parse(
        "http://$ipMovil:8080/api/rest/user?name=$name&surname=$surname");
    var request = http.Request("GET", url);
    request.headers.addAll({"x-hasura-admin-secret": "myadminsecretkey"});
    var client = http.Client();
    var streamedResponse = await client.send(request);
    var dataAsString = await streamedResponse.stream.bytesToString();
    client.close();
    var dataAsMap = json.decode(dataAsString) as Map;
    List users = dataAsMap["users"];

    if (!users.isEmpty) {
      return users;
    }
  }

  var url = Uri.parse("http://$ipMovil:8080/api/rest/users");
  var request = http.Request("GET", url);
  request.headers.addAll({"x-hasura-admin-secret": "myadminsecretkey"});
  var client = http.Client();
  var streamedResponse = await client.send(request);
  var dataAsString = await streamedResponse.stream.bytesToString();
  client.close();
  var dataAsMap = json.decode(dataAsString) as Map;
  List users = dataAsMap["users"];

  int i = 0;
  Map user = users[i];

  if (!name.isEmpty) {
    while (i < users.length) {
      user = users[i];
      print(user["name"]);
      if ((user["name"] as String).toUpperCase()
          .startsWith(name.toUpperCase())) {
        i++;
      } else {
        users.removeAt(i);
        if (i != 0) {
          i--;
        }
      }
    }
  }
  i = 0;
  if (!surname.isEmpty) {
    while (i < users.length) {
      user = users[i];
      if ((user["surname"] as String).toUpperCase()
          .startsWith(surname.toUpperCase())) {
        i++;
      } else {
        users.removeAt(i);
        if (i != 0) {
          i--;
        }
      }
    }
  }

  return users;
}

Future<Map> postAccLog(int facility_id, String user_id,
    DateTime timestamp, String type, double temperature) async {
  const ipMovil = "10.0.2.2";
  var url = Uri.parse("http://$ipMovil:8080/api/rest/access_log");
  var request = http.Request("POST", url);
  request.headers.addAll({"x-hasura-admin-secret": "myadminsecretkey"});
  request.body =
  '{'
      '"facility_id": $facility_id,'
      '"user_id": "$user_id",'
      '"timestamp": "${timestamp.toIso8601String()}",'
      '"type": "$type",'
      '"temperature": "$temperature"'
  '}';
  var client = http.Client();
  var streamedResponse = await client.send(request);
  var dataAsString = await streamedResponse.stream.bytesToString();
  client.close();
  await Future.delayed(Duration(seconds: 2));
  var dataAsMap = json.decode(dataAsString) as Map;
  return dataAsMap["insert_access_log_one"];
}

class Alert extends StatelessWidget {
  final String _text;

  Alert(this._text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_text),
      actions: <Widget>[
        ElevatedButton(
          child: Text("OK"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
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


// VISTA

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
          title: const Text("Centros"),
        ),
        body: Center(child: Column(
            children: <Widget>[
              Container(
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: Border.all(
                      color: Colors.black,
                      width: 1.0,
                    ),
                  ),
                  child: const Text("Seleccione el centro para"
                      " registrar u obtener su información:",
                      textScaleFactor: 1.5
                  )
              ),
              FutureBuilder<List>(
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
                              " ningún centro disponible, pruebe más tarde.",
                              textScaleFactor: 1.5
                          );
                        }

                        return Expanded(child: ListView.builder(
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
                          )
                          );
                      }
                      return Alert("Error: ${snapshot.connectionState}");
                    default:
                      return Alert("Error: ${snapshot.connectionState}");
                  }
                },
              ),
            ]
        )
        )
    );
  }
}

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
                  MaterialPageRoute(builder: (context) => IdentificarPage(facility: facility)),
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

class IdentificarPage extends StatelessWidget {
  Map facility;

  IdentificarPage({Key? key, required this.facility}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identificar usuario')),
      body: Builder(builder: (BuildContext context) {
        return Container(
          alignment: Alignment.center,
          child: Flex(
            direction: Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () => FlutterBarcodeScanner.scanBarcode(
                  '#ff6666', 'Cancel', true, ScanMode.QR).then(
                        (value) {
                    if(value != '-1') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>
                            RegistrarPage(uuid: value, facility: facility,)
                        ),
                      );
                    }
                  }
                ),
                child: const Text('Con QR',
                    textScaleFactor: 1.5
                )
              ),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>
                    UsuariosPage(facility: facility))
                ),
                child: const Text('Manual',
                    textScaleFactor: 1.5
                )
              ),
            ]
          )
        );
      }
      )
    );
  }
}

class UsuariosPage extends StatefulWidget {
  Map facility;

  UsuariosPage({Key? key, required this.facility}): super(key: key);

  @override
  _UsuariosPageState createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  late Future<List> _value;
  String _nombre = '',
      _apellido = '';

  @override
  initState() {
    super.initState();
    _value = getUsers(_nombre, _apellido);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Usuarios"),
        ),
        body: Center(child: Column(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(
                    hintText: "nombre apellido",
                    labelText: "Introduzca el nombre y apellido del usuario"),
                onFieldSubmitted: (value) {
                  value = value.trim();
                  if (!value.isEmpty) {
                    List<String> values = value.split(' ');

                    setState(() {
                      _nombre = values[0];
                      if (values.length > 1) {
                        _apellido = values[1];
                      }
                        _value = getUsers(_nombre, _apellido);
                    });
                  }
                },
              ),
              FutureBuilder<List>(
                future: _value,
                builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      return CircularProgressIndicator();
                    case ConnectionState.done:
                      if (snapshot.hasError) {
                        return Alert("Fallo al conectar con la base de datos");
                      } else {
                        List users = snapshot.data as List;

                        if (users.isEmpty) {
                          return const Text("No se encontraron coincidencias",
                              textScaleFactor: 1.5
                          );
                        }

                        return Expanded(child: ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            Map user = users[index];

                            return ListTile(
                              title: Text("${user["name"]} ${user["surname"]}"),
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          RegistrarPage(uuid: user["uuid"],
                                              facility: widget.facility),
                                    )
                                );
                              },
                            );
                          },
                        )
                        );
                      }
                    default:
                      return Alert("Error: ${snapshot.connectionState}");
                  }
                },
              ),
            ]
        )
        )
    );
  }
}

class EventPage extends StatefulWidget {
  Map facility;

  EventPage({Key? key, required this.facility}) : super(key: key);

  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  late DateTime fechaDesde;
  late DateTime fechaHasta;
  late Future<List> _futAccLog;
  late Future<DateTime?> _futFechaDesde;
  late Future<DateTime?> _futFechaHasta;
  late Future<TimeOfDay?> _futTimeDesde;
  late Future<TimeOfDay?> _futTimeHasta;

  String dateToString(DateTime fecha) =>
      fecha.toIso8601String().substring(0, 10);

  String timeToString(DateTime fecha) =>
      fecha.toString().substring(11, 16);

  @override
  initState() {
    super.initState();
    fechaHasta = DateTime.now();
    int year = fechaHasta.year,
        month = fechaHasta.month,
        day = fechaHasta.day - 28;
    if (day <= 0) {
      day = day % 28 + 1;
      if (month-- == 0) {
        year--;
        month = 12;
      }
    }
    fechaDesde = DateTime(year, month, day,
        fechaHasta.hour, fechaHasta.minute);

    _futAccLog = getEvent(widget.facility['id'], fechaDesde, fechaHasta);

    _futFechaDesde = Future(() => fechaDesde);
    _futFechaHasta = Future(() => fechaHasta);
    _futTimeDesde = Future(() =>
        TimeOfDay(hour: fechaDesde.hour, minute: fechaDesde.minute));
    _futTimeHasta = Future(() =>
        TimeOfDay(hour: fechaHasta.hour, minute: fechaHasta.minute));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Eventos"),
      ),
      body: Center(
        child: Column(
            children: <Widget>[
              Container(
                  decoration: ShapeDecoration(
                    color: Colors.white,
                    shape: Border.all(
                      color: Colors.black,
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                      children: <Widget>[
                        Row(
                            children: <Widget>[
                              const Text(" Inicio ",
                                  textScaleFactor: 2
                              ),
                              FutureBuilder<DateTime?>(
                                  future: _futFechaDesde,
                                  builder: (BuildContext context, AsyncSnapshot<DateTime?> snapshot) {
                                    DateTime? newFecha = snapshot.data;
                                    if (newFecha != null) {
                                      fechaDesde = newFecha;
                                    }

                                    return Container(
                                        decoration: ShapeDecoration(
                                          color: Colors.white,
                                          shape: Border.all(
                                            color: Colors.black,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Text(dateToString(fechaDesde),
                                            textScaleFactor: 2
                                        )
                                    );
                                  }
                              ),
                              IconButton(
                                  icon: const Icon(Icons.calendar_today),
                                  iconSize: 25,
                                  tooltip: 'Austar la fecha de inicio del evento',
                                  onPressed: () => setState(() {
                                    _futFechaDesde = showDatePicker(
                                        context: context,
                                        initialDate: fechaDesde,
                                        firstDate: DateTime(2021),
                                        lastDate: DateTime(2076)
                                    );
                                  }
                                  )
                              ),
                              FutureBuilder<TimeOfDay?>(
                                  future: _futTimeDesde,
                                  builder: (BuildContext context, AsyncSnapshot<TimeOfDay?> snapshot) {
                                    TimeOfDay? newTime = snapshot.data;

                                    if(newTime != null) {
                                      //setState(() =>
                                      fechaDesde = DateTime(
                                          fechaDesde.year,
                                          fechaDesde.month,
                                          fechaDesde.day,
                                          newTime.hour,
                                          newTime.minute
                                        //  )
                                      );
                                    }

                                    return Container(
                                      decoration: ShapeDecoration(
                                        color: Colors.white,
                                        shape: Border.all(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Text(timeToString(fechaDesde),
                                          textScaleFactor: 2
                                      ),
                                    );
                                  }
                              ),
                              IconButton(
                                  icon: const Icon(Icons.access_time),
                                  iconSize: 25,
                                  tooltip: 'Austar la hora de inicio del evento',
                                  onPressed: () => setState((){
                                    _futTimeDesde = showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay(
                                            hour: fechaDesde.hour,
                                            minute: fechaDesde.minute
                                        )
                                    );
                                  },
                                  )
                              )
                            ]
                        ),
                        Row(
                          children: <Widget>[
                            const Text(" Final  ",
                                textScaleFactor: 2
                            ),
                            FutureBuilder<DateTime?>(
                                future: _futFechaHasta,
                                builder: (BuildContext context, AsyncSnapshot<DateTime?> snapshot) {
                                  DateTime? newFecha = snapshot.data;
                                  if(newFecha != null) {
                                    //setState(() =>
                                    fechaHasta = newFecha as DateTime;
                                    //);
                                  }

                                  return Container(
                                    decoration: ShapeDecoration(
                                      color: Colors.white,
                                      shape: Border.all(
                                        color: Colors.black,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Text(dateToString(fechaHasta),
                                        textScaleFactor: 2
                                    ),
                                  );
                                }
                            ),
                            IconButton(
                                icon: const Icon(Icons.calendar_today),
                                iconSize: 25,
                                tooltip: 'Austar la fecha de fin del evento',
                                onPressed: () => setState(() {
                                  _futFechaHasta = showDatePicker(
                                      context: context,
                                      initialDate: fechaHasta,
                                      firstDate: DateTime(2021),
                                      lastDate: DateTime(2076)
                                  );
                                }
                                )
                            ),
                            FutureBuilder<TimeOfDay?>(
                                future: _futTimeHasta,
                                builder: (BuildContext context, AsyncSnapshot<TimeOfDay?> snapshot) {
                                  TimeOfDay? newTime = snapshot.data;

                                  if(newTime != null) {
                                    //setState(() =>
                                    fechaHasta = DateTime(
                                        fechaHasta.year,
                                        fechaHasta.month,
                                        fechaHasta.day,
                                        newTime.hour,
                                        newTime.minute
                                      //)
                                    );
                                  }

                                  return Container(
                                      decoration: ShapeDecoration(
                                        color: Colors.white,
                                        shape: Border.all(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Text(timeToString(fechaHasta),
                                          textScaleFactor: 2
                                      )
                                  );
                                }
                            ),
                            IconButton(
                                icon: const Icon(Icons.access_time),
                                iconSize: 25,
                                tooltip: 'Austar la hora de fin del evento',
                                onPressed: () => setState(() {
                                  _futTimeHasta = showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay(
                                        hour: fechaHasta.hour,
                                        minute: fechaHasta.minute
                                    ),
                                  );
                                }
                                )
                            )
                          ],
                        ),
                        IconButton(
                            alignment: Alignment.topRight,
                            icon: const Icon(Icons.search),
                            iconSize: 25,
                            tooltip: 'Austar la fecha de inicio del evento',
                            onPressed: () => setState(() {
                              _futAccLog = getEvent(widget.facility['id'],
                                  fechaDesde, fechaHasta);
                            })
                        ),
                      ]
                  )
              ),
              FutureBuilder<List>(
                future: _futAccLog,
                builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      return CircularProgressIndicator();
                    case ConnectionState.done:
                      if (snapshot.hasError) {
                        return Alert("Fallo al conectar con la base de datos");
                      } else {
                        List accesos = snapshot.data as List;
                        DateTime now = DateTime.now();

                        if(fechaDesde.isAfter(now) || fechaHasta.isAfter(now)){
                          return const Text("Las fechas deben ser previas a la actual.",
                              textScaleFactor: 1.5
                          );
                        } else if(fechaDesde.isAfter(fechaHasta)) {
                          return const Text("La fecha de inicio debe ser anterior a la final.",
                              textScaleFactor: 1.5
                          );
                        } else if(accesos.isEmpty){
                          return const Text("No se obtuvieron resultados.",
                              textScaleFactor: 1.5
                          );
                        } else {
                          return Expanded(child: SingleChildScrollView(
                              child: DataTable(
                                columns: const <DataColumn>[
                                  DataColumn(
                                    label: Text(
                                      'Tipo',
                                      style: TextStyle(
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Fecha',
                                      style: TextStyle(
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Hora',
                                      style: TextStyle(
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Usuario',
                                      style: TextStyle(
                                          fontStyle: FontStyle.italic),
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
                                            DataCell(
                                                Text(acceso['timestamp']
                                                    .toString().substring(
                                                    0, 11))),
                                            DataCell(
                                                Text(acceso['timestamp']
                                                    .toString().substring(
                                                    11, 16))),
                                            DataCell(Text(
                                                '${user['name']} '
                                                    '${user['surname']}')),
                                          ]
                                      );
                                    }
                                ),
                              )
                          )
                          );
                        }
                      }
                    default:
                      return Alert("Error: ${snapshot.connectionState}");
                  }
                },
              ),
            ]
        ),
    ));
  }
}

class RegistrarPage extends StatelessWidget {
  final String uuid;
  final Map facility;
  
  const RegistrarPage({required this.uuid, required this.facility, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Registrar'),
        ),
        body: Text(uuid)
    );
  }
}


void main() {
  runApp(const MyApp());
}