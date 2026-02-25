# Drawing Gallery Design

**Goal:** A gallery page accessible from the Canvas tab that displays all drawings created by the current user, grouped by day in a 2-column grid.

**Entry point:** Gallery button (right nav item) in `CanvasViewController`.

## Architecture

Follows existing VIPER pattern (Presenter + ViewModel + ViewController).

```
Features/Canvas/
  Presenter/
    DrawingGalleryPresenter.swift       # Fetches drawings, groups by day
  ViewModels/
    DrawingGalleryViewModel.swift       # Section model (date + drawings)
  Views/
    DrawingGalleryViewController.swift  # Collection view + section headers
    DrawingGalleryCell.swift            # Thumbnail cell with Kingfisher

Shared/Views/
    LoadingView.swift                   # Reusable loading indicator wrapper
```

## Data Flow

1. User taps gallery button in `CanvasViewController`
2. `AppCoordinator.openDrawingGallery(from:)` pushes `DrawingGalleryViewController`
3. Presenter calls `FirestoreDrawingService.fetchDrawings(uid:, from:, to:)`
4. Presenter groups `[DrawingModel]` into `[DrawingGallerySection]` by calendar day, newest day first
5. Presenter notifies view via `delegate.didUpdate(viewModel:)`
6. `UICollectionView` renders sections with date headers + 2-column image grid

## Layout

- 2-column grid using `UICollectionViewFlowLayout`
- Section headers showing date (e.g., "February 25, 2026")
- Square aspect ratio cells with rounded corners
- 26pt horizontal padding (matches `ViewComponentConstants.horizontalPadding`)
- 12pt inter-item spacing, 16pt line spacing

## Key Decisions

- **Fetch**: Last 90 days in one call. No pagination for MVP.
- **Image loading**: Kingfisher loads `imageURL` directly. No thumbnail optimization yet.
- **Empty state**: Centered label when no drawings exist.
- **Loading state**: Reusable `LoadingView` shared component wrapping `UIActivityIndicatorView`. Designed to be swapped to custom animation later.
- **Tap action**: None for MVP. Gallery is view-only.
- **Navigation**: `SoulverseNavigationView` with back button, title "Gallery".
- **Theme**: All colors use theme-aware properties (`.themeTextPrimary`, `.themeCardBackground`, etc.)
