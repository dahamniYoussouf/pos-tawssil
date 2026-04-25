import { sequelize } from "./src/config/database.js";
import cacheService from "./src/services/cache.service.js";

beforeEach(async () => {
  await sequelize.sync({ force: true }); // fresh schema before tests
});

afterEach(async () => {
  await cacheService.flush();
});
