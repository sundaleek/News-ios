# AutoDocNews

A native UIKit news feed for iPhone and iPad.

## Stack

- Swift and UIKit
- MVVM + Combine
- `UICollectionViewCompositionalLayout`
- `UICollectionViewDiffableDataSource`
- `URLSession` with async/await
- No third-party dependencies

## Run

1. Open `AutoDocNews.xcodeproj` in Xcode 15 or later.
2. Select an iPhone or iPad simulator.
3. Build and run with `Cmd+R`.

The first page is loaded from the AutoDoc news API. Additional pages are requested only when the collection view approaches its last item.
