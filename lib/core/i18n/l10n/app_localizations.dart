import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'萌宠寄养'**
  String get appName;

  /// No description provided for @tabHome.
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get tabHome;

  /// No description provided for @tabPets.
  ///
  /// In zh, this message translates to:
  /// **'宠物'**
  String get tabPets;

  /// No description provided for @tabChat.
  ///
  /// In zh, this message translates to:
  /// **'聊天'**
  String get tabChat;

  /// No description provided for @tabMy.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get tabMy;

  /// No description provided for @tabProviderHome.
  ///
  /// In zh, this message translates to:
  /// **'看护师首页'**
  String get tabProviderHome;

  /// No description provided for @tabWorkbench.
  ///
  /// In zh, this message translates to:
  /// **'工作台'**
  String get tabWorkbench;

  /// No description provided for @loginTitle.
  ///
  /// In zh, this message translates to:
  /// **'欢迎登录'**
  String get loginTitle;

  /// No description provided for @loginPhone.
  ///
  /// In zh, this message translates to:
  /// **'手机号登录'**
  String get loginPhone;

  /// No description provided for @loginWechat.
  ///
  /// In zh, this message translates to:
  /// **'微信登录'**
  String get loginWechat;

  /// No description provided for @orderTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的订单'**
  String get orderTitle;

  /// No description provided for @orderPending.
  ///
  /// In zh, this message translates to:
  /// **'待付款'**
  String get orderPending;

  /// No description provided for @orderInProgress.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get orderInProgress;

  /// No description provided for @orderCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get orderCompleted;

  /// No description provided for @orderCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消'**
  String get orderCancelled;

  /// No description provided for @petAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加宠物'**
  String get petAdd;

  /// No description provided for @petName.
  ///
  /// In zh, this message translates to:
  /// **'宠物名称'**
  String get petName;

  /// No description provided for @petBreed.
  ///
  /// In zh, this message translates to:
  /// **'品种'**
  String get petBreed;

  /// No description provided for @walletTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的钱包'**
  String get walletTitle;

  /// No description provided for @walletBalance.
  ///
  /// In zh, this message translates to:
  /// **'余额'**
  String get walletBalance;

  /// No description provided for @walletWithdraw.
  ///
  /// In zh, this message translates to:
  /// **'提现'**
  String get walletWithdraw;

  /// No description provided for @clockinTitle.
  ///
  /// In zh, this message translates to:
  /// **'打卡'**
  String get clockinTitle;

  /// No description provided for @clockinIn.
  ///
  /// In zh, this message translates to:
  /// **'签到'**
  String get clockinIn;

  /// No description provided for @clockinOut.
  ///
  /// In zh, this message translates to:
  /// **'签退'**
  String get clockinOut;

  /// No description provided for @themeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色模式'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色模式'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeSystem;

  /// No description provided for @langZh.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get langZh;

  /// No description provided for @langEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @search.
  ///
  /// In zh, this message translates to:
  /// **'搜索附近看护师'**
  String get search;

  /// No description provided for @serviceSelect.
  ///
  /// In zh, this message translates to:
  /// **'选择服务'**
  String get serviceSelect;

  /// No description provided for @checkout.
  ///
  /// In zh, this message translates to:
  /// **'结算'**
  String get checkout;

  /// No description provided for @reviewOrder.
  ///
  /// In zh, this message translates to:
  /// **'评价订单'**
  String get reviewOrder;

  /// No description provided for @refundApply.
  ///
  /// In zh, this message translates to:
  /// **'申请退款'**
  String get refundApply;

  /// No description provided for @identityVerify.
  ///
  /// In zh, this message translates to:
  /// **'实名认证'**
  String get identityVerify;

  /// No description provided for @faceVerify.
  ///
  /// In zh, this message translates to:
  /// **'人脸识别'**
  String get faceVerify;

  /// No description provided for @insurance.
  ///
  /// In zh, this message translates to:
  /// **'宠物保险'**
  String get insurance;

  /// No description provided for @coupons.
  ///
  /// In zh, this message translates to:
  /// **'优惠券'**
  String get coupons;

  /// No description provided for @memberCenter.
  ///
  /// In zh, this message translates to:
  /// **'会员中心'**
  String get memberCenter;

  /// No description provided for @customerService.
  ///
  /// In zh, this message translates to:
  /// **'联系客服'**
  String get customerService;

  /// No description provided for @about.
  ///
  /// In zh, this message translates to:
  /// **'关于我们'**
  String get about;

  /// No description provided for @petsitterApply.
  ///
  /// In zh, this message translates to:
  /// **'申请成为看护师'**
  String get petsitterApply;

  /// No description provided for @serviceManage.
  ///
  /// In zh, this message translates to:
  /// **'服务管理'**
  String get serviceManage;

  /// No description provided for @servicePublish.
  ///
  /// In zh, this message translates to:
  /// **'发布服务'**
  String get servicePublish;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'zh':
      return SZh();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
