import 'dart:async';
import 'package:mealsense_app/services/api_service.dart';
import 'package:mealsense_app/services/session_manager.dart';
import 'package:flutter/material.dart';

/// SessionRefreshManager handles automatic token refresh
/// Refreshes token every 20 minutes (well before 24-hour expiration)
class SessionRefreshManager {
  static final SessionRefreshManager _instance = SessionRefreshManager._internal();

  Timer? _refreshTimer;
  bool _isRefreshing = false;
  static const Duration _refreshInterval = Duration(minutes: 20);

  SessionRefreshManager._internal();

  factory SessionRefreshManager() {
    return _instance;
  }

  /// Start automatic token refresh timer
  void startAutoRefresh() {
    if (_refreshTimer?.isActive ?? false) return; // Already running

    _refreshTimer = Timer.periodic(_refreshInterval, (_) async {
      await autoRefreshToken();
    });

    debugPrint('✓ Session refresh timer started (every 20 minutes)');
  }

  /// Stop automatic token refresh
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    debugPrint('✓ Session refresh timer stopped');
  }

  /// Manually refresh token with safety checks
  Future<bool> autoRefreshToken() async {
    if (_isRefreshing) return false; // Prevent concurrent refresh requests
    if (!SessionManager().isLoggedIn()) return false; // Not logged in

    _isRefreshing = true;
    try {
      final response = await ApiService.refreshToken();

      if (response['statusCode'] == 200) {
        debugPrint('✓ Token automatically refreshed');
        return true;
      } else {
        debugPrint('✗ Token refresh failed: ${response['message']}');
        // If refresh fails, clear session and force re-login
        await SessionManager().clearToken();
        return false;
      }
    } catch (e) {
      debugPrint('✗ Token refresh error: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Refresh token before it expires (call before making important API calls)
  Future<bool> refreshIfNeeded({int minutesBeforeExpiry = 5}) async {
    final sessionManager = SessionManager();

    if (!sessionManager.isLoggedIn()) {
      return false;
    }

    // Check if token is close to expiry
    final timestamp = sessionManager.getTokenTimestamp();
    if (timestamp == null) return false;

    final tokenAge = DateTime.now().millisecondsSinceEpoch - timestamp;
    final timeUntilExpiry = (24 * 60 * 60 * 1000) - tokenAge; // 24 hours in ms
    final minutesUntilExpiry = timeUntilExpiry / (60 * 1000);

    if (minutesUntilExpiry < minutesBeforeExpiry) {
      debugPrint('Token expiring soon ($minutesUntilExpiry min left), refreshing...');
      return await autoRefreshToken();
    }

    return true; // Token still valid
  }
}
