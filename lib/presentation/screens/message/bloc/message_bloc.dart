import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myezzecommerce_app/data/models/models.dart';
import 'package:myezzecommerce_app/data/repository/repository.dart';
import 'package:myezzecommerce_app/presentation/screens/message/bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

const _messagesLimit = 20;

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final StorageRepository _storageRepository = AppRepository.storageRepository;
  final AuthRepository _authRepository = AppRepository.authRepository;
  final MessageRepository _messageRepository = AppRepository.messageRepository;
  late User _loggedFirebaseUser;
  bool _hasReachedMax = false;
  StreamSubscription? _messagesStreamSubs;

  MessageBloc() : super(DisplayMessages.loading()) {
    on<LoadMessages>(_mapLoadMessagesToState);
    on<LoadPreviousMessages>(_mapLoadPreviousMessagesToState,
        transformer: _debounce());
    on<SendTextMessage>(_mapSendTextMessageToState);
    on<SendImageMessage>(_mapSendImageMessageToState);
    on<RemoveMessage>(_mapRemoveMessageToState);
    on<MessagesUpdated>(_mapMessagesUpdatedToState);
  }

  EventTransformer<T> _debounce<T>() {
    return (events, mapper) {
      return events
          .debounceTime(const Duration(milliseconds: 500))
          .switchMap(mapper);
    };
  }

  Future<void> _mapLoadMessagesToState(
      LoadMessages event, Emitter<MessageState> emit) async {
    try {
      _loggedFirebaseUser = _authRepository.loggedFirebaseUser;
      _messagesStreamSubs?.cancel();
      _messagesStreamSubs = _messageRepository
          .fetchRecentMessages(
            uid: _loggedFirebaseUser.uid,
            messagesLimit: _messagesLimit,
          )
          .listen((messages) => add(MessagesUpdated(messages)));
    } catch (e) {
      emit(DisplayMessages.error(e.toString()));
    }
  }

  Future<void> _mapLoadPreviousMessagesToState(
      LoadPreviousMessages event, Emitter<MessageState> emit) async {
    if (_hasReachedMax) return;
    try {
      List<MessageModel> messages =
          await _messageRepository.fetchPreviousMessages(
        uid: _loggedFirebaseUser.uid,
        messagesLimit: _messagesLimit,
        lastMessage: event.lastMessage,
      );
      _hasReachedMax = messages.length < _messagesLimit;
      emit(DisplayMessages.data(
        messages: messages,
        hasReachedMax: _hasReachedMax,
        isPrevious: true,
      ));
    } catch (e) {
      emit(DisplayMessages.error(e.toString()));
    }
  }

  Future<void> _mapSendTextMessageToState(
      SendTextMessage event, Emitter<MessageState> emit) async {
    try {
      var newMessage = TextMessageModel(
        text: event.text,
        id: Uuid().v1(),
        senderId: _loggedFirebaseUser.uid,
        createdAt: Timestamp.now(),
      );

      var automaticReply = await _automaticReply();
      await _messageRepository.addMessage(_loggedFirebaseUser.uid, newMessage);

      if (automaticReply) {
        await _messageRepository.addMessage(
          _loggedFirebaseUser.uid,
          automaticMessage,
        );
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _mapSendImageMessageToState(
      SendImageMessage event, Emitter<MessageState> emit) async {
    try {
      // List<String> imageUrls = [];
      // for (var image in event.images) {
      //   ByteData byteData = await image.getByteData();
      //   Uint8List imageData = byteData.buffer.asUint8List();
      //   String imageUrl = await _storageRepository.uploadImageData(
      //     "users/messages/${_loggedFirebaseUser.uid}/${image.name}",
      //     imageData,
      //   );
      //   imageUrls.add(imageUrl);
      // }
      // var newMessage = ImageMessageModel(
      //   images: imageUrls,
      //   text: event.text,
      //   id: Uuid().v1(),
      //   senderId: _loggedFirebaseUser.uid,
      //   createdAt: Timestamp.now(),
      // );
      // var automaticReply = await _automaticReply();
      // await _messageRepository.addMessage(_loggedFirebaseUser.uid, newMessage);
      // if (automaticReply) {
      //   await _messageRepository.addMessage(
      //     _loggedFirebaseUser.uid,
      //     automaticMessage,
      //   );
      // }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _mapRemoveMessageToState(
      RemoveMessage event, Emitter<MessageState> emit) async {
    try {
      await _messageRepository.removeMessage(
        _loggedFirebaseUser.uid,
        event.message,
      );
    } catch (e) {
      print(e);
    }
  }

  void _mapMessagesUpdatedToState(
      MessagesUpdated event, Emitter<MessageState> emit) {
    _hasReachedMax = event.messages.length < _messagesLimit;
    emit(DisplayMessages.data(
      messages: event.messages,
      hasReachedMax: _hasReachedMax,
      isPrevious: false,
    ));
  }

  Future<bool> _automaticReply() async {
    var lastestMessage = await _messageRepository.getLastestMessage(
      uid: _loggedFirebaseUser.uid,
    );
    return lastestMessage == null ||
        lastestMessage.createdAt
                .toDate()
                .add(const Duration(days: 1))
                .compareTo(DateTime.now()) <
            1;
  }

  @override
  Future<void> close() {
    _messagesStreamSubs?.cancel();
    return super.close();
  }
}

MessageModel automaticMessage = TextMessageModel(
  id: Uuid().v1(),
  senderId: "admin",
  text: "We will reply to your message as soon as possible",
  createdAt: Timestamp.now(),
);
