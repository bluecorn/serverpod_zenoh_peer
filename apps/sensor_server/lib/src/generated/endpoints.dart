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
import 'package:serverpod/serverpod.dart' as _is;
import '../web_door/web_door_endpoint.dart' as _izzwlzt8;

class Endpoints extends _is.EndpointDispatch {
  @override
  void initializeEndpoints(_is.Server server) {
    var endpoints = <String, _is.Endpoint>{
      'webDoor': _izzwlzt8.WebDoorEndpoint()
        ..initialize(server, 'webDoor', null),
    };
    connectors['webDoor'] = _is.EndpointConnector(
      name: 'webDoor',
      endpoint: endpoints['webDoor']!,
      methodConnectors: {
        'readings': _is.MethodStreamConnector(
          name: 'readings',
          params: {},
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['webDoor'] as _izzwlzt8.WebDoorEndpoint).readings(
                session,
              ),
        ),
      },
    );
  }
}
