// lib/screens/user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_app/models/app_user.dart'; // Import our AppUser model

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  // Controllers for TextFormField to pre-fill and get edited text
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  AppUser? _currentUserProfile; // To hold the user's profile data
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Function to fetch user data
  Future<void> _fetchUserProfile() async {
    if (_auth.currentUser == null) {
      // No user logged in, cannot fetch profile
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (docSnapshot.exists) {
        // Use AppUser.fromFirestore to create an object from snapshot
        _currentUserProfile = AppUser.fromFirestore(docSnapshot, null);
        // Set initial values to text controllers
        _nameController.text = _currentUserProfile!.name;
        _phoneController.text = _currentUserProfile!.phoneNumber ?? '';
        _addressController.text = _currentUserProfile!.address ?? '';
      } else {
        // This case should ideally not happen if profile is created on signup
        print(
          'User profile document does not exist for UID: ${_auth.currentUser!.uid}',
        );
        _currentUserProfile = null; // Clear existing if any
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to update user data
  Future<void> _updateUserProfile() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if form is not valid
    }
    _formKey.currentState!.save(); // Save current form values

    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in to update profile.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create a new AppUser object with updated data
      final updatedUser = AppUser(
        uid: _auth.currentUser!.uid,
        email:
            _currentUserProfile?.email ??
            _auth.currentUser!.email!, // Keep original email
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        createdAt:
            _currentUserProfile?.createdAt ??
            Timestamp.now(), // Keep original createdAt
      );

      // Use toFirestore() or toUpdateMap() depending on your needs.
      // toUpdateMap() is generally better for updates as it only sends mutable fields.
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update(updatedUser.toUpdateMap());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      _fetchUserProfile(); // Refresh data after update
    } catch (e) {
      print('Error updating user profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserProfile(); // Fetch user data when screen initializes
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUserProfile == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Failed to load user profile.'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _fetchUserProfile,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Email: ${_currentUserProfile!.email}',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        keyboardType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        // No specific validator for optional fields for now
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Delivery Address',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        keyboardType: TextInputType.streetAddress,
                        maxLines: 2, // Allow multiple lines for address
                        // No specific validator for optional fields for now
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton.icon(
                                onPressed: _updateUserProfile,
                                icon: const Icon(Icons.save),
                                label: const Text('SAVE PROFILE'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(
                                    double.infinity,
                                    50,
                                  ), // Make button wider
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
