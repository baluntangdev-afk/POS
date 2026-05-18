import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../exceptions/exception_extension.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../validation/rules/is_email.dart';
import '../../../validation/rules/is_phone.dart';
import '../../../validation/rules/is_required.dart';
import '../../../validation/validate.dart';
import '../../../widgets/message_dialog.dart';
import '../entities/user.dart';
import '../state/modify_user_notifier.dart';
import '../state/user_state.dart';

class UserFormDialog extends HookConsumerWidget {
  const UserFormDialog({super.key, this.user});

  final User? user;

  bool get isEditing => user != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final idNumberController = useTextEditingController(text: user?.userId ?? '');
    final firstNameController = useTextEditingController(text: user?.firstName ?? '');
    final lastNameController = useTextEditingController(text: user?.lastName ?? '');
    final middleNameController = useTextEditingController(text: user?.middleName ?? '');
    final selectedSuffix = useState<String>(user?.suffix ?? '');
    final emailController = useTextEditingController(text: user?.email ?? '');
    final phoneController = useTextEditingController(text: user?.phone ?? '');
    final addressController = useTextEditingController(text: user?.address ?? '');
    final imageController = useTextEditingController(text: user?.image ?? '');
    final selectedUserType = useState<bool>(user?.systemAdmin ?? false);
    final selectedGender = useState<String>(user?.gender ?? '');
    final selectedStatus = useState<String>(user?.status ?? 'Active');
    final selectedDateOfBirth = useState<DateTime?>(user?.dateOfBirth);
    final isLoading = useState(false);
    final isDialogShowing = useRef(false);
    final validationAttempted = useState(false);

    // Create individual focus nodes for each text field
    final idNumberFocusNode = useFocusNode();
    final firstNameFocusNode = useFocusNode();
    final lastNameFocusNode = useFocusNode();
    final middleNameFocusNode = useFocusNode();
    final emailFocusNode = useFocusNode();
    final phoneFocusNode = useFocusNode();
    final addressFocusNode = useFocusNode();

    ref.listen(modifyUserProvider, (previous, next) {
      if (next.isLoading) {
        isDialogShowing.value = true;
        showDialog<void>(
          barrierDismissible: false,
          context: context,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
        return;
      }

      // Dismiss loading dialog only if we actually showed one
      if (isDialogShowing.value) {
        isDialogShowing.value = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
      next.whenOrNull(
        data: (result) {
          if (result case UserSuccessCreate(:final user)) {
            showMessageDialog(
              context,
              message: 'User has been created successfully.',
              type: DialogType.success,
              onPrimaryPressed: () {
                Navigator.of(context).pop();
                context.pop(user);
              },
            );
          }
          if (result case UserSuccessEdit(:final user)) {
            showMessageDialog(
              context,
              message: 'User has been updated successfully.',
              type: DialogType.success,
              onPrimaryPressed: () {
                Navigator.of(context).pop();
                context.pop(user);
              },
            );
          }
          if (result case UserSuccessReset()) {
            showMessageDialog(
              context,
              message: 'Reset pin successful.',
              type: DialogType.success,
              onPrimaryPressed: () {
                Navigator.of(context).pop();
                context.pop(user);
              },
            );
          }
        },
        error: (error, stackTrace) {
          showMessageDialog(context, message: error.message, type: DialogType.error);
        },
      );
    });

    Future<void> handleReset() async {
      debugPrint('User ID ${user?.id}');
      await ref.read(modifyUserProvider.notifier).resetPin(userId: user!.id);
    }

    Future<void> handleSubmit() async {
      // Mark that validation was attempted (triggers rebuild to show custom field errors)
      validationAttempted.value = true;

      // Validate all fields - collect all errors before returning
      final formValid = formKey.currentState!.validate();
      final genderValid = selectedGender.value.isNotEmpty;
      final dobValid = selectedDateOfBirth.value != null;

      if (!formValid || !genderValid || !dobValid) return;

      isLoading.value = true;

      try {
        final userData = User(
          id: user?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          userId: idNumberController.text.trim(),
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          middleName: middleNameController.text.trim(),
          suffix: selectedSuffix.value,
          email: emailController.text.trim(),
          phone: phoneController.text.trim(),
          image: imageController.text.trim(),
          address: addressController.text.trim(),
          gender: selectedGender.value,
          dateOfBirth: selectedDateOfBirth.value,
          systemAdmin: selectedUserType.value,
          emailVerified: user?.emailVerified ?? false,
          phoneVerified: user?.phoneVerified ?? false,
          locked: user?.locked ?? false,
          status: selectedStatus.value,
          createdAt: user?.createdAt ?? DateTime.now(),
        );
        if (isEditing) {
          await ref.read(modifyUserProvider.notifier).updateUser(userData);
          return;
        }
        await ref.read(modifyUserProvider.notifier).createUser(userData);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: ColorSet.danger));
        }
      } finally {
        isLoading.value = false;
      }
    }

    Widget buildFormContent(BuildContext context, EdgeInsets padding) {
      return SingleChildScrollView(
        padding: padding,
        child: _buildForm(
          context: context,
          formKey: formKey,
          idNumberController: idNumberController,
          firstNameController: firstNameController,
          lastNameController: lastNameController,
          middleNameController: middleNameController,
          selectedSuffix: selectedSuffix,
          emailController: emailController,
          phoneController: phoneController,
          addressController: addressController,
          imageController: imageController,
          selectedUserType: selectedUserType,
          selectedGender: selectedGender,
          selectedStatus: selectedStatus,
          selectedDateOfBirth: selectedDateOfBirth,
          validationAttempted: validationAttempted,
          isEditing: isEditing,
          handleSubmit: handleSubmit,
          handleReset: handleReset,
          isLoading: isLoading,
          idNumberFocusNode: idNumberFocusNode,
          firstNameFocusNode: firstNameFocusNode,
          lastNameFocusNode: lastNameFocusNode,
          middleNameFocusNode: middleNameFocusNode,
          emailFocusNode: emailFocusNode,
          phoneFocusNode: phoneFocusNode,
          addressFocusNode: addressFocusNode,
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: _buildLayoutContainer(
        context: context,
        width: context.responsive.scale(700),
        maxHeight: context.responsive.scale(900),
        padding: const EdgeInsets.all(24),
        buildFormContent: (context, edgeInsets) {
          return buildFormContent(context, edgeInsets);
        },
      ),
    );
  }

  Widget _buildLayoutContainer({
    required BuildContext context,
    required double width,
    required double maxHeight,
    double? maxWidth,
    required EdgeInsets padding,
    required Widget Function(BuildContext, EdgeInsets) buildFormContent,
  }) {
    return Container(
      width: width,
      constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: maxWidth ?? double.infinity),
      decoration: BoxDecoration(
        color: ColorSet.light,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildHeader(context), Flexible(child: buildFormContent(context, padding))],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: ColorSet.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEditing ? Icons.edit : Icons.person_add,
            color: ColorSet.light,
            size: context.responsive.scale(28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEditing ? 'Edit User' : 'Create New User',
              style: TextStyle(
                color: ColorSet.light,
                fontSize: context.responsive.scale(24),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: ColorSet.light, size: context.responsive.scale(28)),
          ),
        ],
      ),
    );
  }

  Widget _buildForm({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required TextEditingController idNumberController,
    required TextEditingController firstNameController,
    required TextEditingController lastNameController,
    required TextEditingController middleNameController,
    required ValueNotifier<String> selectedSuffix,
    required TextEditingController emailController,
    required TextEditingController phoneController,
    required TextEditingController addressController,
    required TextEditingController imageController,
    required ValueNotifier<bool> selectedUserType,
    required ValueNotifier<String> selectedGender,
    required ValueNotifier<String> selectedStatus,
    required ValueNotifier<DateTime?> selectedDateOfBirth,
    required ValueNotifier<bool> validationAttempted,
    required bool isEditing,
    required Future<void> Function() handleSubmit,
    required Future<void> Function() handleReset,
    required ValueNotifier<bool> isLoading,
    required FocusNode idNumberFocusNode,
    required FocusNode firstNameFocusNode,
    required FocusNode lastNameFocusNode,
    required FocusNode middleNameFocusNode,
    required FocusNode emailFocusNode,
    required FocusNode phoneFocusNode,
    required FocusNode addressFocusNode,
  }) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow([
            _buildTextField(
              context: context,
              controller: idNumberController,
              label: 'Employee ID',
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
              icon: Icons.badge,
              enabled: !isEditing,
              focusNode: idNumberFocusNode,
              validator: Validate(rules: [isRequired(message: 'Employee ID is required.')]).call,
            ),
            _buildTextField(
              context: context,
              controller: firstNameController,
              label: 'First Name',
              icon: Icons.person,
              focusNode: firstNameFocusNode,
              validator: Validate(rules: [isRequired(message: 'First name is required.')]).call,
            ),
          ]),
          const SizedBox(height: 8),
          _buildRow([
            _buildTextField(
              context: context,
              controller: middleNameController,
              label: 'Middle Name',
              icon: Icons.person,
              focusNode: middleNameFocusNode,
            ),
            _buildTextField(
              context: context,
              controller: lastNameController,
              label: 'Last Name',
              icon: Icons.person,
              focusNode: lastNameFocusNode,
              validator: Validate(rules: [isRequired(message: 'Last name is required.')]).call,
            ),
            _buildSuffixDropdown(context, selectedSuffix, validationAttempted),
          ]),
          const SizedBox(height: 8),
          _buildRow([
            _buildTextField(
              context: context,
              controller: emailController,
              label: 'Email',
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              focusNode: emailFocusNode,
              validator:
                  Validate(
                    rules: [
                      isRequired(message: 'Email is required.'),
                      isEmail(message: 'Please enter a valid email address.'),
                    ],
                  ).call,
            ),
            _buildTextField(
              context: context,
              controller: phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              focusNode: phoneFocusNode,
              validator:
                  Validate(
                    rules: [
                      isRequired(message: 'Phone number is required.'),
                      isPhone(message: 'Please enter a valid phone number.'),
                    ],
                  ).call,
            ),
          ]),
          const SizedBox(height: 8),
          _buildRow([
            _buildTextField(
              context: context,
              controller: addressController,
              label: 'Address',
              icon: Icons.location_on,
              focusNode: addressFocusNode,
              validator: Validate(rules: [isRequired(message: 'Address is required.')]).call,
            ),
            _buildDatePickerField(
              context: context,
              label: 'Date of Birth',
              icon: Icons.cake,
              selectedDate: selectedDateOfBirth,
              validator: (input) {
                final date = input.toString();
                final validator = Validate(
                  rules: [isRequired(message: 'Date of birth is required.')],
                );
                return validator(date);
              },
              validationAttempted: validationAttempted,
            ),
          ]),
          const SizedBox(height: 8),
          _buildRow([
            _buildPopupMenuField(
              context: context,
              label: 'Gender',
              icon: Icons.wc,
              value: selectedGender.value.isEmpty ? 'Select' : selectedGender.value,
              items: const ['Male', 'Female', 'Other'],
              onChanged: (value) => selectedGender.value = value,
              validator: Validate(rules: [isRequired(message: 'Gender is required.')]).call,
              validationAttempted: validationAttempted,
            ),
            if (isEditing)
              _buildStatusToggleField(
                context: context,
                label: 'Status',
                icon: Icons.toggle_on,
                selectedStatus: selectedStatus,
                validationAttempted: validationAttempted,
              ),
            _buildPopupMenuField(
              context: context,
              label: 'User Type',
              icon: Icons.security,
              value: selectedUserType.value ? 'Admin' : 'User',
              items: const ['User', 'Admin'],
              onChanged: (value) => selectedUserType.value = value == 'Admin',
              validationAttempted: validationAttempted,
            ),
          ]),
          Gap(context.responsive.scale(20)),
          _buildActionButtons(
            context: context,
            isLoading: isLoading,
            handleSubmit: handleSubmit,
            handleReset: handleReset,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<Widget> children) {
    final rowChildren = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rowChildren.add(const SizedBox(width: 12));
      rowChildren.add(Expanded(child: children[i]));
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowChildren);
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required FocusNode focusNode,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ColorSet.text,
            fontSize: context.responsive.scale(16),
          ),
        ),
        const SizedBox(height: 8),
        FormField<String>(
          initialValue: controller.text,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          builder:
              (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    style: TextStyle(fontSize: context.responsive.scale(16)),
                    focusNode: focusNode,
                    controller: controller,
                    keyboardType: keyboardType,
                    inputFormatters: inputFormatters,
                    enabled: enabled,
                    decoration: _inputDecoration(
                      context,
                      icon,
                    ).copyWith(errorText: field.hasError ? field.errorText : null),
                    onChanged: (value) {
                      field.didChange(value);
                    },
                  ),
                ],
              ),
        ),
      ],
    );
  }

  Widget _buildPopupMenuField({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
    String? Function(String?)? validator,
    required ValueNotifier<bool> validationAttempted,
  }) {
    final key = GlobalKey();
    final isSelected = items.contains(value);
    final errorText = validationAttempted.value ? validator?.call(isSelected ? value : null) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ColorSet.text,
            fontSize: context.responsive.scale(16),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          key: key,
          onTap: () async {
            final renderBox = key.currentContext!.findRenderObject()! as RenderBox;
            final offset = renderBox.localToGlobal(Offset.zero);
            final size = renderBox.size;

            if (!context.mounted) return;

            final selected = await showMenu<String>(
              context: context,
              position: RelativeRect.fromLTRB(
                offset.dx,
                offset.dy + size.height,
                offset.dx + size.width,
                offset.dy,
              ),
              color: Colors.white,
              menuPadding: const EdgeInsets.symmetric(vertical: 10),
              items:
                  items
                      .map((item) => PopupMenuItem<String>(value: item, child: Text(item)))
                      .toList(),
            );

            if (selected != null) {
              onChanged(selected);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: ColorSet.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    errorText != null ? ColorSet.danger : ColorSet.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: ColorSet.primary, size: context.responsive.scale(23)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: value.isEmpty ? ColorSet.text.withValues(alpha: 0.5) : ColorSet.text,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: ColorSet.primary),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: TextStyle(color: ColorSet.danger, fontSize: context.responsive.scale(14)),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusToggleField({
    required BuildContext context,
    required String label,
    required IconData icon,
    required ValueNotifier<String> selectedStatus,
    required ValueNotifier<bool> validationAttempted,
  }) {
    final isActive = selectedStatus.value == 'Active';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ColorSet.text,
            fontSize: context.responsive.scale(16),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            selectedStatus.value = isActive ? 'Cancelled' : 'Active';
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: context.responsive.scale(5)),
            decoration: BoxDecoration(
              color: ColorSet.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorSet.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: ColorSet.primary, size: context.responsive.scale(23)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedStatus.value,
                    style: TextStyle(
                      color: isActive ? ColorSet.success : ColorSet.danger,
                      fontSize: context.responsive.scale(16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: context.responsive.scale(50),
                  child: Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      value: isActive,
                      onChanged: (value) {
                        selectedStatus.value = value ? 'Active' : 'Cancelled';
                      },
                      activeThumbColor: ColorSet.success,
                      inactiveThumbColor: ColorSet.danger,
                      inactiveTrackColor: ColorSet.danger.withValues(alpha: 0.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuffixDropdown(
    BuildContext context,
    ValueNotifier<String> selectedSuffix,
    ValueNotifier<bool> validationAttempted,
  ) {
    return _buildPopupMenuField(
      context: context,
      label: 'Suffix',
      icon: Icons.short_text,
      value: selectedSuffix.value.isEmpty ? 'Select' : selectedSuffix.value,
      items: const ['', 'Jr.', 'Sr.', 'I', 'II', 'III', 'IV', 'V'],
      onChanged: (value) => selectedSuffix.value = value,
      validationAttempted: validationAttempted,
    );
  }

  Widget _buildDatePickerField({
    required BuildContext context,
    required String label,
    required IconData icon,
    required ValueNotifier<DateTime?> selectedDate,
    String? Function(DateTime?)? validator,
    required ValueNotifier<bool> validationAttempted,
  }) {
    final errorText = validationAttempted.value ? validator?.call(selectedDate.value) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ColorSet.text,
            fontSize: context.responsive.scale(16),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate.value ?? DateTime(2000),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              selectedDate.value = picked;
            }
          },
          child: InputDecorator(
            decoration: _inputDecoration(context, icon).copyWith(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      errorText != null ? ColorSet.danger : ColorSet.primary.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color:
                      errorText != null ? ColorSet.danger : ColorSet.primary.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: errorText != null ? ColorSet.danger : ColorSet.primary,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              selectedDate.value != null
                  ? DateFormat('MMM dd, yyyy').format(selectedDate.value!)
                  : 'Select date',
              style: TextStyle(
                fontSize: context.responsive.scale(16),
                color:
                    selectedDate.value != null
                        ? ColorSet.text
                        : ColorSet.text.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText, style: const TextStyle(color: ColorSet.danger, fontSize: 12)),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration(BuildContext context, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: ColorSet.primary, size: context.responsive.scale(23)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ColorSet.primary.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ColorSet.primary.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorSet.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorSet.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorSet.danger, width: 2),
      ),
      contentPadding: EdgeInsets.all(context.responsive.scale(16)),
    );
  }

  Widget _buildActionButtons({
    required BuildContext context,
    required ValueNotifier<bool> isLoading,
    required Future<void> Function() handleSubmit,
    required Future<void> Function() handleReset,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading.value ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: context.responsive.scale(20)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: ColorSet.primary),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(color: ColorSet.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FilledButton(
            onPressed: isLoading.value ? null : handleSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: ColorSet.primary,
              padding: EdgeInsets.symmetric(vertical: context.responsive.scale(20)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child:
                isLoading.value
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(ColorSet.light),
                      ),
                    )
                    : Text(
                      isEditing ? 'Update User' : 'Create User',
                      style: const TextStyle(color: ColorSet.light, fontWeight: FontWeight.w600),
                    ),
          ),
        ),
        if (isEditing) const SizedBox(width: 16),
        if (isEditing)
          Expanded(
            child: FilledButton(
              onPressed: handleReset,
              style: FilledButton.styleFrom(
                backgroundColor: ColorSet.danger,
                padding: EdgeInsets.symmetric(vertical: context.responsive.scale(20)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child:
                  isLoading.value
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(ColorSet.light),
                        ),
                      )
                      : const Text(
                        'Reset Pin',
                        style: TextStyle(color: ColorSet.light, fontWeight: FontWeight.w600),
                      ),
            ),
          ),
      ],
    );
  }
}
