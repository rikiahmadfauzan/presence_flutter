import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:presence/app/routes/app_pages.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class PageIndexController extends GetxController {
  RxInt pageIndex = 0.obs;

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  void changePage(int i) async {
    switch (i) {
      case 1:
        Map<String, dynamic> dataResponse = await determinePosition();
        if (dataResponse["error"] != true) {
          Position position = dataResponse["position"];

          List<Placemark> placemarks = await placemarkFromCoordinates(
              position.latitude, position.longitude);
          String address =
              "${placemarks[0].street}, ${placemarks[0].subLocality}, ${placemarks[0].locality}, ${placemarks[0].subAdministrativeArea}, ${placemarks[0].administrativeArea} ${placemarks[0].postalCode}";
          await updatePosition(position, address);
          // position
          double distance = Geolocator.distanceBetween(
              -6.9166886, 107.6084801, position.latitude, position.longitude);
          //presensi
          await presensi(position, address, distance);
        } else {
          Get.snackbar("Terjadi Kesalahan", dataResponse["message"]);
        }
        break;
      case 2:
        pageIndex.value = i;
        Get.offAllNamed(Routes.PROFILE);
        break;
      default:
        pageIndex.value = i;
        Get.offAllNamed(Routes.HOME);
    }
  }

  Future<void> presensi(
      Position position, String address, double distance) async {
    String uid = await auth.currentUser!.uid;

    CollectionReference<Map<String, dynamic>> colPresence =
        await firestore.collection("pegawai").doc(uid).collection("presence");

    QuerySnapshot<Map<String, dynamic>> snapPresence = await colPresence.get();

    // print(snapPresence.docs.length);

    DateTime now = DateTime.now();
    String todayDocID = DateFormat.yMd().format(now).replaceAll("/", "-");

    String status = "Di Luar Area";

    if (distance <= 500) {
      status = "Di Dalam Area";
    }
    if (snapPresence.docs.length == 0) {
      // belum absen
      await Get.defaultDialog(
          title: "ABSEN",
          middleText: "Apakah anda akan melakukan absen sekarang?",
          actions: [
            OutlinedButton(
              onPressed: () => Get.back(),
              child: Text("CANCEL"),
            ),
            ElevatedButton(
              onPressed: () async {
                await colPresence.doc(todayDocID).set({
                  "date": now.toIso8601String(),
                  "masuk": {
                    "date": now.toIso8601String(),
                    "lat": position.latitude,
                    "long": position.longitude,
                    "address": address,
                    "status": status,
                    "distance": distance,
                  },
                });
                Get.back();
                Get.snackbar(
                    "Berhasil", "Telah berhasil melakukan absen Masuk.");
              },
              child: Text("YES"),
            ),
          ]);
    } else {
      DocumentSnapshot<Map<String, dynamic>> todayDoc =
          await colPresence.doc(todayDocID).get();
      if (todayDoc.exists == true) {
        Map<String, dynamic>? dataPresenceToday = todayDoc.data();
        if (dataPresenceToday?["keluar"] != null) {
          // sudah absen
          Get.snackbar("Information",
              "Kamu sudah melakukan absen hari ini silakan lakukan absen kembali besok.");
        } else {
          // absen keluar
          await Get.defaultDialog(
              title: "ABSEN",
              middleText: "Apakah anda akan melakukan absen Keluar sekarang?",
              actions: [
                OutlinedButton(
                  onPressed: () => Get.back(),
                  child: Text("CANCEL"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await colPresence.doc(todayDocID).update({
                      "keluar": {
                        "date": now.toIso8601String(),
                        "lat": position.latitude,
                        "long": position.longitude,
                        "address": address,
                        "status": status,
                        "distance": distance,
                      },
                    });
                    Get.back();
                    Get.snackbar(
                        "Berhasil", "Telah berhasil melakukan absen Keluar.");
                  },
                  child: Text("YES"),
                ),
              ]);
        }
      } else {
        // absen masuk
        await Get.defaultDialog(
            title: "ABSEN",
            middleText: "Apakah anda akan melakukan absen Masuk sekarang?",
            actions: [
              OutlinedButton(
                onPressed: () => Get.back(),
                child: Text("CANCEL"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await colPresence.doc(todayDocID).set({
                    "date": now.toIso8601String(),
                    "masuk": {
                      "date": now.toIso8601String(),
                      "lat": position.latitude,
                      "long": position.longitude,
                      "address": address,
                      "status": status,
                      "distance": distance,
                    },
                  });
                  Get.back();
                  Get.snackbar(
                      "Berhasil", "Telah berhasil melakukan absen Masuk.");
                },
                child: Text("YES"),
              ),
            ]);
      }
    }
  }

  Future<void> updatePosition(Position position, String address) async {
    String uid = await auth.currentUser!.uid;

    await firestore.collection("pegawai").doc(uid).update(
      {
        "position": {
          "lat": position.latitude,
          "long": position.longitude,
        },
        "address": address,
      },
    );
  }

  Future<Map<String, dynamic>> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      // return Future.error('Location services are disabled.');
      return {
        "message":
            "Tidak dapat mengambil location dari device silahkan aktifkan GPS terlebih dahulu.",
        "error": true,
      };
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        // return Future.error('Location permissions are denied');
        return {
          "message": "Izin menggunakan GPS ditolak.",
          "error": true,
        };
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return {
        "message": "Device tidak memperbolehkan untuk mengakses GPS.",
        "error": true,
      };
      // return Future.error(
      //     'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Position position = await Geolocator.getCurrentPosition();
    return {
      "position": position,
      "message": "Berhasil mendapatakan location device.",
      "error": false,
    };
  }
}
