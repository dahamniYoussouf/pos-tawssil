import axios from "axios";

export async function sendGupshupTemplate({ to, templateId, params }) {
  const apiKey = process.env.GUPSHUP_API_KEY;
  const source = process.env.GUPSHUP_SOURCE_NUMBER;

  if (!apiKey || !source || !templateId) {
    throw new Error("Gupshup config missing");
  }

  const body = new URLSearchParams();
  body.append("source", source);
  body.append("destination", to);
  body.append("template", JSON.stringify({ id: templateId, params }));

  const response = await axios.post(
    "https://api.gupshup.io/wa/api/v1/template/msg",
    body,
    {
      headers: {
        apikey: apiKey,
        "Content-Type": "application/x-www-form-urlencoded",
      },
    }
  );

  return response.data;
}
