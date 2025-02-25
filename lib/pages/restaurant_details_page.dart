import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RestaurantDetailsPage extends StatefulWidget {
  final String restaurantId;

  const RestaurantDetailsPage({Key? key, required this.restaurantId})
      : super(key: key);

  @override
  _RestaurantDetailsPageState createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  double _userRating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Restaurante')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('restaurants')
            .doc(widget.restaurantId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var restaurant = snapshot.data!.data() as Map<String, dynamic>;

          // Dados do restaurante
          String openingTime = restaurant['openingTime'] ?? '00:00';
          String closingTime = restaurant['closingTime'] ?? '00:00';
          List<int> daysOpen = restaurant['daysOpen'] != null
              ? List<int>.from(restaurant['daysOpen'])
              : [];
          String description = restaurant['description'] ?? 'Sem descrição';
          String contact = restaurant['contact'] ?? 'Não disponível';

          // Verifica se o restaurante está aberto
          bool isOpen = _checkIfOpen(daysOpen, openingTime, closingTime);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informações do restaurante
                Text(
                  restaurant['name'] ?? 'Sem nome',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${restaurant['cuisine'] ?? 'N/A'} • Preço médio: ${restaurant['price'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                    '📍 ${restaurant['location'] ?? 'Localização não disponível'}'),
                Text('🌐 ${restaurant['instagram'] ?? 'Sem redes sociais'}'),
                Text('📞 Contato: $contact'),
                const SizedBox(height: 8),
                Text(
                  isOpen ? '🟢 Aberto agora' : '🔴 Fechado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isOpen ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '🕒 Horário: ${_formatOpeningDays(daysOpen)} $openingTime - $closingTime',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),

                // Galeria de imagens
                if (restaurant['images'] != null &&
                    (restaurant['images'] as List).isNotEmpty)
                  SizedBox(
                    height: 150,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: (restaurant['images'] as List)
                          .map<Widget>(
                            (imageUrl) => Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(imageUrl,
                                    width: 150, height: 150, fit: BoxFit.cover),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 16),

                // Descrição
                const Text(
                  '📝 Descrição:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 16),

                // Avaliação média
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc(widget.restaurantId)
                      .collection('reviews')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text('⭐ Ainda sem avaliações.');
                    }

                    var reviews = snapshot.data!.docs;
                    double averageRating = reviews
                            .map((e) => (e['rating'] as num).toDouble())
                            .reduce((a, b) => a + b) /
                        reviews.length;

                    return Text(
                      '⭐ ${averageRating.toStringAsFixed(1)} (${reviews.length} avaliações)',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Seção de envio de comentário e avaliação
                const Divider(),
                const Text(
                  "Deixe seu comentário:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Sua avaliação:",
                  style: TextStyle(fontSize: 16),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _userRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setState(() {
                          _userRating = index + 1.0;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    labelText: "Comentário",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _submitReview,
                  child: const Text("Enviar"),
                ),
                const SizedBox(height: 16),

                // Lista de comentários
                const Divider(),
                const Text(
                  "Comentários:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc(widget.restaurantId)
                      .collection('reviews')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var reviews = snapshot.data!.docs;
                    if (reviews.isEmpty) {
                      return const Text("Nenhum comentário ainda.");
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        var review =
                            reviews[index].data() as Map<String, dynamic>;
                        double rating = (review['rating'] as num).toDouble();
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(review['username'] ?? 'Anônimo'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(5, (starIndex) {
                                  return Icon(
                                    starIndex < rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: Colors.amber,
                                  );
                                }),
                              ),
                              const SizedBox(height: 4),
                              Text(review['comment'] ?? ''),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Função para submeter o comentário/avaliação usando o nome da conta do usuário.
  Future<void> _submitReview() async {
    String comment = _commentController.text.trim();

    if (comment.isEmpty || _userRating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Preencha o comentário e selecione uma avaliação de 1 a 5 estrelas."),
        ),
      );
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Você precisa estar logado para comentar."),
        ),
      );
      return;
    }

    String username = user.displayName ?? user.email ?? 'Usuário Anônimo';

    try {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('reviews')
          .add({
        'username': username,
        'comment': comment,
        'rating': _userRating,
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Comentário enviado!")));
      _commentController.clear();
      setState(() {
        _userRating = 0;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao enviar comentário.")));
    }
  }

  // Função para verificar se o restaurante está aberto
  bool _checkIfOpen(
      List<int> daysOpen, String openingTime, String closingTime) {
    DateTime now = DateTime.now();
    int currentDay = now.weekday % 7; // Firebase usa Domingo como 0
    TimeOfDay nowTime = TimeOfDay(hour: now.hour, minute: now.minute);
    TimeOfDay openTime = _parseTime(openingTime);
    TimeOfDay closeTime = _parseTime(closingTime);

    if (!daysOpen.contains(currentDay)) return false;
    return _isTimeBetween(nowTime, openTime, closeTime);
  }

  // Converte uma string de horário em TimeOfDay
  TimeOfDay _parseTime(String time) {
    List<String> parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // Verifica se o horário atual está entre o horário de abertura e fechamento
  bool _isTimeBetween(TimeOfDay now, TimeOfDay start, TimeOfDay end) {
    int nowMinutes = now.hour * 60 + now.minute;
    int startMinutes = start.hour * 60 + start.minute;
    int endMinutes = end.hour * 60 + end.minute;
    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }

  // Formata os dias de funcionamento
  String _formatOpeningDays(List<int> daysOpen) {
    if (daysOpen.isEmpty) return 'Dias não informados';

    const List<String> weekDays = [
      'Dom',
      'Seg',
      'Ter',
      'Qua',
      'Qui',
      'Sex',
      'Sáb'
    ];
    return daysOpen
        .map((index) => index >= 0 && index < weekDays.length
            ? weekDays[index]
            : 'Inválido')
        .join(', ');
  }
}
