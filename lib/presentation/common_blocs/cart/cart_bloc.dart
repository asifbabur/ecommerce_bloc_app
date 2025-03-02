import 'dart:async';

import 'package:myezzecommerce_app/presentation/common_blocs/cart/bloc.dart';
import 'package:myezzecommerce_app/data/repository/app_repository.dart';
import 'package:myezzecommerce_app/data/repository/auth_repository/auth_repo.dart';
import 'package:myezzecommerce_app/data/repository/cart_repository/cart_repo.dart';
import 'package:myezzecommerce_app/data/repository/product_repository/product_repo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final AuthRepository _authRepository = AppRepository.authRepository;
  final CartRepository _cartRepository = AppRepository.cartRepository;
  final ProductRepository _productRepository = AppRepository.productRepository;
  late User _loggedFirebaseUser;
  StreamSubscription? _fetchCartSub;

  CartBloc() : super(CartLoading()) {
    on<LoadCart>(_onLoadCart);
    on<AddCartItemModel>(_onAddCartItem);
    on<RemoveCartItemModel>(_onRemoveCartItem);
    on<UpdateCartItemModel>(_onUpdateCartItem);
    on<ClearCart>(_onClearCart);
    on<CartUpdated>(_onCartUpdated);
  }

  Future<void> _onLoadCart(LoadCart event, Emitter<CartState> emit) async {
    try {
      _fetchCartSub?.cancel();
      _loggedFirebaseUser = _authRepository.loggedFirebaseUser;
      _fetchCartSub = _cartRepository
          .fetchCart(_loggedFirebaseUser.uid)
          .listen((cart) => add(CartUpdated(cart)));
    } catch (e) {
      emit(CartLoadFailure(e.toString()));
    }
  }

  Future<void> _onAddCartItem(
      AddCartItemModel event, Emitter<CartState> emit) async {
    try {
      await _cartRepository.addCartItemModel(
          _loggedFirebaseUser.uid, event.cartItem);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _onRemoveCartItem(
      RemoveCartItemModel event, Emitter<CartState> emit) async {
    try {
      await _cartRepository.removeCartItemModel(
        _loggedFirebaseUser.uid,
        event.cartItem,
      );
    } catch (e) {
      print(e);
    }
  }

  Future<void> _onUpdateCartItem(
      UpdateCartItemModel event, Emitter<CartState> emit) async {
    try {
      await _cartRepository.updateCartItemModel(
        _loggedFirebaseUser.uid,
        event.cartItem,
      );
    } catch (e) {
      print(e);
    }
  }

  Future<void> _onClearCart(ClearCart event, Emitter<CartState> emit) async {
    try {
      await _cartRepository.clearCart(_loggedFirebaseUser.uid);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _onCartUpdated(
      CartUpdated event, Emitter<CartState> emit) async {
    emit(CartLoading());
    var updatedCart = event.updatedCart;
    var priceOfGoods = 0;

    for (var i = 0; i < updatedCart.length; i++) {
      priceOfGoods += updatedCart[i].price;
      try {
        var productInfo =
            await _productRepository.getProductById(updatedCart[i].productId);
        updatedCart[i] = updatedCart[i].cloneWith(productInfo: productInfo);
      } catch (e) {
        emit(CartLoadFailure(e.toString()));
        return;
      }
    }
    emit(CartLoaded(cart: updatedCart, priceOfGoods: priceOfGoods));
  }

  @override
  Future<void> close() {
    _fetchCartSub?.cancel();
    return super.close();
  }
}
