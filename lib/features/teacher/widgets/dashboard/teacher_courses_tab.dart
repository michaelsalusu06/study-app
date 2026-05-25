import 'package:flutter/material.dart';

class TeacherCoursesTab extends StatelessWidget {
  const TeacherCoursesTab({super.key});

  // Hardcoded dummy data to replace DummyData.courses for instant compilation
  static const _courses = [
    {'title': 'Advanced Mathematics', 'students': 142, 'rating': 4.8},
    {'title': 'Physics 101: Mechanics', 'students': 89, 'rating': 4.5},
    {'title': 'Introduction to Computer Science', 'students': 256, 'rating': 4.9},
    {'title': 'Biology: Cell Structure', 'students': 64, 'rating': 4.2},
    {'title': 'World History: 20th Century', 'students': 112, 'rating': 4.7},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // The unified 3-color background gradient
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
                  'My Courses',
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
              
              // Course List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 24.0, 
                    right: 24.0, 
                    bottom: 40.0, 
                  ),
                  itemCount: _courses.length,
                  itemBuilder: (context, index) => _buildCourseItem(_courses[index]),
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
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search courses...',
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

  Widget _buildCourseItem(Map<String, dynamic> course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF), // Very light indigo background
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.menu_book_rounded, 
              color: Color(0xFF4F46E5), // Indigo icon
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          // Course Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course['title'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B), // Dark slate
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.people_alt_rounded, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      '${course['students']} students',
                      style: TextStyle(
                        fontSize: 12, 
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)), // Amber star
                    const SizedBox(width: 4),
                    Text(
                      course['rating'].toString(),
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.w600, 
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Popup Menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400),
            onSelected: (value) {
              // Action handlers go here later
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'analytics', child: Text('Analytics')),
              PopupMenuItem(
                value: 'delete', 
                child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}