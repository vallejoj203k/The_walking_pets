import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_card.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/chat/providers/chat_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/empty_state.dart';
import '../../../config/theme/app_colors.dart';

class WalkerRequestsScreen extends StatefulWidget {
  const WalkerRequestsScreen({super.key});

  @override
  State<WalkerRequestsScreen> createState() => _WalkerRequestsScreenState();
}

class _WalkerRequestsScreenState extends State<WalkerRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final userId = context.read<AuthProvider>().userModel!.id;
    await context.read<BookingProvider>().loadWalkerBookings(userId);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final pending =
        booking.walkerBookings.where((b) => b.status == 'pending').toList();
    final active = booking.walkerBookings
        .where((b) =>
            b.status == 'accepted' || b.status == 'in_progress')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Solicitudes',
        showBack: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabCtrl,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Pendientes (${pending.length})'),
              Tab(text: 'Activas (${active.length})'),
            ],
          ),
          Expanded(
            child: booking.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildList(context, pending,
                          'No hay solicitudes pendientes.', true),
                      _buildList(context, active,
                          'No hay servicios activos.', false),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List bookings,
      String emptyMessage, bool isPending) {
    if (bookings.isEmpty) {
      return EmptyState(
          message: emptyMessage,
          icon: Icons.inbox_outlined);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (_, i) {
          final b = bookings[i];
          return BookingCard(
            booking: b,
            isWalkerView: true,
            onAccept: isPending
                ? () async {
                    await context
                        .read<BookingProvider>()
                        .updateBookingStatus(b.id, 'accepted');
                    // Auto-create chat conversation
                    if (b.walkerUserId != null && b.ownerUserId != null) {
                      await context
                          .read<ChatProvider>()
                          .getOrCreateConversation(
                              b.walkerUserId!, b.ownerUserId!);
                    }
                  }
                : null,
            onReject: isPending
                ? () => context
                    .read<BookingProvider>()
                    .updateBookingStatus(b.id, 'cancelled')
                : null,
            onStart: b.status == 'accepted'
                ? () => context
                    .read<BookingProvider>()
                    .updateBookingStatus(b.id, 'in_progress')
                : null,
            onComplete: b.status == 'in_progress'
                ? () => context
                    .read<BookingProvider>()
                    .updateBookingStatus(b.id, 'completed')
                : null,
          );
        },
      ),
    );
  }
}
