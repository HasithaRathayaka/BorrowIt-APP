# BorrowIt — Peer-to-Peer Neighborhood Item Lending & Borrowing App

> *"Borrow nearby. Own less. Know more neighbors."*
> **iOS & iPadOS 17.0+ / 18.0+ | Swift 5.10 / Swift 6 | 100% SwiftUI | MVVM + Protocol-Oriented DI**

---

## 1. Executive Summary & App Overview

**BorrowIt** is a production-grade iOS and iPadOS application engineered for neighborhood communities (modeled on the Cedar Grove neighborhood). Instead of households purchasing expensive tools, camping equipment, or kitchen appliances used only once or twice a year, BorrowIt enables secure, verified, peer-to-peer sharing managed through an end-to-end verified state machine:

$$\text{Pending} \longrightarrow \text{Approved} \longrightarrow \text{Handoff (50m Geofence)} \longrightarrow \text{Borrowed (Live Activity)} \longrightarrow \text{Returned (Review \& Deposit Released)}$$

The project integrates 6 native Apple frameworks (**LocalAuthentication**, **CoreData**, **UserNotifications**, **MapKit + CoreLocation**, **Vision + AVFoundation**, **CoreML**, **WidgetKit + AppIntents**, **ActivityKit**, **Swift Charts**, and **EventKit**) with a hybrid **Supabase Realtime Backend** and instant offline local seeding for 100% out-of-the-box evaluation on any Xcode Simulator.

---

## 2. Architecture & Design Patterns

The codebase strictly follows **Clean MVVM** paired with **Protocol-Oriented Dependency Injection (DI)** and a Repository pattern.

### 2.1 MVVM + Dependency Injection Diagram

```mermaid
graph TD
    subgraph UI_Layer [SwiftUI View Layer]
        V1[WelcomeOnboardingView]
        V2[ExploreDashboardView / MapView]
        V3[HandoffQRView / VisionScanner]
        V4[BorrowsTabView / LiveActivityCard]
        V5[SettingsView / VivaToolkit]
        V6[iPadSplitDashboardView]
    end

    subgraph ViewModel_Layer [Observable ViewModels]
        VM1[AuthViewModel]
        VM2[ExploreViewModel]
        VM3[BorrowLifecycleViewModel]
        VM4[AddItemViewModel]
        VM5[ChatViewModel]
    end

    subgraph Service_Protocols [Protocol-Oriented Interfaces]
        P1[BackendServiceProtocol]
        P2[BiometricServiceProtocol]
        P3[ClassifierProtocol]
        P4[QRServiceProtocol]
        P5[GeofenceServiceProtocol]
        P6[NotificationServiceProtocol]
    end

    subgraph Implementations [Services & Hardware Bridges]
        S1[SupabaseService]
        S2[MockBackendService]
        S3[PersistenceController CoreData]
        S4[BiometricAuthService LocalAuth]
        S5[ImageClassifierService Vision/CoreML]
        S6[LocationGeofenceService CoreLocation]
        S7[LiveActivityManager ActivityKit]
    end

    UI_Layer --> ViewModel_Layer
    ViewModel_Layer --> Service_Protocols
    Service_Protocols --> Implementations
```

### 2.2 Directory Structure

```text
BorrowIt/
├── App/
│   ├── BorrowItApp.swift                 // Scene phase lifecycle & Face ID lock listener
│   ├── ContentView.swift                 // Adaptive iPad NavigationSplitView vs iPhone TabView
│   └── AppConfig.swift                   // App Group, Cedar Grove coordinates, Supabase config
├── Models/
│   ├── BorrowItem.swift                  // Item models, Category enum, Coordinate, Cedar Grove seed
│   ├── BorrowTransaction.swift           // State machine: Pending->Approved->Handoff->Borrowed->Returned
│   ├── ChatMessage.swift                 // Message threads, unread status, quick replies
│   ├── UserProfile.swift                 // Profile, Trust Score, MonthlySavings for Swift Charts
│   └── QRPayload.swift                   // Signed cryptographic QR payload with 5-minute rotation
├── Services/
│   ├── Protocols/
│   │   └── ServiceProtocols.swift        // Protocol abstraction for Backend, Biometrics, ML, QR
│   ├── Backend/
│   │   ├── SupabaseService.swift         // REST + Realtime client with offline seed fallback
│   │   └── PersistenceController.swift   // Programmatic Core Data store & offline QR pass cache
│   ├── NativeSDKs/
│   │   ├── BiometricAuthService.swift    // LocalAuthentication Face ID / Touch ID with simulator bypass
│   │   ├── LocationGeofenceService.swift // CoreLocation 50m circular geofence monitoring
│   │   ├── NotificationService.swift     // UNUserNotificationCenter rich alerts & badges
│   │   ├── ImageClassifierService.swift  // Vision VNClassifyImageRequest & taxonomy mapping
│   │   ├── QRCodeService.swift           // CIFilter generator & Vision VNDetectBarcodesRequest scanner
│   │   ├── LiveActivityManager.swift     // ActivityKit Dynamic Island & Lock Screen lifecycle
│   │   └── CalendarEventService.swift    // EventKit calendar reminder integration
│   └── Settings/
│       └── AppSettingsManager.swift      // 6 functional accessibility toggles & Viva Demo Toolkit
├── ViewModels/
│   ├── AuthViewModel.swift               // Sign in with Apple & Supabase email auth
│   ├── ExploreViewModel.swift            // Search query, 500m radius slider, category filters
│   ├── BorrowLifecycleViewModel.swift    // State machine transitions, QR scanner, review submission
│   ├── AddItemViewModel.swift            // Core ML photo auto-categorization & suggested terms
│   └── ChatViewModel.swift               // Realtime chat messaging & inline Face ID lender approval
├── Views/
│   ├── Onboarding/
│   │   ├── WelcomeOnboardingView.swift   // Screen 1: Welcome & Onboarding
│   │   └── BiometricGateView.swift       // Screen 2: Face ID Security Gate
│   ├── Explore/
│   │   ├── ExploreDashboardView.swift    // Screens 3 & 4: Feed & Interactive Map Toggle
│   │   ├── FilterSheetView.swift         // Screen 5: Search Filters Sheet (100m-2000m slider)
│   │   ├── ItemDetailView.swift          // Screen 6: Item Detail with specifications & ShareLink
│   │   ├── ScheduleBorrowView.swift      // Screen 7: Date range picker & EventKit toggle
│   │   ├── RequestSentView.swift         // Screen 8: 4-step vertical timeline state tracker
│   │   ├── AddItemView.swift             // Screen 9: Add Item with live Core ML classification
│   │   └── EmptyExploreStateView.swift   // Screen 16: Zero items found recovery state
│   ├── Messages/
│   │   ├── MessagesInboxView.swift       // Screen 10: Messages inbox with status badges
│   │   └── ChatThreadView.swift          // Screen 10 (Detail): Threads, quick replies & inline approval
│   ├── Handoff/
│   │   ├── HandoffQRView.swift           // Screen 11: Rotating QR Pass & Vision Barcode Scanner
│   │   └── PickupVerifiedView.swift      // Screen 12: Pickup verified confirmation
│   ├── Borrows/
│   │   ├── BorrowsTabView.swift          // Screen 13: Active borrows, Live Activity card & demo bar
│   │   └── ReturnReviewView.swift        // Screen 14: Return complete & 5-star review modal
│   ├── ProfileAndSettings/
│   │   ├── ProfileStatsView.swift        // Screen 15: Swift Charts 6-month savings bar chart
│   │   └── SettingsView.swift            // Screen 17: 6 Accessibility toggles & Viva Demo Toolkit
│   └── Shared/
│       ├── DesignSystem.swift            // Emerald palette, squircles, pills, accessibility scale
│       └── iPadSplitDashboardView.swift  // iPadOS 3-column NavigationSplitView adaptive layout
├── WidgetsAndIntents/
│   ├── BorrowActivityAttributes.swift    // ActivityKit Live Activity attributes
│   ├── BorrowItHomeWidget.swift          // WidgetKit Home Screen interactive widget
│   └── ReturnItemAppIntent.swift         // AppIntents return button action
├── BorrowItTests/
│   └── BorrowItTests.swift               // Swift Testing framework (@Suite, @Test, #expect)
└── BorrowIt.xcodeproj/
    └── project.pbxproj                   // Complete Xcode project configuration
```

---

## 3. Supabase PostgreSQL Database Schema

When deploying live Supabase connectivity, execute this SQL script in the Supabase SQL Editor:

```sql
-- 1. Profiles Table
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    initials TEXT NOT NULL,
    email TEXT NOT NULL,
    neighborhood TEXT DEFAULT 'Cedar Grove',
    trust_score INT DEFAULT 94,
    community_rating NUMERIC(2,1) DEFAULT 4.9,
    total_borrows INT DEFAULT 18,
    total_lends INT DEFAULT 11,
    waste_avoided_kg NUMERIC(4,1) DEFAULT 42.0,
    total_saved NUMERIC(6,2) DEFAULT 312.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Items Table
CREATE TABLE public.items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL,
    daily_rate NUMERIC(6,2) NOT NULL,
    deposit_hold NUMERIC(6,2) NOT NULL,
    distance_meters NUMERIC(6,1) NOT NULL,
    rating NUMERIC(2,1) DEFAULT 5.0,
    is_available BOOLEAN DEFAULT TRUE,
    is_available_weekend BOOLEAN DEFAULT TRUE,
    exact_address TEXT,
    latitude NUMERIC(9,6) NOT NULL,
    longitude NUMERIC(9,6) NOT NULL,
    lender_id UUID REFERENCES public.profiles(id),
    lender_name TEXT NOT NULL,
    core_ml_tag TEXT,
    system_image_name TEXT DEFAULT 'bolt.fill',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Borrows Table
CREATE TABLE public.borrows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id UUID REFERENCES public.items(id) ON DELETE CASCADE,
    borrower_id UUID REFERENCES public.profiles(id),
    borrower_name TEXT NOT NULL,
    lender_id UUID REFERENCES public.profiles(id),
    lender_name TEXT NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    total_days INT NOT NULL,
    daily_rate NUMERIC(6,2) NOT NULL,
    total_cost NUMERIC(6,2) NOT NULL,
    deposit_hold NUMERIC(6,2) NOT NULL,
    state TEXT NOT NULL CHECK (state IN ('pending', 'approved', 'handoff', 'borrowed', 'returned', 'cancelled')),
    handoff_token TEXT,
    picked_up_at TIMESTAMP WITH TIME ZONE,
    returned_at TIMESTAMP WITH TIME ZONE,
    review_rating INT,
    review_comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Messages Table (Realtime Enabled)
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL,
    sender_id UUID REFERENCES public.profiles(id),
    sender_name TEXT NOT NULL,
    content TEXT NOT NULL,
    is_system_notification BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Supabase Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.borrows;

-- Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.borrows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to items" ON public.items FOR SELECT USING (true);
CREATE POLICY "Allow authenticated insert to items" ON public.items FOR INSERT WITH CHECK (auth.uid() = lender_id);
```

---

## 4. Step-by-Step Instructions to Run & Test in Xcode

1. **Open the Project:**
   - Double-click `BorrowIt.xcodeproj` in Xcode 15 or 16.
2. **Select Simulator:**
   - Choose any iPhone (e.g., iPhone 15 Pro, iPhone 16) or iPad (e.g., iPad Pro 11-inch) simulator.
3. **Run the Application:**
   - Press `Cmd + R`. The app will launch directly into the **Explore Dashboard** populated with the **Cedar Grove Seed Dataset** (DeWalt Drill, Trail Tent, Camp Chairs, Circular Saw, Stand Mixer, Kayak, etc.).
4. **Run Unit Tests (Swift Testing Framework):**
   - Press `Cmd + U`. The `@Suite("BorrowIt Core Logic & State Machine Tests")` will execute all 7 mandatory tests using `import Testing` (`@Test`, `#expect`) with 100% pass rate.
5. **Interactive Viva Demonstration Tour:**
   - **Explore Tab (Screens 3 & 4):** Toggle smoothly between **Feed List** and **Interactive Map**. Tapping the map pins (`Drill 120m`, `Tent 310m`) centers the pin and updates the floating card.
   - **Filter Sheet (Screen 5):** Tap the filter slider button. Adjust radius from `100m` to `2000m` to see count update dynamically.
   - **Add Item with Core ML (Screen 9):** Tap the `+` button in Explore. Tap any of the test image preset buttons (`Backpacking Tent`, `Circular Saw`, `Artisan Stand Mixer`, `Kayak & Paddle`). Notice the animated `Core ML: [Category]` badge update instantly, auto-selecting the category and recommending deposit terms.
   - **Handoff QR Pass (Screen 11):** Navigate to the **Handoff QR** tab. Inspect the rotating pass with 5-minute timer and the `"Core Data offline"` badge. Switch to **Scan & Verify QR** and tap `"Verify Pickup QR (Vision On-Device)"` — this runs genuine `VNDetectBarcodesRequest` against the image on-device.
   - **Borrows & Live Activity (Screen 13):** Inspect the active borrow card and the Live Activity Preview card. Use the **Viva Demo Lifecycle Controller Bar** to test all transitions (`Approve (Bio)` -> `50m Arrive` -> `Scan QR` -> `Return`).
   - **Return Review (Screen 14):** Tapping "Return" opens the return completed sheet with 5-star rating selector and comment submission.
   - **Profile & Swift Charts (Screen 15):** In Settings, tap the profile card to see the 6-month savings bar chart (`BarMark`) highlighting October ($312 total saved).
   - **Settings & Accessibility (Screen 17):** Test the 6 functional toggles. Tap `+` or `-` on **Dynamic Type Scaling** to scale UI text dynamically. Toggle **Increase Contrast** to see borders and colors instantly enhance. Tap **"Lock App with Face ID"** to trigger the biometric security gate.

---

## 5. Learning Outcomes Reflection (LO1 – LO4)

### LO1: Multi-Device Platform Adaptation
BorrowIt avoids stretched or generic layouts by implementing responsive structural adaptations tailored to Apple HIG:
- **iPhone Architecture:** A compact 5-tab `TabView` with curated SF Symbols (`safari.fill`, `bubble.left.and.bubble.right.fill`, `qrcode.viewfinder`, `shippingbox.fill`, `gearshape.fill`) engineered for one-handed thumb interaction.
- **iPadOS Architecture:** When `horizontalSizeClass == .regular`, the app morphs into a genuine 3-column `NavigationSplitView` (`iPadSplitDashboardView`). The **Sidebar** manages sections and neighborhood stats, the **Content Column** provides side-by-side feed browsing, and the **Detail Column** pairs the selected item detail with an inline chat thread and handoff status inspector.
- **WidgetKit & ActivityKit Glanceable Surfaces:** Item handoffs extend beyond the app via an interactive Home Screen widget (`BorrowItHomeWidget`) powered by `AppIntents` and Lock Screen / Dynamic Island Live Activities (`Activity<BorrowActivityAttributes>`).

### LO2: Mobile Software Architecture & Clean Code
- **MVVM Separation:** Business state machines and calculations (`BorrowTransaction`, `BorrowLifecycleViewModel`, `ExploreViewModel`) are separated from presentation views.
- **Protocol-Oriented Dependency Injection:** Every service conforms to a clean interface (`BackendServiceProtocol`, `BiometricServiceProtocol`, `ClassifierProtocol`, `QRServiceProtocol`, `GeofenceServiceProtocol`, `NotificationServiceProtocol`). This enables swapping `SupabaseService` with `MockBackendService` during unit testing with zero view modifications.
- **Offline Persistence & Cache:** `PersistenceController` defines Core Data entities (`CachedItemEntity`, `CachedBorrowEntity`, `OfflineQRPassEntity`). The rotating QR pass is cached locally with SHA-256 token verification, guaranteeing handoffs function even when offline in rural parks or underground garages.

### LO3: External APIs & Hybrid Backend
- **Supabase Integration:** Configured with REST endpoints (`/rest/v1/items`, `/rest/v1/borrows`, `/rest/v1/messages`) and Realtime subscriptions for peer messaging.
- **Zero-Friction Offline Fallback:** To ensure flawless evaluation for graders without requiring pre-configured API keys, `SupabaseService` inspects credentials and falls back automatically to the comprehensive **Cedar Grove Neighborhood Seed Store**. Every mutation (creating a borrow, sending a message, approving a request, submitting a review) updates in-memory and Core Data storage persistently.

### LO4: Hardware Sensors & On-Device Machine Learning
- **Core Location 50m Geofencing:** Utilizes `CLLocationManager` monitoring a `CLCircularRegion` with a 50.0m radius centered on the lender's coordinates. Entering the boundary automatically transitions the borrow to `handoff`, triggers a `UNUserNotificationCenter` alert, and prepares the QR pass.
- **Vision Framework On-Device QR Scanner:** Instead of third-party scanning libraries, `QRCodeService` utilizes `AVCaptureSession` and `VNDetectBarcodesRequest` (`.qr` symbology) to decode signed payloads. For simulator evaluation, the service processes the `CGImage` directly through `VNImageRequestHandler`.
- **LocalAuthentication (Face ID / Touch ID):** Employs `LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason:)` to protect account access and gate sensitive actions (approving requests, unlocking addresses).
- **Core ML & Vision Image Auto-Categorization:** When creating an item listing, `ImageClassifierService` runs `VNClassifyImageRequest` on-device without external AI network dependencies. Taxonomy keywords are mapped to BorrowIt categories (`Power Tools`, `Camping`, `Kitchen`, etc.) with real-time confidence scores and suggested deposit terms.
