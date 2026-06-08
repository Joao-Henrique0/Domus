class NumTranform {
  static String formatValue(double value) {
    // Verifica se o valor é um inteiro
    if (value == value.roundToDouble()) {
      return value.toInt().toString(); // Converte para inteiro e exibe sem decimais
    } else {
      return value.toStringAsFixed(2); // Caso contrário, exibe com duas casas decimais
    }
  }
}