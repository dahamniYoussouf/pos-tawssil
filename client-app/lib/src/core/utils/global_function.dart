bool hasNumberInText(String text) {
  return RegExp(r'\d').hasMatch(text);
}
