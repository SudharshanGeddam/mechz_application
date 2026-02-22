import 'package:flutter/material.dart';

class SearchingRadarView extends StatefulWidget {
  const SearchingRadarView({super.key});

  @override
  State<SearchingRadarView> createState() => _SearchingRadarViewState();
}

class _SearchingRadarViewState extends State<SearchingRadarView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildRadarCircle(double delay) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final value = (_animationController.value + delay) % 1;

        return Transform.scale(
          scale: value * 3,
          child: Opacity(
            opacity: 1 - value,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Searching")),
      body: SizedBox.expand(
        child: Container(
          color: Colors.orange,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildRadarCircle(0.0),
                      _buildRadarCircle(0.3),
                      _buildRadarCircle(0.6),

                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                        ),
                        child: Icon(Icons.build, color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                const Text(
                  "Searching for nearby mechanics...",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
