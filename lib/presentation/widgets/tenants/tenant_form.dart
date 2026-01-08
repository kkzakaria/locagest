import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../../../domain/entities/tenant.dart';
import '../../providers/tenants_provider.dart';
import 'identity_document_section.dart';
import 'guarantor_section.dart';

/// Form widget for creating or editing a tenant
/// Supports all tenant fields including ID documents and guarantor information
class TenantForm extends ConsumerStatefulWidget {
  /// Existing tenant for edit mode, null for create mode
  final Tenant? tenant;

  /// Callback when form is successfully submitted
  final void Function(Tenant tenant)? onSuccess;

  const TenantForm({
    super.key,
    this.tenant,
    this.onSuccess,
  });

  @override
  ConsumerState<TenantForm> createState() => _TenantFormState();
}

class _TenantFormState extends ConsumerState<TenantForm> {
  final _formKey = GlobalKey<FormState>();

  // Personal info controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneSecondaryController = TextEditingController();
  final _emailController = TextEditingController();

  // Professional info controllers
  final _professionController = TextEditingController();
  final _employerController = TextEditingController();

  // Notes controller
  final _notesController = TextEditingController();

  // ID document state
  IdDocumentType? _idType;
  String? _idNumber;
  Uint8List? _idDocumentBytes;
  String? _idDocumentName;

  // Guarantor state
  String? _guarantorName;
  String? _guarantorPhone;
  Uint8List? _guarantorDocumentBytes;
  String? _guarantorDocumentName;

  // Phone duplicate warning
  List<Tenant> _duplicatePhoneWarning = [];

  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.tenant != null;

    if (_isEditMode) {
      final t = widget.tenant!;
      _firstNameController.text = t.firstName;
      _lastNameController.text = t.lastName;
      _phoneController.text = t.phone;
      _phoneSecondaryController.text = t.phoneSecondary ?? '';
      _emailController.text = t.email ?? '';
      _professionController.text = t.profession ?? '';
      _employerController.text = t.employer ?? '';
      _notesController.text = t.notes ?? '';
      _idType = t.idType;
      _idNumber = t.idNumber;
      _guarantorName = t.guarantorName;
      _guarantorPhone = t.guarantorPhone;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _phoneSecondaryController.dispose();
    _emailController.dispose();
    _professionController.dispose();
    _employerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkPhoneDuplicate(String phone) async {
    if (phone.trim().isEmpty) {
      setState(() => _duplicatePhoneWarning = []);
      return;
    }

    try {
      final duplicates = await ref.read(tenantRepositoryProvider).checkPhoneDuplicate(
        phone,
        excludeTenantId: _isEditMode ? widget.tenant!.id : null,
      );
      if (mounted) {
        setState(() => _duplicatePhoneWarning = duplicates);
      }
    } catch (e) {
      // Ignore errors in duplicate check
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isEditMode) {
      await _handleUpdate();
    } else {
      await _handleCreate();
    }
  }

  Future<void> _handleCreate() async {
    final notifier = ref.read(createTenantProvider.notifier);

    // Create a temporary ID for document uploads (will be replaced by actual ID)
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();

    // Upload ID document if selected
    String? idDocumentPath;
    if (_idDocumentBytes != null && _idDocumentName != null) {
      idDocumentPath = await notifier.uploadIdDocument(
        tempId,
        _idDocumentBytes!,
        _idDocumentName!,
      );

      // Check for upload error
      final state = ref.read(createTenantProvider);
      if (state.error != null) {
        return; // Error will be displayed by the UI
      }
    }

    // Upload guarantor document if selected
    String? guarantorIdPath;
    if (_guarantorDocumentBytes != null && _guarantorDocumentName != null) {
      guarantorIdPath = await notifier.uploadGuarantorIdDocument(
        tempId,
        _guarantorDocumentBytes!,
        _guarantorDocumentName!,
      );

      // Check for upload error
      final state = ref.read(createTenantProvider);
      if (state.error != null) {
        return; // Error will be displayed by the UI
      }
    }

    // Create the tenant
    final tenant = await notifier.createTenant(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: TenantValidators.normalizePhone(_phoneController.text.trim()),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      phoneSecondary: _phoneSecondaryController.text.trim().isEmpty
          ? null
          : TenantValidators.normalizePhone(_phoneSecondaryController.text.trim()),
      idType: _idType?.dbValue,
      idNumber: _idNumber?.trim().isEmpty == true ? null : _idNumber?.trim(),
      idDocumentUrl: idDocumentPath,
      profession: _professionController.text.trim().isEmpty ? null : _professionController.text.trim(),
      employer: _employerController.text.trim().isEmpty ? null : _employerController.text.trim(),
      guarantorName: _guarantorName?.trim().isEmpty == true ? null : _guarantorName?.trim(),
      guarantorPhone: (_guarantorPhone == null || _guarantorPhone!.trim().isEmpty)
          ? null
          : TenantValidators.normalizePhone(_guarantorPhone!.trim()),
      guarantorIdUrl: guarantorIdPath,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (tenant != null && mounted) {
      // Add to list
      ref.read(tenantsProvider.notifier).addTenant(tenant);

      // Reset form state
      notifier.reset();

      // Call success callback
      widget.onSuccess?.call(tenant);
    }
  }

  Future<void> _handleUpdate() async {
    final notifier = ref.read(editTenantProvider.notifier);
    final tenantId = widget.tenant!.id;

    // Upload new ID document if selected
    String? newIdDocumentPath;
    if (_idDocumentBytes != null && _idDocumentName != null) {
      // Delete old document if exists
      if (widget.tenant!.idDocumentUrl != null) {
        await notifier.deleteDocument(widget.tenant!.idDocumentUrl!);
      }

      newIdDocumentPath = await notifier.uploadIdDocument(
        tenantId,
        _idDocumentBytes!,
        _idDocumentName!,
      );

      // Check for upload error
      final state = ref.read(editTenantProvider);
      if (state.error != null) {
        return;
      }
    }

    // Upload new guarantor document if selected
    String? newGuarantorIdPath;
    if (_guarantorDocumentBytes != null && _guarantorDocumentName != null) {
      // Delete old document if exists
      if (widget.tenant!.guarantorIdUrl != null) {
        await notifier.deleteDocument(widget.tenant!.guarantorIdUrl!);
      }

      newGuarantorIdPath = await notifier.uploadGuarantorIdDocument(
        tenantId,
        _guarantorDocumentBytes!,
        _guarantorDocumentName!,
      );

      // Check for upload error
      final state = ref.read(editTenantProvider);
      if (state.error != null) {
        return;
      }
    }

    // Update the tenant
    final tenant = await notifier.updateTenant(
      id: tenantId,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: TenantValidators.normalizePhone(_phoneController.text.trim()),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      phoneSecondary: _phoneSecondaryController.text.trim().isEmpty
          ? null
          : TenantValidators.normalizePhone(_phoneSecondaryController.text.trim()),
      idType: _idType?.dbValue,
      idNumber: _idNumber?.trim().isEmpty == true ? null : _idNumber?.trim(),
      idDocumentUrl: newIdDocumentPath ?? widget.tenant!.idDocumentUrl,
      profession: _professionController.text.trim().isEmpty ? null : _professionController.text.trim(),
      employer: _employerController.text.trim().isEmpty ? null : _employerController.text.trim(),
      guarantorName: _guarantorName?.trim().isEmpty == true ? null : _guarantorName?.trim(),
      guarantorPhone: (_guarantorPhone == null || _guarantorPhone!.trim().isEmpty)
          ? null
          : TenantValidators.normalizePhone(_guarantorPhone!.trim()),
      guarantorIdUrl: newGuarantorIdPath ?? widget.tenant!.guarantorIdUrl,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (tenant != null && mounted) {
      // Update in list
      ref.read(tenantsProvider.notifier).updateTenant(tenant);

      // Reset form state
      notifier.reset();

      // Call success callback
      widget.onSuccess?.call(tenant);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the appropriate provider based on mode
    final bool isLoading;
    final bool isUploadingDocument;
    final String? error;

    if (_isEditMode) {
      final editState = ref.watch(editTenantProvider);
      isLoading = editState.isLoading;
      isUploadingDocument = editState.isUploadingDocument;
      error = editState.error;
    } else {
      final createState = ref.watch(createTenantProvider);
      isLoading = createState.isLoading;
      isUploadingDocument = createState.isUploadingDocument;
      error = createState.error;
    }

    final isProcessing = isLoading || isUploadingDocument;

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

          // Phone duplicate warning
          if (_duplicatePhoneWarning.isNotEmpty) ...[
            _DuplicateWarning(tenants: _duplicatePhoneWarning),
            const SizedBox(height: 16),
          ],

          // Personal Information Section
          _buildSectionHeader(context, 'Informations personnelles', Icons.person),
          const SizedBox(height: 16),

          // First name (required)
          TextFormField(
            controller: _firstNameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            enabled: !isProcessing,
            decoration: const InputDecoration(
              labelText: 'Prenom *',
              hintText: 'Jean',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: TenantValidators.validateFirstName,
          ),

          const SizedBox(height: 16),

          // Last name (required)
          TextFormField(
            controller: _lastNameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            enabled: !isProcessing,
            decoration: const InputDecoration(
              labelText: 'Nom *',
              hintText: 'Dupont',
              prefixIcon: Icon(Icons.person),
            ),
            validator: TenantValidators.validateLastName,
          ),

          const SizedBox(height: 16),

          // Phone (required)
          TextFormField(
            controller: _phoneController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.phone,
            enabled: !isProcessing,
            decoration: const InputDecoration(
              labelText: 'Telephone *',
              hintText: '07 XX XX XX XX',
              prefixIcon: Icon(Icons.phone),
            ),
            validator: TenantValidators.validatePhone,
            onChanged: _checkPhoneDuplicate,
          ),

          const SizedBox(height: 16),

          // Secondary phone (optional)
          TextFormField(
            controller: _phoneSecondaryController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.phone,
            enabled: !isProcessing,
            decoration: const InputDecoration(
              labelText: 'Telephone secondaire',
              hintText: '01 XX XX XX XX',
              prefixIcon: Icon(Icons.phone_android),
            ),
            validator: TenantValidators.validatePhoneOptional,
          ),

          const SizedBox(height: 16),

          // Email (optional)
          TextFormField(
            controller: _emailController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            enabled: !isProcessing,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'jean.dupont@email.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: TenantValidators.validateEmail,
          ),

          const SizedBox(height: 24),

          // Professional Information Section
          _buildSectionHeader(context, 'Informations professionnelles', Icons.work),
          const SizedBox(height: 16),

          // Profession (optional)
          TextFormField(
            controller: _professionController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            enabled: !isProcessing,
            decoration: const InputDecoration(
              labelText: 'Profession',
              hintText: 'Ingenieur',
              prefixIcon: Icon(Icons.work_outline),
            ),
            validator: TenantValidators.validateProfession,
          ),

          const SizedBox(height: 16),

          // Employer (optional)
          TextFormField(
            controller: _employerController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            enabled: !isProcessing,
            decoration: const InputDecoration(
              labelText: 'Employeur',
              hintText: 'Societe ABC',
              prefixIcon: Icon(Icons.business),
            ),
            validator: TenantValidators.validateEmployer,
          ),

          const SizedBox(height: 24),

          // ID Document Section
          IdentityDocumentSection(
            idType: _idType,
            idNumber: _idNumber,
            existingDocumentUrl: widget.tenant?.idDocumentUrl,
            isUploading: isUploadingDocument,
            enabled: !isProcessing,
            onIdTypeChanged: (type) => setState(() => _idType = type),
            onIdNumberChanged: (value) => _idNumber = value,
            onDocumentSelected: (bytes, name) {
              _idDocumentBytes = bytes;
              _idDocumentName = name;
            },
            onDocumentRemoved: () {
              _idDocumentBytes = null;
              _idDocumentName = null;
            },
          ),

          const SizedBox(height: 24),

          // Guarantor Section
          GuarantorSection(
            guarantorName: _guarantorName,
            guarantorPhone: _guarantorPhone,
            existingDocumentUrl: widget.tenant?.guarantorIdUrl,
            isUploading: isUploadingDocument,
            enabled: !isProcessing,
            onNameChanged: (value) => _guarantorName = value,
            onPhoneChanged: (value) => _guarantorPhone = value,
            onDocumentSelected: (bytes, name) {
              _guarantorDocumentBytes = bytes;
              _guarantorDocumentName = name;
            },
            onDocumentRemoved: () {
              _guarantorDocumentBytes = null;
              _guarantorDocumentName = null;
            },
          ),

          const SizedBox(height: 24),

          // Notes Section
          _buildSectionHeader(context, 'Notes', Icons.notes),
          const SizedBox(height: 16),

          TextFormField(
            controller: _notesController,
            textInputAction: TextInputAction.done,
            maxLines: 3,
            enabled: !isProcessing,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Informations supplementaires...',
              prefixIcon: Icon(Icons.note_add_outlined),
              alignLabelWithHint: true,
            ),
            validator: TenantValidators.validateNotes,
            onFieldSubmitted: (_) => _handleSubmit(),
          ),

          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isProcessing ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    Theme.of(context).primaryColor.withValues(alpha: 0.6),
              ),
              child: isProcessing
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
                        Text(
                          isUploadingDocument
                              ? 'Envoi du document...'
                              : 'Enregistrement...',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      _isEditMode ? 'Modifier' : 'Creer le locataire',
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

/// Phone duplicate warning widget
class _DuplicateWarning extends StatelessWidget {
  final List<Tenant> tenants;

  const _DuplicateWarning({required this.tenants});

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ce numero existe deja',
                  style: TextStyle(
                    color: Colors.orange[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ...tenants.map((t) => Text(
                  '• ${t.fullName}',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 13,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
