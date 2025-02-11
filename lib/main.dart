import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AEZER',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _userInput = TextEditingController();
  static var apiKey = dotenv.env["GEMINI_API_KEY"] ?? "";
  final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];

  bool _isDarkMode = false; // Track dark mode state

  Future<void> sendMessage() async {
    final message = _userInput.text;

    if (message.isEmpty) return; // Prevent empty messages

    setState(() {
      _messages.add(Message(isUser: true, message: message, date: DateTime.now()));
      _userInput.clear(); // Clear text field
    });

    _scrollToBottom(); // Scroll after user message

    // Check for dark mode or light mode commands
    if (message.toLowerCase() == "dark mode on") {
      setState(() {
        _isDarkMode = true;
      });
    } else if (message.toLowerCase() == "light mode on") {
      setState(() {
        _isDarkMode = false;
      });
    } else {
      final content = [Content.text(message)];
      final response = await model.generateContent(content);

      setState(() {
        _messages.add(Message(
            isUser: false, message: response.text ?? "", date: DateTime.now()));
      });
    }

    _scrollToBottom(); // Scroll after bot response
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _isDarkMode ? Colors.grey[700] : Colors.white60,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _isDarkMode ? Colors.white : Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'CHAT WITH AEZER',
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
            fontSize: 19,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        toolbarHeight: 80,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.8), BlendMode.dstATop),
            image: AssetImage(
              _isDarkMode ? 'assets/image-invert.png' : 'assets/lightmode.jpg',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Messages(
                      isUser: message.isUser,
                      message: message.message,
                      date: DateFormat('HH:mm').format(message.date),
                      isDarkMode: _isDarkMode,
                  );
                },
              ),
            ),
            Container(
              color: _isDarkMode ? Colors.grey[700] : Colors.white,
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 15,
                    child: TextFormField(
                      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                      controller: _userInput,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _isDarkMode ? Colors.grey[700] : Colors.white60,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: _isDarkMode
                                ? Colors.pinkAccent
                                : Colors.black,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: _isDarkMode
                                ? Colors.pinkAccent
                                : Colors.black,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: _isDarkMode
                                ? Colors.pinkAccent
                                : Colors.black,
                            width: 2,
                          ),
                        ),
                        hintText: 'Enter Your Message',
                        hintStyle: TextStyle(color: _isDarkMode ? Colors.white54 : Colors.black54),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    padding: EdgeInsets.all(12),
                    iconSize: 30,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        _isDarkMode ? Colors.white : Colors.black,
                      ),
                      foregroundColor: WidgetStateProperty.all(
                        _isDarkMode ? Colors.pink : Colors.white,
                      ),
                      shape: WidgetStateProperty.all(CircleBorder()),
                    ),
                    onPressed: () {
                      sendMessage();
                    },
                    icon: Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Message {
  final bool isUser;
  final String message;
  final DateTime date;

  Message({required this.isUser, required this.message, required this.date});
}

class Messages extends StatefulWidget {
  final bool isUser;
  final String message;
  final String date;
  final bool isDarkMode;

  const Messages({
    super.key,
    required this.isUser,
    required this.message,
    required this.date,
    required this.isDarkMode,
  });

  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  bool _showTime = false;

  void _toggleTimeVisibility() {
    setState(() {
      _showTime = !_showTime;
    });

    if (_showTime) {
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showTime = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onDoubleTap: _toggleTimeVisibility,
          child: Align(
            alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.75,
                minWidth: widget.message.length < 10 ? 50 : 0,
              ),
              padding: EdgeInsets.symmetric(
                vertical: 10,
                horizontal: widget.message.length < 10 ? 15 : 20,
              ),
              decoration: BoxDecoration(
                gradient: widget.isUser
                    ? LinearGradient(
                        colors: [Colors.pink, Colors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: widget.isDarkMode
                            ? [Colors.grey[800]!, Colors.grey[900]!]
                            : [Colors.black, Colors.grey.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.message,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
                  ),
                  if (_showTime)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        widget.date,
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'Poppins',
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}