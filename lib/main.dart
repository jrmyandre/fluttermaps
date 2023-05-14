import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'directions_model.dart';
import 'directions_reposiroty.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});


  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen()
    );
  }
}

class MapScreen extends StatefulWidget{
  const MapScreen({super.key});
  
  


  @override
  // ignore: library_private_types_in_public_api
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(-6.200000, 106.816666),
    zoom: 11.5,
  );
  final dbRef = FirebaseDatabase.instance.ref().child("locations");
  List<Map<dynamic,dynamic>> dataList = [];

  late GoogleMapController _googleMapController;
  final Set<Marker> _markers = {};
  Directions? _info;
  List<Polyline> _polylines = [];
  int totalDistance = 0;
  List<int> totalDuration = [0, 0];

  @override
  void initState(){
    super.initState();

    dbRef.onValue.listen((event) {
      Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, values) {
        dataList.add(values);
      });
      _updateMarker();
    });
  }

  void _updateMarker ()async{
    _markers.clear();

    for(var i=0;i<dataList.length; i++){
      double lat = double.parse(dataList[i]['latitude']);
      double lng = double.parse(dataList[i]['longitude']);

      Marker marker = Marker(
        markerId: MarkerId(i.toString()),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: 'Marker $i'),
        icon: BitmapDescriptor.defaultMarker,
      );
     
      _markers.add(marker);

    }

    for(var i=0; i<_markers.length; i++){
      final directions = await DirectionsRepository().getDirections(origin: _markers.elementAt(i).position, destination: _markers.elementAt(i+1).position);
      if (directions != null){
          setState(() {
            _info = directions;
            _polylines.add(Polyline(polylineId: PolylineId("Polyline $i"),
              color: Colors.blue,
              width: 5,
              points: _info!.polylinePoints
                .map((e) => LatLng(e.latitude, e.longitude)).toList(),
              
              ));
            totalDistance += _info!.distance;
            
            totalDuration[1] += (_info!.duration/60).toInt();
            totalDuration[0] += totalDuration[1]~/60;
            totalDuration[1] = totalDuration[1]%60;
          });
        }
    }
  }
  

  @override
  void dispose(){
    _googleMapController.dispose();
    super.dispose();
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(
            myLocationEnabled: false,
            initialCameraPosition: _initialCameraPosition,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            onMapCreated: (controller) => _googleMapController = controller,
            markers: _markers,
            polylines: Set<Polyline>.of(_polylines),
            // {
            //   if(_info != null)
            //   Polyline(polylineId: const PolylineId("Polyline"),
            //   color: Colors.blue,
            //   width: 5,
            //   points: _info!.polylinePoints
            //     .map((e) => LatLng(e.latitude, e.longitude)).toList(),
              
            //   )
            // },
            // onLongPress: _addMarker,
            ),
            if (_info != null)
            Positioned(
              top: 20.0,
              child: Column(
                children:[ 
                  Container(
                padding: const EdgeInsets.symmetric(vertical: 6.0,
                horizontal: 12.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, -2),
                      blurRadius: 6.0,
                      spreadRadius: 6.0,
                    )
                  ]
                ),
                  width: MediaQuery.of(context).size.width,
                child: Text(
                  'Total: ${totalDistance/1000} km, ${totalDuration[0]} hours ${totalDuration[1]} minutes',
                  style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                          ),
                          const SizedBox(height: 10.0),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 6.0,
                horizontal: 12.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, -2),
                      blurRadius: 6.0,
                      spreadRadius: 6.0,
                    )
                  ]
                ),
                  width: MediaQuery.of(context).size.width,
                child: Text(
                  'Last Step: ${_info!.distance/1000} km, ${_info!.duration/60.toInt()~/60} hours ${_info!.duration~/60.toInt()} minutes',
                  style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                          

                          )
                          ]
              ),
            )
        ]
      ),


        floatingActionButton: Padding(
          padding: const EdgeInsets.only(right: 50.0, bottom: 10),
          child: FloatingActionButton(
            
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            child: const Icon(Icons.location_on),
            onPressed: () => _googleMapController.animateCamera(
              _info != null
              ? CameraUpdate.newLatLngBounds(_info!.bounds, 100.0)
              : CameraUpdate.newCameraPosition(_initialCameraPosition),
              ),
            ),
        ),
        );
  }

  // void _addMarker(LatLng pos)async{
  //   if ((_markers.length >= 6 || _markers.isEmpty)){
  //     setState(() {
  //       _markers.clear();
  //       _polylines.clear();
  //       totalDistance = 0;
  //       totalDuration = [0, 0];
  //       _markers.add(Marker(markerId: MarkerId(pos.toString()),
  //       position: pos,
  //       infoWindow: InfoWindow(title: pos.toString()),
  //       icon: BitmapDescriptor.defaultMarker));
  //       _info = null;
  //     });
  //   }
  //   else {
  //     setState(() {
  //       _markers.add(Marker(markerId: MarkerId(pos.toString()),
  //       position: pos,
  //       infoWindow: InfoWindow(title: pos.toString()),
  //       icon: BitmapDescriptor.defaultMarker));
       
  //     });

  //     //final directions = await DirectionsRepository().getDirections(origin: _markers.first.position, destination: pos);
  //     for (var i = 0; i< _markers.length; i++){
  //       final directions = await DirectionsRepository().getDirections(origin: _markers.elementAt(i).position, destination: _markers.elementAt(i+1).position);
  //       if (directions != null){
  //         setState(() {
  //           _info = directions;
  //           _polylines.add(Polyline(polylineId: PolylineId("Polyline $i"),
  //             color: Colors.blue,
  //             width: 5,
  //             points: _info!.polylinePoints
  //               .map((e) => LatLng(e.latitude, e.longitude)).toList(),
              
  //             ));
  //           totalDistance += _info!.distance;
            
  //           totalDuration[1] += (_info!.duration/60).toInt();
  //           totalDuration[0] += totalDuration[1]~/60;
  //           totalDuration[1] = totalDuration[1]%60;
  //         });
  //       }
  //     }
  //     // setState(() {
  //     //   _info = directions;
  //     // });

  //   }
  // }
}
