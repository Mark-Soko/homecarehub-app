import 'package:flutter/material.dart';
import 'package:handyman_provider_flutter/components/base_scaffold_widget.dart';
import 'package:handyman_provider_flutter/main.dart';
import 'package:handyman_provider_flutter/networks/rest_apis.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../components/app_common_dialog.dart';
import '../../components/price_widget.dart';
import '../../utils/common.dart';
import '../../utils/constant.dart';
import 'wallet_history_screen.dart';

class WalletScreen extends StatefulWidget {
  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  num _balance = 0;
  bool _loadingBalance = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    setState(() => _loadingBalance = true);
    try {
      final b = await getUserWalletBalance();
      if (mounted) setState(() {
        _balance = b;
        _loadingBalance = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingBalance = false);
    }
  }

  String _idempotencyKey(String prefix) => '$prefix-${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond}';

  String _normalizePhone(String input) {
    String phone = input.trim().replaceAll(' ', '').replaceAll('-', '');
    if (phone.startsWith('+')) phone = phone.substring(1);
    if (phone.startsWith('0') && phone.length >= 10) phone = '254${phone.substring(1)}';
    if (phone.startsWith('7') && phone.length >= 9) phone = '254$phone';
    return phone;
  }

  void _showAddToWalletDialog() {
    final amountCont = TextEditingController();
    final phoneCont = TextEditingController(text: appStore.userContactNumber.validate().isNotEmpty ? appStore.userContactNumber : null);
    showInDialog(
      context,
      builder: (ctx) => AppCommonDialog(
        title: 'Add to wallet',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter amount (KES) and M-Pesa number. You will receive an STK push to pay.', style: secondaryTextStyle()),
            12.height,
            AppTextField(
              controller: amountCont,
              textFieldType: TextFieldType.NUMBER,
              decoration: inputDecoration(context, hint: 'Amount'),
            ),
            12.height,
            AppTextField(
              controller: phoneCont,
              textFieldType: TextFieldType.PHONE,
              decoration: inputDecoration(context, hint: '07XXXXXXXX or 2547XXXXXXXX'),
            ),
            20.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  text: languages.lblCancel,
                  color: context.cardColor,
                  textColor: context.iconColor,
                  onTap: () => finish(ctx),
                ).expand(),
                12.width,
                AppButton(
                  text: 'Proceed',
                  color: context.primaryColor,
                  textColor: white,
                  onTap: () async {
                    final amountStr = amountCont.text.trim();
                    final phone = phoneCont.text.trim();
                    if (amountStr.isEmpty || double.tryParse(amountStr) == null || double.parse(amountStr) <= 0) {
                      toast('Please enter a valid amount');
                      return;
                    }
                    if (phone.isEmpty) {
                      toast('Please enter M-Pesa number');
                      return;
                    }
                    finish(ctx);
                    appStore.setLoading(true);
                    try {
                      await walletDepositTuma(
                        amount: double.parse(amountStr),
                        phone: _normalizePhone(phone),
                        idempotencyKey: _idempotencyKey('dep'),
                      );
                      toast('STK Push sent. Complete payment on your phone. Balance will update after payment.');
                      _loadBalance();
                    } catch (e) {
                      final msg = e.toString().replaceFirst('Exception: ', '');
                      toast(msg.isNotEmpty ? msg : 'Something went wrong');
                    }
                    appStore.setLoading(false);
                  },
                ).expand(),
              ],
            ),
          ],
        ),
      ).paddingAll(16),
    ).whenComplete(() => appStore.setLoading(false));
  }

  void _showWithdrawDialog() {
    final amountCont = TextEditingController();
    final phoneCont = TextEditingController(text: appStore.userContactNumber.validate().isNotEmpty ? appStore.userContactNumber : null);
    showInDialog(
      context,
      builder: (ctx) => AppCommonDialog(
        title: 'Withdraw to M-Pesa',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter amount (KES) and M-Pesa number to receive the money.', style: secondaryTextStyle()),
            12.height,
            AppTextField(
              controller: amountCont,
              textFieldType: TextFieldType.NUMBER,
              decoration: inputDecoration(context, hint: 'Amount'),
            ),
            12.height,
            AppTextField(
              controller: phoneCont,
              textFieldType: TextFieldType.PHONE,
              decoration: inputDecoration(context, hint: '07XXXXXXXX or 2547XXXXXXXX'),
            ),
            20.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  text: languages.lblCancel,
                  color: context.cardColor,
                  textColor: context.iconColor,
                  onTap: () => finish(ctx),
                ).expand(),
                12.width,
                AppButton(
                  text: 'Withdraw',
                  color: context.primaryColor,
                  textColor: white,
                  onTap: () async {
                    final amountStr = amountCont.text.trim();
                    final phone = phoneCont.text.trim();
                    if (amountStr.isEmpty || double.tryParse(amountStr) == null || double.parse(amountStr) <= 0) {
                      toast('Please enter a valid amount');
                      return;
                    }
                    if (phone.isEmpty) {
                      toast('Please enter M-Pesa number');
                      return;
                    }
                    final amount = double.parse(amountStr);
                    if (amount > _balance) {
                      toast('Insufficient balance');
                      return;
                    }
                    finish(ctx);
                    appStore.setLoading(true);
                    try {
                      await walletWithdrawTuma(
                        amount: amount,
                        phone: _normalizePhone(phone),
                        idempotencyKey: _idempotencyKey('wd'),
                      );
                      toast('Withdrawal initiated. You will receive the amount on your M-Pesa.');
                      _loadBalance();
                    } catch (e) {
                      final msg = e.toString().replaceFirst('Exception: ', '');
                      toast(msg.isNotEmpty ? msg : 'Something went wrong');
                    }
                    appStore.setLoading(false);
                  },
                ).expand(),
              ],
            ),
          ],
        ),
      ).paddingAll(16),
    ).whenComplete(() => appStore.setLoading(false));
  }

  String _currentYearMonth() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

  void _showPayStatutoryDialog() {
    showInDialog(
      context,
      builder: (ctx) => _PayStatutoryDialog(
        balance: _balance.toDouble(),
        yearMonth: _currentYearMonth(),
        onSuccess: () {
          finish(ctx);
          _loadBalance();
        },
      ),
    ).whenComplete(() => appStore.setLoading(false));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: 'Wallet',
      body: RefreshIndicator(
        onRefresh: _loadBalance,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: boxDecorationWithRoundedCorners(
                  borderRadius: radius(12),
                  backgroundColor: context.primaryColor.withOpacity(0.1),
                  border: Border.all(color: context.primaryColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available balance', style: secondaryTextStyle(size: 14)),
                    8.height,
                    if (_loadingBalance)
                      SizedBox(height: 28, child: Loader())
                    else
                      PriceWidget(price: _balance, size: 22, isBoldText: true, color: context.primaryColor),
                  ],
                ),
              ),
              24.height,
              AppButton(
                text: 'Add to wallet',
                color: context.primaryColor,
                textColor: white,
                onTap: _showAddToWalletDialog,
              ),
              12.height,
              AppButton(
                text: 'Withdraw',
                color: context.cardColor,
                textColor: context.primaryColor,
                onTap: _showWithdrawDialog,
              ),
              12.height,
              AppButton(
                text: 'Pay statutory for month',
                color: context.cardColor,
                textColor: context.primaryColor,
                onTap: _showPayStatutoryDialog,
              ),
              24.height,
              OutlinedButton.icon(
                onPressed: () => WalletHistoryScreen().launch(context),
                icon: Icon(Icons.history, size: 20, color: context.primaryColor),
                label: Text(languages.lblWalletHistory, style: boldTextStyle(color: context.primaryColor)),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: context.primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayStatutoryDialog extends StatefulWidget {
  final double balance;
  final String yearMonth;
  final VoidCallback onSuccess;

  const _PayStatutoryDialog({required this.balance, required this.yearMonth, required this.onSuccess});

  @override
  State<_PayStatutoryDialog> createState() => _PayStatutoryDialogState();
}

class _PayStatutoryDialogState extends State<_PayStatutoryDialog> {
  List<Map<String, dynamic>> _types = [];
  bool _loadingTypes = true;
  int? _selectedTypeId;
  final _amountCont = TextEditingController();
  String _yearMonth = '';

  @override
  void initState() {
    super.initState();
    _yearMonth = widget.yearMonth;
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    setState(() => _loadingTypes = true);
    try {
      final list = await getStatutoryDeductionTypes(voluntaryOnly: true);
      if (mounted) setState(() {
        _types = list;
        _loadingTypes = false;
        if (list.isNotEmpty && _selectedTypeId == null) _selectedTypeId = list.first['id'] as int?;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingTypes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCommonDialog(
      title: 'Pay statutory for month',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pay from your wallet for a statutory deduction for the selected month.', style: secondaryTextStyle()),
          12.height,
          if (_loadingTypes)
            SizedBox(height: 40, child: Loader())
          else if (_types.isEmpty)
            Text('No voluntary statutory types available.', style: secondaryTextStyle())
          else ...[
            Text('Deduction type', style: boldTextStyle(size: 12)),
            4.height,
            DropdownButtonFormField<int>(
              value: _selectedTypeId,
              decoration: inputDecoration(context, hint: 'Select type'),
              items: _types.map((t) {
                final id = t['id'] as int?;
                final name = t['name'] as String? ?? 'Unknown';
                return DropdownMenuItem<int>(value: id, child: Text(name));
              }).toList(),
              onChanged: (v) => setState(() => _selectedTypeId = v),
            ),
            12.height,
            AppTextField(
              controller: _amountCont,
              textFieldType: TextFieldType.NUMBER,
              decoration: inputDecoration(context, hint: 'Amount (KES)'),
            ),
            8.height,
            Text('Month: $_yearMonth', style: secondaryTextStyle(size: 12)),
            20.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  text: languages.lblCancel,
                  color: context.cardColor,
                  textColor: context.iconColor,
                  onTap: () => finish(context),
                ).expand(),
                12.width,
                AppButton(
                  text: 'Pay',
                  color: context.primaryColor,
                  textColor: white,
                  onTap: () async {
                    if (_selectedTypeId == null) {
                      toast('Select a deduction type');
                      return;
                    }
                    final amountStr = _amountCont.text.trim();
                    if (amountStr.isEmpty || double.tryParse(amountStr) == null || double.parse(amountStr) <= 0) {
                      toast('Enter a valid amount');
                      return;
                    }
                    final amount = double.parse(amountStr);
                    if (amount > widget.balance) {
                      toast('Insufficient balance');
                      return;
                    }
                    appStore.setLoading(true);
                    try {
                      await voluntaryStatutoryPay(
                        statutoryDeductionTypeId: _selectedTypeId!,
                        amount: amount,
                        yearMonth: _yearMonth,
                      );
                      toast('Payment completed.');
                      widget.onSuccess();
                    } catch (e) {
                      final msg = e.toString().replaceFirst('Exception: ', '');
                      toast(msg.isNotEmpty ? msg : 'Payment failed');
                    }
                    appStore.setLoading(false);
                  },
                ).expand(),
              ],
            ),
          ],
        ],
      ),
    ).paddingAll(16);
  }
}
