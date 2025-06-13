// import 'package:events_amo/pages/create_events.dart';
// import 'package:flutter/material.dart';

// class CreateEventMenu extends StatelessWidget {
//   final Function onClose;

//   const CreateEventMenu({super.key, required this.onClose});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 8,
//       color: Color(0xFF1A1F38),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Container(
//         width: 300,
//         padding: EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               "Create New",
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             SizedBox(height: 20),
//             _buildOption(
//               context, 
//               "Official Event", 
//               Icons.event_available, 
//               Theme.of(context).colorScheme.primary,
//               () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => CreateEventPage()),
//                 );
//                 onClose();
//               }
//             ),
//             SizedBox(height: 16),
//             _buildOption(
//               context, 
//               "Community Event", 
//               Icons.groups, 
//               Theme.of(context).colorScheme.secondary,
//               () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => CreateEventPage()),
//                 );
//                 onClose();
//               }
//             ),
//             SizedBox(height: 16),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildOption(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(15),
//       child: Container(
//         padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(15),
//           border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
//           gradient: LinearGradient(
//             colors: [
//               color.withValues(alpha: 0.2),
//               color.withValues(alpha: 0.05),
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(icon, color: color, size: 28),
//             SizedBox(width: 15),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }