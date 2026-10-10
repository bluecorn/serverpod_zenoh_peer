/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;
import 'package:http/http.dart' as _i85jenna;
import 'package:sensor_client/src/protocol/web_door/sensor_level.dart'
    as _i63isrvn;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'protocol.dart' as _il2as5qe;

/// The web door: the phone's vibration levels, for browsers.
/// {@category Endpoint}
class EndpointLevels extends _isc.EndpointRef {
  EndpointLevels(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'levels';

  /// Each key's vibration level, once a second, while the caller listens.
  _ida.Stream<_i63isrvn.SensorLevel> levels() =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_i63isrvn.SensorLevel>,
        _i63isrvn.SensorLevel
      >('levels', 'levels', {}, {});
}

class Client extends _isc.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(_isc.MethodCallContext, Object, StackTrace)? onFailedCall,
    Function(_isc.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i85jenna.Client? httpClientOverride,
  }) : super(
         host,
         _il2as5qe.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    levels = EndpointLevels(this);
  }

  late final EndpointLevels levels;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {'levels': levels};

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {};
}
