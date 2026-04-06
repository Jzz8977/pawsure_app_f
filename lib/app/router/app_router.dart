import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/providers/user_provider.dart';
import '../../shared/widgets/app_shell.dart';

// Auth
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/pages/login_phone_page.dart';

// Pet Owner
import '../../features/pet_owner/home/presentation/pages/home_page.dart';
import '../../features/pet_owner/pets/presentation/pages/pets_page.dart';
import '../../features/pet_owner/chat/pages/chat_page.dart';
import '../../features/pet_owner/chat/pages/chatroom_page.dart';
import '../../features/pet_owner/my/presentation/pages/my_page.dart';
import '../../features/pet_owner/search/presentation/pages/search_page.dart';
import '../../features/pet_owner/services/presentation/pages/services_page.dart';

// Provider Role
import '../../features/provider_role/home/pages/provider_home_page.dart';
import '../../features/provider_role/work_tab/pages/work_tab_page.dart';
import '../../features/provider_role/clockin/pages/clockin_page.dart';
import '../../features/provider_role/clockin/pages/clockin_record_page.dart';
import '../../features/provider_role/clockin/pages/clockin_tasks_page.dart';
import '../../features/provider_role/clockin/pages/clockin_task_detail_page.dart';
import '../../features/provider_role/report_issue/pages/report_issue_page.dart';

// Order
import '../../features/order/presentation/pages/order_page.dart';
import '../../features/order/presentation/pages/provider_detail_page.dart';
import '../../features/order/presentation/pages/select_service_page.dart';
import '../../features/order/presentation/pages/checkout_page.dart';
import '../../features/order/presentation/pages/order_detail_page.dart';
import '../../features/order/presentation/pages/review_order_page.dart';
import '../../features/order/presentation/pages/claim_apply_page.dart';
import '../../features/order/presentation/pages/pending_payment_page.dart';
import '../../features/order/presentation/pages/payment_success_page.dart';
import '../../features/order/presentation/pages/order_date_edit_page.dart';
import '../../features/order/presentation/pages/order_service_edit_page.dart';
import '../../features/order/presentation/pages/order_address_edit_page.dart';
import '../../features/order/presentation/pages/refund_apply_page.dart';
import '../../features/order/presentation/pages/refund_detail_page.dart';

// Manage
import '../../features/manage/presentation/pages/address_list_page.dart';
import '../../features/manage/presentation/pages/address_edit_page.dart';
import '../../features/manage/presentation/pages/pet_add_page.dart';
import '../../features/manage/presentation/pages/pet_detail_page.dart';
import '../../features/manage/presentation/pages/provider_order_detail_page.dart';
import '../../features/manage/presentation/pages/petsitter_application_page.dart';
import '../../features/manage/presentation/pages/petsitter_list_page.dart';
import '../../features/manage/presentation/pages/service_manage_page.dart';
import '../../features/manage/presentation/pages/service_publish_page.dart';
import '../../features/manage/presentation/pages/deposit_page.dart';

// User
import '../../features/user/presentation/pages/user_profile_page.dart';
import '../../features/user/presentation/pages/identity_verification_page.dart';
import '../../features/user/presentation/pages/phone_change_page.dart';
import '../../features/user/presentation/pages/wallet_page.dart';
import '../../features/user/presentation/pages/wallet_detail_page.dart';
import '../../features/user/presentation/pages/withdraw_page.dart';
import '../../features/user/presentation/pages/stored_card_page.dart';
import '../../features/user/presentation/pages/insurance_page.dart';
import '../../features/user/presentation/pages/coupons_page.dart';
import '../../features/user/presentation/pages/favorites_page.dart';
import '../../features/user/presentation/pages/face_verify_page.dart';
import '../../features/user/presentation/pages/member_center_page.dart';
import '../../features/user/presentation/pages/customer_service_page.dart';
import '../../features/user/presentation/pages/agreement_page.dart';
import '../../features/user/presentation/pages/platform_rules_page.dart';
import '../../features/user/presentation/pages/about_page.dart';

/// RouterNotifier：将 Riverpod 用户状态桥接为 GoRouter 的 refreshListenable
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen<UserModel?>(userNotifierProvider, (_, _s) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: notifier,
    redirect: (context, state) {
      final user = ref.read(userNotifierProvider);
      final isLoggedIn = user != null;
      final loc = state.matchedLocation;
      final isAuthRoute =
          loc.startsWith('/welcome') || loc.startsWith('/login-phone');

      if (!isLoggedIn && !isAuthRoute) return '/welcome';
      if (isLoggedIn && isAuthRoute) {
        return user.role == UserRole.petOwner ? '/home' : '/provider-home';
      }
      return null;
    },
    routes: [
      // ─── Auth ───────────────────────────────────────────────
      GoRoute(path: '/welcome', builder: (_, _s) => const WelcomePage()),
      GoRoute(path: '/login-phone', builder: (_, _s) => const LoginPhonePage()),

      // ─── App Shell（宠物主 4 tabs / 看护师 4 tabs）─────────
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          // 宠物主 tabs
          GoRoute(path: '/home', builder: (_, _s) => const HomePage()),
          GoRoute(path: '/pets', builder: (_, _s) => const PetsPage()),
          // 看护师 tabs
          GoRoute(path: '/provider-home', builder: (_, _s) => const ProviderHomePage()),
          GoRoute(path: '/work-tab', builder: (_, _s) => const WorkTabPage()),
          // 共享 tabs
          GoRoute(path: '/chat', builder: (_, _s) => const ChatPage()),
          GoRoute(path: '/my', builder: (_, _s) => const MyPage()),
        ],
      ),

      // ─── packageUser ─────────────────────────────────────
      GoRoute(path: '/user-profile', builder: (_, _s) => const UserProfilePage()),
      GoRoute(path: '/identity-verification', builder: (_, _s) => const IdentityVerificationPage()),
      GoRoute(path: '/phone-change', builder: (_, _s) => const PhoneChangePage()),
      GoRoute(path: '/wallet', builder: (_, _s) => const WalletPage()),
      GoRoute(path: '/wallet-detail', builder: (_, _s) => const WalletDetailPage()),
      GoRoute(path: '/withdraw', builder: (_, _s) => const WithdrawPage()),
      GoRoute(path: '/stored-card', builder: (_, _s) => const StoredCardPage()),
      GoRoute(path: '/insurance', builder: (_, _s) => const InsurancePage()),
      GoRoute(path: '/coupons', builder: (_, _s) => const CouponsPage()),
      GoRoute(path: '/favorites', builder: (_, _s) => const FavoritesPage()),
      GoRoute(path: '/face-verify', builder: (_, _s) => const FaceVerifyPage()),
      GoRoute(path: '/member-center', builder: (_, _s) => const MemberCenterPage()),
      GoRoute(path: '/customer-service', builder: (_, _s) => const CustomerServicePage()),
      GoRoute(path: '/agreement', builder: (_, _s) => const AgreementPage()),
      GoRoute(path: '/platform-rules', builder: (_, _s) => const PlatformRulesPage()),
      GoRoute(path: '/about', builder: (_, _s) => const AboutPage()),

      // ─── packageOrder ─────────────────────────────────────
      GoRoute(path: '/order', builder: (_, _s) => const OrderPage()),
      GoRoute(path: '/provider-detail/:id', builder: (_, s) => ProviderDetailPage(id: s.pathParameters['id']!)),
      GoRoute(path: '/select-service', builder: (_, _s) => const SelectServicePage()),
      GoRoute(path: '/checkout', builder: (_, _s) => const CheckoutPage()),
      GoRoute(path: '/order-detail/:id', builder: (_, s) => OrderDetailPage(id: s.pathParameters['id']!)),
      GoRoute(path: '/review-order/:id', builder: (_, s) => ReviewOrderPage(id: s.pathParameters['id']!)),
      GoRoute(path: '/claim-apply', builder: (_, _s) => const ClaimApplyPage()),
      GoRoute(path: '/pending-payment', builder: (_, _s) => const PendingPaymentPage()),
      GoRoute(path: '/payment-success', builder: (_, _s) => const PaymentSuccessPage()),
      GoRoute(path: '/order-date-edit', builder: (_, _s) => const OrderDateEditPage()),
      GoRoute(path: '/order-service-edit', builder: (_, _s) => const OrderServiceEditPage()),
      GoRoute(path: '/order-address-edit', builder: (_, _s) => const OrderAddressEditPage()),
      GoRoute(path: '/refund-apply', builder: (_, _s) => const RefundApplyPage()),
      GoRoute(path: '/refund-detail/:id', builder: (_, s) => RefundDetailPage(id: s.pathParameters['id']!)),

      // ─── packageManage ────────────────────────────────────
      GoRoute(path: '/address-list', builder: (_, _s) => const AddressListPage()),
      GoRoute(path: '/address-edit', builder: (_, s) => AddressEditPage(id: s.uri.queryParameters['id'])),
      GoRoute(path: '/pet-add', builder: (_, s) => PetAddPage(id: s.uri.queryParameters['id'])),
      GoRoute(path: '/pet-detail/:id', builder: (_, s) => PetDetailPage(id: s.pathParameters['id']!)),
      GoRoute(path: '/provider-order-detail', builder: (_, _s) => const ProviderOrderDetailPage()),
      GoRoute(path: '/petsitter-application', builder: (_, _s) => const PetsitterApplicationPage()),
      GoRoute(path: '/petsitter-list', builder: (_, _s) => const PetsitterListPage()),
      GoRoute(path: '/service-manage', builder: (_, _s) => const ServiceManagePage()),
      GoRoute(path: '/service-publish', builder: (_, _s) => const ServicePublishPage()),
      GoRoute(path: '/deposit', builder: (_, _s) => const DepositPage()),

      // ─── packageProvider ──────────────────────────────────
      GoRoute(path: '/clockin', builder: (_, _s) => const ClockinPage()),
      GoRoute(path: '/report-issue', builder: (_, _s) => const ReportIssuePage()),
      GoRoute(path: '/clockin-record', builder: (_, _s) => const ClockinRecordPage()),
      GoRoute(path: '/clockin-tasks', builder: (_, _s) => const ClockinTasksPage()),
      GoRoute(path: '/clockin-task-detail/:id', builder: (_, s) => ClockinTaskDetailPage(id: s.pathParameters['id']!)),

      // ─── 其他 ─────────────────────────────────────────────
      GoRoute(path: '/search', builder: (_, _s) => const SearchPage()),
      GoRoute(path: '/services', builder: (_, _s) => const ServicesPage()),
      GoRoute(path: '/chatroom/:id', builder: (_, s) => ChatroomPage(id: s.pathParameters['id']!)),
    ],
  );
});
