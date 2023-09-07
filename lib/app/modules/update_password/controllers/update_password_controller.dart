import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UpdatePasswordController extends GetxController {
  RxBool isLoading = false.obs;
  TextEditingController currC = TextEditingController();
  TextEditingController newC = TextEditingController();
  TextEditingController confirmC = TextEditingController();

  FirebaseAuth auth = FirebaseAuth.instance;

  void updatePass() async {
    if (currC.text.isNotEmpty &&
        newC.text.isNotEmpty &&
        confirmC.text.isNotEmpty) {
      if (newC.text == confirmC.text) {
        isLoading.value = true;
        try {
          String emailUser = auth.currentUser!.email!;

          await auth.signInWithEmailAndPassword(
              email: emailUser, password: currC.text);
          await auth.currentUser!.updatePassword(newC.text);

          Get.back();

          Get.snackbar("Berhasil", "Berhasil update password.");
        } on FirebaseAuthException catch (e) {
          if (e.code == "wrong-password") {
            Get.snackbar("Terjadi kesalahan", "Password sekarang salah.");
          } else {
            Get.snackbar("Terjadi kesalahan", "${e.code.toLowerCase()}");
          }
          Get.snackbar("Terjadi kesalahan", "Tidak dapat update password.");
        } catch (e) {
          Get.snackbar("Terjadi kesalahan", "Tidak dapat update password.");
        } finally {
          isLoading.value = false;
        }
      } else {
        Get.snackbar("Terjadi kesalahan", "Confirm password tidak cocok.");
      }
    } else {
      Get.snackbar("Terjadi kesalahan", "Semua harus diisi.");
    }
  }
}
