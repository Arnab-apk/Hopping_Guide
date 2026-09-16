# Magic Lane Maps Flutter Example

This project demonstrates how to use the **Magic Lane Maps SDK for Flutter**.  
It showcases basic map usage, adding markers, performing searches, calculating routes, and starting navigation simulations.

The example works on Android and iOS devices with support for both phones and emulators.
Other platforms are not supported yet.

## Features
- Display maps with the **GemMap widget**
- Add **point and line markers**
- Perform **text and category-based searches**
- Calculate routes and run a **navigation simulation**
- Clear and reset the map view

## Getting Started

1. Make sure the [minimum requirements](https://developer.magiclane.com/docs/flutter/guides/introduction/minimum-requirements) are met.
2. Get your **API token** from the [Magic Lane Developer Portal](https://developer.magiclane.com/api/login) - required to unlock full functionality and to remove the watermark from the map widget.
3. Make sure the current working directory is in the `example` folder. Pass the token at build time:
   ```bash
   flutter run --dart-define=GEM_TOKEN=your_api_token_here
   ```
   Select the device where the application needs to be run and experiment with the example.
    
## Documentation

Check the [Guides](https://developer.magiclane.com/docs/flutter/guides/category/introduction) for complete documentation regarding all the features.

## Other examples

Over **60 examples** are available on the [Magic Lane Developer Website](https://developer.magiclane.com/docs/flutter/examples/get-started/) showcasing the most common use cases. Follow the [Get Started with Examples Guide](https://developer.magiclane.com/docs/flutter/examples/get-started/) for instructions on how to run the examples.

## Integrate the Magic Lane SDK for Flutter in another project

Check the [Integrate the SDK guide](https://developer.magiclane.com/docs/flutter/guides/get-started/integrate-sdk) for instructions regarding integration in a new/existing project.