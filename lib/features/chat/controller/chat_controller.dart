// lib/features/chat/controller/chat_controller.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/chat_message_model.dart';
import '../data/models/chat_model.dart';
import '../data/repositories/chat_repository.dart';

class ChatController extends ChangeNotifier {
  ChatController({required this.myUid, required this.chat});

  final String myUid;
  final ChatModel chat;
  final _repo = ChatRepository.instance;

  List<ChatMessage> _messages          = [];
  bool _chatExistsInDb                 = false;
  bool _loading                        = true;
  bool _sending                        = false;
  String? _error;

  // Presença do outro usuário
  bool _otherOnline                    = false;
  int? _otherLastSeen;

  List<ChatMessage> get messages       => _messages;
  bool get chatExistsInDb              => _chatExistsInDb;
  bool get loading                     => _loading;
  bool get sending                     => _sending;
  String? get error                    => _error;
  bool get otherOnline                 => _otherOnline;
  int? get otherLastSeen               => _otherLastSeen;

  StreamSubscription<List<ChatMessage>>? _msgSub;
  StreamSubscription<Map<String, dynamic>>? _presenceSub;

  Future<void> init() async {
    // Vai online
    await _repo.goOnline(myUid);

    // Subscreve presença do outro
    _presenceSub = _repo.presenceStream(chat.otherUid).listen((p) {
      _otherOnline   = p['online'] == true;
      _otherLastSeen = p['last_seen'] as int?;
      notifyListeners();
    });

    try {
      _chatExistsInDb = await _repo.chatExists(chat.chatId, myUid);
      if (_chatExistsInDb) {
        _subscribeMessages();
      } else {
        _loading = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ChatController] init error: $e');
      _chatExistsInDb = false;
      _loading        = false;
      notifyListeners();
    }
  }

  void _subscribeMessages() {
    _msgSub = _repo.messagesStream(chat.chatId).listen(
      (msgs) {
        _messages = msgs;
        _loading  = false;
        notifyListeners();
        // Marca como lido ao receber novas msgs
        _repo.markAsRead(chat.chatId, myUid);
      },
      onError: (e) {
        _error   = e.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _sending) return;
    _sending = true;
    _error   = null;
    notifyListeners();

    try {
      await _repo.sendMessage(
        chat:              chat,
        senderId:          myUid,
        text:              text.trim(),
        chatAlreadyExists: _chatExistsInDb,
      );
      if (!_chatExistsInDb) {
        _chatExistsInDb = true;
        _subscribeMessages();
      }
    } catch (e) {
      _error = 'Falha ao enviar. Tente novamente.';
      debugPrint('[ChatController] sendMessage error: $e');
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _repo.goOffline(myUid);
    _msgSub?.cancel();
    _presenceSub?.cancel();
    super.dispose();
  }
}