import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:project_flutter/service/gemini_chat_service.dart';
import 'package:project_flutter/theme/theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GeminiChatService _chatService = GeminiChatService.instance;

  final ChatUser _me = ChatUser(id: '1', firstName: 'أنت');
  final ChatUser _bot = ChatUser(
    id: '2',
    firstName: 'مرشد المعزب',
    profileImage: null,
  );

  final List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isBotTyping = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      await _chatService.startNewSession();
      setState(() {
        _isLoading = false;
        _messages.add(
          ChatMessage(
            user: _bot,
            createdAt: DateTime.now(),
            text:
                'أهلاً بك! 👋 أنا مرشدك في "المعزب".\n'
                'أخبرني عن ميزانيتك ونوع الأماكن التي تحبها، وسأساعدك في اختيار المكان الأنسب لك.',
          ),
        );
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _onSend(ChatMessage message) async {
    setState(() {
      _messages.insert(0, message);
      _isBotTyping = true;
    });

    try {
      final reply = await _chatService.sendMessage(message.text);
      if (!mounted) return;
      setState(() {
        _isBotTyping = false;
        _messages.insert(
          0,
          ChatMessage(user: _bot, createdAt: DateTime.now(), text: reply),
        );
      });
    } catch (e) {
      debugPrint('Gemini sendMessage error: $e');
      if (!mounted) return;
      setState(() {
        _isBotTyping = false;
        _messages.insert(
          0,
          ChatMessage(
            user: _bot,
            createdAt: DateTime.now(),
            text: 'حدث خطأ أثناء الاتصال بالمساعد الذكي:\n${e.toString()}',
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9F6),
        appBar: AppBar(
          backgroundColor: AppTheme.baseBlack,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: customColors.accentColor,
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'مرشد المعزب',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
        ),
        body: _buildBody(customColors),
      ),
    );
  }

  Widget _buildBody(AppCustomColors customColors) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initChat();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.baseBlack,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DashChat(
      currentUser: _me,
      onSend: _onSend,
      messages: _messages,
      typingUsers: _isBotTyping ? [_bot] : [],
      inputOptions: InputOptions(
        alwaysShowSend: true,
        sendOnEnter: true,
        inputTextDirection: TextDirection.rtl,
        inputTextStyle: const TextStyle(fontSize: 15),
        inputDecoration: InputDecoration(
          hintText: 'اكتب رسالتك...',
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: customColors.accentColor),
          ),
        ),
        sendButtonBuilder: (onSend) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: onSend,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: customColors.accentColor,
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ),
      messageOptions: MessageOptions(
        currentUserContainerColor: AppTheme.baseBlack,
        currentUserTextColor: Colors.white,
        containerColor: Colors.white,
        textColor: const Color(0xFF1D1D1D),
        borderRadius: 18,
        showOtherUsersAvatar: true,
        showCurrentUserAvatar: false,
        avatarBuilder: (user, onTap, onLongPress) => CircleAvatar(
          radius: 16,
          backgroundColor: customColors.accentColor,
          child: const Icon(
            Icons.smart_toy_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
      messageListOptions: const MessageListOptions(showDateSeparator: false),
    );
  }
}
