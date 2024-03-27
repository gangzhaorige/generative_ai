import 'package:flutter/material.dart';
import 'package:flutter_front_end/models/message_model.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../viewmodel/conversation_model.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {

  final SpeechToText _speechToText = SpeechToText();
  late TextEditingController _questionController; 
  bool _speechEnabled = false;


  @override
  void initState() {
    _questionController = TextEditingController();
    super.initState();
    _initSpeech();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _questionController.text = result.recognizedWords;
    });
  }

  void resetQuestion() {
    setState(() {
      _questionController.text = '';
    });
  }

  @override
  void dispose() {
    super.dispose();
    _questionController.dispose();
  }

  void scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients) {
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> addMessage() async {
    Provider.of<ConversationModel>(context, listen: false).addMessage(MessageModel(isSender: true, text: _questionController.text, url: ''));
    scrollDown();
    String question = _questionController.text;
    resetQuestion();
    await Provider.of<ConversationModel>(context, listen: false).generateResponse(question).then((value) {
      scrollDown();
      print('Nani!');
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SizedBox(
        width: 1000,
        child: TextField(
          controller: _questionController,
          style: const TextStyle(
            color: Colors.white
          ),
          onSubmitted: (value) {
            addMessage();
          },
          onEditingComplete: () {},
          autofocus: true,
          cursorColor: Colors.white,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            filled: true,
            hintText: 'Your question here!',
            labelText: 'Ask anything about SFBU!',
            labelStyle: const TextStyle(
              color: Colors.white
            ),
            hintStyle: const TextStyle(fontSize: 20.0, color: Colors.white),
            focusColor: Colors.white,
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(25.7),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(25.7),
            ),
            
            suffixIcon: SizedBox(
              width: 100,
              child: Row(
                children: [
                  IconButton(
                    splashColor: Colors.transparent,
                    onPressed: _speechToText.isNotListening ? _startListening : _stopListening,
                    icon: Icon(
                      _speechToText.isNotListening ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                    )
                  ),
                  IconButton(
                    splashColor: Colors.transparent,
                    onPressed: addMessage,
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                    )
                  ),
                ],
              ),
            )
          ),
        ),
      ),
    );
  }
}