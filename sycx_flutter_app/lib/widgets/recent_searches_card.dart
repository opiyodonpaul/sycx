import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:sycx_flutter_app/utils/constants.dart';

class RecentSearchesCard extends StatelessWidget {
  final List<String> searches;
  final VoidCallback onClearAll;
  final Function(int) onRemoveSearch;

  const RecentSearchesCard({
    super.key,
    required this.searches,
    required this.onClearAll,
    required this.onRemoveSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: AppTextStyles.titleStyle,
              ),
              ElevatedButton(
                onPressed: onClearAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryButtonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Clear All',
                  style: AppTextStyles.buttonTextStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimationLimiter(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: searches.length,
              separatorBuilder: (context, index) => const SizedBox(height: 5),
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Container(
                        margin: const EdgeInsets.all(1),
                        child: Card(
                            elevation: 2,
                            color: AppColors.textFieldFillColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 4),
                              leading: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.history,
                                    color: AppColors.primaryButtonColor,
                                  ),
                                  SizedBox(width: 8),
                                  VerticalDivider(
                                    color: AppColors.altPriTextColor,
                                    thickness: 1,
                                    width: 1,
                                  ),
                                  SizedBox(width: 8),
                                ],
                              ),
                              title: Text(
                                searches[index],
                                style: AppTextStyles.bodyTextStyle,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 8),
                                  const VerticalDivider(
                                    color: AppColors.altPriTextColor,
                                    thickness: 1,
                                    width: 1,
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      size: 20,
                                      color: AppColors.gradientEnd,
                                    ),
                                    onPressed: () => onRemoveSearch(index),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            )),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
