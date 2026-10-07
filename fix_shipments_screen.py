import re

with open('lib/src/features/shipments/presentation/screens/shipments_screen.dart', 'r') as f:
    content = f.read()

# The file has _FilterBottomSheet class nested inside _ShipmentCardSkeleton
# We need to fix this by:
# 1. Removing the inner _FilterBottomSheet class
# 2. Adding _FilterBottomSheet at the top level after _ShipmentCardSkeleton

# First, let's find the pattern of the broken class
# The broken file has _FilterBottomSheet inside _ShipmentCardSkeleton

# Pattern to find the broken class structure
pattern = r'(class _ShipmentCardSkeleton extends StatelessWidget \{\s*.*?)\n\s*}\n\s*class _FilterBottomSheet extends StatelessWidget \{.*?\n\}\s*\n\}\s*$'

replacement = r'''\1
  }
}

class _FilterBottomSheet extends StatelessWidget {
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;

  const _FilterBottomSheet({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = AppUtils.getFilterOptions();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtrele',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...filters.map((filter) => RadioListTile<String>(
                title: Text(filter),
                value: filter,
                groupValue: currentFilter,
                onChanged: (value) => onFilterChanged(value!),
                activeColor: context.colorScheme.primary,
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}'''

new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)

with open('lib/src/features/shipments/presentation/screens/shipments_screen.dart', 'w') as f:
    f.write(new_content)

print('Fixed _FilterBottomSheet placement')