import * as functions from "firebase-functions";
import fetch from "node-fetch";

export const geminiChat = functions.https.onRequest(async (req, res) => {
  try {
    const { message, language, businessData } = req.body;

    if (!message) {
      res.status(400).json({ error: "Message is required" });
      return;
    }

    const apiKey = functions.config().gemini.key;

    const prompt = `
You are FlacronCV AI Assistant.
Language: ${language}

Business Info:
${JSON.stringify(businessData)}

Customer Message:
${message}

Reply clearly and politely.
`;

    const response = await fetch(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=" +
        apiKey,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
        }),
      }
    );

    const data: any = await response.json();

    const reply =
      data.candidates?.[0]?.content?.parts?.[0]?.text ??
      "Sorry, I could not answer that.";

    res.json({ reply });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "AI error" });
  }
});
