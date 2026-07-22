import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'profile_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  String? _validateInputs() {
    final emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
    final phoneRegex = RegExp(r"^((\+92)|(0092))-{0,1}\d{3}-{0,1}\d{7}$|^\d{11}$");

    if (_nameController.text.trim().length < 3) return "Full Name must be at least 3 characters.";
    if (!emailRegex.hasMatch(_emailController.text)) return "Please enter a valid email address.";
    if (!phoneRegex.hasMatch(_phoneController.text)) return "Enter a valid phone number (e.g., 03001234567).";
    if (_passwordController.text.length < 6) return "Password must be at least 6 characters long.";
    return null;
  }

  void _handleRegister() async {
    final error = _validateInputs();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.register(
          _nameController.text,
          _emailController.text,
          _phoneController.text,
          _passwordController.text
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account created successfully!"), backgroundColor: Colors.green));
        // New users always go to Profile Setup first
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                const Text("Join the", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                const Text("CivicCare AI Portal.", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0066FF))),
                const SizedBox(height: 25),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                  child: Column(
                    children: [
                      const Text("Create Account", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      const SizedBox(height: 20),
                      _buildInputField(_nameController, "Full Name", Icons.person_outline),
                      const SizedBox(height: 15),
                      _buildInputField(_emailController, "Email Address", Icons.mail_outline),
                      const SizedBox(height: 15),
                      _buildInputField(_phoneController, "Phone Number", Icons.phone_outlined),
                      const SizedBox(height: 15),
                      _buildInputField(_passwordController, "Password", Icons.lock_outline, obscure: true),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity, height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0066FF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                          onPressed: _isLoading ? null : _handleRegister,
                          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Register Now", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Already have an account? Sign In", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))
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
      controller: controller,
      obscureText: obscure,
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