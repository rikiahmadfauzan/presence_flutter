import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:presence/app/routes/app_pages.dart';

class LoginController extends GetxController {
  RxBool isLoading = false.obs;
  TextEditingController emailC = TextEditingController();
  TextEditingController passwordC = TextEditingController();

  FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> login() async {
    if (emailC.text.isNotEmpty && passwordC.text.isNotEmpty) {
      isLoading.value = true;
      try {
        UserCredential userCredential = await auth.signInWithEmailAndPassword(
          email: emailC.text,
          password: passwordC.text,
        );
        print(userCredential);
        if (userCredential.user != null) {
          if (userCredential.user!.emailVerified == true) {
            isLoading.value = false;
            if (passwordC.text == "password") {
              Get.offAllNamed(Routes.NEW_PASSWORD);
            } else {
              Get.offAllNamed(Routes.HOME);
            }
          } else {
            Get.defaultDialog(
                title: "Belum Verifikasi",
                middleText:
                    "Kamu belum verifikasi email ini, Lakukan verivikasi terlebih dahulu.",
                actions: [
                  OutlinedButton(
                    onPressed: () {
                      isLoading.value = false;
                      Get.back();
                    }, //back
                    child: Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await userCredential.user!.sendEmailVerification();
                        Get.snackbar("Berhasil",
                            "Email verifikasi telah dikirim ulang silahkan dicek kembali.");
                        isLoading.value = false;
                        Get.back();
                      } catch (e) {
                        isLoading.value = false;
                        Get.snackbar("Terjadi Kesalahan",
                            "Tidak dapat mengirim ulang email verifikasi.");
                      }
                    }, //back
                    child: Text("Kirim Ulang"),
                  ),
                ]);
          }
        }
        isLoading.value = false;
      } on FirebaseAuthException catch (e) {
        isLoading.value = false;

        if (e.code == 'user-not-found') {
          Get.snackbar("Terjadi Kesalahan", "Email tidak terdaftar.");
        } else if (e.code == 'wrong-password') {
          Get.snackbar("Terjadi Kesalahan", "Password salah.");
        }
      } catch (e) {
        isLoading.value = false;
        Get.snackbar("Terjadi Kesalahan", "Tidak dapat login.");
      }
    } else {
      Get.snackbar("Terjadi Kesalahan", "Email dan password harus diisi.");
    }
  }
}
