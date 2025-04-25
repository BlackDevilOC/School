class AuthService {
  // Hardcoded credentials for demo purposes
  // In a real app, you'd use a secure authentication method
  final String validUsername = 'Ibadullah';
  final String validPassword = 'ibad1234';

  bool login(String username, String password) {
    return username == validUsername && password == validPassword;
  }

  void logout() {
    // Additional logout logic would go here
    // Such as clearing stored tokens, etc.
  }
}
