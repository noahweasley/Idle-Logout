import 'dart:async';

/// Signature for callbacks that have no arguments and return a [bool] or a
/// [Future<bool>].
///
/// This allows both synchronous and asynchronous implementations.
typedef AsyncOrBoolGetter = FutureOr<bool> Function();
