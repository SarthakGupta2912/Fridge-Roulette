import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_roulette/services/chef_brain.dart';

void main() {
  group('classifyDownloadError', () {
    test('connection problems become noInternet', () {
      expect(
        classifyDownloadError(
          const DownloadException(DownloadError.network('offline')),
        ),
        ChefBrainProblem.noInternet,
      );
      expect(
        classifyDownloadError(SocketException('offline')),
        ChefBrainProblem.noInternet,
      );
      expect(
        classifyDownloadError(TimeoutException('slow')),
        ChefBrainProblem.noInternet,
      );
    });

    test('server and rate limit problems become server', () {
      expect(
        classifyDownloadError(
          const DownloadException(DownloadError.serverError(503)),
        ),
        ChefBrainProblem.server,
      );
      expect(
        classifyDownloadError(
          const DownloadException(DownloadError.rateLimited()),
        ),
        ChefBrainProblem.server,
      );
    });

    test('missing or forbidden models become unavailable', () {
      expect(
        classifyDownloadError(
          const DownloadException(DownloadError.notFound()),
        ),
        ChefBrainProblem.unavailable,
      );
      expect(
        classifyDownloadError(
          const DownloadException(DownloadError.forbidden()),
        ),
        ChefBrainProblem.unavailable,
      );
    });

    test('disk problems become storage', () {
      expect(
        classifyDownloadError(
          const FileSystemException(
            'Could not write',
            'model.task',
            OSError('No space left on device', 28),
          ),
        ),
        ChefBrainProblem.storage,
      );
      expect(
        classifyDownloadError(Exception('ENOSPC')),
        ChefBrainProblem.storage,
      );
    });

    test('plugin startup problems become startup', () {
      expect(
        classifyDownloadError(PlatformException(code: 'startup')),
        ChefBrainProblem.startup,
      );
      expect(
        classifyDownloadError(MissingPluginException('missing')),
        ChefBrainProblem.startup,
      );
    });

    test('cancel and unknown are kept apart', () {
      expect(
        classifyDownloadError(
          const DownloadException(DownloadError.canceled()),
        ),
        ChefBrainProblem.cancelled,
      );
      expect(
        classifyDownloadError(Exception('something odd')),
        ChefBrainProblem.unknown,
      );
    });
  });
}
