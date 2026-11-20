import '../../core/services/pseudo.dart';
import '../../core/strings.dart';

/// Message affiché pour un pseudo refusé (issues #543 et #631).
String pseudoErrorMessage(PseudoError error) {
  return switch (error) {
    PseudoError.tooShort => Strings.pseudoTooShort,
    PseudoError.tooLong => Strings.pseudoTooLong,
    PseudoError.invalidCharacters => Strings.pseudoInvalid,
    PseudoError.forbiddenWord => Strings.pseudoForbidden,
  };
}
