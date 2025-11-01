import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:random_string/random_string.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:e_commerce_app/service/database.dart';
import 'package:e_commerce_app/widget/widget_support.dart';

class AddFood extends StatefulWidget {
  const AddFood({super.key});

  @override
  State<AddFood> createState() => _AddFoodState();
}

class _AddFoodState extends State<AddFood> {
  final List<String> fooditems = ['Ice-cream', 'drinks', 'milk', 'fast_food'];
  String? value;
  final namecontroller = TextEditingController();
  final pricecontroller = TextEditingController();
  final detailcontroller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  /// ✅ Pick image from gallery
  Future<void> getImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = image;
        _uploadProgress = 0.0; // reset upload progress
      });
    }
  }

  /// ✅ Upload image to Cloudinary and return its URL
  Future<String?> uploadImageToCloudinary(XFile image) async {
    try {
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
      final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];

      // Debug: confirm .env values
      print("🌩️ CLOUDINARY_CLOUD_NAME: $cloudName");
      print("📦 CLOUDINARY_UPLOAD_PRESET: $uploadPreset");

      if (cloudName == null || uploadPreset == null) {
        throw Exception(
          "Cloudinary credentials missing in .env (CLOUDINARY_CLOUD_NAME or CLOUDINARY_UPLOAD_PRESET)",
        );
      }

      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );

      Uint8List imageBytes = await image.readAsBytes();

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: image.name,
          ),
        );

      print("📤 Uploading image: ${image.name} → $url");

      final response = await http.Response.fromStream(await request.send());

      print("📥 Response status: ${response.statusCode}");
      print("📦 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Upload success! Image URL: ${data['secure_url']}");
        return data['secure_url'];
      } else {
        throw Exception("Cloudinary upload failed: ${response.body}");
      }
    } catch (e) {
      print("❌ Cloudinary upload failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Cloudinary upload failed: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return null;
    }
  }

  /// ✅ Upload item details (image + metadata)
  Future<void> uploadItem() async {
    if (selectedImage == null ||
        namecontroller.text.isEmpty ||
        pricecontroller.text.isEmpty ||
        detailcontroller.text.isEmpty ||
        value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Please fill all fields and select an image"),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final imageUrl = await uploadImageToCloudinary(selectedImage!);
      if (imageUrl == null) throw Exception("Image upload returned null");

      String addId = randomAlphaNumeric(10);

      Map<String, dynamic> addItem = {
        "Image": imageUrl,
        "Name": namecontroller.text.trim(),
        "Price": pricecontroller.text.trim(),
        "Detail": detailcontroller.text.trim(),
        "Category": value!,
        "CreatedAt": DateTime.now(),
      };

      await DatabaseMethods().addFoodItem(addItem, value!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text("✅ Food item added successfully!"),
        ),
      );

      setState(() {
        _isUploading = false;
        _uploadProgress = 0;
        namecontroller.clear();
        pricecontroller.clear();
        detailcontroller.clear();
        selectedImage = null;
        value = null;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Upload failed: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// ✅ Reusable text field
  Widget _textField(
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        color: const Color(0xFFececf8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: AppWidget.LightTextFeildStyle(),
        ),
      ),
    );
  }

  /// ✅ Dropdown for categories
  Widget _categoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFFececf8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: Colors.white,
          iconSize: 36,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
          hint: const Text("Select Category"),
          value: value,
          items: fooditems
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 18.0, color: Colors.black),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => value = val),
        ),
      ),
    );
  }

  /// ✅ UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_new_outlined,
            color: Color(0xFF373866),
          ),
        ),
        centerTitle: true,
        title: Text("Add Item", style: AppWidget.HeadlineTextFeildStyle()),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Upload the Item Picture",
                style: AppWidget.semiBoldTextFeildStyle(),
              ),
              const SizedBox(height: 20.0),

              Center(
                child: GestureDetector(
                  onTap: getImage,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: selectedImage == null
                          ? const Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.black,
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: kIsWeb
                                  ? Image.network(
                                      selectedImage!.path,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(selectedImage!.path),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30.0),
              Text("Item Name", style: AppWidget.semiBoldTextFeildStyle()),
              const SizedBox(height: 10.0),
              _textField("Enter Item Name", namecontroller),

              const SizedBox(height: 30.0),
              Text("Item Price", style: AppWidget.semiBoldTextFeildStyle()),
              const SizedBox(height: 10.0),
              _textField("Enter Item Price", pricecontroller),

              const SizedBox(height: 30.0),
              Text("Item Detail", style: AppWidget.semiBoldTextFeildStyle()),
              const SizedBox(height: 10.0),
              _textField("Enter Item Detail", detailcontroller, maxLines: 5),

              const SizedBox(height: 20.0),
              Text(
                "Select Category",
                style: AppWidget.semiBoldTextFeildStyle(),
              ),
              const SizedBox(height: 10.0),
              _categoryDropdown(),

              const SizedBox(height: 30.0),

              GestureDetector(
                onTap: _isUploading ? null : uploadItem,
                child: Center(
                  child: Material(
                    elevation: 5.0,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: _isUploading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "Add",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              if (_isUploading)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: LinearProgressIndicator(
                    value: _uploadProgress > 0 ? _uploadProgress : null,
                    backgroundColor: Colors.grey[300],
                    color: Colors.deepPurple,
                    minHeight: 5,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
