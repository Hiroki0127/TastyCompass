"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReviewService = exports.FavoriteService = exports.UserService = void 0;
const userService_1 = require("./userService");
const userServicePostgres_1 = require("./userServicePostgres");
const favoriteService_1 = require("./favoriteService");
const favoriteServicePostgres_1 = require("./favoriteServicePostgres");
const reviewService_1 = require("./reviewService");
const reviewServicePostgres_1 = require("./reviewServicePostgres");
const USE_POSTGRES = process.env.USE_POSTGRES === 'true';
console.log(`📦 Using ${USE_POSTGRES ? 'PostgreSQL' : 'in-memory'} services`);
// Export the appropriate service classes
exports.UserService = USE_POSTGRES ? userServicePostgres_1.UserService : userService_1.UserService;
exports.FavoriteService = USE_POSTGRES ? favoriteServicePostgres_1.FavoriteService : favoriteService_1.FavoriteService;
exports.ReviewService = USE_POSTGRES ? reviewServicePostgres_1.ReviewService : reviewService_1.ReviewService;
