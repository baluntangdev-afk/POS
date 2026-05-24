import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../validation/rules/is_email.dart';
import '../../../validation/rules/is_phone.dart';
import '../../../validation/rules/is_required.dart';
import '../../../validation/validate.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/network_error_dialog.dart';
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
          showNetworkErrorDialog(context, error: error);
        },
      );
    });

    Future<void> handleReset() async {
      debugPrint('User ID ${user?.id}');
      await ref.read(modifyUserProvider.notifier).resetPin(userId: user!.id);
    }

    Future<void> handleSubmit() async {
      validationAttempted.value = true;

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
          await showNetworkErrorDialog(context, error: e);
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
        width: context.responsive.value(kiosk: 700.0, tablet: 560.0, phone: double.infinity),
        maxHeight: context.responsive.value<double>(kiosk: 900, tablet: 720, phone: 680),
        padding: EdgeInsets.all(context.responsive.value<double>(kiosk: 24, tablet: 20, phone: 16)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.elevated,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(POSRadius.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildHeader(context), Flexible(child: buildFormContent(context, padding))],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final r = context.responsive;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: r.value<double>(kiosk: 24, tablet: 20, phone: 16),
        vertical: r.value<double>(kiosk: 18, tablet: 16, phone: 14),
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: ColorSet.gradientBg,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(r.value<double>(kiosk: 10, tablet: 9, phone: 8)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(POSRadius.sm),
            ),
            child: Icon(
              isEditing ? Icons.edit_rounded : Icons.person_add_rounded,
              color: Colors.white,
              size: r.value<double>(kiosk: 22, tablet: 20, phone: 18),
            ),
          ),
          SizedBox(width: r.value<double>(kiosk: 14, tablet: 12, phone: 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit User' : 'Create New User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: r.value<double>(kiosk: 20, tablet: 18, phone: 16),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  isEditing
                      ? 'Update the employee information below'
                      : 'Fill in the details to add a new employee',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: r.value<double>(kiosk: 13, tablet: 12, phone: 11),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(POSRadius.sm),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(POSRadius.sm),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: r.value<double>(kiosk: 22, tablet: 20, phone: 18),
                ),
              ),
            ),
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
          _buildSectionLabel(context, 'Personal Information', Icons.person_outline_rounded),
          const SizedBox(height: 12),
          _buildResponsiveRow(context, [
            _buildTextField(
              context: context,
              controller: idNumberController,
              label: 'Employee ID',
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
              icon: Icons.badge_rounded,
              enabled: !isEditing,
              focusNode: idNumberFocusNode,
              validator: Validate(rules: [isRequired(message: 'Employee ID is required.')]).call,
            ),
            _buildTextField(
              context: context,
              controller: firstNameController,
              label: 'First Name',
              icon: Icons.person_rounded,
              focusNode: firstNameFocusNode,
              validator: Validate(rules: [isRequired(message: 'First name is required.')]).call,
            ),
          ]),
          const SizedBox(height: 12),
          _buildResponsiveRow(context, [
            _buildTextField(
              context: context,
              controller: middleNameController,
              label: 'Middle Name',
              icon: Icons.person_rounded,
              focusNode: middleNameFocusNode,
            ),
            _buildTextField(
              context: context,
              controller: lastNameController,
              label: 'Last Name',
              icon: Icons.person_rounded,
              focusNode: lastNameFocusNode,
              validator: Validate(rules: [isRequired(message: 'Last name is required.')]).call,
            ),
            _buildSuffixDropdown(context, selectedSuffix, validationAttempted),
          ]),
          const SizedBox(height: 20),
          _buildSectionLabel(context, 'Contact Details', Icons.contact_phone_outlined),
          const SizedBox(height: 12),
          _buildResponsiveRow(context, [
            _buildTextField(
              context: context,
              controller: emailController,
              label: 'Email',
              inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              focusNode: emailFocusNode,
              validator: Validate(
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
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              focusNode: phoneFocusNode,
              validator: Validate(
                rules: [
                  isRequired(message: 'Phone number is required.'),
                  isPhone(message: 'Please enter a valid phone number.'),
                ],
              ).call,
            ),
          ]),
          const SizedBox(height: 12),
          _buildResponsiveRow(context, [
            _buildTextField(
              context: context,
              controller: addressController,
              label: 'Address',
              icon: Icons.location_on_rounded,
              focusNode: addressFocusNode,
              validator: Validate(rules: [isRequired(message: 'Address is required.')]).call,
            ),
            _buildDatePickerField(
              context: context,
              label: 'Date of Birth',
              icon: Icons.cake_rounded,
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
          const SizedBox(height: 20),
          _buildSectionLabel(context, 'Account Settings', Icons.manage_accounts_rounded),
          const SizedBox(height: 12),
          _buildResponsiveRow(context, [
            _buildPopupMenuField(
              context: context,
              label: 'Gender',
              icon: Icons.wc_rounded,
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
                icon: Icons.toggle_on_rounded,
                selectedStatus: selectedStatus,
                validationAttempted: validationAttempted,
              ),
            _buildPopupMenuField(
              context: context,
              label: 'User Type',
              icon: Icons.security_rounded,
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

  Widget _buildSectionLabel(BuildContext context, String label, IconData icon) {
    final r = context.responsive;
    return Row(
      children: [
        Icon(icon, size: r.value<double>(kiosk: 18, tablet: 16, phone: 15), color: ColorSet.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
            fontWeight: FontWeight.w700,
            color: ColorSet.primary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: POSColors.borderSubtle)),
      ],
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

  Widget _buildResponsiveRow(BuildContext context, List<Widget> children) {
    if (context.breakpoint.isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }
    if (context.breakpoint.isTablet && children.length > 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow(children.sublist(0, 2)),
          const SizedBox(height: 12),
          _buildRow(children.sublist(2)),
        ],
      );
    }
    return _buildRow(children);
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
    final r = context.responsive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: POSColors.textSecondary,
            fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
          ),
        ),
        const SizedBox(height: 6),
        FormField<String>(
          initialValue: controller.text,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                style: TextStyle(fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13), color: POSColors.textPrimary),
                focusNode: focusNode,
                controller: controller,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                enabled: enabled,
                decoration: _inputDecoration(context, icon).copyWith(
                  errorText: field.hasError ? field.errorText : null,
                ),
                onChanged: (value) => field.didChange(value),
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
    final r = context.responsive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: POSColors.textSecondary,
            fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 13),
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
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
                  offset.dy + size.height + 4,
                  offset.dx + size.width,
                  offset.dy,
                ),
                color: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(POSRadius.md),
                ),
                menuPadding: const EdgeInsets.symmetric(vertical: 8),
                items: items
                    .map(
                      (item) => PopupMenuItem<String>(
                        value: item,
                        child: Text(
                          item.isEmpty ? 'None' : item,
                          style: TextStyle(
                            fontWeight: item == value ? FontWeight.w700 : FontWeight.normal,
                            color: item == value ? ColorSet.primary : POSColors.textPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );

              if (selected != null) onChanged(selected);
            },
            borderRadius: BorderRadius.circular(POSRadius.md),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                vertical: r.value<double>(kiosk: 12, tablet: 11, phone: 10),
              ),
              decoration: BoxDecoration(
                color: POSColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(POSRadius.md),
                border: Border.all(
                  color: errorText != null
                      ? ColorSet.danger
                      : POSColors.borderDefault,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: ColorSet.primary, size: r.value<double>(kiosk: 18, tablet: 17, phone: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 13),
                        color: isSelected ? POSColors.textPrimary : POSColors.textTertiary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: POSColors.iconSubtle,
                    size: r.value<double>(kiosk: 18, tablet: 17, phone: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: TextStyle(color: ColorSet.danger, fontSize: r.value<double>(kiosk: 12, tablet: 12, phone: 11)),
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
    final r = context.responsive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: POSColors.textSecondary,
            fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 13),
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => selectedStatus.value = isActive ? 'Cancelled' : 'Active',
            borderRadius: BorderRadius.circular(POSRadius.md),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                vertical: r.value<double>(kiosk: 12, tablet: 11, phone: 10),
              ),
              decoration: BoxDecoration(
                color: POSColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(POSRadius.md),
                border: Border.all(color: POSColors.borderDefault),
              ),
              child: Row(
                children: [
                  Icon(icon, color: ColorSet.primary, size: r.value<double>(kiosk: 18, tablet: 17, phone: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedStatus.value,
                      style: TextStyle(
                        color: isActive ? ColorSet.success : ColorSet.danger,
                        fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 13),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: r.scale(44),
                    child: Transform.scale(
                      scale: 0.85,
                      child: Switch(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        value: isActive,
                        onChanged: (value) =>
                            selectedStatus.value = value ? 'Active' : 'Cancelled',
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
      icon: Icons.short_text_rounded,
      value: selectedSuffix.value.isEmpty ? 'None' : selectedSuffix.value,
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
    final r = context.responsive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: POSColors.textSecondary,
            fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 13),
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate.value ?? DateTime(2000),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) selectedDate.value = picked;
            },
            borderRadius: BorderRadius.circular(POSRadius.md),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                vertical: r.value<double>(kiosk: 12, tablet: 11, phone: 10),
              ),
              decoration: BoxDecoration(
                color: POSColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(POSRadius.md),
                border: Border.all(
                  color: errorText != null ? ColorSet.danger : POSColors.borderDefault,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: ColorSet.primary, size: r.value<double>(kiosk: 18, tablet: 17, phone: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedDate.value != null
                          ? DateFormat('MMM dd, yyyy').format(selectedDate.value!)
                          : 'Select date',
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 13),
                        color: selectedDate.value != null
                            ? POSColors.textPrimary
                            : POSColors.textTertiary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_rounded,
                    color: POSColors.iconSubtle,
                    size: r.value<double>(kiosk: 16, tablet: 15, phone: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: TextStyle(color: ColorSet.danger, fontSize: r.value<double>(kiosk: 12, tablet: 12, phone: 11)),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration(BuildContext context, IconData icon) {
    final r = context.responsive;
    return InputDecoration(
      prefixIcon: Icon(icon, color: ColorSet.primary, size: r.value<double>(kiosk: 20, tablet: 18, phone: 16)),
      filled: true,
      fillColor: POSColors.surfaceSubtle,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(POSRadius.md),
        borderSide: const BorderSide(color: POSColors.borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(POSRadius.md),
        borderSide: const BorderSide(color: POSColors.borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(POSRadius.md),
        borderSide: const BorderSide(color: ColorSet.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(POSRadius.md),
        borderSide: const BorderSide(color: ColorSet.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(POSRadius.md),
        borderSide: const BorderSide(color: ColorSet.danger, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(POSRadius.md),
        borderSide: const BorderSide(color: POSColors.borderSubtle),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: r.value<double>(kiosk: 16, tablet: 14, phone: 14),
        vertical: r.value<double>(kiosk: 14, tablet: 12, phone: 12),
      ),
    );
  }

  Widget _buildActionButtons({
    required BuildContext context,
    required ValueNotifier<bool> isLoading,
    required Future<void> Function() handleSubmit,
    required Future<void> Function() handleReset,
  }) {
    final r = context.responsive;

    final cancelBtn = OutlinedButton(
      onPressed: isLoading.value ? null : () => Navigator.of(context).pop(),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: r.value<double>(kiosk: 14, tablet: 13, phone: 12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.md)),
        side: const BorderSide(color: POSColors.borderStrong),
        foregroundColor: POSColors.textSecondary,
      ),
      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
    );

    final submitBtn = DecoratedBox(
      decoration: BoxDecoration(
        gradient: isLoading.value
            ? null
            : const LinearGradient(
                colors: ColorSet.gradientBg,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isLoading.value ? POSColors.borderStrong : null,
        borderRadius: BorderRadius.circular(POSRadius.md),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(POSRadius.md),
        child: InkWell(
          onTap: isLoading.value ? null : handleSubmit,
          borderRadius: BorderRadius.circular(POSRadius.md),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: r.value<double>(kiosk: 14, tablet: 13, phone: 12)),
            child: Center(
              child: isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isEditing ? Icons.check_rounded : Icons.person_add_rounded,
                          color: Colors.white,
                          size: r.value<double>(kiosk: 16, tablet: 15, phone: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isEditing ? 'Update User' : 'Create User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    final resetBtn = isEditing
        ? SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: handleReset,
              icon: Icon(Icons.lock_reset_rounded, size: r.value<double>(kiosk: 16, tablet: 15, phone: 14)),
              label: const Text('Reset Pin', style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorSet.danger,
                side: BorderSide(color: ColorSet.danger.withValues(alpha: 0.5)),
                padding: EdgeInsets.symmetric(vertical: r.value<double>(kiosk: 14, tablet: 13, phone: 12)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(POSRadius.md),
                ),
              ),
            ),
          )
        : null;

    if (context.breakpoint.isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          submitBtn,
          const SizedBox(height: 10),
          if (resetBtn != null) ...[resetBtn, const SizedBox(height: 10)],
          cancelBtn,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cancelBtn),
        const SizedBox(width: 12),
        Expanded(child: submitBtn),
        if (resetBtn != null) ...[const SizedBox(width: 12), Expanded(child: resetBtn)],
      ],
    );
  }
}
