import 'package:flutter/material.dart';
import '../models/focus_reward.dart';

class FocusGemCollection extends StatelessWidget {
  const FocusGemCollection({
    super.key,
    required this.collection,
    this.legacyGems = 0,
  });

  final FocusRewardCollection collection;
  final int legacyGems;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Your gem collection',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final gem in FocusGem.values)
              SizedBox(
                width: 140,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Image.asset(gem.assetPath, height: 56, width: 56),
                        const SizedBox(height: 8),
                        Text(
                          '${gem.label} × ${collection.count(gem)}',
                          style: TextStyle(
                            color: Color(gem.colorValue),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(gem.category),
                        Text(gem.timeRange),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (legacyGems > 0)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Earlier gems: $legacyGems · Kept separately because their focus durations were not saved.',
            ),
          ),
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            '1 ranking point per completed focus minute. Gem rarity does not multiply points.',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
