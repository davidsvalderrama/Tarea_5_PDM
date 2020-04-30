
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeMap extends StatefulWidget {
  HomeMap({Key key}) : super(key: key);

  @override
  _HomeMapState createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {
  Set<Polygon> _mapPolygons = Set();
  

  TextEditingController _controller = TextEditingController();

  _dialog() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: TextField(
            controller: _controller,
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                  child: Text(
                    "Buscar Ubicación",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                new FlatButton(
                  child: new Text("BUSCAR"),
                  onPressed: () async {
                    List<Placemark> placemark = await Geolocator()
                        .placemarkFromAddress(_controller.text);
                    _mapController.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: LatLng(
                            placemark.first.position.latitude,
                            placemark.first.position.longitude,
                          ),
                          zoom: 15.0,
                        ),
                      ),
                    );
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                ),
                new FlatButton(
                  child: new Text("CANCELAR"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  _addPolygons() {
    setState(() {
      if (_mapPolygons.isNotEmpty) {
        _mapPolygons = Set();
      } else {
        List<LatLng> points = new List();
        _mapMarkers.forEach((mark) {
            points.add(mark.position);
        });
        if (points.isNotEmpty) {
          _mapPolygons.add(Polygon(
              polygonId: PolygonId('polygon'),
              points: points,
              strokeColor: Colors.blueAccent));
        }
      }
    });
  }
  Set<Marker> _mapMarkers = Set();
  GoogleMapController _mapController;
  Position _currentPosition;
  Position _defaultPosition = Position(
    longitude: 20.608148,
    latitude: -103.417576,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getCurrentPosition(),
      builder: (context, result) {
        if (result.error == null) {
          if (_currentPosition == null) _currentPosition = _defaultPosition;
          return Scaffold(
            appBar: AppBar(
              title: Text("Tarea 5"),
              centerTitle: true,
            ),
            drawer: _drawer(context),
            body: Stack(
              children: <Widget>[
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  markers: _mapMarkers,
                  polygons: _mapPolygons,
                  onLongPress: _setMarker,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition.latitude,
                      _currentPosition.longitude,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          Scaffold(
            body: Center(child: Text("Error!")),
          );
        }
        return Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  void _onMapCreated(controller) {
    setState(() {
      _mapController = controller;
    });
  }

  void _setMarker(LatLng coord) async {
    // get address
    String _markerAddress = await _getGeolocationAddress(
      Position(latitude: coord.latitude, longitude: coord.longitude),
    );

    // add marker
    setState(() {
      _mapMarkers.add(
        Marker(
          markerId: MarkerId(coord.toString()),
          position: coord,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          onTap: (){
          showModalBottomSheet(context: context, builder: (BuildContext bc){
            return Container(
              child: ListView(
                children: <Widget>[
                  ListTile(
                    title: Text("Dirección: "),
                    subtitle: Text(_markerAddress),
                  ),
                  ListTile(
                    title: Text("Latitud y longitud: "),
                    subtitle: Text(coord.toString()),
                  ),
                ],
              ),
            );
          });
        },
        ),
      );
    });
  }

  Future<void> _getCurrentPosition() async {
    // get current position
    _currentPosition = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    // get address
    String _currentAddress = await _getGeolocationAddress(_currentPosition);

    // add marker
    _mapMarkers.add(
      Marker(
        markerId: MarkerId(_currentPosition.toString()),
        position: LatLng(
          _currentPosition.latitude,
          _currentPosition.longitude,
        ),
        onTap: (){
          showModalBottomSheet(context: context, builder: (BuildContext bc){
            return Container(
              child: ListView(
                children: <Widget>[
                  ListTile(
                    title: Text("Dirección: "),
                    subtitle: Text(_currentAddress),
                  ),
                  ListTile(
                    title: Text("Latitud y longitud: "),
                    subtitle: Text(_currentPosition.toString()),
                  ),
                ],
              ),
            );
          });
        },
      ),
    );

    // move camera
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentPosition.latitude,
            _currentPosition.longitude,
          ),
          zoom: 15.0,
        ),
      ),
    );
  }

  Future<String> _getGeolocationAddress(Position position) async {
    var places = await Geolocator().placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (places != null && places.isNotEmpty) {
      final Placemark place = places.first;
      return "${place.thoroughfare}, ${place.locality}";
    }
    return "No address availabe";
  }

  Widget _drawer(context) {
    return Drawer(
      child: Container(
        child: new ListView(
          children: <Widget>[
            Divider(),
            ListTile(
              onTap: () {
                _getCurrentPosition();
                Navigator.of(context).pop();
              },
              title: new Text(
                "Ubicación actual",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              trailing: new Icon(Icons.location_searching),
            ),
            Divider(),
            ListTile(
              onTap: () {
                _dialog();
              },
              title: new Text(
                "Busca la dirección",
                style: TextStyle(
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Divider(),
            ListTile(
              onTap: () {
                _addPolygons();
                Navigator.of(context).pop();
              },
              title: new Text(
                "Dibujar polígono",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
