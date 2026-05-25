// import 'package:flutter/material.dart';

// class TeacherEarningsTab extends StatelessWidget {
//   const TeacherEarningsTab({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // The custom Bottom Navigation Bar matching your image
//       bottomNavigationBar: _buildBottomNavigationBar(),
//       body: Container(
//         // Applying the identical 3-color gradient from the Profile Tab
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFF3B82F6), // Vivid blue at top
//               Color(0xFF93C5FD), // Light blue in middle
//               Color(0xFFFFFFFF), // White at bottom
//             ],
//             stops: [0.0, 0.4, 1.0],
//           ),
//         ),
//         child: SafeArea(
//           bottom: false,
//           child: ListView(
//             padding: EdgeInsets.zero,
//             children: [
//               const SizedBox(height: 16),
//               // Header Title
//               const Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 24.0),
//                 child: Text(
//                   'Earnings',
//                   style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),
              
//               // Total Balance Main Card
//               _buildBalanceCard(),
              
//               const SizedBox(height: 32),
              
//               // Recent Transactions Section
//               const Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 24.0),
//                 child: Text(
//                   'Recent Transactions',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF1E293B), // Dark slate color
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
              
//               // Transaction List
//               _buildTransactionItem(
//                 title: 'Student Payment',
//                 date: 'May 24, 2026',
//                 amount: '+Rp 250,000',
//                 isIncome: true,
//               ),
//               _buildTransactionItem(
//                 title: 'Withdrawal to Bank',
//                 date: 'May 20, 2026',
//                 amount: '-Rp 1,000,000',
//                 isIncome: false,
//               ),
//               _buildTransactionItem(
//                 title: 'Student Payment',
//                 date: 'May 18, 2026',
//                 amount: '+Rp 350,000',
//                 isIncome: true,
//               ),
//               _buildTransactionItem(
//                 title: 'Student Payment',
//                 date: 'May 15, 2026',
//                 amount: '+Rp 150,000',
//                 isIncome: true,
//               ),
//               _buildTransactionItem(
//                 title: 'Platform Fee',
//                 date: 'May 15, 2026',
//                 amount: '-Rp 15,000',
//                 isIncome: false,
//               ),
              
//               const SizedBox(height: 40), // Bottom padding
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBalanceCard() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 24.0),
//       padding: const EdgeInsets.all(24.0),
//       decoration: BoxDecoration(
//         // A deeper blue gradient for the card to pop against the lighter background
//         gradient: const LinearGradient(
//           colors: [
//             Color(0xFF1E40AF), // Deep indigo/blue
//             Color(0xFF3B82F6), // Vivid blue
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [
//           BoxShadow(
//             color: const Color(0xFF1E40AF).withOpacity(0.3),
//             blurRadius: 16,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Total Balance',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.white70,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Rp 5,432,000',
//             style: TextStyle(
//               fontSize: 32,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           const SizedBox(height: 24),
//           Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: const [
//                     Text(
//                       'This Month',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.white70,
//                       ),
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                       'Rp 1,200,000',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 height: 30,
//                 width: 1,
//                 color: Colors.white.withOpacity(0.2),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: const [
//                     Text(
//                       'Pending',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.white70,
//                       ),
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                       'Rp 400,000',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTransactionItem({
//     required String title,
//     required String date,
//     required String amount,
//     required bool isIncome,
//   }) {
//     // Green for income, Red for withdrawal
//     final Color iconColor = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);
//     final Color iconBgColor = isIncome ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2);

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12, left: 24, right: 24),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           // Icon Box
//           Container(
//             width: 48,
//             height: 48,
//             decoration: BoxDecoration(
//               color: iconBgColor,
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
//               color: iconColor,
//               size: 24,
//             ),
//           ),
//           const SizedBox(width: 16),
//           // Text Details
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF1E293B),
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   date,
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: Colors.grey.shade500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Amount
//           Text(
//             amount,
//             style: TextStyle(
//               fontSize: 15,
//               fontWeight: FontWeight.bold,
//               color: iconColor,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBottomNavigationBar() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 16,
//             offset: const Offset(0, -4), // Shadow pointing upwards
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: BottomNavigationBar(
//           // Set to index 2 because Earnings is the 3rd item
//           currentIndex: 2, 
//           type: BottomNavigationBarType.fixed,
//           backgroundColor: Colors.white,
//           elevation: 0,
//           selectedItemColor: const Color(0xFF3B82F6), // Active Vivid Blue
//           unselectedItemColor: Colors.grey.shade400, // Inactive Gray
//           selectedFontSize: 12,
//           unselectedFontSize: 12,
//           selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
//           items: const [
//             BottomNavigationBarItem(
//               icon: Padding(
//                 padding: EdgeInsets.only(bottom: 4.0),
//                 child: Icon(Icons.home_rounded),
//               ),
//               label: 'Home',
//             ),
//             BottomNavigationBarItem(
//               icon: Padding(
//                 padding: EdgeInsets.only(bottom: 4.0),
//                 child: Icon(Icons.verified_user_outlined),
//               ),
//               label: 'Verification',
//             ),
//             BottomNavigationBarItem(
//               icon: Padding(
//                 padding: EdgeInsets.only(bottom: 4.0),
//                 child: Icon(Icons.account_balance_wallet_rounded),
//               ),
//               label: 'Earnings',
//             ),
//             BottomNavigationBarItem(
//               icon: Padding(
//                 padding: EdgeInsets.only(bottom: 4.0),
//                 child: Icon(Icons.person_outline_rounded),
//               ),
//               label: 'Profile',
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';

class TeacherEarningsTab extends StatelessWidget {
  const TeacherEarningsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Wrapped in a Container to apply the requested 3-color gradient
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF3B82F6), // Vivid blue
            Color(0xFF93C5FD), // Light blue
            Color(0xFFFFFFFF), // White
          ],
          stops: [0.0, 0.4, 1.0],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Earnings',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white, // Updated to white to contrast with the blue background
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Container(
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  // Deep blue gradient for the main card to pop visually
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1E40AF),
                      Color(0xFF3B82F6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E40AF).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      '\$12,450.00',
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('This Month',
                                  style: textTheme.bodySmall?.copyWith(
                                      color: Colors.white70)),
                              Text('\$4,560.00',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  )),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pending',
                                  style: textTheme.bodySmall?.copyWith(
                                      color: Colors.white70)),
                              Text('\$890.00',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Recent Transactions',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B), // Dark slate for readability
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              ...List.generate(5, (index) => _buildTransactionItem(context, index)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, int index) {
    final textTheme = Theme.of(context).textTheme;
    final isIncome = index % 2 == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white, // Clean white floating card
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // Soft shadow instead of the flat outline border
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isIncome
                  ? const Color(0xFFD1FAE5) // Soft green bg
                  : const Color(0xFFFEE2E2), // Soft red bg
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              size: 22,
              color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIncome ? 'Course Purchase' : 'Withdrawal',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Feb ${20 - index}, 2024',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            isIncome
                ? '+\$${(index + 1) * 25}.00'
                : '-\$${(index + 1) * 100}.00',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }
}