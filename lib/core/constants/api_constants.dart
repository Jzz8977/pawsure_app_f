// ──────────────────────────────────────────────────────────────────────────────
// API 基础配置
// ──────────────────────────────────────────────────────────────────────────────
class ApiConstants {
  ApiConstants._();

  // 当前激活的 Base URL（其他环境注释掉即可）
  static const String baseUrl = 'https://www.jiaweiwei.top';
  // static const String baseUrl = 'https://prod.pawsure.cn';
  // static const String baseUrl = 'http://192.168.8.7:8099';

  static const String fileBaseUrl = 'https://www.jiaweiwei.top';

  static const Duration connectTimeout = Duration(milliseconds: 200000);
  static const Duration receiveTimeout = Duration(milliseconds: 200000);

  static const String tencentMapKey = 'RQ5BZ-XHCC7-J4KXA-H2SBF-57Q7H-JBBHF';

  // 服务端响应 Header 中携带 token 的字段名
  static const String tokenHeader = 'token';
  static const String refreshTokenHeader = 'x-refresh-token';

  // 登录相关路径（响应拦截器据此判断是否需要提取 token）
  static const List<String> loginPaths = [
    AuthApi.wechatLogin,
    AuthApi.phoneLogin,
  ];
}

// ──────────────────────────────────────────────────────────────────────────────
// 前缀辅助（对应 JS 中 prefix / prefixLib / prefixTrade / prefixOrder）
// ──────────────────────────────────────────────────────────────────────────────
const String _id    = '/api/id';
const String _lib   = '/api/lib';
const String _trade = '/api/trade';
const String _order = '/api/order';

// ──────────────────────────────────────────────────────────────────────────────
// AUTH
// ──────────────────────────────────────────────────────────────────────────────
class AuthApi {
  AuthApi._();

  static const String register     = '$_id/auth/wechat/register';
  static const String wechatLogin  = '$_id/auth/wechat/login';
  static const String phoneLogin   = '$_id/auth/phone/login';
  static const String phoneGetCode = '$_id/auth/phone/getCode';
  static const String logout       = '$_id/auth/loginOut';
}

// ──────────────────────────────────────────────────────────────────────────────
// IDENTITY（实名 / 人脸）
// ──────────────────────────────────────────────────────────────────────────────
class IdentityApi {
  IdentityApi._();

  static const String status                  = '$_id/identity/status';
  static const String submitIdCard            = '$_id/identity/submit-idcard';
  static const String submitFinal             = '$_id/identity/submit-final';
  static const String ocr                     = '$_id/identity/ocr';
  static const String verification            = '$_id/auth/identity/verify';
  static const String faceVerification        = '$_id/auth/face/verify';
  static const String uploadIdCard            = '$_id/auth/identity/upload';
  static const String faceVerificationInit    = '$_id/identity/face-verification/init';
  static const String faceVerificationResult  = '$_id/identity/face-verification/result';
  static const String faceVerificationStatus  = '$_id/identity/face-verification/status';
}

// ──────────────────────────────────────────────────────────────────────────────
// HOME / SEARCH
// ──────────────────────────────────────────────────────────────────────────────
class HomeApi {
  HomeApi._();

  static const String bannerList        = '$_id/home/banners';
  static const String serviceProviders  = '$_id/home/providers';
  static const String searchSuggestions = '$_id/search/suggestions';
  static const String searchProviders   = '$_id/search/providers';
}

// ──────────────────────────────────────────────────────────────────────────────
// PROVIDER（看护师详情）
// ──────────────────────────────────────────────────────────────────────────────
class ProviderApi {
  ProviderApi._();

  static const String detail   = '$_id/providers';
  /// 用法：'${ProviderApi.reviews}'.replaceFirst('{id}', id)
  static const String reviews  = '$_id/providers/{id}/reviews';
  static const String gallery  = '$_id/providers/{id}/gallery';
  static const String favorite = '$_id/providers/{id}/favorite';
}

// ──────────────────────────────────────────────────────────────────────────────
// ORDER（订单）
// ──────────────────────────────────────────────────────────────────────────────
class OrderApi {
  OrderApi._();

  // 通用（旧）
  static const String list        = '$_order/orders';
  static const String detail      = '$_order/orders';
  static const String create      = '$_order/orders';
  static const String cancel      = '$_order/orders';
  static const String chat        = '$_order/orders';
  static const String sendMessage = '$_order/message';

  // 用户侧
  static const String userCreate           = '$_order/user/create';
  static const String userList             = '$_order/user/list';
  static const String userDetail           = '$_order/user/detail';
  static const String userCanPay           = '$_order/user/canPay';
  static const String userCancel           = '$_order/user/cancel';
  static const String userConfirmFinish    = '$_order/user/confirmFinish';
  static const String userOrderAmountDetail= '$_order/user/orderAmountDetail';
  static const String userQuerySubOrderNo  = '$_order/user/querySubOrderNo';
  static const String userRefundApply      = '$_order/user/refund/apply';

  // 服务端（看护师）侧
  static const String serverList          = '$_order/server/list';
  static const String serverAccept        = '$_order/server/accept';
  static const String serverReject        = '$_order/server/reject';
  static const String serverStartService  = '$_order/server/start-service';
  static const String serverFinishService = '$_order/server/finish-service';
  static const String serverConfirmCancel = '$_order/server/confirm-cancel';
  static const String serverRejectCancel  = '$_order/server/reject-cancel';
  static const String serverConfirmRefund = '$_order/server/confirm-refund';
  static const String serverRejectRefund  = '$_order/server/reject-refund';
}

// ──────────────────────────────────────────────────────────────────────────────
// USER
// ──────────────────────────────────────────────────────────────────────────────
class UserApi {
  UserApi._();

  static const String addresses = '$_id/user/addresses';
  static const String pets      = '$_id/user/pets';
  static const String coupons   = '$_id/user/coupons';
}

// ──────────────────────────────────────────────────────────────────────────────
// COUPON
// ──────────────────────────────────────────────────────────────────────────────
class CouponApi {
  CouponApi._();

  static const String getByUser = '$_id/coupon/getCouponsByUserId';
}

// ──────────────────────────────────────────────────────────────────────────────
// CUSTOMER（个人信息）
// ──────────────────────────────────────────────────────────────────────────────
class CustomerApi {
  CustomerApi._();

  static const String getInfo     = '$_id/customer/detailCustomerInfo';
  static const String editInfo    = '$_id/customer/updateCustomerInfo';
  static const String certified   = '$_id/customer/updateCertified';
  static const String updatePhone = '$_id/customer/updatePhone';
}

// ──────────────────────────────────────────────────────────────────────────────
// PET（宠物）
// ──────────────────────────────────────────────────────────────────────────────
class PetApi {
  PetApi._();

  static const String create      = '$_id/pet/createPetInfo';
  static const String update      = '$_id/pet/updatePetInfo';
  static const String delete      = '$_id/pet/delPetInfoList';
  static const String getById     = '$_id/pet/detailPetInfo';
  static const String pageQuery   = '$_id/pet/queryPetInfoList';
}

// ──────────────────────────────────────────────────────────────────────────────
// LIB（字典 / 轮播图 / 品种）
// ──────────────────────────────────────────────────────────────────────────────
class LibApi {
  LibApi._();

  static const String breeds        = '$_lib/breeds/listAll';
  static const String dictList      = '$_lib/dict/list';
  static const String dictBatchList = '$_lib/dict/batchList';
  static const String bannerList    = '$_lib/banner/list';
}

// ──────────────────────────────────────────────────────────────────────────────
// INSURANCE（保险）
// ──────────────────────────────────────────────────────────────────────────────
class InsuranceApi {
  InsuranceApi._();

  static const String listAll = '$_lib/insure/listAll';
}

// ──────────────────────────────────────────────────────────────────────────────
// SERVICE PROVIDER（看护师管理后台）
// ──────────────────────────────────────────────────────────────────────────────
class ServiceProviderApi {
  ServiceProviderApi._();

  static const String application   = '$_id/provider/application';
  static const String dashboard     = '$_id/provider/dashboard';
  static const String orders        = '$_id/provider/orders';
  static const String pendingOrders = '$_id/provider/orders/pending';
  static const String orderAccept   = '$_id/provider/orders/accept';
  static const String orderReject   = '$_id/provider/orders/reject';
  static const String orderComplete = '$_id/provider/orders/complete';
  static const String checkin       = '$_id/provider/checkin';
  static const String checkout      = '$_id/provider/checkout';
  static const String income        = '$_id/provider/income';
  static const String withdraw      = '$_id/provider/withdraw';
  static const String onlineStatus  = '$_id/provider/status';
  static const String profile       = '$_id/provider/profile';
}

// ──────────────────────────────────────────────────────────────────────────────
// FILE（文件上传 / 下载）
// ──────────────────────────────────────────────────────────────────────────────
class FileApi {
  FileApi._();

  static const String getLink = '$_lib/file/getLink';
}

// ──────────────────────────────────────────────────────────────────────────────
// ADDRESS（地址）
// ──────────────────────────────────────────────────────────────────────────────
class AddressApi {
  AddressApi._();

  static const String create     = '$_id/address/create';
  static const String update     = '$_id/address/update';
  static const String delete     = '$_id/address/del';
  static const String get        = '$_id/address/get';
  static const String list       = '$_id/address/list';
  static const String setDefault = '$_id/address/setDefaultAddress';
  static const String getDefault = '$_id/address/default';
}

// ──────────────────────────────────────────────────────────────────────────────
// PETSITTER（申请成为看护师）
// ──────────────────────────────────────────────────────────────────────────────
class PetsitterApi {
  PetsitterApi._();

  static const String saveOrUpdateApplication = '$_id/petsitter/saveOrUpdateApp';
  static const String queryApplication        = '$_id/petsitter/queryApplication';
  static const String queryApplicationDetail  = '$_id/petsitter/queryApplicationDetail';
  static const String withdrawApplication     = '$_id/petsitter/withdrawApplication';
  static const String submitApplication       = '$_id/petsitter/submitApplication';
  static const String updateBusCertified      = '$_id/customer/updateBusCertified';
  static const String checkServiceName        = '$_id/petsitter/checkServiceName';
}

// ──────────────────────────────────────────────────────────────────────────────
// FAVORITE（收藏）
// ──────────────────────────────────────────────────────────────────────────────
class FavoriteApi {
  FavoriteApi._();

  static const String action      = '$_id/collect/action';
  static const String page        = '$_id/collect/page';
  static const String countByType = '$_id/collect/count/by-type';
  static const String cancelBatch = '$_id/collect/cancel/batch';
}

// ──────────────────────────────────────────────────────────────────────────────
// NOTIFICATION（通知）
// ──────────────────────────────────────────────────────────────────────────────
class NotificationApi {
  NotificationApi._();

  static const String page        = '$_id/notification/page';
  static const String markRead    = '$_id/notification/read';
  static const String unreadCount = '$_id/notification/unread/count';
}

// ──────────────────────────────────────────────────────────────────────────────
// WALLET（钱包）
// ──────────────────────────────────────────────────────────────────────────────
class WalletApi {
  WalletApi._();

  static const String info            = '$_trade/wallet/info';
  static const String recharge        = '$_trade/wallet/recharge';
  static const String withdraw        = '$_trade/wallet/withdraw';
  static const String transactionList = '$_trade/record/list';     // 旧，兼容
  static const String recordPage      = '$_trade/wallet/record/page';
}

// ──────────────────────────────────────────────────────────────────────────────
// BILL（账单）
// ──────────────────────────────────────────────────────────────────────────────
class BillApi {
  BillApi._();

  static const String page = '$_trade/bill/page';
}

// ──────────────────────────────────────────────────────────────────────────────
// PROVIDER_ACCOUNT（看护师账户）
// ──────────────────────────────────────────────────────────────────────────────
class ProviderAccountApi {
  ProviderAccountApi._();

  static const String info        = '$_trade/provider/account/info';
  static const String incomePage  = '$_trade/provider/income/page';
  static const String depositPage = '$_trade/provider/deposit/page';
}

// ──────────────────────────────────────────────────────────────────────────────
// DEPOSIT（保证金）
// ──────────────────────────────────────────────────────────────────────────────
class DepositApi {
  DepositApi._();

  static const String page    = '$_trade/provider/deposit/page';
  static const String recharge = '$_trade/provider/deposit/recharge';
  static const String refund   = '$_trade/provider/deposit/refund';
}

// ──────────────────────────────────────────────────────────────────────────────
// STORED_CARD（储值卡）
// ──────────────────────────────────────────────────────────────────────────────
class StoredCardApi {
  StoredCardApi._();

  static const String list = '$_trade/storedCard/list';
}

// ──────────────────────────────────────────────────────────────────────────────
// SERVICE_PUBLISH（服务发布）
// ──────────────────────────────────────────────────────────────────────────────
class ServicePublishApi {
  ServicePublishApi._();

  static const String list                      = '$_id/servicePublish/publishList';
  static const String detail                    = '$_id/servicePublish/publishDetail';
  static const String detailAll                 = '$_id/servicePublish/publishDetailById';
  static const String draft                     = '$_id/servicePublish/draft';
  static const String submit                    = '$_id/servicePublish/submit';
  static const String unpublish                 = '$_id/servicePublish/unpublish';
  static const String availableTypes            = '$_id/servicePublish/availableServiceTypes';
  static const String applicationDetailByType   = '$_id/servicePublish/applicationDetailByServiceType';
  static const String queryApplicationDetail    = '$_id/servicePublish/queryApplicationDetail';
  static const String allPublished              = '$_id/servicePublish/allPublished';
}

// ──────────────────────────────────────────────────────────────────────────────
// PAYMENT（支付）
// ──────────────────────────────────────────────────────────────────────────────
class PaymentApi {
  PaymentApi._();

  static const String createOrder  = '$_id/payment/createOrder';
  static const String queryStatus  = '$_id/payment/queryStatus';
  static const String wechatPay    = '$_id/payment/wechatPay';
  static const String cancel       = '$_trade/pay/cancel';
  static const String refund       = '$_id/payment/refund';
  static const String refundQuery  = '$_id/payment/refund/query';
  static const String updateStatus = '$_trade/pay/mini/updateStatus';
  static const String createPay    = '$_trade/pay/create';
}

// ──────────────────────────────────────────────────────────────────────────────
// REFUND（退款）
// ──────────────────────────────────────────────────────────────────────────────
class RefundApi {
  RefundApi._();

  static const String apply    = '$_id/refund/apply';
  static const String detail   = '$_id/refund/detail';
  static const String cancel   = '$_id/refund/cancel';
  static const String progress = '$_id/refund/progress';
  static const String list     = '$_id/refund/list';
}

// ──────────────────────────────────────────────────────────────────────────────
// CHECKIN（打卡）
// ──────────────────────────────────────────────────────────────────────────────
class CheckinApi {
  CheckinApi._();

  static const String tasks          = '$_order/checkin/tasks/list';
  static const String taskDatesList  = '$_order/checkin/tasks/dates/list';
  static const String tasksDailyList = '$_order/checkin/tasks/daily/list';
  static const String submit         = '$_order/checkin/records/submit';
  static const String recordsQuery   = '$_order/checkin/records/list';
  static const String taskRecord     = '$_order/checkin/tasks/record/get';
  static const String statsOrder     = '$_order/checkin/stats/order/get';
  static const String statsProvider  = '$_order/checkin/stats/provider/get';
}

// ──────────────────────────────────────────────────────────────────────────────
// AI
// ──────────────────────────────────────────────────────────────────────────────
class AiApi {
  AiApi._();

  static const String generate    = '$_id/ai/generate';
  static const String polish      = '$_id/ai/polish';
  static const String averageTime = '$_id/ai/averageTime';
}

// ──────────────────────────────────────────────────────────────────────────────
// COMMENT（评价）
// ──────────────────────────────────────────────────────────────────────────────
class CommentApi {
  CommentApi._();

  static const String submit            = '$_order/comment/submit';
  static const String detail            = '$_order/comment/detail';
  static const String append            = '$_order/comment/append';
  static const String listByUserId      = '$_order/comment/listByUserId';
  static const String listByServerId    = '$_order/comment/listByServerId';
  static const String avgScoreByServer  = '$_order/comment/avgScoreByServerId';
  static const String pageByServerId    = '$_order/comment/pageByServerId';
}
