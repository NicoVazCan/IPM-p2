import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

  static int getAforo(List access_log){
    int aforo = 0;
    List<String> vistos = [];

    for(Map access in access_log) {
      Map user = access['user'];

      if(!vistos.any((visto) => visto == user['uuid'])) {
        aforo++;
        vistos.add(user['uuid']);
      }
    }

    return aforo;
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
  DateTime _fecha;

  Fecha(this._fecha);

  DateTime get fecha => _fecha;

  void setFecha(BuildContext context) async {
    DateTime? nuevaFecha = await showDatePicker(
        context: context,
        initialDate: _fecha,
        firstDate: DateTime(2021),
        lastDate: DateTime(2076)
    );
    if(nuevaFecha != null) {
      _fecha = DateTime(nuevaFecha.year, nuevaFecha.month,
          nuevaFecha.day, _fecha.hour, _fecha.minute);
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

class FechaDesde extends Fecha {
  FechaDesde(DateTime fecha): super(fecha);
}
class FechaHasta extends Fecha {
  FechaHasta(DateTime fecha): super(fecha);
}
class FechaAcceso extends Fecha {
  FechaAcceso(DateTime fecha): super(fecha);
}

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
  Map? _facility = {'id': 0};

  Map? get facility => _facility;

  set facility(Map? value) {
    _facility = value;
  }


}

class Event extends ChangeNotifier {
  Map? _event;

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
      return Expanded(child: Flex(
        mainAxisAlignment: MainAxisAlignment.center,
        direction: Axis.vertical,
        children: [CircularProgressIndicator()],
      ));
    }
    if(response!['status'] == 200) {
      return builder(response!['data']);
    }
    return Center(child: Alert("Error al conectar con la base de datos.\n"
        "Código de estado: ${response!['status']}"));
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
        title: Text(AppLocalizations.of(context)!.centros),
      ),
      persistentFooterButtons: <Widget>[
        IconButton(
            icon: const Icon(Icons.sync),
            iconSize: 20,
            tooltip: AppLocalizations.of(context)!.recargar,
            onPressed: () {
              _askFacilities(context, ip);
            }
        ),
        IconButton(
            icon: const Icon(Icons.settings),
            iconSize: 20,
            tooltip: AppLocalizations.of(context)!.configuracion,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: Border.all(
                    color: Colors.black,
                    width: 1.0,
                  ),
                ),
                child: Text(AppLocalizations.of(context)!.seleccionCentros)
            ),
            Loader(
                facilities,
                (List facilities) => Expanded(child: ListView.builder(
                  itemCount: facilities.length,
                  itemBuilder: (context, index) {
                    Map facility = facilities[index];

                    return ListTile(
                      title: Text(
                        facility["name"],
                        textAlign: TextAlign.center,
                      ),
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
          title: Text(AppLocalizations.of(context)!.configuracion),
        ),
        body: TextFormField(
          decoration: InputDecoration(
              hintText: ip,
              labelText: AppLocalizations.of(context)!.iP),
          keyboardType: TextInputType.number,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {

            if(value == null){
              return AppLocalizations.of(context)!.fI;
            }
            value = value as String;
            var values = value.split('.');
            if(values.length < 4){
              return AppLocalizations.of(context)!.fI;
            }
            for(String i in values) {
              if(i.isEmpty || i.toUpperCase() != i.toLowerCase()){
                return AppLocalizations.of(context)!.fI;
              }
            }
            print(value);
          },
          onFieldSubmitted: (value) {
            value = value.trim();
            if (value.isNotEmpty) {
              _setIp(context, value);
            }
          },
        )
    );
  }
}

class OpcionesPage extends StatelessWidget {

  void _askEvent(BuildContext context, String ip,
      int facility_id, DateTime desde, DateTime hasta) =>
      Provider.of<Event>(context, listen: false)
          .askEvent(ip, facility_id, desde, hasta);

  const OpcionesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String ip = Provider
        .of<Ip>(context)
        .ip;
    Map facility = Provider
        .of<Facility>(context)
        .facility!;
    DateTime fechaDesde = Provider
        .of<FechaDesde>(context)
        .fecha;
    DateTime fechaHasta = Provider
        .of<FechaHasta>(context)
        .fecha;

    return OrientationBuilder(
        builder: (context, orientation) =>
        Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.seleccionOpcion),
            ),
            body: Center(
                child: Flex(
                    direction: orientation == Orientation.portrait ?
                    Axis.vertical : Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 160,
                          height: 80,
                          child: ElevatedButton(
                            // Within the SecondRoute widget
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => IdentificarPage()),
                              );
                            },
                            child: Text(
                                AppLocalizations.of(context)!.registrar),
                          )),
                      const SizedBox(width: 50, height: 50),
                      SizedBox(
                          width: 160,
                          height: 80,
                          child: ElevatedButton(
                            // Within the SecondRoute widget
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) {
                                      _askEvent(context, ip, facility['id'],
                                          fechaDesde, fechaHasta);
                                      return EventPage();
                                    }
                                ),
                              );
                            },
                            child: Text(AppLocalizations.of(context)!.eventos),
                          ))
                    ]
                )
            ),
          )
    );
  }
}

class IdentificarPage extends StatelessWidget {
  IdentificarPage({Key? key}) : super(key: key);

  void _setUsuario(BuildContext context, String uuid) =>
      Provider
          .of<Usuario>(context, listen: false)
          .usuario = uuid;

  @override
  Widget build(BuildContext context) =>
      OrientationBuilder(
          builder: (context, orientation) =>
            Scaffold(
                appBar: AppBar(title: Text(
                    AppLocalizations.of(context)!.identificarUsuario)),
                body: Builder(builder: (BuildContext context) =>
                    Container(
                      alignment: Alignment.center,
                      child: Flex(
                          direction: orientation == Orientation.portrait ?
                          Axis.vertical : Axis.horizontal,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                                width: 160,
                                height: 80,
                                child: ElevatedButton(
                                    onPressed: () =>
                                        FlutterBarcodeScanner.scanBarcode(
                                            '#ff6666',
                                            AppLocalizations.of(context)!
                                                .cancelar,
                                            true, ScanMode.QR).then(
                                                (value) {
                                              if (value != '-1') {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) {
                                                        _setUsuario(
                                                            context, value);
                                                        return RegistrarPage();
                                                      }
                                                  ),
                                                );
                                              }
                                            }
                                        ),
                                    child: Text(AppLocalizations.of(context)!
                                        .qR)
                                )),
                            const SizedBox(width: 50, height: 50),
                            SizedBox(
                                width: 160,
                                height: 80,
                                child: ElevatedButton(
                                    onPressed: () =>
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    UsuariosPage())
                                        ),
                                    child: Text(AppLocalizations.of(context)!
                                        .manual)
                                )),
                          ]
                      )
                  )
                )
            )
          );
}

class UsuariosPage extends StatelessWidget {

  UsuariosPage({Key? key}): super(key: key);

  void _askUsuarios(BuildContext context, String ip,
      String name, String surname) =>
      Provider.of<Usuarios>(context, listen: false)
          .askUsuarios(ip, name, surname);

  void _setUsuario(BuildContext context, Map usuario) =>
      Provider.of<Usuario>(context, listen: false).usuario =
        "${usuario["name"]},${usuario["surname"]},${usuario["uuid"]}";

  @override
  Widget build(BuildContext context) {
    String ip = Provider.of<Ip>(context).ip;
    Map? usuarios = Provider.of<Usuarios>(context).usuarios;
    
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.usuarios),
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
                    return Text(AppLocalizations.of(context)!.sinCoinci);
                  }

                  return Expanded(child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      Map user = users[index];

                      return ListTile(
                        title: Text(
                          "${user["name"]} ${user["surname"]}\n"
                            "nº: ${user["phone"]}",
                          textAlign: TextAlign.center,
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  _setUsuario(context, user);
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

  int _getAforo(List access_log) => Modelo.getAforo(access_log);

  @override
  Widget build(BuildContext context) {
    String ip = Provider.of<Ip>(context).ip;
    Map facility = Provider.of<Facility>(context).facility!;
    DateTime fechaDesde = Provider.of<FechaDesde>(context).fecha;
    DateTime fechaHasta = Provider.of<FechaHasta>(context).fecha;
    Map? event = Provider.of<Event>(context).event;

    return OrientationBuilder(
        builder: (context, orientation) {
          return Scaffold(
              appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.eventos),
              ),
              body: Column(
                    children: <Widget>[
                      Container(
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: Border.all(
                              color: Colors.black,
                              width: 1.0,
                            ),
                          ),
                          child: Flex(
                            direction: orientation == Orientation.portrait?
                              Axis.vertical: Axis.horizontal,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(AppLocalizations.of(context)!.inicio),
                                    Container(
                                        decoration: ShapeDecoration(
                                          color: Colors.white,
                                          shape: Border.all(
                                            color: Colors.black,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Text(fechaToString(fechaDesde))
                                    ),
                                    IconButton(
                                        icon: const Icon(
                                            Icons.calendar_today),
                                        iconSize: 20,
                                        tooltip: AppLocalizations.of(context)!.fechaDesde,
                                        onPressed: () =>
                                            _setFechaDesde(context)
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
                                            horaToString(fechaDesde))
                                    ),
                                    IconButton(
                                        icon: const Icon(Icons.access_time),
                                        iconSize: 20,
                                        tooltip: AppLocalizations.of(context)!.horaDesde,
                                        onPressed: () =>
                                            _setHoraDesde(context)
                                    )
                                  ]
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(AppLocalizations.of(context)!.final0),
                                  Container(
                                      decoration: ShapeDecoration(
                                        color: Colors.white,
                                        shape: Border.all(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Text(fechaToString(fechaHasta))
                                  ),
                                  IconButton(
                                      icon: const Icon(Icons.calendar_today),
                                      iconSize: 20,
                                      tooltip: AppLocalizations.of(context)!.fechaHasta,
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
                                      child: Text(horaToString(fechaHasta))
                                  ),
                                  IconButton(
                                      icon: const Icon(Icons.access_time),
                                      iconSize: 20,
                                      tooltip: AppLocalizations.of(context)!.horaHasta,
                                      onPressed: () => _setHoraHasta(context)
                                  )
                                ],
                              ),
                              IconButton(
                                  alignment: Alignment.center,
                                  icon: const Icon(Icons.search),
                                  iconSize: 20,
                                  tooltip: AppLocalizations.of(context)!.buscar,
                                  onPressed: () =>
                                      _askEvent(
                                          context,
                                          ip,
                                          facility['id'],
                                          fechaDesde,
                                          fechaHasta
                                      )
                              ),
                            ],
                          ),
                      ),
                      Loader(
                          event,
                              (List accesos) {
                            DateTime now = DateTime.now();

                            if (fechaDesde.isAfter(now) ||
                                fechaHasta.isAfter(now)) {
                              return Text(
                                  AppLocalizations.of(context)!.fechasPrevias
                              );
                            } else if (fechaDesde.isAfter(fechaHasta)) {
                              return Text(
                                  AppLocalizations.of(context)!.inicioAnterio
                              );
                            } else if (accesos.isEmpty) {
                              return Text(AppLocalizations.of(context)!.sinResultados
                              );
                            } else {
                              return Expanded(child: Column(
                                  children: <Widget>[
                                    Text(AppLocalizations.of(context)!.aforo1 +
                                        _getAforo(accesos).toString() +
                                        (_getAforo(accesos) > 1?
                                          AppLocalizations.of(context)!.aforo22:
                                          AppLocalizations.of(context)!.aforo21
                                        )
                                    ),
                                    Expanded(child: SingleChildScrollView(
                                        child: DataTable(
                                          columns: <DataColumn>[
                                            DataColumn(
                                              label: Text(
                                                AppLocalizations.of(context)!.tipo,
                                                style: const TextStyle(
                                                    fontStyle: FontStyle
                                                        .italic),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                AppLocalizations.of(context)!.usuario,
                                                style: const TextStyle(
                                                    fontStyle: FontStyle
                                                        .italic),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                AppLocalizations.of(context)!.fecha,
                                                style: const TextStyle(
                                                    fontStyle: FontStyle
                                                        .italic),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                AppLocalizations.of(context)!.hora,
                                                style: const TextStyle(
                                                    fontStyle: FontStyle
                                                        .italic),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                AppLocalizations.of(context)!.numero,
                                                style: const TextStyle(fontStyle: FontStyle.italic),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                AppLocalizations.of(context)!.temperatura,
                                                style: const TextStyle(fontStyle: FontStyle.italic),
                                              ),
                                            ),
                                            DataColumn(
                                              label: Text(
                                                AppLocalizations.of(context)!.vacunado,
                                                style: const TextStyle(fontStyle: FontStyle.italic),
                                              ),
                                            ),
                                          ],
                                          rows: List<DataRow>.generate(
                                              accesos.length,
                                                  (idx) {
                                                Map acceso = accesos[idx] as Map;
                                                Map user = acceso['user'] as Map;

                                                return DataRow(
                                                    cells: [
                                                      DataCell(
                                                          Text(acceso['type']
                                                          )
                                                      ),
                                                      DataCell(
                                                          Text(
                                                              '${user['name']} '
                                                                  '${user['surname']}'
                                                          )
                                                      ),
                                                      DataCell(
                                                          Text(
                                                              acceso['timestamp']
                                                                  .toString()
                                                                  .substring(
                                                                  0, 10)
                                                          )
                                                      ),
                                                      DataCell(
                                                          Text(
                                                              acceso['timestamp']
                                                                  .toString()
                                                                  .substring(
                                                                  11, 16)
                                                          )
                                                      ),
                                                      DataCell(
                                                          Text('${user['phone']}')
                                                      ),
                                                      DataCell(
                                                          Text('${acceso['temperature']}')
                                                      ),
                                                      DataCell(
                                                          Text(
                                                              user['is_vaccinated']?
                                                              AppLocalizations.of(context)!.si:
                                                              AppLocalizations.of(context)!.no
                                                          )
                                                      ),
                                                    ]
                                                );
                                              }
                                          ),
                                        )
                                    ))
                                  ]
                              ));
                            }
                          }
                      ),
                    ]
                ),
              );
        }
        );
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
    String usuario = Provider.of<Usuario>(context).usuario!;
    List<String> list = usuario.split(",");

    if(list.length != 3) {
      return Alert(AppLocalizations.of(context)!.qRMal);
    }
    String name = list[0], surname = list[1], uuid = list[2];
    List<Widget> widgets = <Widget>[
      Column(
          children: <Widget>[
            SizedBox(
              width: 280,
              child: Text(
                  AppLocalizations.of(context)!.accesoFacility1 +
                  name + AppLocalizations.of(context)!.accesoFacility2 +
                  surname + AppLocalizations.of(context)!.accesoFacility3 +
                  facility['name']
              ),
            ),
            SizedBox(
              width: 280,
              child: TextFormField(
                decoration: InputDecoration(
                    hintText: "30.0",
                    labelText: AppLocalizations.of(context)!.introTemperatura),
                keyboardType: TextInputType.number,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return AppLocalizations.of(context)!.fI;
                  }
                },
                onFieldSubmitted: (value) {
                  value = value.trim();
                  if (!value.isEmpty) {
                    _setTemperatura(context, double.parse(value));
                  }
                },
            )),
            SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.fechaAcceso),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: Border.all(
                          color: Colors.black,
                          width: 1.0,
                        ),
                      ),
                      child: Text(fechaToString(fechaAcceso))
                  ),
                  IconButton(
                      icon: const Icon(Icons.calendar_today),
                      iconSize: 20,
                      tooltip: AppLocalizations.of(context)!.fechaAccesoConsejo,
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
                    child: Text(horaToString(fechaAcceso)),
                  ),
                  IconButton(
                      icon: const Icon(Icons.access_time),
                      iconSize: 20,
                      tooltip: AppLocalizations.of(context)!.horaAccesoConsejo,
                      onPressed: () => _setHoraAcceso(context)
                  )
                ]
            ),
            Text(AppLocalizations.of(context)!.entrada,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
              Switch(
                  value: entra,
                  onChanged: (bool value) => _setEntra(context, value)
              ),
              Text(
                  entra? AppLocalizations.of(context)!.entro:
                    AppLocalizations.of(context)!.salio
              )
            ],
            ),
          ]
      ),
      Center(child: IconButton(
          alignment: Alignment.topRight,
          icon: const Icon(Icons.check_circle_outline),
          iconSize: 50,
          tooltip: AppLocalizations.of(context)!.registrar,
          onPressed: () =>
              _setAcceso(context, ip, facility["id"], uuid,
                  fechaAcceso, entra? "IN": "OUT", temperatura)
        )
      ),
      Center(
        child: Loader(
          acceso,
            (Map acceso) => Container(
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: Border.all(
                  color: Colors.black,
                  width: 1.0,
                ),
              ),
              child: acceso.isEmpty?
                Text(AppLocalizations.of(context)!.nadaRegistrado):
                Text(
                  AppLocalizations.of(context)!.registroOK1 +
                  acceso["timestamp"].substring(0,10) + "\n" +
                  AppLocalizations.of(context)!.registroOK2 +
                  acceso["timestamp"].substring(11,16)+ "\n" +
                  AppLocalizations.of(context)!.registroOK3 +
                  acceso["type"] + "\n"
                )
            )
        )
      )
    ];

    return OrientationBuilder(
      builder: (context, orientation) =>
        Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.registrarAcceso),
          ),
          body: Flex(
              direction: orientation == Orientation.portrait?
              Axis.vertical: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widgets
          )
      )
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    String ip = Provider.of<Ip>(context).ip;

    DateTime fechaHasta = DateTime.now();
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

    DateTime fechaDesde = DateTime(year, month, day,
        fechaHasta.hour, fechaHasta.minute);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: Facilities(ip),
        ),
        ChangeNotifierProvider.value(
          value: Facility(),
        ),
        ChangeNotifierProvider.value(
          value: FechaDesde(fechaDesde),
        ),
        ChangeNotifierProvider.value(
          value: FechaHasta(fechaHasta),
        ),
        ChangeNotifierProvider.value(
          value: Event(ip, 0, fechaDesde, fechaHasta),
        ),
        ChangeNotifierProvider.value(
          value: Usuario(),
        ),
        ChangeNotifierProvider.value(
          value: Usuarios(ip, '', ''),
        ),
        ChangeNotifierProvider.value(
          value: FechaAcceso(DateTime.now()),
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
        localizationsDelegates: const[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          /*GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,*/
        ],
        //supportedLocales: AppLocalizations.supportedLocales,
        supportedLocales: const[
          Locale('es', ''),
          Locale('en', ''),
        ],
        theme: ThemeData(primarySwatch: Colors.blue),
        title: "Registro de acceso",
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