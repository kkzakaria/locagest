# Research: Dashboard avec KPIs

**Feature**: 008-dashboard
**Date**: 2026-01-09

## 1. Aggregate Queries in Supabase with RLS

### Decision: Parallel queries with Future.wait()

**Rationale**: Execute all KPI queries in parallel using `Future.wait()` for optimal performance. RLS policies automatically filter data per user, so no additional filtering needed in application code.

**Alternatives considered**:
- **Sequential queries**: Rejected - 5-6x slower than parallel execution (~3500ms vs ~600ms)
- **Single PostgreSQL function via RPC**: Considered but rejected for MVP - adds complexity and requires DB migrations; can be optimized later if performance issues arise
- **Supabase real-time subscriptions**: Deferred - not needed for dashboard that uses pull-to-refresh

**Implementation pattern**:
```dart
Future<DashboardStats> getDashboardStats() async {
  final results = await Future.wait([
    _getBuildingsCount(),
    _getActiveTenantsCount(),
    _getMonthlyRevenue(),
    _getOverdueSchedulesWithDetails(),
    _getExpiringLeases(),
    _getOccupancyStats(),
  ]);
  // Combine results into DashboardStats entity
}
```

### Key Supabase query patterns:

| Query Type | Pattern | Performance |
|------------|---------|-------------|
| COUNT | `.select('id').count(CountOption.exact)` | Fast, minimal data transfer |
| SUM | `.select('amount')` then Dart sum | Fast, RLS-filtered |
| JOIN data | `.select('*, tenant:tenants(name)')` | Medium, use for lists only |
| Date range | `.gte('date', start).lte('date', end)` | Fast with index |

---

## 2. Dashboard State Management with Riverpod

### Decision: FutureProvider with manual invalidation

**Rationale**: FutureProvider is simpler than AsyncNotifier for dashboard data that:
- Loads once on page open
- Refreshes via pull-to-refresh (using `ref.invalidate()`)
- Has no complex state transitions

**Alternatives considered**:
- **AsyncNotifier**: Rejected for MVP - adds complexity without benefit; FutureProvider with invalidation achieves same result
- **StreamProvider with periodic timer**: Rejected - unnecessary battery/network drain; pull-to-refresh is sufficient for property management use case
- **StateNotifier**: Rejected - older pattern, FutureProvider is more idiomatic for async data

**Implementation pattern**:
```dart
// Provider
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final repository = ref.read(dashboardRepositoryProvider);
  return repository.getDashboardStats();
});

// Refresh in UI
ref.invalidate(dashboardStatsProvider);
```

---

## 3. Bottom Navigation with GoRouter

### Decision: ShellRoute wrapper for persistent navigation

**Rationale**: ShellRoute keeps the bottom navigation bar visible across main screens while allowing nested routes (detail pages) to hide it.

**Alternatives considered**:
- **IndexedStack with manual navigation**: Rejected - doesn't integrate with GoRouter deep linking
- **Custom Navigator with nested routers**: Rejected - complex, error-prone
- **Navigator 2.0 raw implementation**: Rejected - GoRouter already handles this

**Implementation pattern**:
```dart
ShellRoute(
  builder: (context, state, child) => MainNavigationShell(child: child),
  routes: [
    GoRoute(path: '/dashboard', ...),
    GoRoute(path: '/buildings', ...),
    GoRoute(path: '/tenants', ...),
    GoRoute(path: '/payments', ...),
  ],
)
```

### Route structure:
- `/dashboard` - Dashboard (tab 0)
- `/buildings` - Buildings list (tab 1)
- `/buildings/:id` - Building detail (no bottom nav - nested)
- `/tenants` - Tenants list (tab 2)
- `/payments` - Payments (tab 3)

---

## 4. Performance Optimization

### Decision: Parallel queries + Riverpod caching

**Rationale**:
- Parallel execution reduces load time from ~3.5s to ~0.6s
- Riverpod FutureProvider caches results until invalidated
- Pull-to-refresh provides user-controlled refresh

**Performance targets** (from Constitution):
- Dashboard queries MUST complete in <2 seconds
- Target: <1 second with parallel queries

**Benchmarks**:
| Approach | Estimated Time | Notes |
|----------|---------------|-------|
| Sequential (6 queries) | 3500ms | Unacceptable |
| Parallel (Future.wait) | 600ms | Target |
| Cached (subsequent load) | <100ms | Optimal |

---

## 5. Occupancy Rate Calculation

### Decision: Calculate from units table status field

**Rationale**: The `units` table already has a `status` field with values: 'vacant', 'occupied', 'maintenance'. Occupancy rate = (occupied count / total count) * 100.

**Formula**:
```
occupancy_rate = (COUNT(units WHERE status='occupied') / COUNT(units)) * 100
```

**Color thresholds** (from spec):
- Green (>85%): Excellent performance
- Orange (70-85%): Average performance
- Red (<70%): Needs improvement

---

## 6. Overdue Rent Detection

### Decision: Query rent_schedules with due_date < today AND status IN ('pending', 'partial')

**Rationale**: The existing `rent_schedules` table tracks all due payments with status field. An overdue schedule is one where:
- `due_date` < current date
- `status` is 'pending' (unpaid) or 'partial' (partially paid)

**Query pattern**:
```dart
await _supabase
  .from('rent_schedules')
  .select('*, leases(*, tenants(*), units(*, buildings(*)))')
  .lt('due_date', today)
  .inFilter('status', ['pending', 'partial'])
  .order('due_date', ascending: true)
  .limit(5);
```

---

## 7. Expiring Leases Detection

### Decision: Query leases with end_date within 30 days AND status = 'active'

**Rationale**: Leases with `end_date` approaching need attention for renewal or tenant departure planning.

**Query pattern**:
```dart
final today = DateTime.now();
final thirtyDaysLater = today.add(Duration(days: 30));

await _supabase
  .from('leases')
  .select('*, tenants(*), units(*, buildings(*))')
  .eq('status', 'active')
  .gte('end_date', today.toIso8601String().split('T')[0])
  .lte('end_date', thirtyDaysLater.toIso8601String().split('T')[0])
  .order('end_date', ascending: true);
```

---

## 8. Entity Design

### Decision: Create lightweight entities for dashboard-specific data

**Rationale**: Dashboard needs aggregated/derived data, not full entity details. Create purpose-built entities:
- `DashboardStats`: Holds all KPI values
- `OverdueRent`: Minimal rent schedule info for display (not full RentSchedule)
- `ExpiringLease`: Minimal lease info for display (not full Lease)

This avoids loading unnecessary data and keeps the dashboard fast.

---

## Summary of Decisions

| Topic | Decision | Key Benefit |
|-------|----------|-------------|
| Queries | Parallel with Future.wait() | 5-6x faster |
| State | FutureProvider + invalidate | Simple, effective |
| Navigation | ShellRoute | Persistent bottom nav |
| Performance | <1s target | Good UX |
| Occupancy | units.status field | No new queries needed |
| Overdue | rent_schedules filter | Leverages existing data |
| Expiring | leases filter with date range | Simple query |
| Entities | Dashboard-specific lightweight | Fast loading |
