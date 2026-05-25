// import 'package:flutter/material.dart';
// import '../../../../core/constants/app_sizes.dart';
// import '../../../../core/widgets/common/avatar_widget.dart';
// import '../../../../core/widgets/inputs/search_input.dart';

// class TeacherStudentsTab extends StatelessWidget {
//   const TeacherStudentsTab({super.key});

//   static const _names = [
//     'Alice Johnson',
//     'Bob Smith',
//     'Carol White',
//     'David Brown',
//     'Eva Green',
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final colorScheme = Theme.of(context).colorScheme;
//     final textTheme = Theme.of(context).textTheme;

//     return SafeArea(
//       child: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(AppSizes.md),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Students',
//                   style: textTheme.headlineMedium?.copyWith(
//                     fontWeight: FontWeight.w700,
//                     color: colorScheme.onSurface,
//                   ),
//                 ),
//                 const SizedBox(height: AppSizes.md),
//                 const SearchInput(
//                     hint: 'Search students...', size: SearchInputSize.small),
//               ],
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               padding:
//                   const EdgeInsets.symmetric(horizontal: AppSizes.md),
//               itemCount: 10,
//               itemBuilder: (context, index) =>
//                   _buildStudentItem(context, index),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStudentItem(BuildContext context, int index) {
//     final colorScheme = Theme.of(context).colorScheme;
//     final textTheme = Theme.of(context).textTheme;
//     final name = _names[index % _names.length];

//     return Container(
//       margin: const EdgeInsets.only(bottom: AppSizes.sm),
//       padding: const EdgeInsets.all(AppSizes.md),
//       decoration: BoxDecoration(
//         color: colorScheme.surface,
//         borderRadius: BorderRadius.circular(AppSizes.radiusMd),
//         border: Border.all(color: colorScheme.outlineVariant),
//       ),
//       child: Row(
//         children: [
//           AvatarWidget(name: name, size: AvatarSize.medium),
//           const SizedBox(width: AppSizes.md),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(name,
//                     style: textTheme.titleSmall
//                         ?.copyWith(fontWeight: FontWeight.w600)),
//                 Text('3 courses enrolled',
//                     style: textTheme.bodySmall?.copyWith(
//                         color: colorScheme.onSurfaceVariant)),
//               ],
//             ),
//           ),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text('75%',
//                   style: textTheme.titleSmall?.copyWith(
//                     fontWeight: FontWeight.w600,
//                     color: colorScheme.primary,
//                   )),
//               Text('progress',
//                   style: textTheme.bodySmall?.copyWith(
//                       color: colorScheme.onSurfaceVariant)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class TeacherStudentsTab extends StatelessWidget {
  const TeacherStudentsTab({super.key});

  static const _names = [
    'Alice Johnson',
    'Bob Smith',
    'Carol White',
    'David Brown',
    'Eva Green',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // The exact 3-color gradient used on the Profile and Earnings tabs
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
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Students',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Custom Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildSearchBar(),
              ),
              const SizedBox(height: 24),
              
              // Student List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 24.0, 
                    right: 24.0, 
                    bottom: 40.0, // Extra padding at the bottom so the last item isn't cut off
                  ),
                  itemCount: 10,
                  itemBuilder: (context, index) => _buildStudentItem(index),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06), // Soft shadow
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search students...',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey.shade400,
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildStudentItem(int index) {
    final name = _names[index % _names.length];
    
    // Grabbing the first letter of the name for the avatar
    final initial = name.isNotEmpty ? name[0] : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // Subtle depth
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Custom built Avatar Widget
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE0E7FF), // Very light indigo background
            child: Text(
              initial,
              style: const TextStyle(
                color: Color(0xFF4F46E5), // Indigo text
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Name and Course Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B), // Dark slate
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '3 courses enrolled',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // Progress Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '75%',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B82F6), // Vivid blue
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'progress',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}