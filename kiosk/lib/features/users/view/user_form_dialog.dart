import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/windows_touch_keyboard.dart';
import '../../../widgets/onscreen_keyboard/keyboard_suppress.dart';
import '../../../widgets/onscreen_keyboard/onscreen_keyboard.dart';
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
    final phoneController = useTextEditingController(text: user?.phone ?? '');
    final imageController = useTextEditingController(text: user?.image ?? '');
    final selectedUserType = useState<String>(user?.role ?? 'user');
    final selectedStatus = useState<String>(user?.status ?? 'Active');
    final isLoading = useState(false);
    final isDialogShowing = useRef(false);
    final validationAttempted = useState(false);

    final idNumberFocusNode = useFocusNode();
    final firstNameFocusNode = useFocusNode();
    final lastNameFocusNode = useFocusNode();
    final middleNameFocusNode = useFocusNode();
    final phoneFocusNode = useFocusNode();

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

      if (!formValid) return;

      isLoading.value = true;

      try {
        final userData = User(
          id: user?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          userId: idNumberController.text.trim(),
          firstName: firstNameController.text.trim(),
          lastName: lastNameController.text.trim(),
          middleName: middleNameController.text.trim(),
          email: user?.email ?? '',
          phone: phoneController.text.trim(),
          image: imageController.text.trim(),
          systemAdmin: selectedUserType.value == 'admin',
          role: selectedUserType.value,
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
          phoneController: phoneController,
          imageController: imageController,
          selectedUserType: selectedUserType,
          selectedStatus: selectedStatus,
          validationAttempted: validationAttempted,
          isEditing: isEditing,
          handleSubmit: handleSubmit,
          handleReset: handleReset,
          isLoading: isLoading,
          idNumberFocusNode: idNumberFocusNode,
          firstNameFocusNode: firstNameFocusNode,
          lastNameFocusNode: lastNameFocusNode,
          middleNameFocusNode: middleNameFocusNode,
          phoneFocusNode: phoneFocusNode,
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
    required TextEditingController phoneController,
    required TextEditingController imageController,
    required ValueNotifier<String> selectedUserType,
    required ValueNotifier<String> selectedStatus,
    required ValueNotifier<bool> validationAttempted,
    required bool isEditing,
    required Future<void> Function() handleSubmit,
    required Future<void> Function() handleReset,
    required ValueNotifier<bool> isLoading,
    required FocusNode idNumberFocusNode,
    required FocusNode firstNameFocusNode,
    required FocusNode lastNameFocusNode,
    required FocusNode middleNameFocusNode,
    required FocusNode phoneFocusNode,
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
          ]),
          const SizedBox(height: 20),
          _buildSectionLabel(context, 'Contact Details', Icons.contact_phone_outlined),
          const SizedBox(height: 12),
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
                isPhone(message: 'Please enter a valid phone number.'),
              ],
            ).call,
          ),
          const SizedBox(height: 20),
          _buildSectionLabel(context, 'Account Settings', Icons.manage_accounts_rounded),
          const SizedBox(height: 12),
          _buildResponsiveRow(context, [
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
              value: _roleLabel(selectedUserType.value),
              items: const ['User', 'Supervisor', 'Admin'],
              onChanged: (value) => selectedUserType.value = _roleValue(value),
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

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'supervisor':
        return 'Supervisor';
      default:
        return 'User';
    }
  }

  String _roleValue(String label) {
    switch (label) {
      case 'Admin':
        return 'admin';
      case 'Supervisor':
        return 'supervisor';
      default:
        return 'user';
    }
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
                keyboardType: KeyboardSuppress.type(keyboardType),
                inputFormatters: inputFormatters,
                enabled: enabled,
                readOnly: KeyboardSuppress.readOnly,
                showCursor: KeyboardSuppress.showCursor,
                onTap: KeyboardSuppress.onTap,
                onTapOutside: (_) {
                  focusNode.unfocus();
                  OnScreenKeyboard.hide();
                  WindowsTouchKeyboard.dismiss();
                },
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
