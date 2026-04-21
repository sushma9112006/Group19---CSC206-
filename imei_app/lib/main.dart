import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ImeiTrackApp(),
  ));
}

const baseUrl = "http://10.19.223.179:4000";

class ImeiTrackApp extends StatefulWidget {
  const ImeiTrackApp({super.key});

  @override
  State<ImeiTrackApp> createState() => _ImeiTrackAppState();
}

class _ImeiTrackAppState extends State<ImeiTrackApp> {
  static const platform = MethodChannel('imei_track/device_specs');

  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  final brandController = TextEditingController();
  final modelController = TextEditingController();
  final ramController = TextEditingController();
  final romController = TextEditingController();
  final storageController = TextEditingController();
  final networkTypeController = TextEditingController();
  final imeiController = TextEditingController();

  final friendPhoneController = TextEditingController();
  final friendOtpController = TextEditingController();
  final friendNameController = TextEditingController();

  final flagImeiController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  String status = "";
  int currentStep = 0;
  List<dynamic> myFriends = [];
  bool loadingDeviceSpecs = false;
  bool ocrBusy = false;
  bool restoringSession = true;
  bool isSuspiciousDevice = false;

  void _applyLatestDevice(dynamic latestDevice) {
    if (latestDevice == null) return;

    brandController.text = (latestDevice["brand"] ?? "").toString().trim();
    modelController.text =
        (latestDevice["device_model"] ?? "").toString().trim();
    ramController.text = (latestDevice["ram"] ?? "").toString().trim();
    romController.text = (latestDevice["rom"] ?? "").toString().trim();
    storageController.text = (latestDevice["storage"] ?? "").toString().trim();
    networkTypeController.text =
        (latestDevice["network_type"] ?? "").toString().trim();
    imeiController.text = (latestDevice["imei"] ?? "").toString().trim();
  }

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString("saved_phone");

    if (savedPhone == null || savedPhone.isEmpty) {
      setState(() {
        restoringSession = false;
      });
      _loadDeviceDetails();
      return;
    }

    phoneController.text = savedPhone;

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/auth/session/$savedPhone"),
      );
      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final latestDevice = data["latestDevice"];
        final suspicious = data["isSuspicious"] == true;
        _applyLatestDevice(latestDevice);

        setState(() {
          isSuspiciousDevice = suspicious;
          currentStep = latestDevice == null ? 1 : 2;
          status = suspicious
              ? "This device is marked suspicious. Friend features are disabled."
              : "Welcome back.";
          restoringSession = false;
        });
      } else {
        await prefs.remove("saved_phone");
        setState(() {
          restoringSession = false;
          currentStep = 0;
          status = data["error"] ?? "Session expired";
        });
      }
    } catch (e) {
      setState(() {
        restoringSession = false;
        status = "Session restore failed: $e";
      });
    } finally {
      _loadDeviceDetails();
    }
  }

  Future<void> _persistLogin(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("saved_phone", phone);
  }

  Future<void> _loadDeviceDetails() async {
    setState(() => loadingDeviceSpecs = true);
    try {
      final deviceInfo = DeviceInfoPlugin();
      final android = await deviceInfo.androidInfo;
      final networkResults = await Connectivity().checkConnectivity();

      String networkType = "Unknown";
      if (networkResults.contains(ConnectivityResult.mobile)) {
        networkType = "Mobile";
      } else if (networkResults.contains(ConnectivityResult.wifi)) {
        networkType = "WiFi";
      }

      final nativeSpecs =
          await platform.invokeMethod<Map<dynamic, dynamic>>('getDeviceSpecs');

      brandController.text =
          (nativeSpecs?['brand']?.toString() ?? android.manufacturer).trim();
      modelController.text =
          (nativeSpecs?['model']?.toString() ?? android.model).trim();
      ramController.text = (nativeSpecs?['ram']?.toString() ?? "").trim();
      storageController.text =
          (nativeSpecs?['storage']?.toString() ?? "").trim();
      romController.text =
          (nativeSpecs?['rom']?.toString() ?? storageController.text).trim();
      networkTypeController.text = networkType;
    } catch (e) {
      setState(() {
        status = "Device details auto-fetch failed: $e";
      });
    } finally {
      setState(() => loadingDeviceSpecs = false);
    }
  }

  Future<void> _pickAndReadImeiImage() async {
    try {
      final XFile? file =
          await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      setState(() {
        ocrBusy = true;
      });

      final inputImage = InputImage.fromFilePath(file.path);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognized = await recognizer.processImage(inputImage);
      await recognizer.close();

      final digitsOnly = recognized.text.replaceAll(RegExp(r'\D'), '');
      final match = RegExp(r'\d{15}').firstMatch(digitsOnly);

      if (match != null) {
        imeiController.text = match.group(0)!;
        if (mounted) {
          showAppPopup(
            "OCR Success",
            "IMEI extracted successfully.",
            Colors.green,
          );
        }
      } else {
        if (mounted) {
          showAppPopup(
            "OCR Result",
            "No 15-digit IMEI found. You can type it manually.",
            Colors.orange,
          );
        }
      }
    } catch (e) {
      setState(() {
        status = "OCR failed: $e";
      });
    } finally {
      setState(() => ocrBusy = false);
    }
  }

  Future<void> sendOtp() async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/auth/send-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": phoneController.text.trim(),
          "purpose": "login",
        }),
      );

      final data = jsonDecode(res.body);
      setState(() {
        status = res.statusCode == 200
            ? "OTP sent. Check backend terminal for test OTP."
            : (data["error"] ?? "No response");
      });
    } catch (e) {
      setState(() => status = "Send OTP failed: $e");
    }
  }

  Future<void> verifyOtp() async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/auth/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": phoneController.text.trim(),
          "otp": otpController.text.trim(),
          "purpose": "login",
        }),
      );

      final data = jsonDecode(res.body);
      setState(() {
        status = data["message"] ?? data["error"] ?? "No response";
        if (res.statusCode == 200) {
          _applyLatestDevice(data["latestDevice"]);
          isSuspiciousDevice = data["isSuspicious"] == true;
          currentStep = data["requiresDeviceRegistration"] == true ? 1 : 2;
        }
      });

      if (res.statusCode == 200) {
        await _persistLogin(phoneController.text.trim());
        showAppPopup("Verified", "OTP verified successfully", Colors.green);
      }
    } catch (e) {
      setState(() => status = "Verify OTP failed: $e");
    }
  }

  Future<void> registerDevice() async {
    final imei = imeiController.text.trim();
    if (imei.isNotEmpty && !RegExp(r'^\d{15}$').hasMatch(imei)) {
      setState(() {
        status = "IMEI must be exactly 15 digits.";
      });
      showAppPopup("Invalid IMEI", status, Colors.orange);
      return;
    }

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/device/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": phoneController.text.trim(),
          "brand": brandController.text.trim(),
          "device_model": modelController.text.trim(),
          "ram": ramController.text.trim(),
          "rom": romController.text.trim(),
          "storage": storageController.text.trim(),
          "network_type": networkTypeController.text.trim(),
          "imei": imei,
        }),
      );

      final data = jsonDecode(res.body);
      setState(() {
        status = data["message"] ?? data["error"] ?? "No response";
        if (res.statusCode == 200) {
          _applyLatestDevice(data["device"]);
          currentStep = 2;
          isSuspiciousDevice =
              (data["device"]?["status"]?.toString() ?? "") == "suspicious";
        }
      });

      if (res.statusCode == 200) {
        showAppPopup(
          "Device Status",
          data["message"] ?? "Registration complete",
          data["message"] == "Registration successful"
              ? Colors.green
              : data["message"] == "Device is suspicious"
                  ? Colors.orange
                  : Colors.red,
        );
      }
    } catch (e) {
      setState(() => status = "Register failed: $e");
    }
  }

  Future<void> sendFriendOtp() async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/friends/send-link-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_phone": phoneController.text.trim(),
          "friend_phone": friendPhoneController.text.trim(),
        }),
      );

      final data = jsonDecode(res.body);
      setState(() {
        status = res.statusCode == 200
            ? "Friend OTP sent. Check backend terminal."
            : (data["error"] ?? "No response");
      });
    } catch (e) {
      setState(() => status = "Friend OTP send failed: $e");
    }
  }

  Future<bool> verifyFriendOtp() async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/friends/verify-link-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_phone": phoneController.text.trim(),
          "friend_phone": friendPhoneController.text.trim(),
          "otp": friendOtpController.text.trim(),
        }),
      );

      final data = jsonDecode(res.body);
      setState(() {
        status = data["message"] ?? data["error"] ?? "No response";
      });

      return res.statusCode == 200;
    } catch (e) {
      setState(() => status = "Friend OTP verify failed: $e");
      return false;
    }
  }

  Future<void> promptFriendName(String friendPhone) async {
    friendNameController.clear();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Name Your Friend"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter a name for this friend. If you skip it, the app will use the next Friend number.",
            ),
            const SizedBox(height: 12),
            inputField("Friend Name", friendNameController),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await saveFriendName(friendPhone, "");
            },
            child: const Text("Skip"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await saveFriendName(
                friendPhone,
                friendNameController.text.trim(),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> saveFriendName(String friendPhone, String friendName) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/friends/set-name"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_phone": phoneController.text.trim(),
          "friend_phone": friendPhone,
          "friend_name": friendName,
        }),
      );

      final data = jsonDecode(res.body);
      setState(() {
        status = data["message"] ?? data["error"] ?? "No response";
      });

      showAppPopup(
        res.statusCode == 200 ? "Friend Added" : "Info",
        status,
        res.statusCode == 200 ? Colors.blue : Colors.orange,
      );
    } catch (e) {
      setState(() => status = "Save friend name failed: $e");
    }
  }

  Future<void> loadMyFriends() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/friends/${phoneController.text.trim()}"),
      );

      final data = jsonDecode(res.body);
      setState(() {
        myFriends = data["friends"] ?? [];
        status = "Friends loaded";
      });
    } catch (e) {
      setState(() => status = "Load friends failed: $e");
    }
  }

  Future<void> flagLost() async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/device/flag-lost"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "owner_phone": phoneController.text.trim(),
          "imei": flagImeiController.text.trim(),
        }),
      );

      final data = jsonDecode(res.body);
      setState(() {
        status = data["message"] ?? data["error"] ?? "No response";
      });

      showAppPopup(
        res.statusCode == 200 ? "Success" : "Info",
        status,
        res.statusCode == 200 ? Colors.redAccent : Colors.orange,
      );
    } catch (e) {
      setState(() => status = "Flag lost failed: $e");
    }
  }

  Future<void> unflagLost() async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/device/unflag-lost"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "owner_phone": phoneController.text.trim(),
          "imei": flagImeiController.text.trim(),
        }),
      );

      final data = jsonDecode(res.body);
      setState(() {
        status = data["message"] ?? data["error"] ?? "No response";
      });

      showAppPopup(
        res.statusCode == 200 ? "Success" : "Info",
        status,
        res.statusCode == 200 ? Colors.green : Colors.orange,
      );
    } catch (e) {
      setState(() => status = "Unflag lost failed: $e");
    }
  }

  Future<void> unregisterDevice() async {
    final imei = imeiController.text.trim();
    if (imei.isEmpty) {
      setState(() {
        status = "No registered IMEI found for this device.";
      });
      showAppPopup("Unable to Unregister", status, Colors.orange);
      return;
    }

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/device/unregister"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": phoneController.text.trim(),
          "imei": imei,
        }),
      );

      final data = jsonDecode(res.body);
      setState(() {
        status = data["message"] ?? data["error"] ?? "No response";
        if (res.statusCode == 200) {
          currentStep = 1;
          imeiController.clear();
        }
      });

      if (res.statusCode == 200) {
        showAppPopup("Unregistered", "Device unregistered successfully", Colors.red);
        isSuspiciousDevice = false;
      }
    } catch (e) {
      setState(() => status = "Unregister failed: $e");
    }
  }

  Future<void> confirmUnregister() async {
    final shouldUnregister = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Unregister Device"),
        content: const Text("Are you sure you want to unregister this device?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (shouldUnregister == true) {
      await unregisterDevice();
    }
  }

  void showAppPopup(String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: color)),
          )
        ],
      ),
    );
  }

  Widget inputField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget verifyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Verify Your Number",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        inputField(
          "Mobile Number",
          phoneController,
          keyboardType: TextInputType.phone,
        ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: sendOtp,
                child: const Text("Send OTP"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: sendOtp,
                child: const Text("Resend OTP"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        inputField(
          "Enter OTP",
          otpController,
          keyboardType: TextInputType.number,
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: verifyOtp,
            child: const Text("Verify OTP"),
          ),
        ),
      ],
    );
  }

  Widget registerStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Register Device Details",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        if (loadingDeviceSpecs) const LinearProgressIndicator(),
        inputField("Brand", brandController, readOnly: true),
        inputField("Device Model", modelController, readOnly: true),
        inputField("RAM", ramController, readOnly: true),
        inputField("ROM", romController, readOnly: true),
        inputField("Storage", storageController, readOnly: true),
        inputField("Network Type", networkTypeController, readOnly: true),
        inputField(
          "IMEI",
          imeiController,
          readOnly: true,
          keyboardType: TextInputType.number,
        ),
        const Text(
          "IMEI can only be fetched using OCR. Upload a screenshot to extract it automatically.",
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: ocrBusy ? null : _pickAndReadImeiImage,
                child: Text(ocrBusy ? "Reading..." : "Upload Screenshot"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => imeiController.clear(),
                child: const Text("Clear IMEI"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => currentStep = 0),
                child: const Text("Previous"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: registerDevice,
                child: const Text("Next"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void showLinkFriendDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Link With A Friend"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              inputField(
                "Friend Mobile Number",
                friendPhoneController,
                keyboardType: TextInputType.phone,
              ),
              ElevatedButton(
                onPressed: sendFriendOtp,
                child: const Text("Send Friend OTP"),
              ),
              const SizedBox(height: 12),
              inputField(
                "Enter Friend OTP",
                friendOtpController,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          ElevatedButton(
            onPressed: () async {
              final friendPhone = friendPhoneController.text.trim();
              final verified = await verifyFriendOtp();

              if (!mounted) return;

              Navigator.pop(context);

              if (verified) {
                await promptFriendName(friendPhone);
              }
            },
            child: const Text("Verify"),
          ),
        ],
      ),
    );
  }

  void showMyFriendsDialog() async {
    await loadMyFriends();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("My Friends"),
        content: SizedBox(
          width: double.maxFinite,
          child: myFriends.isEmpty
              ? const Text("No friends linked yet.")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: myFriends.length,
                  itemBuilder: (_, i) {
                    final f = myFriends[i];
                    return ListTile(
                      title: Text(
                        (f["display_name"]?.toString().isNotEmpty ?? false)
                            ? f["display_name"]
                            : (f["friend_phone"] ?? ""),
                      ),
                      subtitle: Text(
                        "${f["friend_phone"] ?? ""}\n${f["verified"] == true ? "Verified" : "Not verified"}",
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          friendNameController.text =
                              (f["display_name"] ?? "").toString();
                          Navigator.pop(context);
                          await showEditFriendNameDialog(
                            (f["friend_phone"] ?? "").toString(),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
        ],
      ),
    );
  }

  void showFlagDialog() {
    flagImeiController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Flag / Unflag Friend's Device"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            inputField(
              "Friend's IMEI Number",
              flagImeiController,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await unflagLost();
            },
            child: const Text("Unflag"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await flagLost();
            },
            child: const Text("Flag"),
          ),
        ],
      ),
    );
  }

  Future<void> showEditFriendNameDialog(String friendPhone) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Friend Name"),
        content: inputField("Friend Name", friendNameController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await saveFriendName(
                friendPhone,
                friendNameController.text.trim(),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget dashboardStep() {
    if (isSuspiciousDevice) {
      return suspiciousStep();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("IMEI Track",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: showLinkFriendDialog,
            child: const Text("Link With A Friend"),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: showMyFriendsDialog,
            child: const Text("My Friends"),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: showFlagDialog,
            child: const Text("Flag / Unflag"),
          ),
        ),
        const SizedBox(height: 28),
        Align(
          alignment: Alignment.bottomCenter,
          child: TextButton(
            onPressed: confirmUnregister,
            child: const Text("Unregister Device"),
          ),
        ),
      ],
    );
  }

  Widget suspiciousStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Suspicious Device",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          "This device has been marked suspicious. Friend linking, friend lookup, and flagging features are disabled for this phone.",
        ),
        const SizedBox(height: 16),
        const Text(
          "An alert is sent to users who already registered a similar device profile with another number.",
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: confirmUnregister,
          child: const Text("Unregister Device"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    brandController.dispose();
    modelController.dispose();
    ramController.dispose();
    romController.dispose();
    storageController.dispose();
    networkTypeController.dispose();
    imeiController.dispose();
    friendPhoneController.dispose();
    friendOtpController.dispose();
    friendNameController.dispose();
    flagImeiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (restoringSession) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final body = currentStep == 0
        ? verifyStep()
        : currentStep == 1
            ? registerStep()
            : dashboardStep();

    return Scaffold(
      appBar: AppBar(title: const Text("IMEI Track")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            body,
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.black12,
              child: Text(
                "STATUS: $status",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
