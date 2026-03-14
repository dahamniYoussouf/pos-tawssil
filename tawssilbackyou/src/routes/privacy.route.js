import express from 'express';
import { getPrivacyPolicy } from '../controllers/privacy.controller.js';

const router = express.Router();

router.get('/', getPrivacyPolicy);

export default router;