// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:test/test.dart';

import '../../../lsp/code_actions_abstract.dart';

abstract class RefactoringTest extends AbstractCodeActionsTest {
  /// Position of the marker where the refactor will be invoked.
  late Position _position;

  /// A map of file paths to their current content.
  ///
  /// Methods like [executeRefactor] will update this as workspace edits are
  /// sent from the server back to the client.
  Map<String, String> content = {};

  /// Return the title of the refactoring command that is expected to be
  /// available.
  String get refactoringName;

  void addSource(String filePath, String code) {
    content[filePath] = code;
    newFile(filePath, code);
  }

  void addTestSource(String markedCode) {
    _position = positionFromMarker(markedCode);
    final code = withoutMarkers(markedCode);
    addSource(mainFilePath, code);
  }

  /// Finds and executes the refactor with [title], updating [content] with
  /// edits sent by the server.
  Future<void> executeRefactor(CodeAction action) async {
    await executeCommandForEdits(
      action.command!,
      content,
      expectDocumentChanges: true,
    );
  }

  /// Expects to find a refactor [CodeAction] in [mainFileUri] at the offset of
  /// the marker with the title [title].
  Future<CodeAction> expectCodeAction(String title) async {
    final action = await getCodeAction(title);
    expect(action, isNotNull, reason: "Action '$title' should be included");
    return action!;
  }

  /// Expects to find a refactor [CodeAction] in [mainFileUri] at the offset of
  /// the marker with the title [title].
  Future<void> expectNoCodeAction(String title) async {
    expect(await getCodeAction(title), isNull);
  }

  /// Attempts to find a refactor [CodeAction] in [mainFileUri] at the offset of
  /// the marker with the title [title].
  Future<CodeAction?> getCodeAction(String title) async {
    final codeActions = await getCodeActions(
      mainFileUri,
      position: _position,
      kinds: const [CodeActionKind.Refactor],
    );
    final commandOrCodeAction =
        findCommand(codeActions, refactoringName, title);
    final codeAction = commandOrCodeAction?.map(
      (command) => throw 'Expected CodeAction, got Command',
      (codeAction) => codeAction,
    );
    return codeAction;
  }

  /// Unwraps the 'arguments' field from the arguments object (which is the
  /// single argument for the command).
  List<String> getRefactorCommandArguments(CodeAction action) {
    final commandArguments = action.command!.arguments as List<Object?>;

    // Our refactor command uses a single object in its arguments so we can have
    // named fields instead of having the client have to know which index
    // corresponds to the parameters.
    final argsObject = commandArguments.single as Map<String, Object?>;

    // Within that object, the 'arguments' field is the List<String> that
    // contains the values for the parameters.
    final arguments = argsObject['arguments'] as List<Object?>;

    return arguments.cast<String>();
  }

  /// Initializes the server.
  ///
  /// Enables all required client capabilities for new refactors unless the
  /// corresponding flags are set to `false`.
  Future<void> initializeServer({
    bool experimentalOptInFlag = true,
    bool commandParameterSupport = true,
    bool fileCreateSupport = true,
    bool applyEditSupport = true,
  }) async {
    final config = {
      if (experimentalOptInFlag) 'experimentalNewRefactors': true,
    };
    final experimentalCapabilities = {
      if (commandParameterSupport) 'commandParameterSupport': true,
    };

    var workspaceCapabilities =
        withConfigurationSupport(emptyWorkspaceClientCapabilities);
    if (applyEditSupport) {
      workspaceCapabilities = withApplyEditSupport(workspaceCapabilities);
    }
    if (fileCreateSupport) {
      workspaceCapabilities = withDocumentChangesSupport(
          withResourceOperationKinds(
              workspaceCapabilities, [ResourceOperationKind.Create]));
    }

    await provideConfig(
      () => initialize(
        workspaceCapabilities: workspaceCapabilities,
        experimentalCapabilities: experimentalCapabilities,
      ),
      config,
    );
  }
}
