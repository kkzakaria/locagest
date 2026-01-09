# Quickstart: Dashboard avec KPIs

**Feature**: 008-dashboard
**Date**: 2026-01-09

## Prerequisites

- Flutter SDK ^3.10.4 (stable channel)
- Existing LocaGest codebase with completed modules: auth, buildings, units, tenants, leases, payments
- Supabase project with populated test data

## Quick Setup

### 1. Generate Freezed Models

After creating the new model files, run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. File Structure

Create the following new files:

```
lib/
├── domain/
│   ├── entities/
│   │   ├── dashboard_stats.dart        # NEW
│   │   ├── overdue_rent.dart           # NEW
│   │   └── expiring_lease.dart         # NEW
│   └── repositories/
│       └── dashboard_repository.dart   # NEW
├── data/
│   ├── models/
│   │   ├── dashboard_stats_model.dart  # NEW (Freezed)
│   │   ├── overdue_rent_model.dart     # NEW (Freezed)
│   │   └── expiring_lease_model.dart   # NEW (Freezed)
│   ├── datasources/
│   │   └── dashboard_remote_datasource.dart  # NEW
│   └── repositories/
│       └── dashboard_repository_impl.dart    # NEW
└── presentation/
    ├── providers/
    │   └── dashboard_provider.dart     # NEW
    ├── pages/
    │   └── home/
    │       └── dashboard_page.dart     # UPDATE (existing)
    └── widgets/
        └── dashboard/                  # NEW directory
            ├── kpi_card.dart
            ├── overdue_rent_card.dart
            ├── expiring_lease_card.dart
            ├── occupancy_rate_widget.dart
            └── main_navigation_shell.dart
```

### 3. Router Update

Update `lib/core/router/app_router.dart` to use ShellRoute:

```dart
// Wrap main routes in ShellRoute for persistent bottom navigation
ShellRoute(
  builder: (context, state, child) => MainNavigationShell(child: child),
  routes: [
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
    GoRoute(path: '/buildings', builder: (_, __) => const BuildingsListPage()),
    GoRoute(path: '/tenants', builder: (_, __) => const TenantsListPage()),
    GoRoute(path: '/payments', builder: (_, __) => const PaymentsPage()),
  ],
),
```

## Key Implementation Steps

### Step 1: Domain Layer (Entities)

Create simple Dart classes (no Freezed needed for entities):

```dart
// lib/domain/entities/dashboard_stats.dart
class DashboardStats {
  final int buildingsCount;
  final int activeTenantsCount;
  final int totalUnitsCount;
  final int occupiedUnitsCount;
  final double monthlyRevenueCollected;
  final double monthlyRevenueDue;
  final int overdueCount;
  final double overdueAmount;
  final int expiringLeasesCount;

  // Constructor and computed properties...
  double get occupancyRate => totalUnitsCount > 0
      ? (occupiedUnitsCount / totalUnitsCount) * 100
      : 0;
}
```

### Step 2: Data Layer (Datasource)

Create the remote datasource with parallel queries:

```dart
// lib/data/datasources/dashboard_remote_datasource.dart
class DashboardRemoteDatasource {
  final SupabaseClient _supabase;

  Future<DashboardStats> getDashboardStats() async {
    final results = await Future.wait([
      _getBuildingsCount(),
      _getActiveTenantsCount(),
      _getTotalUnitsCount(),
      _getOccupiedUnitsCount(),
      _getMonthlyRevenueCollected(),
      _getMonthlyRevenueDue(),
      _getOverdueCount(),
      _getOverdueAmount(),
      _getExpiringLeasesCount(),
    ]);

    return DashboardStats(
      buildingsCount: results[0] as int,
      // ... map all results
    );
  }

  Future<int> _getBuildingsCount() async {
    final response = await _supabase
        .from('buildings')
        .select('id')
        .count(CountOption.exact);
    return response.count;
  }
  // ... other query methods
}
```

### Step 3: Presentation Layer (Provider)

Create simple FutureProvider:

```dart
// lib/presentation/providers/dashboard_provider.dart
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final datasource = DashboardRemoteDatasource(Supabase.instance.client);
  return DashboardRepositoryImpl(datasource);
});

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  return ref.read(dashboardRepositoryProvider).getDashboardStats();
});

final overdueRentsProvider = FutureProvider<List<OverdueRent>>((ref) async {
  return ref.read(dashboardRepositoryProvider).getOverdueRents(limit: 5);
});

final expiringLeasesProvider = FutureProvider<List<ExpiringLease>>((ref) async {
  return ref.read(dashboardRepositoryProvider).getExpiringLeases(daysAhead: 30);
});
```

### Step 4: Dashboard Page Update

Update the existing dashboard_page.dart:

```dart
// lib/presentation/pages/home/dashboard_page.dart
class DashboardPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final overdueAsync = ref.watch(overdueRentsProvider);
    final expiringAsync = ref.watch(expiringLeasesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('LocaGest')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(overdueRentsProvider);
          ref.invalidate(expiringLeasesProvider);
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              // KPI Cards
              statsAsync.when(
                data: (stats) => _buildKPICards(stats),
                loading: () => _buildLoadingKPIs(),
                error: (e, _) => _buildErrorWidget(e),
              ),
              // Overdue Section
              overdueAsync.when(
                data: (list) => _buildOverdueSection(list),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => _buildErrorWidget(e),
              ),
              // Expiring Leases Section
              expiringAsync.when(
                data: (list) => _buildExpiringSection(list),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => _buildErrorWidget(e),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Step 5: Bottom Navigation Shell

Create the navigation shell widget:

```dart
// lib/presentation/widgets/dashboard/main_navigation_shell.dart
class MainNavigationShell extends ConsumerWidget {
  final Widget child;

  const MainNavigationShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getSelectedIndex(location),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.home_work), label: 'Immeubles'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Locataires'),
          NavigationDestination(icon: Icon(Icons.payments), label: 'Paiements'),
        ],
        onDestinationSelected: (index) => _navigateTo(context, index),
      ),
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith('/buildings')) return 1;
    if (location.startsWith('/tenants')) return 2;
    if (location.startsWith('/payments')) return 3;
    return 0; // Dashboard
  }

  void _navigateTo(BuildContext context, int index) {
    switch (index) {
      case 0: context.go('/dashboard');
      case 1: context.go('/buildings');
      case 2: context.go('/tenants');
      case 3: context.go('/payments');
    }
  }
}
```

## Testing

### Manual Testing Checklist

1. **KPI Cards**: Verify all 4 cards show correct values from database
2. **Occupancy Rate**: Check color coding (green >85%, orange 70-85%, red <70%)
3. **Overdue Section**: Verify top 5 oldest overdue items displayed
4. **Expiring Leases**: Verify leases within 30 days displayed
5. **Pull-to-Refresh**: Verify data refreshes
6. **Navigation**: Verify bottom nav works and highlights correct tab
7. **Empty State**: Test with empty database
8. **Error State**: Test with network disconnected

### Performance Test

```bash
# Measure dashboard load time
flutter run --profile
# Open dashboard and check logs for load time
# Target: <2 seconds
```

## Common Issues

### Issue: Freezed files not generating
```bash
# Clean and regenerate
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: Bottom nav not showing
- Ensure routes are wrapped in ShellRoute
- Check that MainNavigationShell is the builder

### Issue: Slow dashboard load
- Check network tab for query times
- Ensure Future.wait() is used for parallel queries
- Add indexes on frequently queried columns

## French Localization Checklist

- [ ] "Tableau de bord" (Dashboard title)
- [ ] "Immeubles" / "Locataires" / "Paiements" / "Baux" (nav labels)
- [ ] "Revenus du mois" (Monthly revenue)
- [ ] "Impayés" (Overdue)
- [ ] "Baux à renouveler" (Expiring leases)
- [ ] "Taux d'occupation" (Occupancy rate)
- [ ] FCFA currency format with space separator (e.g., "150 000 FCFA")
- [ ] DD/MM/YYYY date format
