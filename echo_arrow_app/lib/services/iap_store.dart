import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../app/economy.dart';
import '../app/profile.dart';
import 'services.dart';

/// 구글 플레이 / 앱스토어 인앱결제.
/// 스토어 상품 ID 는 `echoarrow_<Economy.products 의 id>` (예: echoarrow_coins_m). 콘솔에 같은 ID 로 등록해야 한다.
/// 스토어 연결이 안 되거나 상품이 등록 전이면: 디버그 빌드는 개발용 가짜 결제로, 출시 빌드는 실패로 처리.
class PlayStoreService implements StoreService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final Map<String, ProductDetails> _details = {};
  final Map<String, Completer<bool>> _pending = {};
  final MockStoreService _mock = MockStoreService();
  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _available = false;

  static const consumables = {'coins_s', 'coins_m', 'coins_l', 'coins_xl', 'coins_xxl', 'piggy'};
  static String storeId(String id) => 'echoarrow_$id';
  static String? localId(String storeId) => storeId.startsWith('echoarrow_') ? storeId.substring(10) : null;

  Future<void> init() async {
    _available = await _iap.isAvailable();
    if (!_available) return;
    _sub = _iap.purchaseStream.listen(_onPurchases, onError: (Object e) => Analytics.log('iap_stream_error', {'e': '$e'}));
    final res = await _iap.queryProductDetails({for (final p in Economy.products) storeId(p.id)});
    for (final d in res.productDetails) {
      final id = localId(d.id);
      if (id != null) _details[id] = d;
    }
    if (res.notFoundIDs.isNotEmpty) Analytics.log('iap_not_found', {'ids': res.notFoundIDs.join(',')});
  }

  @override
  String? priceOf(String id) => _details[id]?.price;

  @override
  Future<bool> buy(Product p) async {
    final d = _details[p.id];
    if (!_available || d == null) {
      if (kDebugMode) return _mock.buy(p);
      Analytics.log('iap_unavailable', {'id': p.id});
      return false;
    }
    Analytics.log('iap_start', {'id': p.id});
    final c = _pending[p.id] = Completer<bool>();
    final param = PurchaseParam(productDetails: d);
    final started = consumables.contains(p.id) ? await _iap.buyConsumable(purchaseParam: param) : await _iap.buyNonConsumable(purchaseParam: param);
    if (!started) {
      _pending.remove(p.id);
      return false;
    }
    return c.future.timeout(const Duration(minutes: 5), onTimeout: () => false);
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final pd in list) {
      final id = localId(pd.productID);
      final c = id == null ? null : _pending.remove(id);
      switch (pd.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // 출시 시: 영수증 서버 검증을 여기서 하면 더 안전 (pd.verificationData)
          if (id != null) {
            final product = Economy.products.where((e) => e.id == id).firstOrNull;
            if (product != null && !(pd.status == PurchaseStatus.restored && consumables.contains(id))) {
              MockStoreService.deliver(product, restored: pd.status == PurchaseStatus.restored);
              Analytics.log(pd.status == PurchaseStatus.restored ? 'iap_restored' : 'iap_success', {'id': id});
            }
          }
          c?.complete(true);
        case PurchaseStatus.error:
          Analytics.log('iap_error', {'id': id, 'e': pd.error?.message});
          c?.complete(false);
        case PurchaseStatus.canceled:
          Analytics.log('iap_cancel', {'id': id});
          c?.complete(false);
        case PurchaseStatus.pending:
          _pending[id ?? ''] = c ?? Completer<bool>();
      }
      if (pd.pendingCompletePurchase) await _iap.completePurchase(pd);
    }
    Profile.instance.save();
  }

  @override
  Future<void> restore() async {
    if (!_available) return _mock.restore();
    await _iap.restorePurchases();
  }

  void dispose() => _sub?.cancel();
}
