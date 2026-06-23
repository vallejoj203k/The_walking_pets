import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_card.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/empty_state.dart';
import '../../../config/theme/app_colors.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final userId = context.read<AuthProvider>().userModel!.id;
    await context.read<BookingProvider>().loadOwnerBookings(userId);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final active =
        booking.ownerBookings.where((b) => b.isActive).toList();
    final completed =
        booking.ownerBookings.where((b) => b.status == 'completed').toList();
    final cancelled =
        booking.ownerBookings.where((b) => b.status == 'cancelled').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Mis Reservas',
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
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
              Tab(text: 'Activas (${active.length})'),
              Tab(text: 'Completadas (${completed.length})'),
              Tab(text: 'Canceladas (${cancelled.length})'),
            ],
          ),
          Expanded(
            child: booking.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _BookingList(
                        bookings: active,
                        emptyMessage:
                            'No tienes reservas activas.\nBusca un paseador para comenzar.',
                      ),
                      _BookingList(
                        bookings: completed,
                        emptyMessage: 'Sin reservas completadas aún.',
                      ),
                      _BookingList(
                        bookings: cancelled,
                        emptyMessage: 'Sin reservas canceladas.',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List bookings;
  final String emptyMessage;

  const _BookingList(
      {required this.bookings, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return EmptyState(
          message: emptyMessage, icon: Icons.calendar_today_outlined);
    }
    return RefreshIndicator(
      onRefresh: () async {
        final userId = context.read<AuthProvider>().userModel!.id;
        await context.read<BookingProvider>().loadOwnerBookings(userId);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (_, i) {
          final b = bookings[i];
          return BookingCard(
            booking: b,
            onCancel: b.canCancel
                ? () => context
                    .read<BookingProvider>()
                    .updateBookingStatus(b.id, 'cancelled')
                : null,
            onComplete: b.canComplete
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
