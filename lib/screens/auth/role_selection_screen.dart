import 'package:flutter/material.dart';
import 'package:wenest/utils/constants.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryColor, AppColors.secondaryColor],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Welcome to WeNest!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Select your role to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Role Cards
                Expanded(
                  child: ListView(
                    children: [
                      _buildRoleCard(
                        context,
                        UserType.user,
                      ),
                      const SizedBox(height: 20),
                      _buildRoleCard(
                        context,
                        UserType.agent,
                      ),
                      const SizedBox(height: 20),
                      _buildRoleCard(
                        context,
                        UserType.agency,
                      ),
                      const SizedBox(height: 20),
                      _buildRoleCard(
                        context,
                        UserType.landlord,
                      ),
                    ],
                  ),
                ),
                
                // Already have account
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, AppRoutes.login);
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  Widget _buildRoleCard(BuildContext context, UserType userType) {
    final displayName = UserTypeHelper.getUserTypeDisplayName(userType);
    final description = UserTypeHelper.getUserTypeDescription(userType);
    final icon = UserTypeHelper.getUserTypeIcon(userType);
    
    Color color;
    switch (userType) {
      case UserType.user:
        color = AppColors.primaryColor;
        break;
      case UserType.agent:
        color = AppColors.secondaryColor;
        break;
      case UserType.agency:
        color = AppColors.accentColor;
        break;
      case UserType.landlord:
        color = Colors.teal;
        break;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.signup,
            arguments: userType,
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}