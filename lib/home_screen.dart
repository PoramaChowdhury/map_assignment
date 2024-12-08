import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController googleMapController;
  Position? position;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  Timer? locationTimer;

  @override
  void initState() {
    super.initState();
    startLocationUpdates();
  }

  @override
  void dispose() {
    locationTimer?.cancel();
    super.dispose();
  }

  void startLocationUpdates() {
    locationTimer = Timer.periodic(const Duration(seconds: 10), (Timer t) async {
      // current-location  10sec nd poluline create in 10s movement
      await fetchCurrentLocation();
    });
  }

  Future<void> fetchCurrentLocation() async {
    final isGranted = await isLocationPermissionGranted();
    if (isGranted) {
      final isServiceEnabled = await checkGPSServiceEnable();
      if (isServiceEnabled) {
        // Get the current position
        Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        );

        setState(() {
          position = pos;
          polylineCoordinates.add(LatLng(pos.latitude, pos.longitude));
          markers = {
            Marker(
              markerId: const MarkerId('current-location'),
              position: LatLng(pos.latitude, pos.longitude),
              infoWindow: InfoWindow(
                title: 'My Current Location',
                snippet: 'Latitude: ${pos.latitude}, Longitude: ${pos.longitude}',
              ),
              draggable: true,
            ),
          };
          if (polylineCoordinates.length > 1) {
            polylines.add(
              Polyline(
                polylineId: const PolylineId('tracking'),
                color: Colors.blue,
                width: 5,
                points: polylineCoordinates,
              ),
            );
          }
        });
        googleMapController.animateCamera(
          CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
        );
      } else {
        Geolocator.openLocationSettings();
      }
    } else {
      final result = await requestLocationPermission();
      if (result) {
        fetchCurrentLocation();
      } else {
        Geolocator.openAppSettings();
      }
    }
  }

  Future<bool> isLocationPermissionGranted() async {
    LocationPermission locationPermission = await Geolocator.checkPermission();
    return locationPermission == LocationPermission.always ||
        locationPermission == LocationPermission.whileInUse;
  }

  Future<bool> requestLocationPermission() async {
    LocationPermission locationPermission = await Geolocator.requestPermission();
    return locationPermission == LocationPermission.always ||
        locationPermission == LocationPermission.whileInUse;
  }

  Future<bool> checkGPSServiceEnable() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Screen'),
      ),
      body: position == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          zoom: 16,
          target: LatLng(position!.latitude, position!.longitude),
        ),
        onMapCreated: (GoogleMapController controller) {
          googleMapController = controller;
        },
        markers: markers,
        polylines: polylines,
        zoomControlsEnabled: true,
        zoomGesturesEnabled: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (position != null) {
            googleMapController.animateCamera(
              CameraUpdate.newLatLng(LatLng(position!.latitude, position!.longitude)),
            );
          }
        },
        child: const Icon(Icons.location_history),
      ),
    );
  }
}