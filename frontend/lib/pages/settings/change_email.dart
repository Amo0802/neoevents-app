// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:events_amo/providers/user_provider.dart';
// import 'package:events_amo/providers/auth_provider.dart';

// class ChangeEmailPage extends StatefulWidget {
//   const ChangeEmailPage({super.key});

//   @override
//   State<ChangeEmailPage> createState() => _ChangeEmailPageState();
// }

// class _ChangeEmailPageState extends State<ChangeEmailPage> {
//   final _formKey = GlobalKey<FormState>();
  
//   final _newEmailController = TextEditingController();
//   final _verificationCodeController = TextEditingController();
//   final _passwordController = TextEditingController();
  
//   bool _isLoading = false;
//   bool _isCodeSent = false;
//   bool _obscurePassword = true;
//   String _currentEmail = '';
  
//   @override
//   void initState() {
//     super.initState();
//     _loadCurrentEmail();
//   }
  
//   void _loadCurrentEmail() {
//     // Get the current user's email from the AuthProvider
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     _currentEmail = authProvider.currentUser?.email ?? '';
//   }
  
//   @override
//   void dispose() {
//     _newEmailController.dispose();
//     _verificationCodeController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
  
//   Future<void> _sendVerificationCode() async {
//     if (!_formKey.currentState!.validate()) return;
    
//     setState(() {
//       _isLoading = true;
//     });
    
//     try {
//       // Use UserProvider to initiate email change process
//       final userProvider = Provider.of<UserProvider>(context, listen: false);
      
//       bool success = await userProvider.updateEmail(
//         _passwordController.text,
//         _newEmailController.text
//       );
      
//       if (success) {
//         setState(() {
//           _isCodeSent = true;
//           _isLoading = false;
//         });
        
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Verification code sent to ${_newEmailController.text}')),
//           );
//         }
//       } else {
//         throw Exception(userProvider.error ?? 'Failed to send verification code');
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to send verification code: $e')),
//         );
//       }
//     }
//   }
  
//   Future<void> _verifyAndChangeEmail() async {
//     if (!_formKey.currentState!.validate()) return;
    
//     setState(() {
//       _isLoading = true;
//     });
    
//     try {
//       // Use UserProvider to verify the email change
//       final userProvider = Provider.of<UserProvider>(context, listen: false);
      
//       bool success = await userProvider.verifyEmailChange(
//         _verificationCodeController.text
//       );
      
//       if (success) {
//         // Update the auth provider to refresh user data
//         final authProvider = Provider.of<AuthProvider>(context, listen: false);
//         await authProvider.refreshUser();
        
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Email changed successfully')),
//           );
//           Navigator.pop(context);
//         }
//       } else {
//         throw Exception(userProvider.error ?? 'Failed to verify email change');
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to change email: $e')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//         elevation: 0,
//         title: Text(
//           "Change Email",
//           style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
//         ),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios, color: Colors.white),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(20),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildCurrentEmailInfo(),
//               SizedBox(height: 30),
//               _buildTextField(
//                 controller: _newEmailController,
//                 label: "New Email Address",
//                 hint: "Enter your new email address",
//                 keyboardType: TextInputType.emailAddress,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your new email address';
//                   }
//                   if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
//                     return 'Please enter a valid email address';
//                   }
//                   if (value == _currentEmail) {
//                     return 'New email cannot be the same as the current email';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 20),
//               _buildPasswordField(
//                 controller: _passwordController,
//                 label: "Your Password",
//                 hint: "Enter your password to confirm",
//                 obscure: _obscurePassword,
//                 toggleObscure: () {
//                   setState(() {
//                     _obscurePassword = !_obscurePassword;
//                   });
//                 },
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your password';
//                   }
//                   return null;
//                 },
//               ),
//               SizedBox(height: 20),
//               if (_isCodeSent) ...[
//                 _buildTextField(
//                   controller: _verificationCodeController,
//                   label: "Verification Code",
//                   hint: "Enter the code sent to your new email",
//                   keyboardType: TextInputType.number,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please enter the verification code';
//                     }
//                     return null;
//                   },
//                 ),
//                 SizedBox(height: 40),
//                 _buildVerifyButton(),
//               ] else ...[
//                 SizedBox(height: 40),
//                 _buildSendCodeButton(),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
  
//   Widget _buildCurrentEmailInfo() {
//     return Container(
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
//           width: 1.5,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 Icons.email_outlined,
//                 color: Theme.of(context).colorScheme.secondary,
//               ),
//               SizedBox(width: 10),
//               Text(
//                 "Current Email",
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 10),
//           Text(
//             _currentEmail,
//             style: TextStyle(
//               color: Colors.grey[300],
//               fontSize: 16,
//             ),
//           ),
//           SizedBox(height: 10),
//           Text(
//             "A verification code will be sent to your new email to confirm the change.",
//             style: TextStyle(
//               color: Colors.grey[400],
//               fontSize: 14,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     required String? Function(String?) validator,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//             color: Colors.white,
//           ),
//         ),
//         SizedBox(height: 8),
//         TextFormField(
//           controller: controller,
//           validator: validator,
//           keyboardType: keyboardType,
//           style: TextStyle(color: Colors.white),
//           decoration: InputDecoration(
//             hintText: hint,
//             hintStyle: TextStyle(color: Colors.grey[500]),
//             fillColor: Colors.white.withValues(alpha: 0.1),
//             filled: true,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide.none,
//             ),
//             contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildPasswordField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     required bool obscure,
//     required Function toggleObscure,
//     required String? Function(String?) validator,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//             color: Colors.white,
//           ),
//         ),
//         SizedBox(height: 8),
//         TextFormField(
//           controller: controller,
//           obscureText: obscure,
//           validator: validator,
//           style: TextStyle(color: Colors.white),
//           decoration: InputDecoration(
//             hintText: hint,
//             hintStyle: TextStyle(color: Colors.grey[500]),
//             fillColor: Colors.white.withValues(alpha: 0.1),
//             filled: true,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(12),
//               borderSide: BorderSide.none,
//             ),
//             contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//             suffixIcon: IconButton(
//               icon: Icon(
//                 obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
//                 color: Colors.grey[400],
//               ),
//               onPressed: () => toggleObscure(),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSendCodeButton() {
//     return SizedBox(
//       width: double.infinity,
//       height: 55,
//       child: ElevatedButton(
//         onPressed: _isLoading ? null : _sendVerificationCode,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Theme.of(context).colorScheme.secondary,
//           foregroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           disabledBackgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
//         ),
//         child: _isLoading
//             ? SizedBox(
//                 height: 24,
//                 width: 24,
//                 child: CircularProgressIndicator(
//                   color: Colors.white,
//                   strokeWidth: 2,
//                 ),
//               )
//             : Text(
//                 "Send Verification Code",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//       ),
//     );
//   }

//   Widget _buildVerifyButton() {
//     return SizedBox(
//       width: double.infinity,
//       height: 55,
//       child: ElevatedButton(
//         onPressed: _isLoading ? null : _verifyAndChangeEmail,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Theme.of(context).colorScheme.tertiary,
//           foregroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           disabledBackgroundColor: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.6),
//         ),
//         child: _isLoading
//             ? SizedBox(
//                 height: 24,
//                 width: 24,
//                 child: CircularProgressIndicator(
//                   color: Colors.white,
//                   strokeWidth: 2,
//                 ),
//               )
//             : Text(
//                 "Verify and Change Email",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//       ),
//     );
//   }
// }