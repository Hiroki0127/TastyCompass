"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const helmet_1 = __importDefault(require("helmet"));
const morgan_1 = __importDefault(require("morgan"));
const dotenv_1 = __importDefault(require("dotenv"));
// Load environment variables
dotenv_1.default.config();
const app = (0, express_1.default)();
const PORT = process.env.PORT || 3000;
// Middleware
app.use((0, helmet_1.default)()); // Security headers
app.use((0, cors_1.default)()); // Enable CORS
app.use((0, morgan_1.default)('combined')); // Logging
app.use(express_1.default.json()); // Parse JSON bodies
app.use(express_1.default.urlencoded({ extended: true })); // Parse URL-encoded bodies
// Basic health check route
app.get('/', (req, res) => {
    res.json({
        message: 'TastyCompass API Server',
        version: '1.0.0',
        status: 'running',
        timestamp: new Date().toISOString()
    });
});
// Import routes
const restaurants_1 = __importDefault(require("./routes/restaurants"));
const auth_1 = __importDefault(require("./routes/auth"));
const favorites_1 = __importDefault(require("./routes/favorites"));
// API routes
app.get('/api/health', (req, res) => {
    res.json({
        status: 'healthy',
        uptime: process.uptime(),
        timestamp: new Date().toISOString()
    });
});
// Auth routes
app.use('/api/auth', auth_1.default);
// Restaurant routes
app.use('/api/restaurants', restaurants_1.default);
// Favorite routes
app.use('/api/favorites', favorites_1.default);
// Start server
app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📱 API available at: http://localhost:${PORT}`);
    console.log(`🔍 Health check: http://localhost:${PORT}/api/health`);
    console.log(`💾 Storage: In-memory (data will reset on restart)`);
});
exports.default = app;
