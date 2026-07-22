import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleForgot() async {
    setState(() => _isLoading = true);
    try {
      await _authService.forgotPassword(_emailController.text);
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ResetPasswordScreen(email: _emailController.text)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
              child: Column(
                children: [
                  const Text("Recover Password", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 20),
                  _buildField(_emailController, "Email Address", Icons.mail_outline),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066FF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      onPressed: _isLoading ? null : _handleForgot,
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Send PIN"),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Back to Login"))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String h, IconData i) => TextField(controller: c, decoration: InputDecoration(prefixIcon: Icon(i, size: 18), hintText: h, filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)));
}