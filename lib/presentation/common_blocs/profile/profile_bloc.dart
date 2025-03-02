import 'dart:async';

import 'package:myezzecommerce_app/presentation/common_blocs/profile/bloc.dart';
import 'package:myezzecommerce_app/data/models/models.dart';
import 'package:myezzecommerce_app/data/repository/repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthRepository _authRepository = AppRepository.authRepository;
  final UserRepository _userRepository = AppRepository.userRepository;
  final StorageRepository _storageRepository = AppRepository.storageRepository;
  StreamSubscription? _profileStreamSub;
  UserModel? _loggedUser;

  ProfileBloc() : super(ProfileLoading()) {
    on<LoadProfile>(_onLoadProfile);
    on<UploadAvatar>(_onUploadAvatar);
    on<AddressListChanged>(_onAddressListChanged);
    on<ProfileUpdated>(_onProfileUpdated);
  }

  /// Handle LoadProfile event
  Future<void> _onLoadProfile(
      LoadProfile event, Emitter<ProfileState> emit) async {
    try {
      await _profileStreamSub?.cancel();
      _profileStreamSub = _userRepository
          .loggedUserStream(_authRepository.loggedFirebaseUser)
          .listen((updatedUser) => add(ProfileUpdated(updatedUser)));
    } catch (e) {
      emit(ProfileLoadFailure(e.toString()));
    }
  }

  /// Handle UploadAvatar event
  Future<void> _onUploadAvatar(
      UploadAvatar event, Emitter<ProfileState> emit) async {
    try {
      String imageUrl = await _storageRepository.uploadImageFile(
        "users/profile/${_loggedUser!.id}",
        event.imageFile,
      );
      var updatedUser = _loggedUser!.cloneWith(avatar: imageUrl);
      await _userRepository.updateUserData(updatedUser);
    } catch (e) {
      emit(ProfileLoadFailure(e.toString()));
    }
  }

  /// Handle AddressListChanged event
  Future<void> _onAddressListChanged(
      AddressListChanged event, Emitter<ProfileState> emit) async {
    try {
      var deliveryAddress = event.deliveryAddress;
      var addresses = List<DeliveryAddressModel>.from(_loggedUser!.addresses);

      if (deliveryAddress.isDefault) {
        addresses =
            addresses.map((item) => item.cloneWith(isDefault: false)).toList();
      }

      switch (event.method) {
        case ListMethod.ADD:
          if (addresses.isEmpty) {
            deliveryAddress = deliveryAddress.cloneWith(isDefault: true);
          }
          addresses.add(deliveryAddress);
          break;
        case ListMethod.DELETE:
          addresses.remove(deliveryAddress);
          break;
        case ListMethod.UPDATE:
          addresses = addresses
              .map((item) =>
                  item.id == deliveryAddress.id ? deliveryAddress : item)
              .toList();
          break;
      }

      var updatedUser = _loggedUser!.cloneWith(addresses: addresses);
      await _userRepository.updateUserData(updatedUser);
    } catch (e) {
      emit(ProfileLoadFailure(e.toString()));
    }
  }

  /// Handle ProfileUpdated event
  void _onProfileUpdated(ProfileUpdated event, Emitter<ProfileState> emit) {
    _loggedUser = event.updatedUser;
    emit(ProfileLoaded(event.updatedUser));
  }

  @override
  Future<void> close() {
    _profileStreamSub?.cancel();
    _loggedUser = null;
    return super.close();
  }
}

enum ListMethod { ADD, DELETE, UPDATE }
