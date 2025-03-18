import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_the_label/logic.dart';
import 'package:read_the_label/main.dart';

class AskAiPage extends StatefulWidget {
  String mealName;
  dynamic foodImage;
  final Logic logic;
  AskAiPage(
      {super.key,
      required this.mealName,
      required this.foodImage,
      required this.logic});

  @override
  State<AskAiPage> createState() => _AskAiPageState();
}

class _AskAiPageState extends State<AskAiPage> {
  late final GeminiProvider _provider;
  late String nutritionContext;
  String? _currentMealName;

  final apiKey = kIsWeb
      ? 'AIzaSyA91Qu8C8xDq_cpr0zYIhT00UMlUWXD0Lc'
      : dotenv.env['GEMINI_API_KEY'];

  @override
  void initState() {
    super.initState();
    _currentMealName = widget.mealName;
    _provider = _createProvider();
    widget.logic.mealNameNotifier.addListener(_onMealNameChange);
    
    // Debug print for image type
    debugPrint('Food image type: ${widget.foodImage?.runtimeType}');
    if (kIsWeb && widget.foodImage != null) {
      debugPrint('Running on web platform with image: ${widget.foodImage}');
      if (isXFile(widget.foodImage)) {
        debugPrint('Image is XFile, attempting to read bytes');
        widget.foodImage.readAsBytes().then((bytes) {
          debugPrint('Successfully read ${bytes.length} bytes from XFile');
        }).catchError((error) {
          debugPrint('Error reading XFile bytes: $error');
        });
      }
    }
  }

  void _onMealNameChange() {
    if (widget.logic.mealName != _currentMealName) {
      setState(() {
        _currentMealName = widget.logic.mealName;
        // Create new provider with empty history
        _provider = _createProvider();
      });
    }
  }

  @override
  void dispose() {
    widget.logic.mealNameNotifier.removeListener(_onMealNameChange);
    super.dispose();
  }

  // Helper method to safely check if an object is an XFile
  bool isXFile(dynamic obj) {
    if (obj == null) return false;
    try {
      return obj.runtimeType.toString().contains('XFile');
    } catch (e) {
      debugPrint('Error checking if object is XFile: $e');
      return false;
    }
  }

  GeminiProvider _createProvider([List<ChatMessage>? history]) {
    nutritionContext = '''
      Meal: ${widget.mealName}
      Nutritional Information:
      - Calories: ${widget.logic.totalPlateNutrients['calories']} kcal
      - Protein: ${widget.logic.totalPlateNutrients['protein']}g
      - Carbohydrates: ${widget.logic.totalPlateNutrients['carbohydrates']}g
      - Fat: ${widget.logic.totalPlateNutrients['fat']}g
      - Fiber: ${widget.logic.totalPlateNutrients['fiber']}g
    ''';

    return GeminiProvider(
      history: history,
      model: GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey!,
        systemInstruction: Content.system('''
          You are a helpful friendly assistant specialized in providing nutritional information and guidance about meals.
          
          Current meal context:
          $nutritionContext
          
          Base your answers on this specific nutritional data when discussing this meal.
            Answer questions clearly, with relevant icons, and keep responses concise. Use emojis to make the text more user-friendly and engaging.
        '''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        title: const Text('Ask AI'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.cardBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(
                              _getMealIcon(widget.mealName),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.mealName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Add food image display
                  if (widget.foodImage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getMealIcon(widget.mealName),
                                  color: Colors.white,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Food Image',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Preview not available',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      "Nutritional Information:",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildNutrientChip("🔥 ${widget.logic.totalPlateNutrients['calories'] ?? 0} kcal"),
                        _buildNutrientChip("🥩 ${widget.logic.totalPlateNutrients['protein'] ?? 0}g protein"),
                        _buildNutrientChip("🍚 ${widget.logic.totalPlateNutrients['carbohydrates'] ?? 0}g carbs"),
                        _buildNutrientChip("🧈 ${widget.logic.totalPlateNutrients['fat'] ?? 0}g fat"),
                        _buildNutrientChip("🌱 ${widget.logic.totalPlateNutrients['fiber'] ?? 0}g fiber"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height - 250,
              width: MediaQuery.of(context).size.width,
              child: LlmChatView(
                suggestions: const [
                  '🍽️ Is this meal balanced?',
                  '🍊 Is this meal rich in vitamins?',
                  '🏋️‍♂️ Is this meal good for weight loss?',
                  '💪 How does this meal support muscle growth?',
                  '🌟 What are the health benefits of this meal?',
                ],
                provider: _provider,
                welcomeMessage:
                    "👋 Hello, what would you like to know about ${widget.mealName}? 🍽️",
                style: LlmChatViewStyle(
                  suggestionStyle: SuggestionStyle(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.cardBackground,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      textStyle: TextStyle(
                        fontFamily: 'Poppins',
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: <Color>[
                              Color.fromARGB(255, 0, 21, 255),
                              Color.fromARGB(255, 255, 0, 85),
                              Color.fromARGB(255, 255, 119, 0),
                              Color.fromARGB(255, 250, 220, 194),
                            ],
                            stops: [
                              0.1,
                              0.5,
                              0.7,
                              1.0,
                            ], // Four stops for four colors
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(
                            const Rect.fromLTWH(0.0, 0.0, 250.0, 16.0),
                          ),
                      )),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  actionButtonBarDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  addButtonStyle: ActionButtonStyle(
                    iconColor: Theme.of(context).colorScheme.onSurface,
                    iconDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.cardBackground,
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  chatInputStyle: ChatInputStyle(
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                    ),
                    backgroundColor:
                        Theme.of(context).colorScheme.cardBackground,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  llmMessageStyle: LlmMessageStyle(
                      markdownStyle:
                          MarkdownStyleSheet.fromTheme(Theme.of(context)),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.cardBackground,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      iconDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      iconColor: Colors.white),
                  userMessageStyle: UserMessageStyle(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.cardBackground,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    textStyle: TextStyle(
                      fontFamily: 'Poppins',
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  IconData _getMealIcon(String mealName) {
    final String lowerCaseName = mealName.toLowerCase();
    
    if (lowerCaseName.contains('breakfast') || 
        lowerCaseName.contains('cereal') || 
        lowerCaseName.contains('toast')) {
      return Icons.free_breakfast;
    } else if (lowerCaseName.contains('lunch') || 
               lowerCaseName.contains('sandwich') || 
               lowerCaseName.contains('salad')) {
      return Icons.lunch_dining;
    } else if (lowerCaseName.contains('dinner') || 
               lowerCaseName.contains('supper') || 
               lowerCaseName.contains('steak')) {
      return Icons.dinner_dining;
    } else if (lowerCaseName.contains('snack') || 
               lowerCaseName.contains('chips') || 
               lowerCaseName.contains('cookie')) {
      return Icons.cookie;
    } else if (lowerCaseName.contains('drink') || 
               lowerCaseName.contains('beverage') || 
               lowerCaseName.contains('coffee') ||
               lowerCaseName.contains('tea')) {
      return Icons.local_drink;
    } else if (lowerCaseName.contains('fruit') || 
               lowerCaseName.contains('apple') || 
               lowerCaseName.contains('banana')) {
      return Icons.apple;
    } else if (lowerCaseName.contains('vegetable') || 
               lowerCaseName.contains('salad') || 
               lowerCaseName.contains('broccoli')) {
      return Icons.eco;
    } else if (lowerCaseName.contains('dessert') || 
               lowerCaseName.contains('cake') || 
               lowerCaseName.contains('ice cream')) {
      return Icons.cake;
    } else if (lowerCaseName.contains('pizza')) {
      return Icons.local_pizza;
    } else if (lowerCaseName.contains('burger') || 
               lowerCaseName.contains('hamburger')) {
      return Icons.lunch_dining;
    } else if (lowerCaseName.contains('noodle') || 
               lowerCaseName.contains('pasta') || 
               lowerCaseName.contains('spaghetti')) {
      return Icons.ramen_dining;
    }
    
    // Default icon
    return Icons.restaurant;
  }
}
