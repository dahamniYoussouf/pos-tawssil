import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.resolve(__dirname, "../../.env") });

const appTimeZone = process.env.APP_TIMEZONE || process.env.TZ || "Africa/Algiers";

if (!process.env.APP_TIMEZONE) {
  process.env.APP_TIMEZONE = appTimeZone;
}

if (!process.env.TZ) {
  process.env.TZ = appTimeZone;
}

