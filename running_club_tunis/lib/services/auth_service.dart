import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _justRegistered = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get justRegistered => _justRegistered;

  void clearJustRegistered() {
    _justRegistered = false;
    notifyListeners();
  }


  Stream<UserModel?> authStateStream() async* {
    yield _currentUser;
  }

  // Login with Name and CIN (check if CIN ends with provided last 3 digits)
  Future<bool> login(String name, String cinLast3Digits) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Logic for "Visitor" bypass
      if (name.toLowerCase() == 'visitor') {
        _currentUser = UserModel(
            id: 'visitor', name: 'Visitor', cin: '', role: UserRole.visitor);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Real Firestore query
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('user')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        final userData = result.docs.first.data() as Map<String, dynamic>;
        final String dbCin = userData['cin'] ?? '';

        // Check if CIN ends with the provided last 3 digits
        if (dbCin.endsWith(cinLast3Digits)) {
          _currentUser = UserModel.fromMap(result.docs.first.id, userData);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Login error: $e");
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Register with Name and FULL 8-digit CIN
  Future<bool> register(String name, String fullCin) async {
    _isLoading = true;
    notifyListeners();

    // Validate CIN is 8 digits
    if (fullCin.length != 8 || !RegExp(r'^\d+$').hasMatch(fullCin)) {
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      // Check if user already exists by name
      final existingByName = await FirebaseFirestore.instance
          .collection('user')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (existingByName.docs.isNotEmpty) {
        _isLoading = false;
        notifyListeners();
        return false; // User with this name already exists
      }

      // Check if CIN already exists
      final existingByCin = await FirebaseFirestore.instance
          .collection('user')
          .where('cin', isEqualTo: fullCin)
          .limit(1)
          .get();

      if (existingByCin.docs.isNotEmpty) {
        _isLoading = false;
        notifyListeners();
        return false; // CIN already registered
      }

      final newUser = {
        'name': name,
        'cin': fullCin,
        'role': UserModel.roleToString(UserRole.member),
        'group': null,
        'lastReadTimestamp': FieldValue.serverTimestamp(),
      };

      final docRef =
          await FirebaseFirestore.instance.collection('user').add(newUser);

      // Auto-login after registration
      _currentUser = UserModel(
        id: docRef.id,
        name: name,
        cin: fullCin,
        role: UserRole.member,
        lastReadTimestamp: DateTime.now(),
      );

      _justRegistered = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("Registration error: $e");
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateLastReadTimestamp() async {
    if (_currentUser == null) return;

    final now = DateTime.now();
    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(_currentUser!.id)
          .update({'lastReadTimestamp': Timestamp.fromDate(now)});

      _currentUser = UserModel(
        id: _currentUser!.id,
        name: _currentUser!.name,
        cin: _currentUser!.cin,
        role: _currentUser!.role,
        group: _currentUser!.group,
        lastReadTimestamp: now,
      );
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error updating lastReadTimestamp: $e");
      }
    }
  }

  Future<void> refreshUser() async {
    if (_currentUser == null || _currentUser!.id == 'visitor') return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('user')
          .doc(_currentUser!.id)
          .get();

      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.id, doc.data()!);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error refreshing user: $e");
      }
    }
  }
}