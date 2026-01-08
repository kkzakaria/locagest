import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/building.dart';
import '../../../domain/entities/lease.dart';
import '../../../domain/entities/tenant.dart';
import '../../../domain/entities/unit.dart';
import '../../providers/buildings_provider.dart';
import '../../providers/leases_provider.dart';
import '../../providers/tenants_provider.dart';
import '../../providers/units_provider.dart';

/// Form widget for creating or editing a lease
class LeaseForm extends ConsumerStatefulWidget {
  /// Existing lease for edit mode, null for create mode
  final Lease? lease;

  /// Pre-selected unit ID (when creating from unit detail)
  final String? preselectedUnitId;

  /// Pre-selected tenant ID (when creating from tenant detail)
  final String? preselectedTenantId;

  /// Callback when form is successfully submitted
  final void Function(Lease lease)? onSuccess;

  const LeaseForm({
    super.key,
    this.lease,
    this.preselectedUnitId,
    this.preselectedTenantId,
    this.onSuccess,
  });

  @override
  ConsumerState<LeaseForm> createState() => _LeaseFormState();
}

class _LeaseFormState extends ConsumerState<LeaseForm> {
  final _formKey = GlobalKey<FormState>();

  // Selected entities
  Unit? _selectedUnit;
  Tenant? _selectedTenant;

  // Date controllers
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _hasEndDate = true;

  // Amount controllers
  final _rentAmountController = TextEditingController();
  final _chargesAmountController = TextEditingController();
  final _depositAmountController = TextEditingController();
  bool _depositPaid = false;

  // Payment day
  int _paymentDay = 1;

  // Revision settings
  bool _annualRevision = false;
  final _revisionRateController = TextEditingController();

  // Notes
  final _notesController = TextEditingController();

  // Duration
  int? _durationMonths;

  // Unit availability warning
  Lease? _existingLeaseWarning;

  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.lease != null;

    if (_isEditMode) {
      _initEditMode();
    } else {
      _initCreateMode();
    }
  }

  void _initEditMode() {
    final l = widget.lease!;
    _selectedUnit = l.unit;
    _selectedTenant = l.tenant;
    _startDate = l.startDate;
    _endDate = l.endDate;
    _hasEndDate = l.endDate != null;
    _rentAmountController.text = l.rentAmount.toStringAsFixed(0);
    _chargesAmountController.text = l.chargesAmount.toStringAsFixed(0);
    _depositAmountController.text = l.depositAmount?.toStringAsFixed(0) ?? '';
    _depositPaid = l.depositPaid;
    _paymentDay = l.paymentDay;
    _annualRevision = l.annualRevision;
    _revisionRateController.text = l.revisionRate?.toString() ?? '';
    _notesController.text = l.notes ?? '';
    _durationMonths = l.durationMonths;
  }

  void _initCreateMode() {
    // Load preselected unit or tenant if provided
    if (widget.preselectedUnitId != null) {
      _loadPreselectedUnit();
    }
    if (widget.preselectedTenantId != null) {
      _loadPreselectedTenant();
    }

    // Default charges
    _chargesAmountController.text = '0';
  }

  Future<void> _loadPreselectedUnit() async {
    try {
      final unit = await ref
          .read(unitRepositoryProvider)
          .getUnitById(widget.preselectedUnitId!);
      if (mounted) {
        setState(() => _selectedUnit = unit);
        _checkUnitAvailability(unit.id);
      }
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> _loadPreselectedTenant() async {
    try {
      final tenant = await ref
          .read(tenantRepositoryProvider)
          .getTenantById(widget.preselectedTenantId!);
      if (mounted) {
        setState(() => _selectedTenant = tenant);
      }
    } catch (e) {
      // Ignore error
    }
  }

  @override
  void dispose() {
    _rentAmountController.dispose();
    _chargesAmountController.dispose();
    _depositAmountController.dispose();
    _revisionRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkUnitAvailability(String unitId) async {
    if (_isEditMode) return; // Don't check for edit mode

    try {
      final existingLease = await ref
          .read(leaseRepositoryProvider)
          .getActiveLeaseForUnit(unitId);
      if (mounted) {
        setState(() => _existingLeaseWarning = existingLease);
      }
    } catch (e) {
      setState(() => _existingLeaseWarning = null);
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
        // Update end date if necessary
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = _startDate.add(Duration(days: 365));
        }
        _updateDurationFromDates();
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(Duration(days: 365)),
      firstDate: _startDate.add(Duration(days: 1)),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      setState(() {
        _endDate = picked;
        _updateDurationFromDates();
      });
    }
  }

  void _updateDurationFromDates() {
    if (_endDate != null) {
      final months = (_endDate!.year - _startDate.year) * 12 +
          (_endDate!.month - _startDate.month);
      _durationMonths = months > 0 ? months : 1;
    } else {
      _durationMonths = null;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedUnit == null) {
      _showError('Veuillez selectionner un lot');
      return;
    }

    if (_selectedTenant == null) {
      _showError('Veuillez selectionner un locataire');
      return;
    }

    if (_existingLeaseWarning != null && !_isEditMode) {
      final proceed = await _showConfirmDialog(
        'Ce lot a deja un bail actif. Voulez-vous continuer?',
      );
      if (!proceed) return;
    }

    if (_isEditMode) {
      await _handleUpdate();
    } else {
      await _handleCreate();
    }
  }

  Future<void> _handleCreate() async {
    final notifier = ref.read(createLeaseProvider.notifier);

    final rentAmount = double.tryParse(_rentAmountController.text) ?? 0;
    final chargesAmount = double.tryParse(_chargesAmountController.text) ?? 0;
    final depositAmount = _depositAmountController.text.isNotEmpty
        ? double.tryParse(_depositAmountController.text)
        : null;
    final revisionRate = _revisionRateController.text.isNotEmpty
        ? double.tryParse(_revisionRateController.text)
        : null;

    final lease = await notifier.createLease(
      unitId: _selectedUnit!.id,
      tenantId: _selectedTenant!.id,
      startDate: _startDate,
      endDate: _hasEndDate ? _endDate : null,
      durationMonths: _durationMonths,
      rentAmount: rentAmount,
      chargesAmount: chargesAmount,
      depositAmount: depositAmount,
      depositPaid: _depositPaid,
      paymentDay: _paymentDay,
      annualRevision: _annualRevision,
      revisionRate: revisionRate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (lease != null && mounted) {
      // Add to list
      ref.read(leasesProvider.notifier).addLease(lease);

      // Reset form state
      notifier.reset();

      // Call success callback
      widget.onSuccess?.call(lease);
    }
  }

  Future<void> _handleUpdate() async {
    final notifier = ref.read(editLeaseProvider.notifier);

    final rentAmount = double.tryParse(_rentAmountController.text);
    final chargesAmount = double.tryParse(_chargesAmountController.text);
    final depositAmount = _depositAmountController.text.isNotEmpty
        ? double.tryParse(_depositAmountController.text)
        : null;
    final revisionRate = _revisionRateController.text.isNotEmpty
        ? double.tryParse(_revisionRateController.text)
        : null;

    final lease = await notifier.updateLease(
      id: widget.lease!.id,
      endDate: _hasEndDate ? _endDate : null,
      rentAmount: rentAmount,
      chargesAmount: chargesAmount,
      depositAmount: depositAmount,
      depositPaid: _depositPaid,
      annualRevision: _annualRevision,
      revisionRate: revisionRate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (lease != null && mounted) {
      // Update in list
      ref.read(leasesProvider.notifier).updateLease(lease);

      // Reset form state
      notifier.reset();

      // Call success callback
      widget.onSuccess?.call(lease);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _showConfirmDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmation'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continuer'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading;
    final String? error;

    if (_isEditMode) {
      final editState = ref.watch(editLeaseProvider);
      isLoading = editState.isLoading;
      error = editState.error;
    } else {
      final createState = ref.watch(createLeaseProvider);
      isLoading = createState.isLoading;
      error = createState.error;
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error display
          if (error != null) ...[
            _ErrorBanner(message: error),
            const SizedBox(height: 16),
          ],

          // Unit availability warning
          if (_existingLeaseWarning != null && !_isEditMode) ...[
            _WarningBanner(
              message:
                  'Ce lot a deja un bail ${_existingLeaseWarning!.statusLabel.toLowerCase()} '
                  'avec ${_existingLeaseWarning!.tenantFullName}',
            ),
            const SizedBox(height: 16),
          ],

          // Unit Selection Section
          _buildSectionHeader(context, 'Lot', Icons.home),
          const SizedBox(height: 12),
          _buildUnitSelector(isLoading),

          const SizedBox(height: 24),

          // Tenant Selection Section
          _buildSectionHeader(context, 'Locataire', Icons.person),
          const SizedBox(height: 12),
          _buildTenantSelector(isLoading),

          const SizedBox(height: 24),

          // Dates Section
          _buildSectionHeader(context, 'Duree du bail', Icons.date_range),
          const SizedBox(height: 12),
          _buildDatesSection(isLoading),

          const SizedBox(height: 24),

          // Amounts Section
          _buildSectionHeader(context, 'Montants', Icons.payments),
          const SizedBox(height: 12),
          _buildAmountsSection(isLoading),

          const SizedBox(height: 24),

          // Payment Settings Section
          _buildSectionHeader(context, 'Parametres de paiement', Icons.settings),
          const SizedBox(height: 12),
          _buildPaymentSettingsSection(isLoading),

          const SizedBox(height: 24),

          // Notes Section
          _buildSectionHeader(context, 'Notes', Icons.notes),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            textInputAction: TextInputAction.done,
            maxLines: 3,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Informations supplementaires...',
              prefixIcon: Icon(Icons.note_add_outlined),
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    Theme.of(context).primaryColor.withValues(alpha: 0.6),
              ),
              child: isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Enregistrement...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      _isEditMode ? 'Modifier' : 'Creer le bail',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 8),

          // Required fields note
          Text(
            '* Champs obligatoires',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildUnitSelector(bool isLoading) {
    if (_isEditMode) {
      // In edit mode, show selected unit (cannot change)
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.home, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedUnit != null
                    ? _selectedUnit!.reference
                    : 'Lot non selectionne',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.lock, color: Colors.grey[400], size: 16),
          ],
        ),
      );
    }

    return _UnitDropdown(
      selectedUnit: _selectedUnit,
      enabled: !isLoading,
      onChanged: (unit) {
        setState(() => _selectedUnit = unit);
        if (unit != null) {
          _checkUnitAvailability(unit.id);
        } else {
          setState(() => _existingLeaseWarning = null);
        }
      },
    );
  }

  Widget _buildTenantSelector(bool isLoading) {
    if (_isEditMode) {
      // In edit mode, show selected tenant (cannot change)
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.person, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedTenant?.fullName ?? 'Locataire non selectionne',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.lock, color: Colors.grey[400], size: 16),
          ],
        ),
      );
    }

    return _TenantDropdown(
      selectedTenant: _selectedTenant,
      enabled: !isLoading,
      onChanged: (tenant) {
        setState(() => _selectedTenant = tenant);
      },
    );
  }

  Widget _buildDatesSection(bool isLoading) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Column(
      children: [
        // Start date
        InkWell(
          onTap: isLoading || _isEditMode ? null : _selectStartDate,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date de debut *',
              prefixIcon: const Icon(Icons.calendar_today),
              suffixIcon: _isEditMode
                  ? Icon(Icons.lock, color: Colors.grey[400], size: 16)
                  : null,
            ),
            child: Text(
              dateFormat.format(_startDate),
              style: TextStyle(
                color: _isEditMode ? Colors.grey[600] : Colors.black,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Has end date switch
        SwitchListTile(
          title: const Text('Bail a duree determinee'),
          value: _hasEndDate,
          onChanged: isLoading
              ? null
              : (value) {
                  setState(() {
                    _hasEndDate = value;
                    if (!value) {
                      _endDate = null;
                      _durationMonths = null;
                    } else {
                      _endDate = _startDate.add(Duration(days: 365));
                      _updateDurationFromDates();
                    }
                  });
                },
          contentPadding: EdgeInsets.zero,
        ),

        if (_hasEndDate) ...[
          const SizedBox(height: 16),

          // End date
          InkWell(
            onTap: isLoading ? null : _selectEndDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date de fin',
                prefixIcon: Icon(Icons.event),
              ),
              child: Text(
                _endDate != null ? dateFormat.format(_endDate!) : 'Selectionner',
              ),
            ),
          ),

          if (_durationMonths != null) ...[
            const SizedBox(height: 8),
            Text(
              'Duree: $_durationMonths mois',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildAmountsSection(bool isLoading) {
    return Column(
      children: [
        // Rent amount
        TextFormField(
          controller: _rentAmountController,
          keyboardType: TextInputType.number,
          enabled: !isLoading,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Loyer mensuel (FCFA) *',
            prefixIcon: Icon(Icons.payments),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Le loyer est obligatoire';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Montant invalide';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Charges amount
        TextFormField(
          controller: _chargesAmountController,
          keyboardType: TextInputType.number,
          enabled: !isLoading,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Charges mensuelles (FCFA)',
            prefixIcon: Icon(Icons.receipt_long),
          ),
        ),

        const SizedBox(height: 16),

        // Total display
        if (_rentAmountController.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total mensuel:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_formatFCFA(_calculateTotal())} FCFA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Deposit amount
        TextFormField(
          controller: _depositAmountController,
          keyboardType: TextInputType.number,
          enabled: !isLoading,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Caution (FCFA)',
            prefixIcon: Icon(Icons.account_balance_wallet),
          ),
        ),

        const SizedBox(height: 8),

        // Deposit paid switch
        if (_depositAmountController.text.isNotEmpty)
          SwitchListTile(
            title: const Text('Caution payee'),
            value: _depositPaid,
            onChanged: isLoading
                ? null
                : (value) => setState(() => _depositPaid = value),
            contentPadding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget _buildPaymentSettingsSection(bool isLoading) {
    return Column(
      children: [
        // Payment day
        DropdownButtonFormField<int>(
          value: _paymentDay,
          decoration: const InputDecoration(
            labelText: 'Jour de paiement',
            prefixIcon: Icon(Icons.calendar_month),
          ),
          items: List.generate(
            28,
            (index) => DropdownMenuItem(
              value: index + 1,
              child: Text('${index + 1}'),
            ),
          ),
          onChanged: isLoading
              ? null
              : (value) => setState(() => _paymentDay = value ?? 1),
        ),

        const SizedBox(height: 16),

        // Annual revision switch
        SwitchListTile(
          title: const Text('Revision annuelle'),
          subtitle: const Text('Augmentation automatique du loyer'),
          value: _annualRevision,
          onChanged: isLoading
              ? null
              : (value) => setState(() => _annualRevision = value),
          contentPadding: EdgeInsets.zero,
        ),

        if (_annualRevision) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _revisionRateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'Taux de revision (%)',
              prefixIcon: Icon(Icons.trending_up),
              hintText: '3.5',
            ),
          ),
        ],
      ],
    );
  }

  double _calculateTotal() {
    final rent = double.tryParse(_rentAmountController.text) ?? 0;
    final charges = double.tryParse(_chargesAmountController.text) ?? 0;
    return rent + charges;
  }

  String _formatFCFA(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return formatter.format(amount.round());
  }
}

/// Error banner widget
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[900]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Warning banner widget
class _WarningBanner extends StatelessWidget {
  final String message;

  const _WarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, color: Colors.orange[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.orange[900]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Unit dropdown with building selection first
class _UnitDropdown extends ConsumerStatefulWidget {
  final Unit? selectedUnit;
  final bool enabled;
  final void Function(Unit?) onChanged;

  const _UnitDropdown({
    required this.selectedUnit,
    required this.enabled,
    required this.onChanged,
  });

  @override
  ConsumerState<_UnitDropdown> createState() => _UnitDropdownState();
}

class _UnitDropdownState extends ConsumerState<_UnitDropdown> {
  List<Building> _buildings = [];
  List<Unit> _units = [];
  Building? _selectedBuilding;
  bool _isLoadingBuildings = true;
  bool _isLoadingUnits = false;

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    try {
      final buildings = await ref.read(buildingRepositoryProvider).getBuildings(limit: 100);
      if (mounted) {
        setState(() {
          _buildings = buildings;
          _isLoadingBuildings = false;
        });

        // If we have a preselected unit, find its building
        if (widget.selectedUnit != null) {
          final building = buildings.firstWhere(
            (b) => b.id == widget.selectedUnit!.buildingId,
            orElse: () => buildings.first,
          );
          _selectedBuilding = building;
          _loadUnitsForBuilding(building.id);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBuildings = false);
      }
    }
  }

  Future<void> _loadUnitsForBuilding(String buildingId) async {
    setState(() => _isLoadingUnits = true);

    try {
      final units = await ref.read(unitRepositoryProvider).getUnitsByBuilding(
        buildingId: buildingId,
        limit: 100,
      );
      if (mounted) {
        setState(() {
          _units = units.where((u) => u.status != UnitStatus.maintenance).toList();
          _isLoadingUnits = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _units = [];
          _isLoadingUnits = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingBuildings) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_buildings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Aucun immeuble disponible. Creez un immeuble d\'abord.'),
      );
    }

    return Column(
      children: [
        // Building selection
        DropdownButtonFormField<Building>(
          value: _selectedBuilding,
          decoration: const InputDecoration(
            labelText: 'Immeuble *',
            prefixIcon: Icon(Icons.business),
          ),
          items: _buildings.map((building) {
            return DropdownMenuItem<Building>(
              value: building,
              child: Text(
                building.name,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: widget.enabled ? (building) {
            setState(() {
              _selectedBuilding = building;
              _units = [];
              widget.onChanged(null); // Reset unit selection
            });
            if (building != null) {
              _loadUnitsForBuilding(building.id);
            }
          } : null,
          validator: (value) {
            if (value == null) {
              return 'Veuillez selectionner un immeuble';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Unit selection
        if (_selectedBuilding != null) ...[
          if (_isLoadingUnits)
            const Center(child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ))
          else if (_units.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Aucun lot disponible dans cet immeuble.'),
            )
          else
            DropdownButtonFormField<Unit>(
              value: widget.selectedUnit,
              decoration: const InputDecoration(
                labelText: 'Lot *',
                prefixIcon: Icon(Icons.home),
              ),
              items: _units.map((unit) {
                return DropdownMenuItem<Unit>(
                  value: unit,
                  child: Text(
                    '${unit.reference} - ${unit.statusLabel}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: widget.enabled ? widget.onChanged : null,
              validator: (value) {
                if (value == null) {
                  return 'Veuillez selectionner un lot';
                }
                return null;
              },
            ),
        ],
      ],
    );
  }
}

/// Tenant dropdown with search
class _TenantDropdown extends ConsumerStatefulWidget {
  final Tenant? selectedTenant;
  final bool enabled;
  final void Function(Tenant?) onChanged;

  const _TenantDropdown({
    required this.selectedTenant,
    required this.enabled,
    required this.onChanged,
  });

  @override
  ConsumerState<_TenantDropdown> createState() => _TenantDropdownState();
}

class _TenantDropdownState extends ConsumerState<_TenantDropdown> {
  List<Tenant> _tenants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    try {
      final tenants = await ref.read(tenantRepositoryProvider).getTenants(limit: 100);
      if (mounted) {
        setState(() {
          _tenants = tenants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tenants.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Aucun locataire disponible'),
      );
    }

    return DropdownButtonFormField<Tenant>(
      value: widget.selectedTenant,
      decoration: const InputDecoration(
        labelText: 'Selectionner un locataire *',
        prefixIcon: Icon(Icons.person),
      ),
      items: _tenants.map((tenant) {
        return DropdownMenuItem<Tenant>(
          value: tenant,
          child: Text(
            tenant.fullName,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: widget.enabled ? widget.onChanged : null,
      validator: (value) {
        if (value == null) {
          return 'Veuillez selectionner un locataire';
        }
        return null;
      },
    );
  }
}
