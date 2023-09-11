import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart' as s;

class UpdateProfileController extends GetxController {
  RxBool isLoading = false.obs;
  // RxBool isLoadingAddPegawai = false.obs;
  TextEditingController nipC = TextEditingController();
  TextEditingController nameC = TextEditingController();
  TextEditingController emailC = TextEditingController();

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  s.FirebaseStorage storage = s.FirebaseStorage.instance;

  final ImagePicker picker = ImagePicker();

  XFile? image;

  void pickImage() async {
    image = await picker.pickImage(source: ImageSource.gallery);
    update();
  }

  Future<void> updateProfile(String uid) async {
    if (nipC.text.isNotEmpty &&
        nameC.text.isNotEmpty &&
        emailC.text.isNotEmpty) {
      isLoading.value = true;
      try {
        Map<String, dynamic> data = {
          "name": nameC.text,
        };
        if (image != null) {
          File file = File(image!.path);
          String ext = image!.name.split(".").last;

          await storage.ref('$uid/profile.$ext').putFile(file);
          String urlImage =
              await storage.ref('$uid/profile.$ext').getDownloadURL();

          data.addAll({"profile": urlImage});
        }
        await firestore.collection("pegawai").doc(uid).update(data);
        Get.snackbar("Berhasil", "Berhasil update profile.");
      } catch (e) {
        Get.snackbar("Terjadi kesalahan", "Tidak dapat update profile.");
      } finally {
        isLoading.value = false;
      }
    }
  }

  // void deleteProfile(String uid) async {
  //   try {
  //     await firestore.collection("pegawai").doc(uid).update({
  //       "profile": FieldValue.delete(),
  //     });
  //     Get.back();
  //     Get.snackbar("Berhasil", "Berhasil delete profile.");
  //   } catch (e) {
  //     Get.snackbar("Terjadi kesalahan", "Tidak dapat delete profile.");
  //   } finally {
  //     update();
  //   }
  // }
}
