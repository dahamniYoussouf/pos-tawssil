import { Router } from "express";
import { cacheMiddleware } from "../middlewares/cache.middleware.js";
import * as geoCtrl from "../controllers/geo.controller.js";

const router = Router();

router.get("/wilayas", cacheMiddleware({ ttl: 3600 }), geoCtrl.getWilayas);
router.get("/communes", cacheMiddleware({ ttl: 3600 }), geoCtrl.getCommunes);
router.get("/communes/:id", cacheMiddleware({ ttl: 3600 }), geoCtrl.getCommune);

export default router;
