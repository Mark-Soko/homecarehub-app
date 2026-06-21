// ignore_for_file: must_be_immutable

import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/services/flutter_wave_service_new.dart';
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/app_common_dialog.dart';
import '../../component/base_scaffold_widget.dart';
import '../../component/empty_error_state_widget.dart';
import '../../main.dart';
import '../../model/payment_gateway_response.dart';
import '../../network/rest_apis.dart';
import '../../services/airtel_money/airtel_money_service.dart';
import '../../services/cinet_pay_services_new.dart';
import '../../services/midtrans_service.dart';
import '../../services/paypal_service.dart';
import '../../services/paystack_service.dart';
import '../../services/phone_pe/phone_pe_service.dart';
import '../../services/razorpay_service_new.dart';
import '../../services/sadad_services_new.dart';
import '../../services/stripe_service_new.dart';
import '../../utils/app_configuration.dart';
import '../../utils/colors.dart';
import '../../utils/common.dart';
import '../../utils/configs.dart';
import '../../utils/constant.dart';
import '../../utils/images.dart';

class UserWalletBalanceScreen extends StatefulWidget {
  bool isBackScreen;
  UserWalletBalanceScreen({Key? key, this.isBackScreen = false}) : super(key: key);

  @override
  State<UserWalletBalanceScreen> createState() => _UserWalletBalanceScreenState();
}

class _UserWalletBalanceScreenState extends State<UserWalletBalanceScreen> {
  Future<List<PaymentSetting>>? future;

  TextEditingController walletAmountCont = TextEditingController(text: '0');
  FocusNode walletAmountFocus = FocusNode();

  List<int> defaultAmounts = [150, 200, 500, 1000, 5000, 10000];
  PaymentSetting? currentPaymentMethod;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    future = getPaymentGateways(requireCOD: false, requireWallet: false).then((list) {
      if (list.every((e) => e.type != PAYMENT_METHOD_MPESA)) {
        list.add(PaymentSetting(title: 'M-Pesa', type: PAYMENT_METHOD_MPESA, status: 1));
      }
      return list;
    });

    appStore.setUserWalletAmount();
  }

  void _handleClick() async {
    if (currentPaymentMethod == null) {
      return toast(language.pleaseChooseAnyOnePayment);
    } else if (walletAmountCont.text.toDouble() == 0) {
      return toast(language.theAmountShouldBeEntered);
    }

    if (currentPaymentMethod!.type == PAYMENT_METHOD_STRIPE) {
      StripeServiceNew stripeServiceNew = StripeServiceNew(
        paymentSetting: currentPaymentMethod!,
        totalAmount: walletAmountCont.text.toDouble(),
        onComplete: (p0) {
          Map req = {"amount": walletAmountCont.text.toDouble(), "transaction_type": PAYMENT_METHOD_STRIPE, "transaction_id": p0['transaction_id']};

          walletTopUpApi(request: req);
        },
      );

      stripeServiceNew.stripePay().catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_RAZOR) {
      RazorPayServiceNew razorPayServiceNew = RazorPayServiceNew(
        paymentSetting: currentPaymentMethod!,
        totalAmount: walletAmountCont.text.toDouble(),
        onComplete: (p0) {
          log(p0);
          Map req = {"amount": walletAmountCont.text.toDouble(), "transaction_type": PAYMENT_METHOD_RAZOR, "transaction_id": p0['orderId']};

          walletTopUpApi(request: req);
        },
      );
      razorPayServiceNew.razorPayCheckout().catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_FLUTTER_WAVE) {
      FlutterWaveServiceNew flutterWaveServiceNew = FlutterWaveServiceNew();

      flutterWaveServiceNew.checkout(
        paymentSetting: currentPaymentMethod!,
        totalAmount: walletAmountCont.text.toDouble(),
        onComplete: (p0) {
          Map req = {"amount": walletAmountCont.text.toDouble(), "transaction_type": PAYMENT_METHOD_FLUTTER_WAVE, "transaction_id": p0['transaction_id']};

          walletTopUpApi(request: req);
        },
      );
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_CINETPAY) {
      List<String> supportedCurrencies = ["XOF", "XAF", "CDF", "GNF", "USD"];

      if (!supportedCurrencies.contains(appConfigurationStore.currencyCode)) {
        toast(language.cinetPayNotSupportedMessage);
        return;
      } else if (walletAmountCont.text.toDouble() < 100) {
        return toast('${language.totalAmountShouldBeMoreThan} ${100.toPriceFormat()}');
      } else if (walletAmountCont.text.toDouble() > 1500000) {
        return toast('${language.totalAmountShouldBeLessThan} ${1500000.toPriceFormat()}');
      }

      CinetPayServicesNew cinetPayServices = CinetPayServicesNew(
        paymentSetting: currentPaymentMethod!,
        totalAmount: walletAmountCont.text.toDouble(),
        onComplete: (p0) {
          Map req = {"amount": walletAmountCont.text.toDouble(), "transaction_type": PAYMENT_METHOD_CINETPAY, "transaction_id": p0['transaction_id']};

          walletTopUpApi(request: req);
        },
      );

      cinetPayServices.payWithCinetPay(context: context).catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_SADAD_PAYMENT) {
      SadadServicesNew sadadServices = SadadServicesNew(
        paymentSetting: currentPaymentMethod!,
        totalAmount: walletAmountCont.text.toDouble(),
        remarks: language.topUpWallet,
        onComplete: (p0) {
          Map req = {
            "amount": walletAmountCont.text.toDouble(),
            "transaction_type": PAYMENT_METHOD_SADAD_PAYMENT,
            "transaction_id": p0['transaction_id'],
          };

          walletTopUpApi(request: req);
        },
      );

      sadadServices.payWithSadad(context).catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_PAYPAL) {
      PayPalService.paypalCheckOut(
        context: context,
        paymentSetting: currentPaymentMethod!,
        totalAmount: walletAmountCont.text.toDouble(),
        onComplete: (p0) {
          log('PayPalService onComplete: $p0');
          Map req = {"amount": walletAmountCont.text.toDouble(), "transaction_type": PAYMENT_METHOD_PAYPAL, "transaction_id": p0['transaction_id']};
          walletTopUpApi(request: req);
        },
      );
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_AIRTEL) {
      showInDialog(
        context,
        contentPadding: EdgeInsets.zero,
        barrierDismissible: false,
        builder: (context) {
          return AppCommonDialog(
            title: language.airtelMoneyPayment,
            child: AirtelMoneyDialog(
              amount: walletAmountCont.text.toDouble(),
              paymentSetting: currentPaymentMethod!,
              reference: APP_NAME,
              bookingId: appStore.userId.validate().toInt(),
              onComplete: (res) {
                log('RES: $res');
                Map req = {"amount": walletAmountCont.text.toDouble(), "transaction_type": PAYMENT_METHOD_AIRTEL, "transaction_id": res['transaction_id']};
                walletTopUpApi(request: req);
              },
            ),
          );
        },
      ).then((value) => appStore.setLoading(false));
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_PAYSTACK) {
      PayStackService paystackServices = PayStackService();
      appStore.setLoading(true);
      await paystackServices.init(
        context: context,
        currentPaymentMethod: currentPaymentMethod!,
        loderOnOFF: (p0) {
          appStore.setLoading(p0);
        },
        totalAmount: walletAmountCont.text.toDouble(),
        bookingId: appStore.userId.validate().toInt(),
        onComplete: (res) {
          log('RES: $res');
          Map req = {"amount": walletAmountCont.text.toDouble(), "transaction_type": PAYMENT_METHOD_PAYSTACK, "transaction_id": res['transaction_id']};
          walletTopUpApi(request: req);
        },
      );
      await Future.delayed(const Duration(seconds: 1));
      appStore.setLoading(false);
      paystackServices.checkout().catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_MIDTRANS) {
      MidtransService midtransService = MidtransService();
      appStore.setLoading(true);
      await midtransService.initialize(
        currentPaymentMethod: currentPaymentMethod!,
        totalAmount: walletAmountCont.text.toDouble(),
        loaderOnOFF: (p0) {
          appStore.setLoading(p0);
        },
        onComplete: (res) {
          log('RES: $res');
          Map req = {"amount": walletAmountCont.text.toDouble(), "transaction_type": PAYMENT_METHOD_MIDTRANS, "transaction_id": res['transaction_id']};
          walletTopUpApi(request: req);
        },
      );
      await Future.delayed(const Duration(seconds: 1));
      appStore.setLoading(false);
      midtransService.midtransPaymentCheckout().catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_PHONEPE) {
      PhonePeServices peServices = PhonePeServices(
        paymentSetting: currentPaymentMethod!,
        totalAmount: walletAmountCont.text.toDouble(),
        onComplete: (res) {
          log('RES: $res');
          Map req = {"amount": walletAmountCont.text.toDouble(), "transaction_type": PAYMENT_METHOD_PHONEPE, "transaction_id": res['transaction_id']};
          walletTopUpApi(request: req);
        },
      );

      peServices.phonePeCheckout(context).catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_MPESA) {
      _showMpesaDepositDialog();
    }
  }

  void _showMpesaDepositDialog() {
    final phoneCont = TextEditingController(text: appStore.userContactNumber.validate().isNotEmpty ? appStore.userContactNumber : null);
    showInDialog(
      context,
      builder: (ctx) {
        return AppCommonDialog(
          title: language.mPesaPayment,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
Text(language.enterMpesaPhone, style: secondaryTextStyle()),
            8.height,
              AppTextField(
                controller: phoneCont,
                textFieldType: TextFieldType.PHONE,
                decoration: inputDecoration(context, hintText: '07XXXXXXXX or 2547XXXXXXXX'),
              ),
              16.height,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    text: language.cancel,
                    color: context.cardColor,
                    textColor: textPrimaryColorGlobal,
                    onTap: () => finish(ctx),
                  ),
                  8.width,
                  AppButton(
                    text: language.confirm,
                    color: context.primaryColor,
                    onTap: () async {
                      final phone = phoneCont.text.trim();
                      if (phone.isEmpty) {
                        toast(language.pleaseEnterMpesaPhone);
                        return;
                      }
                      String normalized = _normalizePhone(phone);
                      if (!_isValidKenyanMsisdn(normalized)) {
                        toast('Enter a valid Kenyan number e.g. 07XXXXXXXX');
                        return;
                      }
                      finish(ctx);
                      appStore.setLoading(true);
                      try {
                        final idempotencyKey = 'dep-${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond}';
                        await walletDepositTuma(
                          amount: walletAmountCont.text.toDouble(),
                          phone: normalized,
                          idempotencyKey: idempotencyKey,
                        );
                        await appStore.setUserWalletAmount();
                        toast(language.stkPushSent);
                        setState(() {});
                      } catch (e) {
                        toast(e.toString());
                      }
                      appStore.setLoading(false);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).whenComplete(() => appStore.setLoading(false));
  }

  String _normalizePhone(String input) {
    String phone = input.trim().replaceAll(' ', '').replaceAll('-', '');
    if (phone.startsWith('+')) phone = phone.substring(1);

    // 07XXXXXXXX -> 2547XXXXXXXX
    if (phone.startsWith('0') && phone.length >= 10) {
      phone = '254${phone.substring(1)}';
    }

    // 7XXXXXXXX -> 2547XXXXXXXX
    if (phone.startsWith('7') && phone.length >= 9) {
      phone = '254$phone';
    }

    return phone;
  }

  bool _isValidKenyanMsisdn(String phone) {
    return RegExp(r'^254(7|1)\d{8}$').hasMatch(phone);
  }

  String getPaymentMethodIcon(String value) {
    if (value == PAYMENT_METHOD_STRIPE) {
      return stripe_logo;
    } else if (value == PAYMENT_METHOD_RAZOR) {
      return razorpay_logo;
    } else if (value == PAYMENT_METHOD_CINETPAY) {
      return cinetpay_logo;
    } else if (value == PAYMENT_METHOD_FLUTTER_WAVE) {
      return flutter_wave_logo;
    } else if (value == PAYMENT_METHOD_SADAD_PAYMENT) {
      return "";
    } else if (value == PAYMENT_METHOD_PAYPAL) {
      return paypal_logo;
    } else if (value == PAYMENT_METHOD_AIRTEL) {
      return airtel_logo;
    } else if (value == PAYMENT_METHOD_PAYSTACK) {
      return paystack_logo;
    } else if (value == PAYMENT_METHOD_PHONEPE) {
      return phonepe_logo;
    } else if (value == PAYMENT_METHOD_MPESA) {
      return '';
    }

    return '';
  }

  walletTopUpApi({required Map request}) {
    walletTopUp(request).then((value) {
      if (widget.isBackScreen) {
        finish(context, true);
      }
    });
  }

  String _currentYearMonth() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

  void _showPayStatutoryDialog() {
    showInDialog(
      context,
      builder: (ctx) => _PayStatutoryDialog(
        balance: appStore.userWalletAmount.toDouble(),
        yearMonth: _currentYearMonth(),
        onSuccess: () {
          finish(ctx);
          appStore.setUserWalletAmount();
          setState(() {});
        },
      ),
    ).whenComplete(() => appStore.setLoading(false));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.myWallet,
      child: Stack(
        children: [
          AnimatedScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            listAnimationType: ListAnimationType.None,
            onSwipeRefresh: () {
              appStore.setUserWalletAmount();

              return 1.seconds.delay;
            },
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: context.width(),
                    padding: EdgeInsets.all(16),
                    color: context.cardColor,
                    child: Row(
                      children: [
                        Text(language.balance, style: boldTextStyle(color: context.primaryColor)).expand(),
                        Observer(builder: (context) => PriceWidget(price: appStore.userWalletAmount, size: 16, isBoldText: true, color: Colors.green)),
                      ],
                    ),
                  ),
                  8.height,
                  OutlinedButton.icon(
                    onPressed: _showPayStatutoryDialog,
                    icon: Icon(Icons.receipt_long, size: 20, color: context.primaryColor),
                    label: Text('Pay statutory for month', style: boldTextStyle(size: 14, color: context.primaryColor)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: context.primaryColor),
                    ),
                  ).paddingSymmetric(horizontal: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      16.height,
                      Text(language.topUpWallet, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                      8.height,
                      Text(language.topUpAmountQuestion, style: secondaryTextStyle()),
                      Container(
                        width: context.width(),
                        margin: EdgeInsets.symmetric(vertical: 16),
                        padding: EdgeInsets.all(16),
                        decoration: boxDecorationDefault(
                          color: walletCardColor,
                          borderRadius: radius(8),
                        ),
                        child: Column(
                          children: [
                            AppTextField(
                              textFieldType: TextFieldType.NUMBER,
                              //  textAlign: TextAlign.center,
                              controller: walletAmountCont,
                              focus: walletAmountFocus,
                              textStyle: primaryTextStyle(color: Colors.white),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onTap: () {
                                if (walletAmountCont.text == '0') {
                                  walletAmountCont.selection = TextSelection(baseOffset: 0, extentOffset: walletAmountCont.text.length);
                                }
                              },
                              decoration: InputDecoration(
                                prefixText: isCurrencyPositionLeft ? appConfigurationStore.currencySymbol + " " : '',
                                prefixStyle: primaryTextStyle(color: Colors.white),
                                suffixText: isCurrencyPositionRight ? appConfigurationStore.currencySymbol + " " : '',
                                suffixStyle: primaryTextStyle(color: Colors.white),
                              ),
                              onChanged: (p0) {
                                //
                              },
                            ),
                            24.height,
                            Wrap(
                              spacing: 30,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: List.generate(defaultAmounts.length, (index) {
                                return Container(
                                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                  decoration: boxDecorationDefault(
                                    color: defaultAmounts[index].toString() == walletAmountCont.text ? white : Colors.white12,
                                    borderRadius: radius(8),
                                    border: Border.all(color: defaultAmounts[index].toString() == walletAmountCont.text ? context.primaryColor : Colors.white12),
                                  ),
                                  child: Text(
                                    defaultAmounts[index].toString().formatNumberWithComma(),
                                    style: primaryTextStyle(color: defaultAmounts[index].toString() == walletAmountCont.text ? context.primaryColor : Colors.white),
                                  ),
                                ).onTap(() {
                                  walletAmountCont.text = defaultAmounts[index].toString();
                                  setState(() {});
                                });
                              }),
                            ),
                          ],
                        ),
                      ),
                      16.height,
                      Text(language.paymentMethod, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                      4.height,
                      Text(language.selectYourPaymentMethodToAddBalance, style: secondaryTextStyle()),
                      4.height,
                      SnapHelperWidget<List<PaymentSetting>>(
                        future: future,
                        onSuccess: (list) {
                          return AnimatedWrap(
                            itemCount: list.length,
                            listAnimationType: ListAnimationType.FadeIn,
                            fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                            spacing: 8,
                            runSpacing: 16,
                            itemBuilder: (context, index) {
                              if (list.isEmpty)
                                return NoDataWidget(
                                  title: language.lblNoPayments,
                                  imageWidget: EmptyStateWidget(),
                                );
                              PaymentSetting value = list[index];
                              if (value.status.validate() == 0) return Offstage();
                              String icon = getPaymentMethodIcon(value.type.validate());

                              return Stack(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                    child: Container(
                                      width: context.width() * 0.240,
                                      height: 60,
                                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      decoration: boxDecorationDefault(
                                        borderRadius: radius(8),
                                        border: Border.all(color: primaryColor),
                                      ),
                                      alignment: Alignment.center,
                                      child: icon.isNotEmpty ? Image.asset(icon) : Text(value.type.validate(), style: primaryTextStyle()),
                                    ).onTap(() {
                                      currentPaymentMethod = value;

                                      setState(() {});
                                    }),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      padding: currentPaymentMethod == value ? EdgeInsets.all(2) : EdgeInsets.zero,
                                      decoration: boxDecorationDefault(color: context.primaryColor),
                                      child: currentPaymentMethod == value ? Icon(Icons.done, size: 16, color: Colors.white) : Offstage(),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      100.height,
                    ],
                  ).paddingSymmetric(horizontal: 16),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: AppButton(
              width: context.width(),
              height: 16,
              color: context.primaryColor,
              text: language.proceedToTopUp,
              textStyle: boldTextStyle(color: white),
              onTap: () async {
                hideKeyboard(context);
                _handleClick();
              },
            ),
          ),
        ],
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
  late String _yearMonth;

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
              decoration: InputDecoration(border: OutlineInputBorder()),
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
              decoration: inputDecoration(context, hintText: 'Amount (KES)'),
            ),
            8.height,
            Text('Month: $_yearMonth', style: secondaryTextStyle(size: 12)),
            20.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  text: language.cancel,
                  color: context.cardColor,
                  textColor: textPrimaryColorGlobal,
                  onTap: () => finish(context),
                ).expand(),
                12.width,
                AppButton(
                  text: 'Pay',
                  color: context.primaryColor,
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
                      toast(e.toString());
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
