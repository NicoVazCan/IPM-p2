import 'dart:convert';
import 'package:analyzer/dart/element/type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:provider/provider.dart';

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

// MODELO
class Modelo {
  static Future<Map> getFacilities(String ip) async {
    var url = Uri.parse("http://$ip:8080/api/rest/facilities");
    var request = http.Request("GET", url);
    request.headers.addAll({"x-hasura-admin-secret": "myadminsecretkey"});
    var client = http.Client();
    var streamedResponse = await client.send(request);
    var dataAsString = await streamedResponse.stream.bytesToString();
    client.close();
    await Future.delayed(Duration(seconds: 2));
    var dataAsMap = json.decode(dataAsString) as Map;
    return {"status": streamedResponse.statusCode, "data": dataAsMap["facilities"]};
  }

  static Future<Map> getEvent(String ip, int facility_id, DateTime desde, DateTime hasta) async {
    var url = Uri.parse(
        "http://$ip:8080/api/rest/facility_access_log/$facility_id/daterange");
    var request = http.Request("GET", url);
    request.headers.addAll({"x-hasura-admin-secret": "myadminsecretkey"});
    request.body =
    '{ "startdate": "${desde.toIso8601String()}", "enddate": "${hasta
        .toIso8601String()}"}';
    var client = http.Client();
    var streamedResponse = await client.send(request);
    var dataAsString = await streamedResponse.stream.bytesToString();
    client.close();
    await Future.delayed(Duration(seconds: 2));
    var dataAsMap = json.decode(dataAsString) as Map;
    return {"status": streamedResponse.statusCode, "data": dataAsMap["access_log"]};
  }

  static Future<Map> getUsers(String ip, String name, String surname) async {
    name = name.trim();
    surname = surname.trim();

    if (!name.isEmpty && !surname.isEmpty) {
      var url = Uri.parse(
          "http://$ip:8080/api/rest/user?name=$name&surname=$surname");
      var request = http.Request("GET", url);
      request.headers.addAll({"x-hasura-admin-secret": "myadminsecretkey"});
      var client = http.Client();
      var streamedResponse = await client.send(request);
      var dataAsString = await streamedResponse.stream.bytesToString();
      client.close();
      var dataAsMap = json.decode(dataAsString) as Map;
      List users = dataAsMap["users"];

      if (!users.isEmpty) {
        return {"status": streamedResponse.statusCode, "data": users};
      }
    }

    var url = Uri.parse("http://$ip:8080/api/rest/users");
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

    return {"status": streamedResponse.statusCode, "data": users};
  }

  static Future<Map> postAccLog(String ip, int facility_id, String user_id,
      DateTime timestamp, String type, double temperature) async {
    var url = Uri.parse("http://$ip:8080/api/rest/access_log");
    var request = http.Request("POST", url);
    request.headers.addAll({"x-hasura-admin-secret": "myadminsecretkey"});
    request.body =
    '{'
        '"facility_id": $facility_id,'
        '"user_id": "$user_id",'
        '"timestamp": "${timestamp.toIso8601String()}",'
        '"type": "$type",'
        '"temperature": "${temperature.toString()}"'
        '}';
    var client = http.Client();
    var streamedResponse = await client.send(request);
    var dataAsString = await streamedResponse.stream.bytesToString();
    client.close();
    await Future.delayed(Duration(seconds: 2));
    var dataAsMap = json.decode(dataAsString) as Map;
    return {"status": streamedResponse.statusCode, "data": dataAsMap["insert_access_log_one"]};
  }
}

enum Idiomas { esp, eng }

// VISTA

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

class Facilities extends ChangeNotifier {
  Map? _facilities;

  Facilities(String ip) {
    askFacilities(ip);
  }

  Map? get getFacilities {
    return _facilities;
  }

  void askFacilities(String ip) async {
    _facilities = null;
    notifyListeners();
    _facilities = await Modelo.getFacilities(ip);
    notifyListeners();
  }
}

class FacilitiesPage extends StatelessWidget {
  FacilitiesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            appBar: AppBar(
              title: const Text("Centros"),
            ),
            persistentFooterButtons: <Widget>[
              IconButton(
                  icon: const Icon(Icons.sync),
                  iconSize: 20,
                  tooltip: 'Recargar',
                  onPressed: () {
                    Provider.of<Facilities>(context, listen: false)
                        .askFacilities(Provider.of<Ip>(context, listen: false).getIp);
                  }
              ),
              IconButton(
                  icon: const Icon(Icons.settings),
                  iconSize: 20,
                  tooltip: 'Configuración',
                  onPressed: () =>
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ConfiguracionPage()
                          )
                      )
              ),
            ],
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
                  Loader(
                      Provider.of<Facilities>(context).getFacilities,
                      (List facilities) => Expanded(child: ListView.builder(
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
                      )
                  )
                ]
            )
            )
    );
  }
}

class Loader extends StatelessWidget {
  Map? response;
  Function builder;
  Loader(this.response, this.builder, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if(response == null) {
      return CircularProgressIndicator();
    }
    if(response!['status'] == 200) {
      return builder(response!['value']);
    }
    return Alert("Error al conectar con la base de datos.\n"
        "Código de estado: ${response!['status']}");
  }
}


class Ip extends ChangeNotifier {
  String ip = "10.0.2.2";

  String get getIp {
    return ip;
  }

  set setIp(String ip) {
    this.ip = ip;
    notifyListeners();
  }
}

class ConfiguracionPage extends StatelessWidget {
  ConfiguracionPage({Key? key}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Configuración'),
        ),
        body: TextFormField(
          decoration: InputDecoration(
              hintText: Provider.of<Ip>(context).getIp,
              labelText: "Introduzca la IP de la BBDD"),
          keyboardType: TextInputType.number,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {

            if(value == null){
              return "Formato incorrecto";
            }
            value = value as String;
            var values = value.split('.');
            if(values.length < 4){
              return "Formato incorrecto";
            }
            for(String i in values) {
              if(i.isEmpty || i.toUpperCase() != i.toLowerCase()){
                return "Formato incorrecto";
              }
            }
          },
          onFieldSubmitted: (value) {
            if(value == null) return;
            value = value.trim();
            if (!value.isEmpty) {
              Provider.of<Ip>(context, listen: false).setIp = value;
            }
          },
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

class IdentificarPage extends StatefulWidget {
  Map facility;

  IdentificarPage({Key? key, required this.facility}) : super(key: key);

  @override
  _IdentificarPageState createState() => _IdentificarPageState();

}

class _IdentificarPageState extends State<IdentificarPage> {
  late Future<String> _futQr;

  @override
  void initState() {
    super.initState();
    _futQr = Future(() => '-1');
  }


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
        ChangeNotifierProvider.value(
        value: Usuarios(Provider.of<Ip>(context, listen: false).getIp, '', ''),
    ),
    ],
    child: Scaffold(
        appBar: AppBar(title: const Text('Identificar usuario')),
        body: Builder(builder: (BuildContext context)
    {
      return FutureBuilder(
          future: _futQr,
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.hasData &&
                snapshot.data != null &&
                snapshot.data != '-1') {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        RegistrarPage(uuid: snapshot.data as String,
                          facility: widget.facility,)
                ),
              );
            }
            return Container(
                alignment: Alignment.center,
                child: Flex(
                    direction: Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                          onPressed: () =>
                              setState(() =>
                              _futQr = FlutterBarcodeScanner.scanBarcode(
                                  '#ff6666', 'Cancel', true, ScanMode.QR)
                              ),
                          child: const Text('Con QR',
                              textScaleFactor: 1.5
                          )
                      ),
                      ElevatedButton(
                          onPressed: () =>
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) =>
                                      UsuariosPage(
                                          facility: widget.facility))
                              ),
                          child: const Text('Manual',
                              textScaleFactor: 1.5
                          )
                      ),
                    ]
                )
            );
          }
      );
    })));
  }
}

class Usuarios extends ChangeNotifier {
  Map? _usuarios = null;

  Usuarios(String ip, String name, String surname) {
    askUsuarios(ip, name, surname);
  }

  Map? get getUsuarios {
    return _usuarios;
  }

  void askUsuarios(String ip, String name, String surname) async {
    _usuarios = null;
    notifyListeners();
    _usuarios = await Modelo.getUsers(ip, name, surname);
    notifyListeners();
  }
}

class UsuariosPage extends StatelessWidget {
  Map facility;

  UsuariosPage({Key? key, required this.facility}): super(key: key);

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
                    String nombre = '',
                        apellido = '';
                    List<String> values = value.split(' ');
                    nombre = values[0];
                    if (values.length > 1) {
                      apellido = values[1];
                    }
                    Provider.of<Usuarios>(context, listen: false)
                        .askUsuarios(Provider
                        .of<Ip>(context, listen: false)
                        .getIp, nombre, apellido);
                  }
                },
              ),
              Loader(Provider
                  .of<Usuarios>(context, listen: false)
                  .getUsuarios,
                      (List users) {
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
                          title: Text("${user["name"]} ${user["surname"]}\n"
                              "nº: ${user["phone"]}"),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      RegistrarPage(uuid: user["uuid"],
                                          facility: facility),
                                )
                            );
                          },
                        );
                      },
                    )
                    );
                  })
            ]
        )
        )
    );
  }
}

class Event extends ChangeNotifier {
  Map? event = null;

  Event(String ip, int facility_id,
      DateTime desde, DateTime hasta) {
    askEvent(ip, facility_id, desde, hasta);
  }

  Map? get getEvent => event;

  void askEvent(String ip, int facility_id,
      DateTime desde, DateTime hasta) async {
    event = null;
    notifyListeners();
    event = await Modelo.getEvent(ip, facility_id, desde, hasta);
    notifyListeners();
  }
}

abstract class FechaHora extends ChangeNotifier {
  DateTime fecha = DateTime.now();
  TimeOfDay hora = TimeOfDay.now();

  void setFecha(BuildContext context) async {
    DateTime? nuevaFecha = await showDatePicker(
        context: context,
        initialDate: fecha,
        firstDate: DateTime(2021),
        lastDate: DateTime(2076)
    );
    if(nuevaFecha != null) {
      fecha = nuevaFecha;
      notifyListeners();
    }
  }

  void setHora(BuildContext context) async {
    TimeOfDay? nuevaHora = await showTimePicker(
        context: context,
        initialTime: hora
    );
    if(nuevaHora != null) {
      hora = nuevaHora;
      notifyListeners();
    }
  }

  String fechaToString() =>
      fecha.toIso8601String().substring(0, 10);

  String horaToString() =>
      hora.toString();
}

class FechaHoraDesde extends FechaHora {}
class FechaHoraHasta extends FechaHora {}

class EventPage extends StatelessWidget {
  Map facility;

  EventPage({Key? key, required this.facility}) : super(key: key);
  late DateTime fechaDesde;
  late DateTime fechaHasta;
  late Future<DateTime?> _futFechaDesde;
  late Future<DateTime?> _futFechaHasta;
  late Future<TimeOfDay?> _futTimeDesde;
  late Future<TimeOfDay?> _futTimeHasta;

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

    _futAccLog = Modelo.getEvent(
        Provider.of<Ip>(context, listen: false).getIp,
        widget.facility['id'], fechaDesde, fechaHasta);

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
                                  textScaleFactor: 1.5
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
                                            textScaleFactor: 1.5
                                        )
                                    );
                                  }
                              ),
                              IconButton(
                                  icon: const Icon(Icons.calendar_today),
                                  iconSize: 20,
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
                                      fechaDesde = DateTime(
                                          fechaDesde.year,
                                          fechaDesde.month,
                                          fechaDesde.day,
                                          newTime.hour,
                                          newTime.minute
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
                                          textScaleFactor: 1.5
                                      ),
                                    );
                                  }
                              ),
                              IconButton(
                                  icon: const Icon(Icons.access_time),
                                  iconSize: 20,
                                  tooltip: 'Buscar',
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
                                textScaleFactor: 1.5
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
                                        textScaleFactor: 1.5
                                    ),
                                  );
                                }
                            ),
                            IconButton(
                                icon: const Icon(Icons.calendar_today),
                                iconSize: 20,
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
                                          textScaleFactor: 1.5
                                      )
                                  );
                                }
                            ),
                            IconButton(
                                icon: const Icon(Icons.access_time),
                                iconSize: 20,
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
                            iconSize: 20,
                            tooltip: 'Austar la fecha de inicio del evento',
                            onPressed: () => setState(() {
                              _futAccLog = Modelo.getEvent(
                                  Provider.of<Ip>(context, listen: false).getIp,
                                  widget.facility['id'],
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
                                                    0, 10))),
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

class RegistrarPage extends StatefulWidget {
  final String uuid;
  final Map facility;

  const RegistrarPage({required this.uuid, required this.facility, Key? key})
      : super(key: key);

  @override
  _RegistrarPageState createState() => _RegistrarPageState();

}

class _RegistrarPageState extends State<RegistrarPage> {
  late Future<DateTime?> _futFecha;
  late Future<TimeOfDay?> _futTime;
  late Future<Map> _futAcc;
  late double temperatura;
  late DateTime fecha;
  late bool entra;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    temperatura = 30.0;
    fecha = DateTime.now();
    entra = true;

    _futFecha = Future(() => fecha);
    _futTime = Future(() =>
        TimeOfDay(hour: fecha.hour, minute: fecha.minute));
    _futAcc = Future(() => {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
          title: Text('Registrar acceso'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
          Text("Introduzca los datos del acceso a ${widget.facility['name']}",
              textScaleFactor: 1.5,
          ),
          TextFormField(
            decoration: const InputDecoration(
                hintText: "30.0",
                labelText: "Introduzca la temperatura del usuario"),
            keyboardType: TextInputType.number,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
                if(value == null || double.tryParse(value) == null){
                  return "Formato incorrecto";
                }
              },
            onFieldSubmitted: (value) {
              value = value.trim();
              if (!value.isEmpty) {
                setState(() {
                  temperatura = double.parse(value);
                });
              }
            },
          ),
          const Text("Introduzca la fecha del acceso",
          ),
          Row(
              children: <Widget>[
                FutureBuilder<DateTime?>(
                    future: _futFecha,
                    builder: (BuildContext context, AsyncSnapshot<DateTime?> snapshot) {
                      DateTime? newFecha = snapshot.data;
                      if (newFecha != null) {
                        fecha = newFecha;
                      }

                      return Container(
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: Border.all(
                              color: Colors.black,
                              width: 1.0,
                            ),
                          ),
                          child: Text(dateToString(fecha),
                              textScaleFactor: 1.5
                          )
                      );
                    }
                ),
                IconButton(
                    icon: const Icon(Icons.calendar_today),
                    iconSize: 20,
                    tooltip: 'Austar la fecha del acceso',
                    onPressed: () => setState(() {
                      _futFecha = showDatePicker(
                          context: context,
                          initialDate: fecha,
                          firstDate: DateTime(2021),
                          lastDate: DateTime(2076)
                      );
                    }
                    )
                ),
                FutureBuilder<TimeOfDay?>(
                    future: _futTime,
                    builder: (BuildContext context, AsyncSnapshot<TimeOfDay?> snapshot) {
                      TimeOfDay? newTime = snapshot.data;

                      if(newTime != null) {
                        fecha = DateTime(
                            fecha.year,
                            fecha.month,
                            fecha.day,
                            newTime.hour,
                            newTime.minute
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
                        child: Text(timeToString(fecha),
                            textScaleFactor: 1.5
                        ),
                      );
                    }
                ),
                IconButton(
                    icon: const Icon(Icons.access_time),
                    iconSize: 20,
                    tooltip: 'Austar la hora del acceso',
                    onPressed: () => setState((){
                      _futTime = showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                              hour: fecha.hour,
                              minute: fecha.minute
                          )
                      );
                    },
                    )
                )
              ]
          ),
          const Text("Indique si ha entrado o salido",
          ),
          Row(children: <Widget>[
            Switch(
                value: entra,
                onChanged: (value) => setState(() => entra = value)
            ),
            Text(entra? "Entró": "Salió",
              textScaleFactor: 1.5,
            )
          ],
          ),
          Center(
            child: IconButton(
                alignment: Alignment.topRight,
                icon: const Icon(Icons.check_circle_outline),
                iconSize: 50,
                tooltip: 'Austar la fecha de inicio del evento',
                onPressed: () => setState(() {
                  _futAcc = Modelo.postAccLog(
                      Provider.of<Ip>(context, listen: false).getIp,
                      widget.facility['id'],
                      widget.uuid,
                      fecha,
                      entra? 'IN': 'OUT',
                      temperatura);
                })
            ),
          ),
          Center(child: FutureBuilder<Map>(
              future: _futAcc,
              builder: (BuildContext context, AsyncSnapshot<Map> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return CircularProgressIndicator();
                  case ConnectionState.done:
                    if (snapshot.hasError) {
                      return Alert("Fallo al conectar con la base de datos");
                    } else {
                      Map acceso = snapshot.data as Map;

                      if (acceso.isEmpty) {
                        return const Text("No se ha registrado nada");
                      } else {
                        return Container(
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: Border.all(
                                color: Colors.black,
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "\n Se ha registrado correctamente la\n"
                                  " siguiente información del usuario: \n\n"
                                  " Fecha: ${acceso["timestamp"].substring(0, 10)}\n"
                                  " Hora: ${acceso["timestamp"].substring(11, 16)}\n"
                                  " Tipo: ${acceso["type"]}\n",
                                  textScaleFactor: 1.5,
                                )
                              ]
                            )
                        );
                      }
                    }
                  default:
                    return Alert("Error: ${snapshot.connectionState}");
                }
              },
            ),
          )
        ]
        ),
    );
  }
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
        ChangeNotifierProvider.value(
        value: Facilities(Provider.of<Ip>(context, listen: false).getIp),
    ),
    ],
    child: MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue,),
      home: FacilitiesPage(),
      debugShowCheckedModeBanner: false,
    ));
  }
}

class Counter extends ChangeNotifier {
  var _count = 0;
  int get getCounter {
    return _count;
  }

  void incrementCounter() async {
    await Future.delayed(Duration(seconds: 2));
    _count += 1;
    notifyListeners();
  }
}

/*
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: Counter(),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: MyHomePage("AndroidVille Provider Pattern"),
      ),
    );
  }
}*/

class MyHomePage extends StatelessWidget {
  final String title;
  MyHomePage(this.title);
  void _incrementCounter(BuildContext context) {
    Provider.of<Counter>(context, listen: false).incrementCounter();
  }

  @override
  Widget build(BuildContext context) {
    var counter = Provider.of<Counter>(context).getCounter;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _incrementCounter(context),
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}


void main() {
  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: Ip(),
        ),
      ],
      child: MyApp()));
}