import 'package:flutter/material.dart';
import 'services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleReset() async {
    setState(() => _isLoading = true);
    try {
      // FIXED: Only passing 2 arguments (token/PIN and new password)
      await _authService.resetPassword(_pinController.text, _passwordController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password reset successful!"), backgroundColor: Colors.green));
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
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
                  const Text("Reset Password", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Text("For: ${widget.email}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 20),
                  _buildField(_pinController, "Verification PIN / Token", Icons.pin_outlined),
                  const SizedBox(height: 15),
                  _buildField(_passwordController, "New Password", Icons.lock_outline, obscure: true),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066FF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      onPressed: _isLoading ? null : _handleReset,
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Update Password"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController c, String h, IconData i, {bool obscure = false}) => TextField(controller: c, obscureText: obscure, decoration: InputDecoration(prefixIcon: Icon(i, size: 18), hintText: h, filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)));
}