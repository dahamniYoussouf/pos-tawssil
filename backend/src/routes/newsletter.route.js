import { Router } from "express";
import { validate } from "../middlewares/validate.js";
import { protect, authorize } from "../middlewares/auth.js";
import {
  subscribeNewsletter,
  unsubscribeNewsletter,
  listNewsletterSubscribers
} from "../controllers/newsletter.controller.js";
import {
  subscribeNewsletterValidator,
  unsubscribeNewsletterValidator
} from "../validators/newsletterValidator.js";

const router = Router();

router.post("/subscribe", subscribeNewsletterValidator, validate, subscribeNewsletter);
router.post("/unsubscribe", unsubscribeNewsletterValidator, validate, unsubscribeNewsletter);
router.get("/subscribers", protect, authorize("admin"), listNewsletterSubscribers);

export default router;
