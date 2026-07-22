import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'profile_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      final result = await _authService.login(_emailController.text, _passwordController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Successful"), backgroundColor: Colors.green),
        );

        // CONDITIONAL REDIRECTION (Tasks 2 & 3)
        if (result['isProfileComplete'] == true) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1E),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                const Text("Intelligent", style: TextStyle(fontSize: 35, fontWeight: FontWeight.w900, color: Colors.white)),
                const Text("City Management.", style: TextStyle(fontSize: 35, fontWeight: FontWeight.w900, color: Color(0xFF0066FF))),
                const SizedBox(height: 25),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                  child: Column(
                    children: [
                      const Text("Citizen Login", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      const SizedBox(height: 20),
                      _buildInputField(_emailController, "Email Address", Icons.mail_outline),
                      const SizedBox(height: 15),
                      _buildInputField(_passwordController, "Password", Icons.lock_outline, obscure: true),
                      Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
                              child: const Text("Recover Password", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0066FF)))
                          )
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity, height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066FF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Access Portal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                          child: const Text("Don't have an account? Register now", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller, obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
        hintText: hint,
        filled: true, fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}