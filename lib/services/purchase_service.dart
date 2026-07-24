import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseService extends ChangeNotifier {
  static const productHeart5 = 'kf_can_5';
  static const productHeart20 = 'kf_can_20';
  static const productHeart50 = 'kf_can_50';
  static const productAdFree = 'kf_reklamsiz';

  static const Set<String> productIds = {
    productHeart5,
    productHeart20,
    productHeart50,
    productAdFree,
  };

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> products = <ProductDetails>[];
  bool available = false;
  bool loading = true;
  String? errorMessage;
  Future<void> Function(String productId)? onDelivered;
  Future<void>? _initializeFuture;
  bool _initialized = false;

  Future<void> initialize() {
    if (_initialized) return Future<void>.value();
    return _initializeFuture ??= _doInitialize().whenComplete(() {
      _initializeFuture = null;
    });
  }

  Future<void> _doInitialize() async {
    _subscription ??= _iap.purchaseStream.listen(
      _onPurchaseUpdates,
      onError: (Object error) {
        errorMessage = 'Satın alma güncellemesi alınamadı.';
        notifyListeners();
      },
    );

    try {
      available = await _iap.isAvailable();
      if (available) {
        final response = await _iap.queryProductDetails(productIds);
        products = response.productDetails;
        if (response.error != null) errorMessage = response.error!.message;
      }
    } catch (_) {
      available = false;
      errorMessage = 'Mağaza şu anda kullanılamıyor.';
    } finally {
      _initialized = true;
      loading = false;
      notifyListeners();
    }
  }

  Future<void> buy(String productId) async {
    if (kDebugMode && products.every((p) => p.id != productId)) {
      await onDelivered?.call(productId);
      return;
    }

    final matches = products.where((p) => p.id == productId);
    if (matches.isEmpty) {
      errorMessage = 'Bu ürün mağazada henüz tanımlı değil.';
      notifyListeners();
      return;
    }

    final param = PurchaseParam(productDetails: matches.first);
    if (productId == productAdFree) {
      await _iap.buyNonConsumable(purchaseParam: param);
    } else {
      await _iap.buyConsumable(purchaseParam: param, autoConsume: true);
    }
  }


  Future<void> restore() async {
    try {
      await _iap.restorePurchases();
    } catch (_) {
      errorMessage = 'Satın almalar geri yüklenemedi.';
      notifyListeners();
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // PRODUCTION NOTU: Canı teslim etmeden önce receipt/token sunucuda
        // doğrulanmalıdır. docs/MONETIZATION.md içindeki yayın checklist'ine bak.
        await onDelivered?.call(purchase.productID);
      } else if (purchase.status == PurchaseStatus.error) {
        errorMessage = purchase.error?.message ?? 'Satın alma başarısız oldu.';
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
    notifyListeners();
  }

  String priceFor(String id, String fallback) {
    for (final product in products) {
      if (product.id == id) return product.price;
    }
    return fallback;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
