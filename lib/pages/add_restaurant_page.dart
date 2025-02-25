import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html;
import 'package:rota_gourmet/pages/home_page.dart';
import 'package:rota_gourmet/services/restaurant_service.dart';

class AddRestaurantPage extends StatefulWidget {
  const AddRestaurantPage({super.key});

  @override
  State<AddRestaurantPage> createState() => _AddRestaurantPageState();
}

class _AddRestaurantPageState extends State<AddRestaurantPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController cuisineController = TextEditingController();

  String? selectedPrice;
  TimeOfDay? openingTime;
  TimeOfDay? closingTime;
  List<bool> selectedDays =
      List.generate(7, (index) => false); // 7 dias da semana

  List<File> images = [];
  List<Uint8List> webImages = [];

  final List<String> priceLevels = [
    '\$',
    '\$\$',
    '\$\$\$',
    '\$\$\$\$',
    '\$\$\$\$\$'
  ];

  final RestaurantService _restaurantService = RestaurantService();

  Future<void> _pickImage() async {
    if (kIsWeb) {
      final html.FileUploadInputElement uploadInput =
          html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((event) {
        final file = uploadInput.files!.first;
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((event) {
          setState(() {
            webImages.add(reader.result as Uint8List);
          });
        });
      });
    } else {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          images.add(File(pickedFile.path));
        });
      }
    }
  }

  Future<void> _pickTime(bool isOpeningTime) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: isOpeningTime
          ? (openingTime ?? TimeOfDay.now())
          : (closingTime ?? TimeOfDay.now()),
    );

    if (pickedTime != null) {
      setState(() {
        if (isOpeningTime) {
          openingTime = pickedTime;
        } else {
          closingTime = pickedTime;
        }
      });
    }
  }

  Future<void> _saveRestaurant() async {
    if (nameController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        cuisineController.text.isEmpty ||
        selectedPrice == null ||
        locationController.text.isEmpty ||
        contactController.text.isEmpty ||
        instagramController.text.isEmpty ||
        (images.isEmpty && webImages.isEmpty) ||
        openingTime == null ||
        closingTime == null ||
        !selectedDays.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos!')),
      );
      return;
    }

    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: usuário não autenticado!')),
      );
      return;
    }

    List<int> daysOpen = [];
    for (int i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) daysOpen.add(i);
    }

    await _restaurantService.saveRestaurant(
      userId,
      nameController.text,
      descriptionController.text,
      cuisineController.text,
      selectedPrice!,
      locationController.text,
      contactController.text,
      instagramController.text,
      openingTime!,
      closingTime!,
      daysOpen,
      images,
      webImages,
    );

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Adicionar Restaurante'),
          backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(nameController, 'Nome do Restaurante'),
              _buildTextField(descriptionController, 'Descrição', maxLines: 3),
              _buildTextField(cuisineController, 'Tipo de Comida'),
              _buildDropdown('Valor Médio', priceLevels, selectedPrice,
                  (value) {
                setState(() => selectedPrice = value);
              }),
              _buildTextField(locationController, 'Localização'),
              _buildTextField(contactController, 'Número para Contato',
                  keyboardType: TextInputType.phone),
              _buildTextField(instagramController, 'Instagram'),
              _buildTimePicker(
                  'Horário de Abertura', openingTime, () => _pickTime(true)),
              _buildTimePicker(
                  'Horário de Fechamento', closingTime, () => _pickTime(false)),
              _buildDaysSelector(),
              ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Selecionar Imagens')),
              _buildImagePreview(),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: _saveRestaurant,
                  child: const Text('Salvar Restaurante')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        maxLines: maxLines,
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selectedValue,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay? time, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: const InputDecoration(border: OutlineInputBorder()),
          child: Text(time != null ? time.format(context) : label,
              style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildDaysSelector() {
    List<String> weekDays = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          return GestureDetector(
            onTap: () {
              setState(() => selectedDays[index] = !selectedDays[index]);
            },
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selectedDays[index] ? Colors.green : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(weekDays[index],
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: images.map((imageFile) {
            return Image.file(imageFile,
                width: 100, height: 100, fit: BoxFit.cover);
          }).toList() +
          webImages.map((webImage) {
            return Image.memory(webImage,
                width: 100, height: 100, fit: BoxFit.cover);
          }).toList(),
    );
  }
}
