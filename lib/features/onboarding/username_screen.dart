import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../auth/providers.dart';

class UsernameScreen extends ConsumerStatefulWidget {
  const UsernameScreen({super.key});

  @override
  ConsumerState<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends ConsumerState<UsernameScreen> {
  final _usernameController = TextEditingController();
  bool _isValid = false;
  bool _isLoading = false;
  String? _validationMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _validate(String value) {
    final lower = value.trim().toLowerCase();
    final regex = RegExp(r'^[a-z0-9_.]{3,20}$');
    setState(() {
      if (lower.isEmpty) {
        _isValid = false;
        _validationMessage = null;
      } else if (!regex.hasMatch(lower)) {
        _isValid = false;
        _validationMessage = '3-20 karakter, sadece küçük harf, rakam, _ ve .';
      } else {
        _isValid = true;
        _validationMessage = 'Bu kullanıcı adı uygun ✓';
      }
    });
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final uid = ref.read(uidProvider);

    if (username.isEmpty || !_isValid) return;

    setState(() {
      _isLoading = true;
      _validationMessage = null;
    });

    try {
      if (uid != null) {
        await ref.read(userRepositoryProvider).claimUsername(uid, username);
      }
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValid = false;
          _validationMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    const StatusChip(
                      text: '🌱 BENZERSİZ KİMLİK',
                      tone: ChipTone.primary,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Kullanıcı Adını Seç',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkNeutral : AppColors.neutral,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Bahçe defterinde seni bu isimle tanıyacağız.',
                      style: TextStyle(fontSize: 13.sp, color: AppColors.neutralVariant),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              BloomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kullanıcı Adı',
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _usernameController,
                      onChanged: _validate,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 14.w, right: 6.w),
                          child: Center(
                            widthFactor: 0,
                            child: Text(
                              '@',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        suffixIcon: _usernameController.text.isNotEmpty
                            ? Icon(
                                _isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                color: _isValid ? AppColors.primary : AppColors.secondary,
                              )
                            : null,
                        hintText: 'deniz_yesil',
                      ),
                    ),
                    if (_validationMessage != null) ...[
                      SizedBox(height: 8.h),
                      Text(
                        _validationMessage!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: _isValid ? AppColors.primary : AppColors.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),

              PrimaryPillButton(
                text: 'Bahçeme Gir 🌱',
                isLoading: _isLoading,
                onPressed: _isValid ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
