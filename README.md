# TastyCompass 🍽️

A modern iOS restaurant discovery app built with SwiftUI and Node.js backend, featuring location-based restaurant search, user reviews, favorites, and Google Places integration.

## ✨ Features

### Core Functionality
- **🔍 Location-Based Search**: Find restaurants near you using GPS coordinates
- **⭐ User Reviews & Ratings**: Write, read, and rate restaurant experiences
- **❤️ Favorites System**: Save and manage your favorite restaurants
- **🗺️ Interactive Maps**: View restaurant locations with directions
- **📱 Modern iOS UI**: Built with SwiftUI for a native iOS experience

### Advanced Features
- **🔐 User Authentication**: Secure login/signup with JWT tokens
- **📊 Google Reviews Integration**: View real Google Places reviews with pagination
- **🎯 Smart Filtering**: Filter by cuisine, price range, rating, and distance
- **💾 Offline Support**: Cached images and data for better performance
- **🔄 Pull-to-Refresh**: Easy content updates
- **📤 Share Functionality**: Share restaurant details with friends

## 🛠 Tech Stack

### Frontend (iOS)
- **Swift** - Primary programming language
- **SwiftUI** - Modern declarative UI framework
- **Combine** - Reactive programming and async operations
- **MapKit** - Location services and mapping
- **Core Location** - GPS and location permissions
- **URLSession** - HTTP networking

### Backend (Node.js)
- **Node.js** - Runtime environment
- **TypeScript** - Type-safe JavaScript
- **Express.js** - Web application framework
- **JWT** - Authentication tokens
- **bcryptjs** - Password hashing
- **dotenv** - Environment configuration

### APIs & Services
- **Google Places API** - Restaurant data and reviews
- **REST API** - Custom backend endpoints
- **HTTP/HTTPS** - Network communication

### Development Tools
- **Xcode** - iOS development environment
- **nodemon** - Backend development server
- **ts-node** - TypeScript execution
- **Git** - Version control

## 📱 Screenshots

*Coming soon - app screenshots will be added here*

## 🚀 Getting Started

### Prerequisites
- **iOS Development**: Xcode 15+, iOS 16+
- **Backend Development**: Node.js 18+, npm/yarn
- **Google Places API**: API key for restaurant data

### Installation

#### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/TastyCompass.git
cd TastyCompass
```

#### 2. Backend Setup
```bash
cd tastycompass-backend
npm install
```

#### 3. Environment Configuration
Create a `.env` file in the `tastycompass-backend` directory:
```env
PORT=3000
GOOGLE_PLACES_API_KEY=your_google_places_api_key
JWT_SECRET=your_jwt_secret_key
```

#### 4. Start Backend Server
```bash
npm run dev
```
The backend will be available at `http://localhost:3000`

#### 5. iOS App Setup
1. Open `TastyCompass/TastyCompass.xcodeproj` in Xcode
2. Configure your Google Places API key in `Config.plist`
3. Build and run on iOS Simulator or device

### Configuration

#### Google Places API Setup
1. Get a Google Places API key from [Google Cloud Console](https://console.cloud.google.com/)
2. Enable the following APIs:
   - Places API
   - Maps JavaScript API
   - Geocoding API
3. Add the API key to your backend `.env` file and iOS `Config.plist`

## 📖 API Documentation

### Authentication Endpoints
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/refresh` - Refresh JWT token

### Restaurant Endpoints
- `GET /api/restaurants/search` - Search restaurants by location
- `GET /api/restaurants/:id` - Get restaurant details
- `GET /api/restaurants/:id/google-reviews` - Get Google reviews (paginated)

### User Endpoints
- `GET /api/favorites` - Get user's favorite restaurants
- `POST /api/favorites/toggle` - Add/remove favorite
- `GET /api/reviews` - Get user's reviews
- `POST /api/reviews` - Create new review
- `PUT /api/reviews/:id` - Update review
- `DELETE /api/reviews/:id` - Delete review

## 🏗 Architecture

### iOS App Structure
```
TastyCompass/
├── Views/           # SwiftUI views and screens
├── Components/      # Reusable UI components
├── Services/        # API and data services
├── Models/          # Data models and structures
├── Managers/        # Business logic managers
└── Assets.xcassets/ # App icons and images
```

### Backend Structure
```
tastycompass-backend/
├── src/
│   ├── routes/      # API route definitions
│   ├── services/    # Business logic services
│   ├── types/       # TypeScript type definitions
│   ├── middleware/  # Express middleware
│   └── database/    # Database connections
├── dist/            # Compiled JavaScript
└── package.json     # Dependencies and scripts
```

## 🔧 Development

### Running Tests
```bash
# Backend tests
cd tastycompass-backend
npm test

# iOS tests
# Run in Xcode: Product → Test
```

### Building for Production
```bash
# Backend production build
cd tastycompass-backend
npm run build

# iOS production build
# Archive in Xcode: Product → Archive
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Google Places API for restaurant data
- SwiftUI community for UI components
- Node.js ecosystem for backend tools

## 📞 Support

If you have any questions or need help, please:
- Open an issue on GitHub
- Check the documentation
- Contact the development team

## 🔮 Roadmap

### Upcoming Features
- [ ] Push notifications
- [ ] Social sharing improvements
- [ ] Advanced filtering options
- [ ] Restaurant recommendations
- [ ] User profiles and avatars
- [ ] Reservation system integration
- [ ] Multi-language support
- [ ] Dark mode theme

### Technical Improvements
- [ ] PostgreSQL database integration
- [ ] Redis caching
- [ ] Unit test coverage
- [ ] CI/CD pipeline
- [ ] Performance optimization
- [ ] Accessibility improvements

---

**TastyCompass** - Discover amazing restaurants near you! 🍽️✨
