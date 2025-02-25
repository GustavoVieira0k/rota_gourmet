import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:rota_gourmet/pages/home_page.dart';
import 'package:rota_gourmet/services/restaurant_service.dart';
import 'package:rota_gourmet/utils/web_file_picker.dart';

class EditRestaurantPage extends StatefulWidget {
  final String restaurantId;

  const EditRestaurantPage({super.key, required this.restaurantId});

  @override
  _EditRestaurantPageState createState() => _EditRestaurantPageState();
}

class _EditRestaurantPageState extends State<EditRestaurantPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Controladores para os campos
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController cuisineController = TextEditingController();

  String? selectedPrice;
  TimeOfDay? openingTime;
  TimeOfDay? closingTime;
  List<bool> selectedDays = List.generate(7, (index) => false);

  List<File> images = [];
  List<Uint8List> webImages = [];
  List<String> existingImageUrls = [];

  final List<String> priceLevels = [
    '\$',
    '\$\$',
    '\$\$\$',
    '\$\$\$\$',
    '\$\$\$\$\$'
  ];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  Future<void> _loadRestaurantData() async {
    try {
      print("Carregando dados do restaurante: ${widget.restaurantId}");
      DocumentSnapshot restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .get();

      if (!restaurantDoc.exists) {
        print("Restaurante não encontrado!");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurante não encontrado!')),
        );
        Navigator.pop(context);
        return;
      }

      var data = restaurantDoc.data() as Map<String, dynamic>;
      print("Dados carregados: $data");

      setState(() {
        nameController.text = data['name'] ?? '';
        descriptionController.text = data['description'] ?? '';
        cuisineController.text = data['cuisine'] ?? '';
        selectedPrice = data['price'];
        locationController.text = data['location'] ?? '';
        contactController.text = data['contact'] ?? '';
        instagramController.text = data['instagram'] ?? '';
        openingTime = _parseTime(data['openingTime']);
        closingTime = _parseTime(data['closingTime']);
        existingImageUrls = List<String>.from(data['images'] ?? []);

        List<int> daysOpen = List<int>.from(data['daysOpen'] ?? []);
        List<String> weekDays = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
        for (int i = 0; i < 7; i++) {
          selectedDays[i] = daysOpen.contains(weekDays[i]);
        }

        _isLoading = false;
      });
    } catch (e) {
      print("Erro ao carregar os dados: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar os dados.')),
      );
      setState(() => _isLoading = false);
    }
  }

  TimeOfDay? _parseTime(String? timeString) {
    if (timeString == null) return null;
    final parts = timeString.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      Uint8List? pickedWebImage = await pickWebImage();
      if (pickedWebImage != null) {
        setState(() {
          webImages.add(pickedWebImage);
        });
      }
    } else {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          images.add(File(pickedFile.path));
        });
      }
    }
  }

  Future<void> _updateRestaurant() async {
    if (nameController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        cuisineController.text.isEmpty ||
        selectedPrice == null ||
        locationController.text.isEmpty ||
        contactController.text.isEmpty ||
        instagramController.text.isEmpty ||
        (existingImageUrls.isEmpty && images.isEmpty && webImages.isEmpty) ||
        openingTime == null ||
        closingTime == null ||
        !selectedDays.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> newImageUrls = List.from(existingImageUrls);

      // Upload de novas imagens (mobile)
      for (var image in images) {
        String fileName =
            'restaurants/${widget.restaurantId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        UploadTask uploadTask =
            FirebaseStorage.instance.ref().child(fileName).putFile(image);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        newImageUrls.add(downloadUrl);
      }

      // Upload de novas imagens (web)
      for (var webImage in webImages) {
        String fileName =
            'restaurants/${widget.restaurantId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        UploadTask uploadTask =
            FirebaseStorage.instance.ref().child(fileName).putData(webImage);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        newImageUrls.add(downloadUrl);
      }

      // Converter dias selecionados
      List<int> daysOpen = [];
      List<String> weekDays = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
      for (int i = 0; i < 7; i++) {
        if (selectedDays[i]) daysOpen.add(weekDays[i] as int);
      }

      // Atualizar no Firestore
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .update({
        'name': nameController.text,
        'description': descriptionController.text,
        'cuisine': cuisineController.text,
        'price': selectedPrice,
        'location': locationController.text,
        'contact': contactController.text,
        'instagram': instagramController.text,
        'openingTime': openingTime!.format(context),
        'closingTime': closingTime!.format(context),
        'daysOpen': daysOpen,
        'images': newImageUrls,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restaurante atualizado com sucesso!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao atualizar restaurante.')),
      );
    }

    setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Restaurante'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(nameController, 'Nome do Restaurante'),
                      _buildTextField(descriptionController, 'Descrição',
                          maxLines: 3),
                      _buildTextField(cuisineController, 'Tipo de Comida'),
                      _buildDropdown('Valor Médio', priceLevels, selectedPrice,
                          (value) {
                        setState(() => selectedPrice = value);
                      }),
                      _buildTextField(locationController, 'Localização'),
                      _buildTextField(contactController, 'Número para Contato',
                          keyboardType: TextInputType.phone),
                      _buildTextField(instagramController, 'Instagram'),
                      _buildTimePicker('Horário de Abertura', openingTime,
                          () => _pickTime(true)),
                      _buildTimePicker('Horário de Fechamento', closingTime,
                          () => _pickTime(false)),
                      _buildDaysSelector(),
                      ElevatedButton(
                          onPressed: _pickImage,
                          child: const Text('Selecionar Imagens')),
                      _buildImagePreview(),
                      const SizedBox(height: 20),
                      ElevatedButton(
                          onPressed: _updateRestaurant,
                          child: const Text('Salvar Alterações')),
                    ],
                  ),
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
      children:
          existingImageUrls.map((url) => _buildNetworkImage(url)).toList() +
              images.map((file) => _buildFileImage(file)).toList() +
              webImages.map((webImage) => _buildWebImage(webImage)).toList(),
    );
  }

  Widget _buildNetworkImage(String url) {
    return Stack(
      children: [
        Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              setState(() => existingImageUrls.remove(url));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFileImage(File file) {
    return Stack(
      children: [
        Image.file(file, width: 100, height: 100, fit: BoxFit.cover),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              setState(() => images.remove(file));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWebImage(Uint8List webImage) {
    return Stack(
      children: [
        Image.memory(webImage, width: 100, height: 100, fit: BoxFit.cover),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              setState(() => webImages.remove(webImage));
            },
          ),
        ),
      ],
    );
  }
}
