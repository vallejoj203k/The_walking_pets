import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/conversation_card.dart';
import 'chat_detail_screen.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/empty_state.dart';
import '../../../config/theme/app_colors.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final userId = context.read<AuthProvider>().userModel?.id;
    if (userId == null) return;
    final chat = context.read<ChatProvider>();
    chat.setCurrentUser(userId);
    await chat.loadConversations(userId);
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final userId = context.read<AuthProvider>().userModel?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Mensajes',
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: chat.isLoading
          ? const Center(child: CircularProgressIndicator())
          : chat.conversations.isEmpty
              ? const EmptyState(
                  message:
                      'No tienes conversaciones aún.\nAcepta una reserva para chatear.',
                  icon: Icons.chat_bubble_outline,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chat.conversations.length,
                    itemBuilder: (_, i) {
                      final conv = chat.conversations[i];
                      return ConversationCard(
                        conversation: conv,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                conversationId: conv.id,
                                currentUserId: userId,
                                otherUserId: conv.otherUserId ?? '',
                                otherUserName:
                                    conv.otherUserName ?? 'Usuario',
                              ),
                            ),
                          ).then((_) => _load());
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
