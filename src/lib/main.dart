import 'dart:convert';
import 'package:analyzer/dart/analysis/context_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    var dataAsMap = json.decode(dataAsString) as Map;
    return {"status": streamedResponse.statusCode, "data": dataAsMap["insert_access_log_one"]};
  }
}

String fechaToString(DateTime fecha) =>
    fecha.toIso8601String().substring(0, 10);

String horaToString(DateTime fecha) =>
    fecha.toIso8601String().substring(11, 16);

class Ip extends ChangeNotifier {
  String _ip = "10.0.2.2";

  String get ip => _ip;

  set ip(String ip) {
    _ip = ip;
    notifyListeners();
  }
}

class Facilities extends ChangeNotifier {
  Map? _facilities;

  Facilities(String ip) {
    askFacilities(ip);
  }

  Map? get facilities => _facilities;

  void askFacilities(String ip) async {
    _facilities = null;
    notifyListeners();
    _facilities = await Modelo.getFacilities(ip);
    notifyListeners();
  }
}

abstract class Fecha extends ChangeNotifier {
  DateTime _fecha = DateTime.now();

  DateTime get fecha => _fecha;

  void setFecha(BuildContext context) async {
    DateTime? nuevaFecha = await showDatePicker(
        context: context,
        initialDate: _fecha,
        firstDate: DateTime(2021),
        lastDate: DateTime(2076)
    );
    if(nuevaFecha != null) {
      _fecha = nuevaFecha;
      notifyListeners();
    }
  }

  void setHora(BuildContext context) async {
    TimeOfDay? nuevaHora = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: _fecha.hour,
            minute: _fecha.minute)
    );
    if(nuevaHora != null) {
      _fecha = DateTime(_fecha.year, _fecha.month,
          _fecha.day, nuevaHora.hour, nuevaHora.minute);
      notifyListeners();
    }
  }
}

class FechaDesde extends Fecha {}
class FechaHasta extends Fecha {}
class FechaAcceso extends Fecha {}

class Acceso extends ChangeNotifier {
  Map? _acceso = {"status": 200, "data": {}};

  Map? get acceso => _acceso;

  void setAcceso(String ip, int facility_id, String user_id,
      DateTime timestamp, String type, double temperature) async {
    _acceso = null;
    notifyListeners();
    _acceso = await Modelo.postAccLog(ip, facility_id, user_id, timestamp, type, temperature);
    notifyListeners();
  }
}

class Usuarios extends ChangeNotifier {
  Map? _usuarios = null;

  Usuarios(String ip, String name, String surname) {
    askUsuarios(ip, name, surname);
  }

  get usuarios => _usuarios;

  void askUsuarios(String ip, String name, String surname) async {
    _usuarios = null;
    notifyListeners();
    _usuarios = await Modelo.getUsers(ip, name, surname);
    notifyListeners();
  }
}

class Usuario extends ChangeNotifier {
  String? _usuario;

  String? get usuario => _usuario;

  set usuario(String? uid){
    _usuario = uid;
    notifyListeners();
  }
}

class Temperatura extends ChangeNotifier {
  double _temperatura = 30.0;

  double get temperatura => _temperatura;

  set temperatura(double value) {
    _temperatura = value;
    notifyListeners();
  }
}

class Entra extends ChangeNotifier {
  bool _entra = true;

  bool get entra => _entra;

  set entra(bool value) {
    _entra = value;
    notifyListeners();
  }
}

class Facility extends ChangeNotifier {
  Map? _facility;

  Map? get facility => _facility;

  set facility(Map? value) {
    _facility = value;
  }


}

class Event extends ChangeNotifier {
  Map? _event = null;

  Event(String ip, int facility_id,
      DateTime desde, DateTime hasta) {
    askEvent(ip, facility_id, desde, hasta);
  }

  Map? get event => _event;

  void askEvent(String ip, int facility_id,
      DateTime desde, DateTime hasta) async {
    _event = null;
    notifyListeners();
    _event = await Modelo.getEvent(ip, facility_id, desde, hasta);
    notifyListeners();
  }
}

// VISTA

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
      return builder(response!['data']);
    }
    return Alert("Error al conectar con la base de datos.\n"
        "Código de estado: ${response!['status']}");
  }
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
            if(Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              SystemNavigator.pop();
            }
          },
        ),
      ],
    );
  }
}

class FacilitiesPage extends StatelessWidget {
  FacilitiesPage({Key? key}) : super(key: key);

  void _askFacilities(BuildContext context, String ip) =>
      Provider.of<Facilities>(context, listen: false).askFacilities(ip);

  void _setFacility(BuildContext context, Map facility) =>
      Provider.of<Facility>(context, listen: false).facility = facility;

  @override
  Widget build(BuildContext context) {
    String ip = Provider.of<Ip>(context).ip;
    Map? facilities = Provider.of<Facilities>(context).facilities;

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
              _askFacilities(context, ip);
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
                facilities,
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
                              builder: (context) {
                                _setFacility(context, facility);
                                return OpcionesPage();
                            }
                          )
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

class ConfiguracionPage extends StatelessWidget {
  ConfiguracionPage({Key? key}): super(key: key);

  void _setIp(BuildContext context, String ip) =>
      Provider.of<Ip>(context, listen: false).ip = ip;

  @override
  Widget build(BuildContext context) {
    String ip = Provider.of<Ip>(context).ip;
    return Scaffold(
        appBar: AppBar(
          title: Text('Configuración'),
        ),
        body: TextFormField(
          decoration: InputDecoration(
              hintText: ip,
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
            print(value);
          },
          onFieldSubmitted: (value) {
            value = value.trim();
            if (!value.isEmpty) {
              _setIp(context, value);
            }
          },
        )
    );
  }
}

class OpcionesPage extends StatelessWidget {
  
  const OpcionesPage({Key? key}): super(key: key);

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
                  MaterialPageRoute(builder: (context) => IdentificarPage()),
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
                  MaterialPageRoute(builder: (context) => EventPage()),
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
  IdentificarPage({Key? key}): super(key: key);

  void _setUsuario(BuildContext context, String uuid) =>
      Provider.of<Usuario>(context, listen: false).usuario = uuid;

  @override
  Widget build(BuildContext context) {
    String ip = Provider.of<Ip>(context).ip;

        return MultiProvider(providers: [
          ChangeNotifierProvider.value(
            value: Usuarios(ip, '', ''),
          ),
          ChangeNotifierProvider.value(
            value: FechaAcceso(),
          ),
          ChangeNotifierProvider.value(
            value: Acceso(),
          ),
        ],
        child: Scaffold(
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
                                    MaterialPageRoute(builder: (context) {
                                        _setUsuario(context, value);
                                        return RegistrarPage();
                                      }
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
                                  UsuariosPage())
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
    ));
  }
}

class UsuariosPage extends StatelessWidget {

  UsuariosPage({Key? key}): super(key: key);

  void _askUsuarios(BuildContext context, String ip,
      String name, String surname) =>
      Provider.of<Usuarios>(context, listen: false)
          .askUsuarios(ip, name, surname);

  void _setUsuario(BuildContext context, String uuid) =>
      Provider.of<Usuario>(context, listen: false).usuario = uuid;

  @override
  Widget build(BuildContext context) {
    String ip = Provider.of<Ip>(context).ip;
    Map? usuarios = Provider.of<Usuarios>(context).usuarios;
    
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
                    _askUsuarios(context, ip, nombre, apellido);
                  }
                },
              ),
              Loader(
                usuarios,
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
                                builder: (context) {
                                  _setUsuario(context, user["uuid"]);
                                  return RegistrarPage();
                                }
                              )
                          );
                        },
                      );
                    },
                  )
                  );
                }
              )
            ]
        )
        )
    );
  }
}

class EventPage extends StatelessWidget {
  EventPage({Key? key}) : super(key: key);

  void _setFechaDesde(BuildContext context) =>
      Provider.of<FechaDesde>(context, listen: false).setFecha(context);

  void _setHoraDesde(BuildContext context) =>
      Provider.of<FechaDesde>(context, listen: false).setHora(context);

  void _setFechaHasta(BuildContext context) =>
      Provider.of<FechaHasta>(context, listen: false).setFecha(context);

  void _setHoraHasta(BuildContext context) =>
      Provider.of<FechaHasta>(context, listen: false).setHora(context);

  void _askEvent(BuildContext context, String ip,
      int facility_id, DateTime desde, DateTime hasta) =>
      Provider.of<Event>(context, listen: false)
          .askEvent(ip, facility_id, desde, hasta);

  @override
  Widget build(BuildContext context) {
    String ip = Provider.of<Ip>(context).ip;
    Map facility = Provider.of<Facility>(context).facility!;
    DateTime fechaDesde = Provider.of<FechaDesde>(context).fecha;
    DateTime fechaHasta = Provider.of<FechaHasta>(context).fecha;
    Map? event = Provider.of<Event>(context).event;

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
                                Container(
                                    decoration: ShapeDecoration(
                                      color: Colors.white,
                                      shape: Border.all(
                                        color: Colors.black,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Text(
                                        fechaToString(fechaDesde),
                                        textScaleFactor: 1.5
                                    )
                                ),
                                IconButton(
                                    icon: const Icon(Icons.calendar_today),
                                    iconSize: 20,
                                    tooltip: 'Austar la fecha de inicio del evento',
                                    onPressed: () => _setFechaDesde(context)
                                ),
                                Container(
                                  decoration: ShapeDecoration(
                                    color: Colors.white,
                                    shape: Border.all(
                                      color: Colors.black,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Text(
                                      horaToString(fechaDesde),
                                      textScaleFactor: 1.5
                                  ),
                                ),
                                IconButton(
                                    icon: const Icon(Icons.access_time),
                                    iconSize: 20,
                                    tooltip: 'Ajustar la hora de inicio del evento',
                                    onPressed: () => _setHoraDesde(context)
                                )
                              ]
                          ),
                          Row(
                            children: <Widget>[
                              const Text(" Final  ",
                                  textScaleFactor: 1.5
                              ),
                              Container(
                                decoration: ShapeDecoration(
                                  color: Colors.white,
                                  shape: Border.all(
                                    color: Colors.black,
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                    fechaToString(fechaHasta),
                                    textScaleFactor: 1.5
                                ),
                              ),
                              IconButton(
                                  icon: const Icon(Icons.calendar_today),
                                  iconSize: 20,
                                  tooltip: 'Austar la fecha de fin del evento',
                                  onPressed: () => _setFechaHasta(context)
                              ),
                              Container(
                                  decoration: ShapeDecoration(
                                    color: Colors.white,
                                    shape: Border.all(
                                      color: Colors.black,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Text(
                                      horaToString(fechaHasta),
                                      textScaleFactor: 1.5
                                  )
                              ),
                              IconButton(
                                  icon: const Icon(Icons.access_time),
                                  iconSize: 20,
                                  tooltip: 'Austar la hora de fin del evento',
                                  onPressed: () => _setHoraHasta(context)
                              )
                            ],
                          ),
                          IconButton(
                              alignment: Alignment.topRight,
                              icon: const Icon(Icons.search),
                              iconSize: 20,
                              tooltip: 'Buscar',
                              onPressed: () =>
                                  _askEvent(
                                      context,
                                      ip,
                                      facility['id'],
                                      fechaDesde,
                                      fechaHasta
                                  )
                          ),
                        ]
                    )
                ),
                Loader(
                    event,
                        (List accesos) {
                      DateTime now = DateTime.now();

                      if (fechaDesde.isAfter(now) || fechaHasta.isAfter(now)) {
                        return const Text(
                            "Las fechas deben ser previas a la actual.",
                            textScaleFactor: 1.5
                        );
                      } else if (fechaDesde.isAfter(fechaHasta)) {
                        return const Text(
                            "La fecha de inicio debe ser anterior a la final.",
                            textScaleFactor: 1.5
                        );
                      } else if (accesos.isEmpty) {
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
                ),
              ]
          ),
        ));
  }
}

class RegistrarPage extends StatelessWidget {
  const RegistrarPage({Key? key}): super(key: key);

  void _setTemperatura(BuildContext context, double value) =>
      Provider.of<Temperatura>(context, listen: false).temperatura = value;

  void _setFechaAcceso(BuildContext context) =>
      Provider.of<FechaAcceso>(context, listen: false).setFecha(context);

  void _setHoraAcceso(BuildContext context) =>
      Provider.of<FechaAcceso>(context, listen: false).setHora(context);

  void _setEntra(BuildContext context, bool entra) =>
      Provider.of<Entra>(context, listen: false).entra = entra;

  void _setAcceso(BuildContext context, String ip, int facility_id,
      String user_id, DateTime timestamp, String type, double temperature) =>
      Provider.of<Acceso>(context, listen: false)
          .setAcceso(ip, facility_id, user_id, timestamp, type, temperature);


  @override
  Widget build(BuildContext context) {
    String ip = Provider.of<Ip>(context).ip;
    Map facility = Provider.of<Facility>(context).facility!;
    DateTime fechaAcceso = Provider.of<FechaAcceso>(context).fecha;
    bool entra = Provider.of<Entra>(context).entra;
    double temperatura = Provider.of<Temperatura>(context).temperatura;
    Map? acceso = Provider.of<Acceso>(context).acceso;
    String uuid = Provider.of<Usuario>(context).usuario!;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Registrar acceso'),
      ),
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("Introduzca los datos del acceso a ${facility['name']}",
              textScaleFactor: 1.5,
            ),
            TextFormField(
              decoration: const InputDecoration(
                  hintText: "30.0",
                  labelText: "Introduzca la temperatura del usuario"),
              keyboardType: TextInputType.number,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || double.tryParse(value) == null) {
                  return "Formato incorrecto";
                }
              },
              onFieldSubmitted: (value) {
                value = value.trim();
                if (!value.isEmpty) {
                  _setTemperatura(context, double.parse(value));
                }
              },
            ),
            const Text("Introduzca la fecha del acceso",
            ),
            Row(
                children: <Widget>[
                  Container(
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: Border.all(
                          color: Colors.black,
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                          fechaToString(fechaAcceso),
                          textScaleFactor: 1.5
                      )
                  ),
                  IconButton(
                      icon: const Icon(Icons.calendar_today),
                      iconSize: 20,
                      tooltip: 'Austar la fecha del acceso',
                      onPressed: () => _setFechaAcceso(context)
                  ),
                  Container(
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: Border.all(
                        color: Colors.black,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                        horaToString(fechaAcceso),
                        textScaleFactor: 1.5
                    ),
                  ),
                  IconButton(
                      icon: const Icon(Icons.access_time),
                      iconSize: 20,
                      tooltip: 'Austar la hora del acceso',
                      onPressed: () => _setHoraAcceso(context)
                  )
                ]
            ),
            const Text("Indique si ha entrado o salido",
            ),
            Row(children: <Widget>[
              Switch(
                  value: entra,
                  onChanged: (bool value) => _setEntra(context, value)
              ),
              Text(entra?
                  "Entró" : "Salió",
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
                  onPressed: () =>
                      _setAcceso(context, ip, facility["id"], uuid,
                          fechaAcceso, entra? "IN": "OUT", temperatura)
              ),
            ),
            Center(child: Loader(
                acceso,
                (Map acceso) {
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
                                    " Fecha: ${acceso["timestamp"].substring(0,
                                    10)}\n"
                                    " Hora: ${acceso["timestamp"].substring(11,
                                    16)}\n"
                                    " Tipo: ${acceso["type"]}\n",
                                textScaleFactor: 1.5,
                              )
                            ]
                        )
                    );
                  }
                }
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
    String ip = Provider.of<Ip>(context).ip;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: Facilities(ip),
        ),
        ChangeNotifierProvider.value(
          value: Facility(),
        ),
        ChangeNotifierProvider.value(
          value: FechaDesde(),
        ),
        ChangeNotifierProvider.value(
          value: FechaHasta(),
        ),
        ChangeNotifierProvider.value(
          value: Event(ip, 0, DateTime.now(), DateTime.now()),
        ),
        ChangeNotifierProvider.value(
          value: Usuario(),
        ),
        ChangeNotifierProvider.value(
          value: Usuarios(ip, '', ''),
        ),
        ChangeNotifierProvider.value(
          value: FechaAcceso(),
        ),
        ChangeNotifierProvider.value(
          value: Entra(),
        ),
        ChangeNotifierProvider.value(
          value: Temperatura(),
        ),
        ChangeNotifierProvider.value(
          value: Acceso(),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(primarySwatch: Colors.blue,),
        home: FacilitiesPage(),
        debugShowCheckedModeBanner: false,
      )
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