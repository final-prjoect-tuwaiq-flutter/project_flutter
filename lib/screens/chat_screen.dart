import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_flutter/service/gemini_chat_service.dart';
import 'package:project_flutter/theme/theme.dart';
import 'package:project_flutter/widgets/app_ui.dart';

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
      if (!mounted) return;
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
      if (!mounted) return;
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
    final colors = appColors(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: colors.creamBackground,
          body: Column(
            children: [
              _ChatHeader(isTyping: _isBotTyping),
              Expanded(child: _buildBody(colors)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppCustomColors colors) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
            const SizedBox(height: 14),
            Text(
              'يجهّز المرشد نفسه لخدمتك…',
              style: TextStyle(
                color: colors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          child: AppStatePanel(
            icon: Icons.wifi_off_rounded,
            title: 'تعذّر الاتصال بالمرشد',
            subtitle: _errorMessage,
            actionLabel: 'إعادة المحاولة',
            actionIcon: Icons.refresh_rounded,
            onAction: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _initChat();
            },
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
        inputToolbarPadding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        inputToolbarMargin: EdgeInsets.zero,
        inputToolbarStyle: BoxDecoration(
          color: colors.surfaceColor,
          border: Border(top: BorderSide(color: colors.borderSoft)),
        ),
        inputTextStyle: TextStyle(fontSize: 15, color: colors.textPrimary),
        inputDecoration: InputDecoration(
          hintText: 'اسأل عن مكان، ميزانية، أو نشاط…',
          filled: true,
          fillColor: colors.creamBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide(color: colors.borderSoft),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide(color: colors.borderSoft),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide(color: colors.accentColor, width: 1.4),
          ),
        ),
        sendButtonBuilder: (onSend) => Padding(
          padding: const EdgeInsetsDirectional.only(start: 8),
          child: GestureDetector(
            onTap: onSend,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: colors.accentGradient,
                boxShadow: [
                  BoxShadow(
                    color: colors.accentColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              // السهم يشير لليسار في الواجهة العربية
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 19,
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
        ),
      ),
      messageOptions: MessageOptions(
        currentUserContainerColor: colors.inkSoft,
        currentUserTextColor: Colors.white,
        containerColor: colors.surfaceColor,
        textColor: colors.textPrimary,
        borderRadius: 20,
        messagePadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 11,
        ),
        showOtherUsersAvatar: true,
        showCurrentUserAvatar: false,
        showTime: true,
        timeFontSize: 10,
        avatarBuilder: (user, onTap, onLongPress) => Padding(
          padding: const EdgeInsetsDirectional.only(end: 6),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: colors.accentGradient,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ),
      messageListOptions: const MessageListOptions(showDateSeparator: false),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final bool isTyping;

  const _ChatHeader({required this.isTyping});

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return Container(
      decoration: BoxDecoration(
        gradient: colors.inkGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: Stack(
          children: [
            PositionedDirectional(
              top: -60,
              end: -40,
              child: AppGlowBlob(color: colors.accentColor, size: 180),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                child: Row(
                  children: [
                    AppCircleButton(
                      icon: Icons.arrow_forward_rounded,
                      tooltip: 'رجوع',
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 46,
                      height: 46,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: colors.accentGradient,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.inkColor,
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: colors.goldColor,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مرشد المعزب',
                            style: AppTheme.display(
                              18,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF4CD39B),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isTyping
                                    ? 'يكتب الآن…'
                                    : 'مساعدك الذكي لاختيار وجهتك',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.62),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
