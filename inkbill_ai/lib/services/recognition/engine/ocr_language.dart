enum OcrLanguage {
  english('English', 'en'),
  hindi('Hindi', 'hi'),
  marathi('Marathi', 'mr');

  final String displayName;
  final String code;

  const OcrLanguage(this.displayName, this.code);
}
