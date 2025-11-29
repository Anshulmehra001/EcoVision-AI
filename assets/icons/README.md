# App Icon Setup

## Current Status

This directory should contain the app icon for EcoVision AI.

## Required File

Place your app icon as `app_icon.png` in this directory. The icon should be:
- **Size**: 1024x1024 pixels (minimum)
- **Format**: PNG with transparency
- **Design**: Should represent EcoVision AI branding

## Generating Icons

Once you have `app_icon.png` in this directory, run:

```bash
flutter pub run flutter_launcher_icons
```

This will automatically generate all required icon sizes for:
- Android (various densities)
- iOS (if configured)
- Web (if configured)

## Design Guidelines

The icon should:
- Be simple and recognizable at small sizes
- Use the EcoVision AI color scheme (greens, blues for environmental theme)
- Include elements suggesting AI, nature, or environmental analysis
- Work well on both light and dark backgrounds

## Temporary Icon

Until a custom icon is created, the default Flutter icon will be used. To create a placeholder:

1. Create a 1024x1024 PNG with your design
2. Save it as `app_icon.png` in this directory
3. Run `flutter pub run flutter_launcher_icons`

## Icon Resources

Consider using these tools to create your icon:
- Figma (free design tool)
- Canva (icon templates)
- Adobe Illustrator
- Online icon generators
