import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'database_helper.dart';
import 'utils.dart';
import 'official.dart';

class OfficialsPage extends StatefulWidget {
  const OfficialsPage({Key? key}) : super(key: key);

  @override
  State<OfficialsPage> createState() => _OfficialsPageState();
}

class _OfficialsPageState extends State<OfficialsPage> {
  // Theme colors
  final Color _primaryColor = const Color(0xFF0A2463);
  final Color _accentColor = const Color(0xFF3E92CC);
  final Color _backgroundColor = const Color(0xFFF8F9FA);

  void _navigateToOfficialDetails(Official official, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(official.name),
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
          ),
          body: _OfficialDetailsScreen(official: official),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: _primaryColor,
        colorScheme: ColorScheme.light(
          primary: _primaryColor,
          secondary: _accentColor,
        ),
      ),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          title: const Text('SK Officials'),
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: FutureBuilder<List<Official>>(
          future: getAllOfficials(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF0A2463))),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading officials',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            final officials = snapshot.data ?? [];

            if (officials.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people_outline,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No officials available',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            final chairman =
                officials.firstWhereOrNull((o) => o.position == "SK Chairman");
            final secretary =
                officials.firstWhereOrNull((o) => o.position == "SK Secretary");
            final treasurer =
                officials.firstWhereOrNull((o) => o.position == "SK Treasurer");
            final kagawadList =
                officials.where((o) => o.position == "SK Kagawad").toList();

            final isMobile = MediaQuery.of(context).size.width < 600;

            return isMobile
                ? _buildMobileLayout(
                    chairman, secretary, treasurer, kagawadList)
                : _buildDesktopLayout(
                    chairman, secretary, treasurer, kagawadList);
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(Official? chairman, Official? secretary,
      Official? treasurer, List<Official> kagawads) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Chairman, Secretary, Treasurer Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (secretary != null)
                InkWell(
                  onTap: () => _navigateToOfficialDetails(secretary, context),
                  child: _buildExecutiveCard(
                      secretary, Icons.description_outlined),
                ),
              if (chairman != null)
                InkWell(
                  onTap: () => _navigateToOfficialDetails(chairman, context),
                  child: _buildExecutiveCard(chairman, Icons.person_outline),
                ),
              if (treasurer != null)
                InkWell(
                  onTap: () => _navigateToOfficialDetails(treasurer, context),
                  child: _buildExecutiveCard(
                      treasurer, Icons.attach_money_outlined),
                ),
            ],
          ),
          const SizedBox(height: 40),
          // Kagawads Section
          Text(
            'SK Kagawads',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          if (kagawads.isEmpty)
            const Text("No Kagawads available")
          else
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: kagawads
                  .map((kagawad) => InkWell(
                        onTap: () =>
                            _navigateToOfficialDetails(kagawad, context),
                        child: _buildKagawadCard(kagawad, Icons.people_outline),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(Official? chairman, Official? secretary,
      Official? treasurer, List<Official> kagawads) {
    final List<Official> allOfficials = [];

    if (chairman != null) allOfficials.add(chairman);
    if (secretary != null) allOfficials.add(secretary);
    if (treasurer != null) allOfficials.add(treasurer);
    allOfficials.addAll(kagawads);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allOfficials.length,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () => _navigateToOfficialDetails(allOfficials[index], context),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildMobileCard(allOfficials[index]),
          ),
        );
      },
    );
  }

  Widget _buildExecutiveCard(Official official, IconData icon) {
    return SizedBox(
      width: 300,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildOfficialImage(official.image),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: _primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    official.position,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                official.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKagawadCard(Official official, IconData icon) {
    return SizedBox(
      width: 200,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildOfficialImage(official.image, size: 80),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: _primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    official.position,
                    style: TextStyle(
                      fontSize: 14,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                official.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCard(Official official) {
    IconData icon;
    switch (official.position) {
      case "SK Chairman":
        icon = Icons.person_outline;
        break;
      case "SK Secretary":
        icon = Icons.description_outlined;
        break;
      case "SK Treasurer":
        icon = Icons.attach_money_outlined;
        break;
      default:
        icon = Icons.people_outline;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildOfficialImage(official.image),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 20, color: _primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        official.position,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    official.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficialImage(String base64Image, {double size = 100}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _primaryColor, width: 2),
      ),
      child: ClipOval(
        child: (base64Image.isNotEmpty)
            ? _decodeImage(base64Image)
            : Icon(Icons.person, size: size * 0.6, color: Colors.grey),
      ),
    );
  }

  Widget _decodeImage(String base64Image) {
    try {
      if (base64Image.startsWith('data:image') || base64Image.length > 500) {
        return Image.memory(
          base64Decode(base64Image),
          fit: BoxFit.cover,
        );
      } else {
        return Image.network(
          base64Image,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.broken_image, size: 40, color: Colors.grey.shade400),
        );
      }
    } catch (_) {
      return Icon(Icons.broken_image, size: 40, color: Colors.grey.shade400);
    }
  }
}

class _OfficialDetailsScreen extends StatelessWidget {
  final Official official;

  const _OfficialDetailsScreen({required this.official});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Large image display
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
            ),
            child: official.image.isNotEmpty
                ? Image.memory(
                    base64Decode(official.image),
                    fit: BoxFit.contain,
                  )
                : Center(
                    child: Icon(
                      Icons.person,
                      size: 150,
                      color: Colors.grey.shade400,
                    ),
                  ),
          ),
          const SizedBox(height: 30),
          // Name and position
          Text(
            official.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            official.position,
            style: TextStyle(
              fontSize: 20,
              color: theme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 30),
          // Back button
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Back to Officials'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

extension SafeFirstWhere<E> on List<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
