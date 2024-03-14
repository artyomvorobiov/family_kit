import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart' as loc;
import 'package:google_api_headers/google_api_headers.dart' as header;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart' as places;
import 'package:location/location.dart' as loc;
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:location_geocoder/location_geocoder.dart';

import 'map_dottom.dart';
class MedicineGroup {
  final LatLng position;
  final List<DocumentSnapshot> medicines;
  final String address;

  MedicineGroup(this.position, this.address, this.medicines);
}

class LocationAccess extends StatefulWidget {
  const LocationAccess({super.key});

  @override
  State<LocationAccess> createState() => _LocationAccessState();
}

class _LocationAccessState extends State<LocationAccess> {
  final homeScaffoldKey = GlobalKey<ScaffoldState>();
  loc.Location location = loc.Location();
  final Map<String, Marker> _markers = {};
  final LocatitonGeocoder geocoder = LocatitonGeocoder('AIzaSyBYg4SD_fvydAJIOBwZcKIVGqj_QxdFM1U');
   QuerySnapshot? familyMedicines;
   var id;
   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double latitude = 0;
  double longitude = 0;
  GoogleMapController? _controller;
  final CameraPosition _kGooglePlex = const CameraPosition(
    target: LatLng(55.78332474744334, 37.599756904265156),
    zoom: 10,
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;
Future<void> _handleSearch() async {
    places.Prediction? p = await loc.PlacesAutocomplete.show(
        context: context,

      strictbounds: false,
        apiKey: 'AIzaSyBYg4SD_fvydAJIOBwZcKIVGqj_QxdFM1U',
        onError: onError,
        mode: loc.Mode.overlay,
        language: 'RU',
        types: [],
        decoration: InputDecoration(
            hintText: 'Поиск адресов',
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Colors.white))),
        components: []
);

if (p != null) {
  displayPrediction(p, homeScaffoldKey.currentState);
}
  }

  void onError(places.PlacesAutocompleteResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Message',
        message: response.errorMessage!,
        contentType: ContentType.failure,
      ),
    ));
  }

  Future<void> displayPrediction(
      places.Prediction p, ScaffoldState? currentState) async {
    places.GoogleMapsPlaces _places = places.GoogleMapsPlaces(
        apiKey: 'AIzaSyBYg4SD_fvydAJIOBwZcKIVGqj_QxdFM1U',
        apiHeaders: await const header.GoogleApiHeaders().getHeaders());
    places.PlacesDetailsResponse detail =
        await _places.getDetailsByPlaceId(p.placeId!);
    final lat = detail.result.geometry!.location.lat;
    final lng = detail.result.geometry!.location.lng;
    _markers.clear(); 
    final marker = Marker(
      markerId: const MarkerId('deliveryMarker'),
      position: LatLng(lat, lng),
      infoWindow: const InfoWindow(
        title: '',
      ),
    );
    setState(() {
      _markers['myLocation'] = marker;
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 15),
        ),
      );
    });
  }
  getCurrentLocation() async {
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted ==  loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted !=  loc.PermissionStatus.granted) {
        return;
      }
    }

     loc.LocationData currentPosition = await location.getLocation();
    latitude = currentPosition.latitude!;
    longitude = currentPosition.longitude!;
    await _fetchMedicineLocations();
    print('Markers: $_markers');

    if (mounted) {
    final marker = Marker(
      markerId: const MarkerId('myLocation'),
      position: LatLng(latitude, longitude),
      infoWindow: const InfoWindow(
        title: 'you can add any message here',
      ),
    );
    setState(() {
      _markers['myLocation'] = marker;
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(latitude, longitude), zoom: 15),
        ),
      );
    });
    List<MedicineGroup> medicineGroups = await _fetchMedicineLocations();

  setState(() {
    _markers.clear();

    for (var group in medicineGroups) {
  final marker = Marker(
    markerId: MarkerId(group.position.toString()),
    position: group.position,
    infoWindow: InfoWindow(
      title: 'Лекарства по адресу',
      snippet: group.address, 
    ),
    onTap: () {
      _showMedicinesDialog(group.medicines);
    },
  );

  _markers[group.position.toString()] = marker;
}

  });
    }
  }
  

  void _showMedicinesDialog(List<DocumentSnapshot> medicines) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return MedicineListBottomSheet(medicines);
    },
  );
}


  Future<String> _getFamilyId() async {
    User? user = _auth.currentUser;

    if (user != null) {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      if (userSnapshot.exists) {
        if (userSnapshot['selectedFamily'] == 1) {
            return userSnapshot['familyId'];
        }
        else if (userSnapshot['selectedFamily'] == 2) {
            return userSnapshot['familyId2'];
        }
        else {
          return userSnapshot['familyId3'];
        }
      }
    }

    return ''; 
  }


Future<List<MedicineGroup>> _fetchMedicineLocations() async {
  User? user = _auth.currentUser;

  if (user != null) {
    String familyId = await _getFamilyId();

    if (familyId.isNotEmpty) {
      familyMedicines = await _firestore
          .collection('drugs')
          .where('familyId', isEqualTo: familyId)
          .get();

      Map<String, List<DocumentSnapshot>> groupedMedicines = {};

      for (DocumentSnapshot doc in familyMedicines!.docs) {
    var medicine = doc.data() as Map<String, dynamic>;
    var address = medicine['address'];

    if (address != null && address != 'Выберите адрес') {
      groupedMedicines.putIfAbsent(address, () => []);
      groupedMedicines[address]!.add(doc);
    }
  }

      List<MedicineGroup> medicineGroups = [];

      for (var entry in groupedMedicines.entries) {
        var address = entry.key;
        var latLng = await getLocationFromAddress(address);

        if (latLng != null) {
          medicineGroups.add(MedicineGroup(latLng, address, entry.value));
        }
      }

      return medicineGroups;
    }
  }

  return [];
}




Future<LatLng?> getLocationFromAddress(String address) async {
  try {
    var addresses = await geocoder.findAddressesFromQuery(address);
    // List<Location> locations = await locationFromAddress(addresses[0].);
    
    if (addresses.isNotEmpty) {
      double? lat = addresses.first.coordinates.latitude!;
      double? lng = addresses.first.coordinates.longitude!;
      
      return LatLng(lat, lng);
    }
  } catch (e) {
    print('Error converting address to LatLng: $e');
  }

  return null; // Return null if conversion fails
}

Future<void> onMapCreated(GoogleMapController controller) async {
    _controller = controller;
    String value = await DefaultAssetBundle.of(context)
        .loadString('assets/map_style.json');
    _controller?.setMapStyle(value);
  }


  @override
  void initState() {
    getCurrentLocation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children :[SizedBox(
          // margin: const EdgeInsets.symmetric(horizontal: 10),
          width: double.infinity,
          height: double.infinity,
          child: GoogleMap(
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: _kGooglePlex,
            markers: _markers.values.toSet(),
            onTap: (LatLng latlng) {
              latitude = latlng.latitude;
              longitude = latlng.longitude;
              final marker = Marker(
                markerId: const MarkerId('myLocation'),
                position: LatLng(latitude, longitude),
                infoWindow: const InfoWindow(
                  // title: 'AppLocalizations.of(context).will_deliver_here',
                ),
              );
              setState(() {
                _markers['myLocation'] = marker;
              });
            },
            onMapCreated:onMapCreated,
          ),
        ),
         Positioned(
              left: 10,// you can change place of search bar any where on the map
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
    primary: Color.fromARGB(255, 10, 114, 1), // Set button color
  ),
                  onPressed: _handleSearch,
                  child: const Icon(Icons.search)),
            )
        ]
      ),
    );
  
  }
}
  